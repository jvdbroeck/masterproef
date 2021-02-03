XPCIE_HOME := $(shell pwd)
XPCIE_KVER := $(shell uname -r)

obj-m := xpcie.o

# DEFINES := -DMEASURE_TIME_DMA
# DEFINES := -DMEASURE_TIME_COPYHI
# DEFINES := -DMEASURE_TIME_PROCESS
DEFINES :=

EXTRA_CFLAGS += -Wall -std=gnu90 $(DEFINES)

all:
	make -C /lib/modules/$(XPCIE_KVER)/build M=$(XPCIE_HOME) modules

clean:
	rm -f *.o .*.cmd *.ko *.mod.c *.mod
	rm -f Module.markers Module.symvers modules.order
	rm -rf .tmp_versions Modules.symvers
