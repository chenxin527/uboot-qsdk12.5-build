obj-y := cmd_bootqca.o
obj-y += cmd_blowsecfuse.o
obj-y += cmd_sec_auth.o
ifndef CONFIG_CMD_DISABLE_EXECTZT
obj-y += cmd_exectzt.o
endif
obj-$(CONFIG_IPQ_TZT) += cmd_tzt.o
obj-$(CONFIG_SMP_CMD_SUPPORT) += cmd_runmulticore.o
obj-y += fdt_info.o
obj-y += board_init.o
obj-y += clk.o
obj-$(CONFIG_DPR_EXECUTE) += cmd_dpr.o
ifndef CONFIG_ENV_IS_NOWHERE
obj-y += env.o
endif
obj-y += fdt_fixup.o
obj-y += ethaddr.o
obj-$(CONFIG_QCA_APPSBL_DLOAD) += crashdump.o
