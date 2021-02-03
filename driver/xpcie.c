/*
 * xpcie.c
 *
 * Created on: 26-okt.-2012
 * Author: jens
 */

// http://www.makelinux.net/ldd3/
/** Contains handy "loadable module"-definitions.
 * http://www.makelinux.net/ldd3/chp-2-sect-6
 */
#include <linux/module.h>

/** __init and __exit macro's.
 * Also: module_init(...), module_exit(...)
 */
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/pci.h>
#include <linux/interrupt.h>
#include <linux/types.h>
#include <linux/mm.h>
#include <linux/wait.h>
#include <linux/semaphore.h>
#include <linux/sched.h>
#include <linux/string.h>
#include <linux/delay.h>
#include <linux/workqueue.h>
#include <linux/time.h>

#include "xpcie.h"
#include "xilinxip.h"

/** Module information.
 * http://www.makelinux.net/ldd3/chp-2-sect-6
 */
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Jens Van den Broeck");
MODULE_DESCRIPTION("PCI-express driver for the Xilinx XUPV5 FPGA board (ML505)");
MODULE_VERSION("1:0.1");

const uint16_t PCI_VENDORID = 0x10EE;
const uint16_t PCI_DEVICEID = 0x0505;
const uint16_t DEV_MAJOR = 100;
const char* DRIVER_NAME = "xpcie";
const int FAILURE = -1;
#define BAR_COUNT 3

#define msg(str, args...) printk("[%s::%s] " str "\n",DRIVER_NAME,__func__,##args)
#define err(str, args...) msg("ERROR *** " str,##args)
#define REVERSE(x) ((((x) & 0xFF000000)>>24) | (((x) & 0x00FF0000) >> 8) | (((x) & 0x0000FF00) << 8) | (((x) & 0x000000FF) << 24))

/* PCI Device instance.
 * Structure containing information wrt the PCI card.
 */
struct pci_dev *xpcie_card;

/* PCI BAR address, size, buffer
 */
struct bar_descriptor {
	uint32_t base;
	uint32_t length;
void __iomem *buffer;
};
struct bar_descriptor bars[BAR_COUNT];

uint64_t blocknr = 0;
volatile int currentwritebuf = 0;
volatile int currentreadbuf = 0;
int dmabufcount = 0;
bool started = false;
bool enabled = true;
uint64_t elapsed = 0;
bool lastxfer = false;

uint8_t *dmaReadBufferArray[MAX_DMA_BUF_COUNT];
dma_addr_t dmaReadBufferAddressArray[MAX_DMA_BUF_COUNT];

// 'volatile' is nodig!
volatile uint32_t *fpga_control;
volatile uint32_t *fpga_dma;
volatile uint32_t *fpga_pcie;

// nodig voor blocking read
// http://rico-studio.com/linux/block-read/
wait_queue_head_t read_wq;

bool reading = false;

/** Function prototypes
 */
int xpcie_init(void);
void xpcie_exit(void);
int xpcie_open(struct inode *, struct file *);
int xpcie_release(struct inode *, struct file *);
ssize_t xpcie_read(struct file *, char __user *, size_t, loff_t *);
ssize_t xpcie_write(struct file *, const char __user *, size_t, loff_t *);
long xpcie_ioctl(struct file *, unsigned int, unsigned long);
irqreturn_t msi_handler(int, void*, struct pt_regs*);
int map_mmap(struct file *, struct vm_area_struct *);

void increase_currentreadbuf(void);
void increase_currentwritebuf(void);


#if defined(MEASURE_TIME_DMA)
uint64_t totaltime_usec = 0;
uint64_t totaldummy_usec = 0;
#endif

struct file_operations operations = {
	.open = xpcie_open,
	.release = xpcie_release,
	.read = xpcie_read,
	.write = xpcie_write,
	.unlocked_ioctl = xpcie_ioctl,
	.mmap = map_mmap
};

void increase_currentreadbuf() {
	currentreadbuf++;
	if(currentreadbuf>=dmabufcount)
		currentreadbuf = 0;
}

void increase_currentwritebuf() {
	currentwritebuf++;
	if(currentwritebuf>=dmabufcount)
		currentwritebuf = 0;
	wake_up_interruptible(&read_wq);
}

/** Driver entry point.
 * Called when module is inserted.
 */
module_init( xpcie_init);

/** Driver exit point.
 * Called when module is removed.
 */
module_exit( xpcie_exit);

/** Driver entry point.
 * Called when module is inserted into kernel.
 */
int xpcie_init(void) {
	int res, i;

	/* Walk the list of PCI devices present in the system,
	 * and search for our Xilinx PCIe card.
	 *
	 * Returns NULL on error.
	 */
	xpcie_card = pci_get_device(PCI_VENDORID, PCI_DEVICEID, NULL);
	if (xpcie_card == NULL) {
		err("xpcie not found");
		return FAILURE;
	}
	msg("xpcie found");

	/* The first thing to be done when the PCI card is found,
	 * is enabling the device.
	 *
	 * Returns 0 on success.
	 */
	if (pci_enable_device(xpcie_card) > 0) {
		err("failed to enable xpcie card");
		return FAILURE;
	}
	msg("xpcie card enabled");

	/* Request I/O address regions.
	 * Each region is either memory or I/O. Essentially they are the same,
	 * but I/O is not cached by the CPU. I/O can have "side effects" on the device.
	 *
	 * pci_resource_start Returns the first address (memory address or I/O port number)
	 * associated with one of the 6 PCI I/O regions.
	 * pci_resource_len Returns the length associated with this resource.
	 * pci_resource_flags Returns the flags associated with this resource.
	 *
	 * By using pci_resource_* functions, one does not have to take the other configuration
	 * data into account. Linux has done this for us, and structured the resource information.
	 *
	 * http://www.embeddedlinux.org.cn/EssentialLinuxDeviceDrivers/final/ch10lev1sec3.html
	 */
	msg("retrieving I/O address regions (BAR registers)");
	for (i = 0; i < BAR_COUNT; i++) {
		bars[i].base = pci_resource_start(xpcie_card, i);
		bars[i].length = pci_resource_len(xpcie_card, i);
		msg("BAR%u: start=0x%08lx, size=0x%08lx",
				i, (unsigned long)bars[i].base, (unsigned long)bars[i].length);

		/* Reserve memory regions.
		 *
		 * Parameters: PCI device, BAR id, name of owner (string)
		 *
		 * http://www.embeddedlinux.org.cn/EssentialLinuxDeviceDrivers/final/ch10lev1sec3.html
		 */
		if (pci_request_region(xpcie_card, i, DRIVER_NAME) != 0) {
			err("BAR%u memory region in use!", i);
		}

		/* Allocate resources, do physical-virtual address mapping.
		 * The physical PCI address is mapped into the virtual kernel address space.
		 *
		 * This function returns a virtual address that maps to
		 * the physical address associated with the PCI memory region.
		 *
		 * The virtual address obtained can be released by using the pci_iounmap()-function.
		 * Obtained addresses should NOT be dereferenced directly!
		 * The correct way to read/write I/O memory regions is by using ioread*() and iowrite*().
		 *
		 * Returns NULL on error.
		 *
		 * http://www.makelinux.net/ldd3/chp-8-sect-4#chp-8-sect-4
		 * http://www.makelinux.net/ldd3/chp-9-sect-4
		 * http://www.embeddedlinux.org.cn/EssentialLinuxDeviceDrivers/final/ch10lev1sec3.html
		 *
		 * Function definition: [linux_source]/lib/iomap.c
		 */
		bars[i].buffer = pci_iomap(xpcie_card, i, ~0);
		if (bars[i].buffer == NULL) {
			err("BAR%u mapping failed", i);
		} else {
			msg("BAR%u mapped at 0x%08lx", i, (unsigned long)bars[i].buffer);
		}
	}

	/* Buffer allocation
	 */
	fpga_control 	= (volatile uint32_t*)bars[0].buffer;
	fpga_dma 		= (volatile uint32_t*)bars[1].buffer;
	fpga_pcie 		= (volatile uint32_t*)bars[2].buffer;

	/* Allocate interrupts
	 */
	if(pci_enable_msi(xpcie_card)==0) {
		msg("MSI interrupt allocated: %u", xpcie_card->irq);
	} else {
		err("MSI interrupt not allocated");
	}
	if(request_irq(xpcie_card->irq, (irq_handler_t)msi_handler, 0, "xpcie", NULL)==0) {
		msg("Interrupt handler installed");
	} else {
		err("Interrupt handler not installed");
	}

	/* Write command register:
	 * ENABLE BUS MASTER
	 * ENABLE MEMORY ACCESS
	 * ENABLE IO ACCESS
	 *
	 * http://www.xilinx.com/support/answers/36829.htm
	 * http://www.xilinx.com/support/answers/38447.htm
	 */
	//pci_write_config_word(xpcie_card, 4, 7);

	/* Enable bus mastering
	 */
	pci_set_master(xpcie_card);

	/* Register driver in kernel.
	 */
	res = register_chrdev(DEV_MAJOR, DRIVER_NAME, &operations);
	if (res) {
		err("registration of character device failed");
	}

	if (pci_set_consistent_dma_mask(xpcie_card, 0xffffff) == 0) {
		msg("consistent dma mask ok");
	} else {
		msg("consistent dma mask not ok");
		return FAILURE;
	}


	for(i=0; i<MAX_DMA_BUF_COUNT; i++) {
		dmaReadBufferArray[i] = pci_alloc_consistent(xpcie_card, BUF_SIZE, &(dmaReadBufferAddressArray[i]));
		if(dmaReadBufferArray[i]==NULL) {
			err("unable to allocate DMA buffer %u", i);
		} else {
			dmabufcount++;
		}
	}
	msg("%u DMA buffers of size 0x%08x allocated", dmabufcount, BUF_SIZE);

	init_waitqueue_head(&read_wq);

	msg("driver is loaded");

	return 0;
}

/** Driver exit point.
 * Called when module is removed from kernel.
 */
void xpcie_exit(void) {
	int i;

	msg("free DMA regions");
	for(i=0; i<MAX_DMA_BUF_COUNT; i++) {
		if(dmaReadBufferArray[i]!=NULL) {
			pci_free_consistent(xpcie_card, BUF_SIZE, dmaReadBufferArray[i], dmaReadBufferAddressArray[i]);
		}
	}

	/* Remove every allocated resource:
	 * - buffers 'kfree'
	 * - memory regions 'release_mem_region'
	 * - interrupts 'free_irq'
	 * - I/O memory 'iounmap'
	 * - unregister chrdev 'unregister_chrdev'
	 *
	 * Make every allocated pointer a NULL-pointer.
	 */
	msg("unmapping I/O regions (BAR mappings)");
	for (i = 0; i < BAR_COUNT; i++) {
		if (bars[i].buffer != NULL) {
			pci_iounmap(xpcie_card, bars[i].buffer);
		}

		pci_release_region(xpcie_card, i);
	}

	msg("free allocated interrupts");
	if(xpcie_card->irq!=0) {
		free_irq(xpcie_card->irq, NULL);
		pci_disable_msi(xpcie_card);
	}

	msg("unregistering character device");
	unregister_chrdev(DEV_MAJOR, DRIVER_NAME);

	msg("driver is unloaded");
}

/**
 * Called when user accesses device
 */
int xpcie_open(struct inode *inode, struct file *file) {
	return 0;
}

/**
 * Called when user closes device
 */
int xpcie_release(struct inode *inode, struct file *file) {
	return 0;
}

/** Called when user wants to read from the device.
 *
 * Arguments:
 * - fileptr File pointer to the opened device.
 * - user_buffer USER SPACE address where the data is to be placed.
 * - count Number of bytes to be read.
 *
 * http://www.makelinux.net/ldd3/chp-9-sect-4
 */
ssize_t xpcie_read(struct file *fileptr, char __user *user_buffer, size_t count, loff_t *offset) {
	wait_event_interruptible(read_wq, currentreadbuf!=currentwritebuf);
	*user_buffer = (char)currentreadbuf;
	reading = true;
	return 1;
}

/** Called when user wants to write to the device.
*
* Arguments:
* - fileptr File pointer to the opened device.
* - user_buffer USER SPACE address where the source data is located.
* - count Number of bytes to be written.
*
* http://www.makelinux.net/ldd3/chp-9-sect-4
*/
ssize_t xpcie_write(struct file *fileptr, const char __user *user_buffer, size_t count, loff_t *offset) {
	return 0;
}

/** Called when user sends a command to the device.
 * User can execute this command like so:
 * [evt_return_value =] ioctl(fd, XPCIE_IOC_CMD1, 10);
 *
 * Arguments:
 * - fileptr File pointer to the opened device.
 * - cmd Command code to be executed.
 * - arg Command argument.
 * !!! if user does not give third argument, value is undefined!
 *
 * http://www.makelinux.net/ldd3/chp-6-sect-1
 * http://www.linuxforu.com/2011/08/io-control-in-linux/
 */
long xpcie_ioctl(struct file *fileptr, unsigned int cmd, unsigned long arg) {
	switch (cmd) {

	case XPCIE_IOC_STATUS:
		return (long)REVERSE(fpga_control[0]);
		break;

	case XPCIE_IOC_ENABLE:
		fpga_control[0] = REVERSE(0x80000000);
		break;

	case XPCIE_IOC_DISABLE:
		fpga_control[0] = REVERSE(0x00000000);
		break;

	case XPCIE_IOC_DONE:
		reading = false;
		increase_currentreadbuf();
		return (long)lastxfer;
		break;

	case XPCIE_IOC_READDMAREGISTER:
		return REVERSE(fpga_dma[(unsigned int)arg]);
		break;

	case XPCIE_IOC_READPCIREGISTER:
		return REVERSE(fpga_pcie[(unsigned int)arg]);
		break;

	case XPCIE_IOC_GETBUFCOUNT:
		return dmabufcount;
		break;

	case XPCIE_IOC_LASTXFER:
		lastxfer = true;
		fpga_control[0] = REVERSE(0x40000000);
		break;

	case XPCIE_IOC_CHECK:
		return XPCIE_MAGIC;
		break;

	case XPCIE_IOC_RESET:
		lastxfer = false;
		fpga_control[0] = REVERSE(0x20000000);
#if defined(MEASURE_TIME_DMA)
		msg("Total time spent in DMA transfers: %llu us", totaltime_usec);
		msg("Total time spent in dummy: %llu us", totaldummy_usec);
		msg("Total number of blocks: %llu", blocknr);
#endif
		break;

	default:
		msg("command not supported");
	}

	return 0;
}

// http://developer.axis.com/wiki/doku.php?id=mmap
// http://www.makelinux.net/ldd3/chp-15-sect-2 [15.2.1]
int buffer_to_map = 0;
bool mapping_dma = true;
int map_mmap(struct file *filp, struct vm_area_struct *vma) {

	int result = 0;
	if(mapping_dma) {
		unsigned long offset = (unsigned long)(dmaReadBufferAddressArray[buffer_to_map]>>PAGE_SHIFT);
		//msg("mmap: [start=%p,offset=%p,size=%p]", (void*)vma->vm_start, offset, (void*)vma->vm_end-vma->vm_start);

		// 1: virtual memory area into which mapping takes place
		// 2: user space virtual memory address (start of mapped region)
		// 3: kernel space physical address, right shifted by PAGE_SHIFT bits
		// 4: size of mapped memory region
		// 5: protection flags
		result = remap_pfn_range(vma, vma->vm_start, offset, vma->vm_end-vma->vm_start, vma->vm_page_prot);

		// check if mapping succeeded
		if(result) {
			return -EAGAIN;
		}

		buffer_to_map++;
		if(buffer_to_map == dmabufcount) {
			buffer_to_map = 0;
			mapping_dma = false;
		}
	} else {
		result = remap_pfn_range(vma, vma->vm_start, HIGH_MEMORY_START>>PAGE_SHIFT, vma->vm_end-vma->vm_start, vma->vm_page_prot);
		if(result) {
			return -EAGAIN;
		}

		mapping_dma = true;
	}

	return 0;
}

#if defined(MEASURE_TIME_DMA)
struct timeval tv_begin,tv_end;
#endif

bool interrupt_state = true;
irqreturn_t msi_handler(int irq, void *dev_id, struct pt_regs *regs) {
	if(!started) {
		msg("Starting first DMA transfer");
	}

	if(enabled) {
		if(interrupt_state) {
			if(currentwritebuf==currentreadbuf && started && reading) {
				err("Reading too slow (block %llu)!", blocknr);
			} else {
				#if defined(MEASURE_TIME_DMA)
				do_gettimeofday(&tv_begin);
				#endif

				uint32_t addr = dmaReadBufferArray[currentwritebuf];

				/*
				 DMA Controller
					- Interrupt Enable: done + error
					- Address Control: only increment destination
					- Source Address: arbiter FIFO
					- Destination Address: geheugen in PC
					- Size of transfer: buffer size
				*/
				fpga_dma[12] 	= REVERSE(0x00000003);
				fpga_dma[1]		= REVERSE(0x40000000);
				fpga_dma[2]		= REVERSE(0xCEE00004);
				fpga_dma[3]		= REVERSE(0xA0000000+addr);
				fpga_dma[4]		= REVERSE(BUF_SIZE);

				started = true;
			}
		} else {
			blocknr++;
			increase_currentwritebuf();

			if((dma_status_get_error(REVERSE(fpga_dma[DMA_REG_STATUS])) !=0) || (dma_istatus_get_error(REVERSE(fpga_dma[DMA_REG_ISTATUS])))) {
				err("DMA bus error");
				enabled = false;
			} else {
				fpga_dma[0] = REVERSE(0x0000000A);

				#if defined(MEASURE_TIME_DMA)
				do_gettimeofday(&tv_end);
				totaltime_usec += (uint64_t)((tv_end.tv_sec-tv_begin.tv_sec)*1000000+(tv_end.tv_usec-tv_begin.tv_usec));

				do_gettimeofday(&tv_begin);
				do_gettimeofday(&tv_end);
				totaldummy_usec += (uint64_t)((tv_end.tv_sec-tv_begin.tv_sec)*1000000+(tv_end.tv_usec-tv_begin.tv_usec));
				#endif
			}
		}
		interrupt_state = !interrupt_state;
	}

	return IRQ_HANDLED;
}
