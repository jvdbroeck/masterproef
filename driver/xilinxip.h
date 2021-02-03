#ifndef XILINXIP_H
#define XILINXIP_H

static const int RPFIFO_BASE					= 128;
static const int RPFIFO_DATA					= 192;

static const int RPFIFO_REG_ID 					= 0;
#define rpfifo_id_get_major_version_number(x) 	(((x) & 0xF0000000) >> 28)
#define rpfifo_id_get_minor_version_number(x) 	(((x) & 0x0FE00000) >> 21)
#define rpfifo_id_get_minor_version_letter(x) 	(((x) & 0x001F0000) >> 16)
#define rpfifo_id_get_block_id(x) 				(((x) & 0x0000FF00) >> 8)
#define rpfifo_id_get_block_type(x) 			(((x) & 0x000000FF))

static const int RPFIFO_REG_STATUS 				= 1;
#define rpfifo_status_get_empty(x)				(((x) & 0x80000000) >> 31)
#define rpfifo_status_get_almostempty(x)		(((x) & 0x40000000) >> 30)
#define rpfifo_status_get_deadlock(x)			(((x) & 0x20000000) >> 29)
#define rpfifo_status_get_width(x)				(((x) & 0x0E000000) >> 25)
#define rpfifo_status_get_occupancy(x)			(((x) & 0x01FFFFFF))

static const int DMA_REG_CONTROL				= 1;
#define dma_control_get_srci(x)					(((x) & 0x80000000) >> 31)
#define dma_control_get_dsti(x) 				(((x) & 0x40000000) >> 30)

static const int DMA_REG_SRC					= 2;
static const int DMA_REG_DST 					= 3;
static const int DMA_REG_LENGTH					= 4;

static const int DMA_REG_STATUS					= 5;
#define dma_status_get_busy(x) 					(((x) & 0x80000000) >> 31)
#define dma_status_get_error(x) 				(((x) & 0x40000000) >> 30)

static const int DMA_REG_ISTATUS				= 11;
#define dma_istatus_get_done(x)					(((x) & 0x00000001))
#define dma_istatus_get_error(x)				(((x) & 0x00000002) >> 1)

static const int DMA_REG_IENABLE				= 12;
#define dma_ienable_get_done(x) 				(((x) & 0x00000001))
#define dma_ienable_get_error(x) 				(((x) & 0x00000002) >> 1)

static const int PCIE_REG_IP2PCI0U				= 0;
static const int PCIE_REG_IP2PCI0L				= 1;
static const int PCIE_REG_IP2PCI1U				= 2;
static const int PCIE_REG_IP2PCI1L				= 3;
static const int PCIE_REG_IP2PCI2U				= 4;
static const int PCIE_REG_IP2PCI2L				= 5;
static const int PCIE_REG_IP2PCI3U				= 6;
static const int PCIE_REG_IP2PCI3L				= 7;
static const int PCIE_REG_IP2PCI4U				= 8;
static const int PCIE_REG_IP2PCI4L				= 9;
static const int PCIE_REG_IP2PCI5U				= 10;
static const int PCIE_REG_IP2PCI5L				= 11;

static const int PCIE_REG_BCR					= 12;
#define pcie_bcr_get_bme(x)						(((x) & 0x00000100) >> 8)
#define pcie_bcr_get_bar2(x)					(((x) & 0x00000004) >> 2)
#define pcie_bcr_get_bar1(x)					(((x) & 0x00000002) >> 1)
#define pcie_bcr_get_bar0(x)					(((x) & 0x00000001))

static const int PCIE_REG_PRIDR					= 13;
#define pcie_pridr_get_bus(x)					(((x) & 0x0000FF00) >> 8)
#define pcie_pridr_get_device(x)				(((x) & 0x000000F0) >> 4)
#define pcie_pridr_get_function(x)				(((x) & 0x0000000F))

static const int PCIE_REG_PRCR					= 14;
#define pcie_prcr_get_maxpsize(x)				(((x) & 0x00000700) >> 8)
#define pcie_prcr_get_maxrsize(x)				(((x) & 0x00000007))

static const int PCIE_REG_STATUS				= 15;
#define pcie_status_get_linkwidth(x)			(((x) & 0x000003C0) >> 6)
#define pcie_status_get_linkup(x)				(((x) & 0x00000020) >> 5)

static const int PCIE_REG_INTERRUPT				= 16;
#define pcie_bir_get_sur(x)						(((x) & 0x40000000) >> 30)
#define pcie_bir_get_mur(x)						(((x) & 0x20000000) >> 29)
#define pcie_bir_get_mca(x)						(((x) & 0x10000000) >> 28)
#define pcie_bir_get_mep(x)						(((x) & 0x08000000) >> 27)
#define pcie_bir_get_suc(x)						(((x) & 0x04000000) >> 26)
#define pcie_bir_get_msi(x)						(((x) & 0x02000000) >> 25)
#define pcie_bir_get_sct(x)						(((x) & 0x01000000) >> 24)
#define pcie_bir_get_sep(x)						(((x) & 0x00800000) >> 23)
#define pcie_bir_get_sca(x)						(((x) & 0x00400000) >> 22)
#define pcie_bir_get_sbo(x)						(((x) & 0x00200000) >> 21)
#define pcie_bir_get_nbe(x)						(((x) & 0x00100000) >> 20)
#define pcie_bir_get_linkdown(x)				(((x) & 0x00080000) >> 19)
#define pcie_bir_get_bme(x)						(((x) & 0x00004000) >> 14)

static const int PCIE_REG_INTERRUPTENABLE		= 17;
#define pcie_bier_get_sur(x)					(((x) & 0x40000000) >> 30)
#define pcie_bier_get_mur(x)					(((x) & 0x20000000) >> 29)
#define pcie_bier_get_mca(x)					(((x) & 0x10000000) >> 28)
#define pcie_bier_get_mep(x)					(((x) & 0x08000000) >> 27)
#define pcie_bier_get_suc(x)					(((x) & 0x04000000) >> 26)
#define pcie_bier_get_msi(x)					(((x) & 0x02000000) >> 25)
#define pcie_bier_get_sct(x)					(((x) & 0x01000000) >> 24)
#define pcie_bier_get_sep(x)					(((x) & 0x00800000) >> 23)
#define pcie_bier_get_sca(x)					(((x) & 0x00400000) >> 22)
#define pcie_bier_get_sbo(x)					(((x) & 0x00200000) >> 21)
#define pcie_bier_get_nbe(x)					(((x) & 0x00100000) >> 20)
#define pcie_bier_get_linkdown(x)				(((x) & 0x00080000) >> 19)
#define pcie_bier_get_bme(x)					(((x) & 0x00004000) >> 14)

static const int PCIE_REG_MAR					= 18;
static const int PCIE_REG_MDR					= 19;

#endif
