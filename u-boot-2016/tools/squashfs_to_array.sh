#!/bin/bash

######################################################################
# Copyright (c) 2020 The Linux Foundation. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 and
# only version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#####################################################################

unsquashfs -d tmp bt_fw_patch_squashfs.img
echo "" > bt_binary_array.h
for entry in ./tmp/image/*
do
  echo "$entry"
  file_name=${entry##*/}
  file_name="${file_name//./}"

  echo "unsigned char $file_name[] = {" >> bt_binary_array.h
  hexdump -v  -e '15/1 "0x%02X, " 1/1  " 0x%02X,\n"' $entry | sed 's/\, 0x .*//' >> bt_binary_array.h

  echo "};" >> bt_binary_array.h
done

rm -rf ./tmp
