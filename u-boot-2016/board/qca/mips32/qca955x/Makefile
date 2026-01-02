BOARD=board955x
COMPRESSED_UBOOT=0
ETH_CONFIG=_s17

obj-y	=			\
	$(BOARD).o		\
	flash.o			\
	extra.o			\
	init-955x.o	\
	../common/ath_serial.o	\
	../common/ath_pci.o	\
	../common/qca-mach-common.o	\
	../common/athrs17_lpbk.o	\
	rgmii-cal-955x.o	\
	qca-eth-955x.o

ifeq ($(ATH_DUAL_FLASH),1)
OBJS	+= ../common/ath_nand.o ../../../drivers/nand/nand_ids.o
endif

ifndef BOOT_FROM_NAND
obj-y	+= ../common/ath_flash.o
endif

ifeq ($(ATH_RGMII_CAL),1)
obj-y	+= rgmii-cal-955x.o
obj-y	+= ../common/athrs17_lpbk.o
endif

ifeq ($(ETH_CONFIG2), _s17)
OBJS	+= ../common/athrs17_phy.o
endif

ifeq ($(ETH_CONFIG), _s17)
obj-y	+= ../common/athrs17_phy.o
endif

ifeq ($(ETH_CONFIG), _s27)
OBJS	+= ../common/athr_s27_phy.o
endif

obj-y	+= 955x.o tap-955x.o
