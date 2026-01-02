BOARD=board953x
COMPRESSED_UBOOT=0
ETH_CONFIG=_s27

obj-y	=			\
	$(BOARD).o		\
	flash.o			\
	extra.o			\
	init-953x.o	\
	qca-eth-953x.o	\
	../common/ath_serial.o	\
	../common/ath_pci.o	\
	../common/qca-mach-common.o

ifeq ($(ATH_DUAL_FLASH),1)
OBJS	+= ../../../drivers/nand/nand_ids.o
ifeq ($(ATH_SPI_NAND),1)
OBJS	+= ../common/ath_spi_nand.o
else
OBJS	+= ../common/ath_nand.o
endif
endif

ifndef BOOT_FROM_NAND
obj-y	+= ../common/ath_flash.o
endif

ifeq ($(ATH_RGMII_CAL),1)
OBJS	+= ../common/rgmii-cal-953x.o
OBJS	+= ../common/athrs17_lpbk.o
endif

ifeq ($(ETH_CONFIG), _f1e)
OBJS	+= ../common/athrsf1_phy.o
endif

ifeq ($(ETH_CONFIG), _vir)
OBJS	+= ../common/athrs_vir_phy.o
endif

ifeq ($(ETH_CONFIG2), _vir)
OBJS	+= ../common/athrs_vir_phy.o
endif

ifeq ($(ETH_CONFIG), _s27)
obj-y	+= ../common/athr_s27_phy.o
endif

obj-y	+= 953x.o tap-953x.o
