/*
 * xpcie.h
 *
 *  Created on: 26-okt.-2012
 *      Author: jens
 */

#ifndef XPCIE_H_
#define XPCIE_H_

#include <linux/types.h>
#include <linux/ioctl.h>

/** Definition of I/O ports of device.
 *
 * http://www.makelinux.net/ldd3/chp-6-sect-1
 * [linux_source]/Documentation/ioctl/io-number.txt
 */

// Use 'x' as the magic number (Xilinx)
#define XPCIE_IOC_MAGIC 'x'


/** Use macro's from ioctl.h:
 * _IO		To execute a command w/o arguments.
 * _IOW		To write data to the driver.
 * _IOR		To read data from the driver.
 */
#define XPCIE_IOC_ENABLE _IO(XPCIE_IOC_MAGIC, 1)
#define XPCIE_IOC_DISABLE _IO(XPCIE_IOC_MAGIC, 2)
#define XPCIE_IOC_STATUS _IO(XPCIE_IOC_MAGIC, 3)
#define XPCIE_IOC_READDMAREGISTER _IO(XPCIE_IOC_MAGIC, 4)
#define XPCIE_IOC_READPCIREGISTER _IO(XPCIE_IOC_MAGIC, 5)
#define XPCIE_IOC_DONE _IO(XPCIE_IOC_MAGIC, 6)
#define XPCIE_IOC_GETBUFCOUNT _IO(XPCIE_IOC_MAGIC, 7)
#define XPCIE_IOC_LASTXFER _IO(XPCIE_IOC_MAGIC, 8)
#define XPCIE_IOC_CHECK _IO(XPCIE_IOC_MAGIC, 9)
#define XPCIE_IOC_RESET _IO(XPCIE_IOC_MAGIC, 10)

enum
{
  BUF_SIZE_WORDS = 2048,
  BUF_SIZE = BUF_SIZE_WORDS * sizeof(uint32_t),
  MAX_DMA_BUF_COUNT = 100,
  XPCIE_MAGIC = 0xCAFEBABE,
  HIGH_MEMORY_START = 0x80000000
};




#endif /* XPCIE_H_ */
