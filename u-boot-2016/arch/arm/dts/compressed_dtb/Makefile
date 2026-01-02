$(obj)/dtbcombined.S: $(obj)/../../../../dtb_combined.bin
	gzip -k --best $(obj)/../../../../dtb_combined.bin
	echo ".section .dtb.combine_blob,\"a\"" > $(obj)/dtbcombined.S
	echo '.balign 16' >> $(obj)/dtbcombined.S
	echo ".global __dtb_blob_begin" >> $(obj)/dtbcombined.S
	echo "__dtb_blob_begin:" >> $(obj)/dtbcombined.S
	echo '.incbin "$(obj)/../../../../dtb_combined.bin.gz"' >> $(obj)/dtbcombined.S
	echo '.balign 16' >> $(obj)/dtbcombined.S
	echo ".global __dtb_blob_end" >> $(obj)/dtbcombined.S
	echo "__dtb_blob_end:" >> $(obj)/dtbcombined.S
	echo ".word 0" >> $(obj)/dtbcombined.S

obj-y := dtbcombined.o
