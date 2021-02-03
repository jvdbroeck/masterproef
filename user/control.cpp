/*
 * testapplication.c
 *
 *  Created on: 27-okt.-2012
 *      Author: jens
 */

#include <iostream>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <sstream>

#include "../driver/xpcie.h"
#include "../driver/xilinxip.h"

const char *const DEVICE_NAME = "/dev/xpcie";

int main(int argc, char* argv[]) {
	/*
	 Check number of arguments, display help text if needed.
	*/
	if(argc <= 1) {
		std::cout << "Wrong number of arguments." << std::endl;
		std::cout << "   Syntax: ./control [command]" << std::endl;
		return 1;
	}

	/*
	 Try to open the device file.
	 If it cannot be opened, nothing can be done. Return.
	*/
	int file = open(DEVICE_NAME, O_RDWR);
	if(file == -1) {
		std::cout << "File " << DEVICE_NAME << " could not be opened." << std::endl;
		return file;
	}

	/*
	 Process the given command, if possible.
	*/
	 if(strcmp(argv[1], "enable")==0) {
	 	std::cout << "Enabling sampler" << std::endl;
		ioctl(file, XPCIE_IOC_ENABLE);

	} else if(strcmp(argv[1], "disable")==0) {
		std::cout << "Disabling sampler" << std::endl;
		ioctl(file, XPCIE_IOC_DISABLE);

	} else if(strcmp(argv[1], "flush")==0) {
		std::cout << "Getting last buffer from sampler" << std::endl;
		ioctl(file, XPCIE_IOC_LASTXFER);

	} else if(strcmp(argv[1], "reset")==0) {
		std::cout << "Resetting sampler" << std::endl;
		ioctl(file, XPCIE_IOC_RESET);

	} else if(strcmp(argv[1], "status")==0) {
		long tmp = 0;
		long result = ioctl(file, XPCIE_IOC_STATUS);

		if((result & 0x00000001) !=0) {
			std::cout << "Arbiter FIFO is vol" << std::endl;
		} else if((result & 0x00000002) !=0){
			std::cout << "Arbiter FIFO is leeg" << std::endl;
		} else {
			std::cout << "Arbiter FIFO bevat data, maar is niet vol" << std::endl;
		}

		if((result & 0x00000004) !=0) {
			std::cout << "Sampler FIFO is ooit vol gelopen !RISICO OP VERLIES VAN DATA!" << std::endl;
		}

		if((result & 0x00000008) !=0) {
			std::cout << "Sampler FIFO is vol" << std::endl;
		} else if((result & 0x00000010) !=0) {
			std::cout << "Sampler FIFO is leeg" << std::endl;
		} else {
			std::cout << "Sampler FIFO bevat data, maar is niet vol" << std::endl;
		}

		if((result & 0x00000020) !=0) {
			std::cout << "SRAM-geheugen is vol" << std::endl;
		} else if((result & 0x00000040) !=0) {
			std::cout << "SRAM-geheugen is leeg" << std::endl;
		} else {
			std::cout << "SRAM-geheugen bevat data, maar is niet vol" << std::endl;
		}

		std::cout << "Huidige toestand van FSM: ";
		tmp = (long)((result & 0x00000700)>>8);
		switch(tmp) {
			case 0:
				std::cout << "Sampler is uitgeschakeld" << std::endl;
				break;
			case 1:
				std::cout << "Arbiter wacht op data" << std::endl;
				break;
			case 2:
				std::cout << "Arbiter wacht op interrupt van DMA controller" << std::endl;
				break;
			case 4:
				std::cout << "Arbiter wacht op reset van de PC" << std::endl;
				break;
			case 7:
				std::cout << "Ongeldige toestand!" << std::endl;
				break;
			default:
				std::cout << "Er is iets fout gelopen bij het opvragen van de status." << std::endl;
				break;
		}

		tmp = (long)((result & 0x0FFFF000)>>12);
		std::cout << "Er staan " << tmp << " samples in de arbiter FIFO" << std::endl;

		if((result & 0x80000000) ==0) {
			std::cout << "Sampler is uitgeschakeld" << std::endl;
		} else {
			std::cout << "Sampler is ingeschakeld" << std::endl;
		}

	} else if(strcmp(argv[1], "dma")==0) {
		uint32_t c = (uint32_t)ioctl(file, XPCIE_IOC_READDMAREGISTER, DMA_REG_CONTROL);
		std::cout << "DMA Control Register:";
		std::cout << " SINC=" << dma_control_get_srci(c);
		std::cout << " DINC=" << dma_control_get_dsti(c);
		std::cout << std::endl;

		uint32_t s = (uint32_t)ioctl(file, XPCIE_IOC_READDMAREGISTER, DMA_REG_SRC);
		std::cout << "DMA Source Register:";
		std::cout << " 0x" << std::hex << s << std::dec;
		std::cout << std::endl;

		uint32_t d = (uint32_t)ioctl(file, XPCIE_IOC_READDMAREGISTER, DMA_REG_DST);
		std::cout << "DMA Destination Register:";
		std::cout << " 0x" << std::hex << d << std::dec;
		std::cout << std::endl;

		uint32_t l = (uint32_t)ioctl(file, XPCIE_IOC_READDMAREGISTER, DMA_REG_LENGTH);
		std::cout << "DMA Length Register:";
		std::cout << " 0x" << std::hex << l << std::dec;
		std::cout << std::endl;

		uint32_t S = (uint32_t)ioctl(file, XPCIE_IOC_READDMAREGISTER, DMA_REG_STATUS);
		std::cout << "DMA Status Register:";
		std::cout << " BSY=" << dma_status_get_busy(S);
		std::cout << " ERR=" << dma_status_get_error(S);
		std::cout << std::endl;

		uint32_t is = (uint32_t)ioctl(file, XPCIE_IOC_READDMAREGISTER, DMA_REG_ISTATUS);
		std::cout << "DMA Interrupt Status Register:";
		std::cout << " DONE=" << dma_istatus_get_done(is);
		std::cout << " ERR=" << dma_istatus_get_error(is);
		std::cout << std::endl;

		uint32_t ie = (uint32_t)ioctl(file, XPCIE_IOC_READDMAREGISTER, DMA_REG_IENABLE);
		std::cout << "DMA Interrupt Enable Register:";
		std::cout << " DONE=" << dma_ienable_get_done(ie);
		std::cout << " ERR=" << dma_ienable_get_error(ie);
		std::cout << std::endl;

	} else if(strcmp(argv[1], "pcie")==0) {
		uint32_t r;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI0U);
		std::cout << "PCI IP->PCI Register 0:";
		std::cout << " 0x" << std::hex << r << std::dec;
		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI0L);
		std::cout << " 0x" << std::hex << r << std::dec;
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI1U);
		std::cout << "PCI IP->PCI Register 1:";
		std::cout << " 0x" << std::hex << r << std::dec;
		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI1L);
		std::cout << " 0x" << std::hex << r << std::dec;
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI2U);
		std::cout << "PCI IP->PCI Register 2:";
		std::cout << " 0x" << std::hex << r << std::dec;
		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI2L);
		std::cout << " 0x" << std::hex << r << std::dec;
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI3U);
		std::cout << "PCI IP->PCI Register 3:";
		std::cout << " 0x" << std::hex << r << std::dec;
		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI3L);
		std::cout << " 0x" << std::hex << r << std::dec;
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI4U);
		std::cout << "PCI IP->PCI Register 4:";
		std::cout << " 0x" << std::hex << r << std::dec;
		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI4L);
		std::cout << " 0x" << std::hex << r << std::dec;
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI5U);
		std::cout << "PCI IP->PCI Register 5:";
		std::cout << " 0x" << std::hex << r << std::dec;
		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_IP2PCI5L);
		std::cout << " 0x" << std::hex << r << std::dec;
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_BCR);
		std::cout << "PCI Bridge Control Register:";
		std::cout << " BME=" << pcie_bcr_get_bme(r);
		std::cout << " BAR2=" << pcie_bcr_get_bar2(r);
		std::cout << " BAR1=" << pcie_bcr_get_bar1(r);
		std::cout << " BAR0=" << pcie_bcr_get_bar0(r);
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_PRIDR);
		std::cout << "PCI Requester ID Register:";
		std::cout << " BUS=" << pcie_pridr_get_bus(r);
		std::cout << " DEVICE=" << pcie_pridr_get_device(r);
		std::cout << " FUNCTION=" << pcie_pridr_get_function(r);
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_PRCR);
		std::cout << "PCI Request Control Register:";
		std::cout << " Max payload size=" << pcie_prcr_get_maxpsize(r);
		std::cout << " Max read request size=" << pcie_prcr_get_maxrsize(r);
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_STATUS);
		std::cout << "PCI Status Register:";
		std::cout << " Link width=" << pcie_status_get_linkwidth(r);
		std::cout << " Link up=" << pcie_status_get_linkup(r);
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_INTERRUPT);
		std::cout << "PCI Ints:";
		std::cout << " SlUnsupReq=" << pcie_bir_get_sur(r);
		std::cout << " MUnsupReq=" << pcie_bir_get_mur(r);
		std::cout << " MComplAbt=" << pcie_bir_get_mca(r);
		std::cout << " MErrPoison=" << pcie_bir_get_mep(r);
		std::cout << " SlUnexpCompl=" << pcie_bir_get_suc(r);
		std::cout << " MSI=" << pcie_bir_get_msi(r);
		std::cout << " SlComplTO=" << pcie_bir_get_sct(r);
		std::cout << " SlErrPoison=" << pcie_bir_get_sep(r);
		std::cout << " SlComplAbt=" << pcie_bir_get_sca(r);
		std::cout << " SlBarOR=" << pcie_bir_get_sbo(r);
		std::cout << " NonContBE=" << pcie_bir_get_nbe(r);
		std::cout << " LinkDn=" << pcie_bir_get_linkdown(r);
		std::cout << " BME=" << pcie_bir_get_bme(r);
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_INTERRUPTENABLE);
		std::cout << "PCI IEnable:";
		std::cout << " SlUnsupReq=" << pcie_bier_get_sur(r);
		std::cout << " MUnsupReq=" << pcie_bier_get_mur(r);
		std::cout << " MComplAbt=" << pcie_bier_get_mca(r);
		std::cout << " MErrPoison=" << pcie_bier_get_mep(r);
		std::cout << " SlUnexpCompl=" << pcie_bier_get_suc(r);
		std::cout << " MSI=" << pcie_bier_get_msi(r);
		std::cout << " SlComplTO=" << pcie_bier_get_sct(r);
		std::cout << " SlErrPoison=" << pcie_bier_get_sep(r);
		std::cout << " SlComplAbt=" << pcie_bier_get_sca(r);
		std::cout << " SlBarOR=" << pcie_bier_get_sbo(r);
		std::cout << " NonContBE=" << pcie_bier_get_nbe(r);
		std::cout << " LinkDn=" << pcie_bier_get_linkdown(r);
		std::cout << " BME=" << pcie_bier_get_bme(r);
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_MAR);
		std::cout << "PCI MSI Address Register:";
		std::cout << " 0x" << std::hex << r << std::dec;
		std::cout << std::endl;

		r = (uint32_t)ioctl(file, XPCIE_IOC_READPCIREGISTER, PCIE_REG_MDR);
		std::cout << "PCI MSI Data Register:";
		std::cout << " 0x" << std::hex << r << std::dec;
		std::cout << std::endl;

	} else {
		std::cout << "Wrong argument: dma_init, dma_read." << std::endl;

	}

	/*
	 Finally close the opened file.
	*/
	close(file);
	return 0;
}
