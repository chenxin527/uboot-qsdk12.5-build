#
# SPDX-License-Identifier:	GPL-2.0+
#

dtb-$(CONFIG_S5PC100) += s5pc1xx-smdkc100.dtb
dtb-$(CONFIG_S5PC110) += s5pc1xx-goni.dtb
dtb-$(CONFIG_EXYNOS4) += exynos4210-origen.dtb \
	exynos4210-smdkv310.dtb \
	exynos4210-universal_c210.dtb \
	exynos4210-trats.dtb \
	exynos4412-trats2.dtb \
	exynos4412-odroid.dtb

dtb-$(CONFIG_EXYNOS5) += exynos5250-arndale.dtb \
	exynos5250-snow.dtb \
	exynos5250-spring.dtb \
	exynos5250-smdk5250.dtb \
	exynos5420-smdk5420.dtb \
	exynos5420-peach-pit.dtb \
	exynos5800-peach-pi.dtb \
	exynos5422-odroidxu3.dtb

dtb-$(CONFIG_ARCH_IPQ807x) += ipq807x-hk01.dtb \
	ipq807x-hk02.dtb \
	ipq807x-hk06.dtb \
	ipq807x-hk07.dtb \
	ipq807x-hk08.dtb \
	ipq807x-hk09.dtb \
	ipq807x-hk10.dtb \
	ipq807x-hk14.dtb \
	ipq807x-hk11-c1.dtb \
	ipq807x-ac01.dtb \
	ipq807x-ac03.dtb \
	ipq807x-ac04.dtb \
	ipq807x-oak02.dtb \
	ipq807x-hk01-c2.dtb \
	ipq807x-hk01-c4.dtb \
	ipq807x-hk01-c5.dtb \
	ipq807x-hk10-c2.dtb \
	ipq807x-db-hk02.dtb

dtb-$(CONFIG_ARCH_IPQ806x) += ipq806x-ap148.dtb \
	ipq806x-ap160.dtb \
	ipq806x-ap160_2xx.dtb \
	ipq806x-ap161.dtb \
	ipq806x-db149.dtb \
	ipq806x-ap145.dtb \
	ipq806x-ap145_1xx.dtb \
	ipq806x-ak01.dtb

dtb-$(CONFIG_ARCH_IPQ40xx) += ipq40xx-dk01-c1.dtb \
		ipq40xx-dk01-c2.dtb \
		ipq40xx-dk04-c1.dtb \
		ipq40xx-dk04-c2.dtb \
		ipq40xx-dk04-c3.dtb \
		ipq40xx-dk04-c4.dtb \
		ipq40xx-dk07-c1.dtb \
		ipq40xx-dk07-c2.dtb \
		ipq40xx-dk07-c3.dtb \
		ipq40xx-dk07-c4.dtb \
		ipq40xx-dk01-s1.dtb \
		ipq40xx-dk06-c1.dtb

ifneq ($(CONFIG_IPQ_TINY),y)
dtb-$(CONFIG_ARCH_IPQ5018) += ipq5018-emulation.dtb \
			ipq5018-mp02.1.dtb \
			ipq5018-mp03.1-c2.dtb \
			ipq5018-mp03.1-c3.dtb \
			ipq5018-mp03.3.dtb \
			ipq5018-mp03.3-c2.dtb \
			ipq5018-mp03.3-c3.dtb \
			ipq5018-mp03.3-c4.dtb \
			ipq5018-mp03.3-c5.dtb \
			ipq5018-mp03.4-c1.dtb \
			ipq5018-mp03.4-c2.dtb \
			ipq5018-mp03.6-c1.dtb \
			ipq5018-mp03.6-c2.dtb \
			ipq5018-mp03.5-c1.dtb \
			ipq5018-mp03.5-c2.dtb \
			ipq5018-db-mp02.1.dtb \
			ipq5018-db-mp03.1.dtb \
			ipq5018-db-mp03.1-c2.dtb \
			ipq5018-db-mp03.3.dtb \
			ipq5018-db-mp03.3-c2.dtb \
			ipq5018-tb-mp04.dtb \
			ipq5018-mp03.1.dtb
else
dtb-$(CONFIG_ARCH_IPQ5018) += ipq5018-db-mp02.1.dtb \
				ipq5018-mp02.1.dtb \
				ipq5018-mp03.1.dtb \
				ipq5018-db-mp03.1.dtb
endif

ifneq ($(CONFIG_IPQ_TINY),y)
dtb-$(CONFIG_ARCH_IPQ5332) += ipq5332-emulation.dtb \
				ipq5332-mi01.2.dtb \
				ipq5332-mi01.2-qcn9160-c1.dtb \
				ipq5332-mi01.3.dtb \
				ipq5332-mi01.4.dtb \
				ipq5332-mi01.6.dtb \
				ipq5332-mi01.9.dtb \
				ipq5332-mi01.12.dtb \
				ipq5332-mi01.13.dtb \
				ipq5332-mi03.1.dtb \
				ipq5332-mi04.1.dtb \
				ipq5332-mi04.3.dtb \
				ipq5332-db-mi01.1.dtb \
				ipq5332-db-mi02.1.dtb \
				ipq5332-db-mi03.1.dtb \
				ipq5332-tb-mi03.1.dtb \
				ipq5332-tb-mi05.1.dtb
else
ifneq ($(CONFIG_IPQ_TINY_SPI_NOR),y)
dtb-$(CONFIG_ARCH_IPQ5332) += ipq5332-mi01.3.dtb \
				ipq5332-mi04.3.dtb \
				ipq5332-mi04.1.dtb \
				ipq5332-db-mi02.1.dtb \
				ipq5332-mi01.2.dtb \
				ipq5332-tb-mi03.1.dtb \
				ipq5332-tb-mi05.1.dtb
else
dtb-$(CONFIG_ARCH_IPQ5332) += ipq5332-mi04.1.dtb \
				ipq5332-tb-mi05.1.dtb
endif
endif

$(info === 板级选择调试 ===)
$(info CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_02  = $(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_02))
$(info CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_07  = $(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_07))
$(info CONFIG_TARGET_IPQ6018_JDCLOUD_RE_SS_01  = $(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_SS_01))
$(info CONFIG_TARGET_IPQ6018_LINK_NN6000       = $(CONFIG_TARGET_IPQ6018_LINK_NN6000))
$(info CONFIG_TARGET_IPQ6018_REDMI_AX5_JDCLOUD = $(CONFIG_TARGET_IPQ6018_REDMI_AX5_JDCLOUD))

ifdef CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_02
$(info 选择: JDCloud AX6600 Athena (RE-CS-02))
dtb-$(CONFIG_ARCH_IPQ6018) += ipq6018-re-cs-02.dtb
endif

ifdef CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_07
$(info 选择: JDCloud ER1 (RE-CS-07))
dtb-$(CONFIG_ARCH_IPQ6018) += ipq6018-re-cs-07.dtb
endif

ifdef CONFIG_TARGET_IPQ6018_JDCLOUD_RE_SS_01
$(info 选择: JDCloud AX1800 Pro Arthur (RE-SS-01))
dtb-$(CONFIG_ARCH_IPQ6018) += ipq6018-re-ss-01.dtb
endif

ifdef CONFIG_TARGET_IPQ6018_LINK_NN6000
$(info 选择: Link NN6000 (V1 & V2))
dtb-$(CONFIG_ARCH_IPQ6018) += ipq6018-nn6000.dtb
endif

ifdef CONFIG_TARGET_IPQ6018_REDMI_AX5_JDCLOUD
$(info 选择: Redmi AX5 JDCloud)
dtb-$(CONFIG_ARCH_IPQ6018) += ipq6018-ax5-jdcloud.dtb
endif

dtb-$(CONFIG_ARCH_IPQ9574) += ipq9574-al01-c1.dtb \
			ipq9574-al02-c1.dtb \
			ipq9574-al03-c1.dtb \
			ipq9574-al02-c2.dtb \
			ipq9574-al02-c3.dtb \
			ipq9574-al02-c4.dtb \
			ipq9574-al02-c7.dtb \
			ipq9574-al02-c8.dtb \
			ipq9574-al02-c9.dtb \
			ipq9574-al02-c10.dtb \
			ipq9574-al02-c13.dtb \
			ipq9574-al02-c17.dtb \
			ipq9574-al02-c18.dtb \
			ipq9574-al02-c19.dtb \
			ipq9574-al05.dtb \
			ipq9574-al06.dtb \
			ipq9574-db-al01-c1.dtb \
			ipq9574-db-al01-c2.dtb \
			ipq9574-db-al01-c3.dtb \
			ipq9574-db-al02-c1.dtb \
			ipq9574-db-al02-c2.dtb \
			ipq9574-db-al02-c3.dtb

dtb-$(CONFIG_ARCH_ROCKCHIP) += \
	rk3288-firefly.dtb \
	rk3288-jerry.dtb \
	rk3036-sdk.dtb
dtb-$(CONFIG_TEGRA) += tegra20-harmony.dtb \
	tegra20-medcom-wide.dtb \
	tegra20-paz00.dtb \
	tegra20-plutux.dtb \
	tegra20-seaboard.dtb \
	tegra20-tec.dtb \
	tegra20-trimslice.dtb \
	tegra20-ventana.dtb \
	tegra20-whistler.dtb \
	tegra20-colibri.dtb \
	tegra30-apalis.dtb \
	tegra30-beaver.dtb \
	tegra30-cardhu.dtb \
	tegra30-colibri.dtb \
	tegra30-tec-ng.dtb \
	tegra114-dalmore.dtb \
	tegra124-jetson-tk1.dtb \
	tegra124-nyan-big.dtb \
	tegra124-venice2.dtb \
	tegra210-e2220-1170.dtb \
	tegra210-p2371-0000.dtb \
	tegra210-p2371-2180.dtb \
	tegra210-p2571.dtb

dtb-$(CONFIG_ARCH_MVEBU) +=			\
	armada-388-gp.dtb			\
	armada-xp-gp.dtb

dtb-$(CONFIG_ARCH_UNIPHIER) += \
	uniphier-ph1-ld4-ref.dtb \
	uniphier-ph1-ld6b-ref.dtb \
	uniphier-ph1-pro4-ref.dtb \
	uniphier-ph1-pro5-4kbox.dtb \
	uniphier-ph1-sld3-ref.dtb \
	uniphier-ph1-sld8-ref.dtb \
	uniphier-proxstream2-gentil.dtb \
	uniphier-proxstream2-vodka.dtb
dtb-$(CONFIG_ARCH_ZYNQ) += zynq-zc702.dtb \
	zynq-zc706.dtb \
	zynq-zed.dtb \
	zynq-zybo.dtb \
	zynq-microzed.dtb \
	zynq-picozed.dtb \
	zynq-zc770-xm010.dtb \
	zynq-zc770-xm011.dtb \
	zynq-zc770-xm012.dtb \
	zynq-zc770-xm013.dtb
dtb-$(CONFIG_ARCH_ZYNQMP) += \
	zynqmp-ep108.dtb
dtb-$(CONFIG_AM33XX) += am335x-boneblack.dtb am335x-evm.dtb
dtb-$(CONFIG_AM43XX) += am437x-gp-evm.dtb am437x-sk-evm.dtb

dtb-$(CONFIG_ARCH_SOCFPGA) +=				\
	socfpga_arria5_socdk.dtb			\
	socfpga_cyclone5_mcvevk.dtb			\
	socfpga_cyclone5_socdk.dtb			\
	socfpga_cyclone5_de0_nano_soc.dtb			\
	socfpga_cyclone5_sockit.dtb			\
	socfpga_cyclone5_socrates.dtb			\
	socfpga_cyclone5_sr1500.dtb

dtb-$(CONFIG_TARGET_DRA7XX_EVM) += dra72-evm.dtb dra7-evm.dtb
dtb-$(CONFIG_TARGET_BEAGLE_X15) += am57xx-beagle-x15.dtb
dtb-$(CONFIG_TARGET_STV0991) += stv0991.dtb

dtb-$(CONFIG_LS102XA) += ls1021a-qds.dtb \
	ls1021a-twr.dtb
dtb-$(CONFIG_FSL_LSCH3) += fsl-ls2080a-qds.dtb \
	fsl-ls2080a-rdb.dtb
dtb-$(CONFIG_FSL_LSCH2) += fsl-ls1043a-qds.dtb \
	fsl-ls1043a-rdb.dtb

dtb-$(CONFIG_MACH_SUN4I) += \
	sun4i-a10-a1000.dtb \
	sun4i-a10-ba10-tvbox.dtb \
	sun4i-a10-chuwi-v7-cw0825.dtb \
	sun4i-a10-cubieboard.dtb \
	sun4i-a10-gemei-g9.dtb \
	sun4i-a10-hackberry.dtb \
	sun4i-a10-hyundai-a7hd.dtb \
	sun4i-a10-inet1.dtb \
	sun4i-a10-inet-3f.dtb \
	sun4i-a10-inet-3w.dtb \
	sun4i-a10-inet97fv2.dtb \
	sun4i-a10-inet9f-rev03.dtb \
	sun4i-a10-itead-iteaduino-plus.dtb \
	sun4i-a10-jesurun-q5.dtb \
	sun4i-a10-marsboard.dtb \
	sun4i-a10-mini-xplus.dtb \
	sun4i-a10-mk802.dtb \
	sun4i-a10-mk802ii.dtb \
	sun4i-a10-olinuxino-lime.dtb \
	sun4i-a10-pcduino.dtb \
	sun4i-a10-pov-protab2-ips9.dtb
dtb-$(CONFIG_MACH_SUN5I) += \
	sun5i-a10s-auxtek-t003.dtb \
	sun5i-a10s-auxtek-t004.dtb \
	sun5i-a10s-mk802.dtb \
	sun5i-a10s-olinuxino-micro.dtb \
	sun5i-a10s-r7-tv-dongle.dtb \
	sun5i-a10s-wobo-i5.dtb \
	sun5i-a13-ampe-a76.dtb \
	sun5i-a13-empire-electronix-d709.dtb \
	sun5i-a13-hsg-h702.dtb \
	sun5i-a13-inet-86vs.dtb \
	sun5i-a13-inet-98v-rev2.dtb \
	sun5i-a13-olinuxino.dtb \
	sun5i-a13-olinuxino-micro.dtb \
	sun5i-a13-q8-tablet.dtb \
	sun5i-a13-utoo-p66.dtb \
	sun5i-r8-chip.dtb
dtb-$(CONFIG_MACH_SUN6I) += \
	sun6i-a31-app4-evb1.dtb \
	sun6i-a31-colombus.dtb \
	sun6i-a31-hummingbird.dtb \
	sun6i-a31-i7.dtb \
	sun6i-a31-m9.dtb \
	sun6i-a31-mele-a1000g-quad.dtb \
	sun6i-a31-mixtile-loftq.dtb \
	sun6i-a31s-cs908.dtb \
	sun6i-a31s-primo81.dtb \
	sun6i-a31s-sinovoip-bpi-m2.dtb
dtb-$(CONFIG_MACH_SUN7I) += \
	sun7i-a20-ainol-aw1.dtb \
	sun7i-a20-bananapi.dtb \
	sun7i-a20-bananapro.dtb \
	sun7i-a20-cubieboard2.dtb \
	sun7i-a20-cubietruck.dtb \
	sun7i-a20-hummingbird.dtb \
	sun7i-a20-i12-tvbox.dtb \
	sun7i-a20-lamobo-r1.dtb \
	sun7i-a20-m3.dtb \
	sun7i-a20-m5.dtb \
	sun7i-a20-mk808c.dtb \
	sun7i-a20-olimex-som-evb.dtb \
	sun7i-a20-olinuxino-lime.dtb \
	sun7i-a20-olinuxino-lime2.dtb \
	sun7i-a20-olinuxino-micro.dtb \
	sun7i-a20-orangepi.dtb \
	sun7i-a20-orangepi-mini.dtb \
	sun7i-a20-pcduino3.dtb \
	sun7i-a20-pcduino3-nano.dtb \
	sun7i-a20-primo73.dtb \
	sun7i-a20-wexler-tab7200.dtb \
	sun7i-a20-wits-pro-a20-dkt.dtb \
	sun7i-a20-yones-toptech-bd1078.dtb
dtb-$(CONFIG_MACH_SUN8I_A23) += \
	sun8i-a23-evb.dtb \
	sun8i-a23-gt90h-v4.dtb \
	sun8i-a23-q8-tablet.dtb
dtb-$(CONFIG_MACH_SUN8I_A33) += \
	sun8i-a33-ga10h-v1.1.dtb \
	sun8i-a33-q8-tablet.dtb \
	sun8i-a33-sinlinx-sina33.dtb
dtb-$(CONFIG_MACH_SUN8I_A83T) += \
	sun8i-a83t-allwinner-h8homlet-v2.dtb
dtb-$(CONFIG_MACH_SUN8I_H3) += \
	sun8i-h3-orangepi-pc.dtb \
	sun8i-h3-orangepi-plus.dtb
dtb-$(CONFIG_MACH_SUN9I) += \
	sun9i-a80-optimus.dtb \
	sun9i-a80-cubieboard4.dtb

dtb-$(CONFIG_VF610) += vf500-colibri.dtb \
	vf610-colibri.dtb

dtb-$(CONFIG_SOC_KEYSTONE) += k2hk-evm.dtb \
	k2l-evm.dtb \
	k2e-evm.dtb \
	k2g-evm.dtb

targets += $(dtb-y)

# Add any required device tree compiler flags here
DTC_FLAGS +=

PHONY += dtbs

ifneq ($(CONFIG_OF_COMBINE),)

%(obj)/%.dtb.comb.S: %(obj)/%.dtb
	@:

$(obj)/dtbtable.S: $(addsuffix .comb.o, $(addprefix $(obj)/, $(dtb-y)))
	@:

obj-y := dtbtable.o $(addsuffix .comb.o, $(dtb-y))

targets += obj-$(CONFIG_OF_EMBED)

else
dtbs: $(addprefix $(obj)/, $(dtb-y))
	@:
endif

clean-files := *.dtb *.o *.S
