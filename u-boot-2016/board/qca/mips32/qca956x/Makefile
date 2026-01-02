BOARD=board956x
COMPRESSED_UBOOT=0

ifdef CONFIG_AP151
ETH_CONFIG=_s27
else
ETH_CONFIG=_s17
endif

OBJS=	\
	$(BOARD).o		\
	flash.o			\
	extra.o			\
	init-956x.o	\
	qca-eth-956x.o	\
	../common/qca-mach-common.o	\
	../common/ath_serial.o	\
	../common/ath_pci.o

ifndef BOOT_FROM_NAND
OBJS	+= ../common/ath_flash.o
endif

ifeq ($(ATH_RGMII_CAL),1)
OBJS	+= ../common/rgmii-cal-956x.o
OBJS	+= ../common/athrs17_lpbk.o
endif

ifeq ($(ETH_CONFIG), _s17)
OBJS	+= ../common/athrs17_phy.o
endif

ifeq ($(ETH_CONFIG), _s27)
OBJS	+= ../common/athr_s27_phy.o
endif

OBJS	+= 956x.o tap-956x.o

$(OBJS): .depend

.depend:
obj-y	+= $(OBJS)
