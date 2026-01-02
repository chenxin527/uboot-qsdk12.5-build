######################################################################
# Copyright (c) 2017, 2019, The Linux Foundation. All rights reserved.
# Copyright (c) 2022 Qualcomm Innovation Center, Inc. All rights reserved.
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

"""
Script to create a U-Boot flashable multi-image blob.

This script creates a multi-image blob, from a bunch of images, and
adds a U-Boot shell script to the blob, that can flash the images from
within U-Boot. The procedure to use this script is listed below.

  1. Create an images folder. Ex: my-pack

  2. Copy all the images to be flashed into the folder.

  3. Copy the partition MBN file into the folder. The file should be
     named 'partition.mbn'. This is used to determine the offsets for
     each of the named partitions.

  4. Create a flash configuration file, specifying the images be
     flashed, and the partition in which the images is to be
     flashed. The flash configuration file can be specified using the
     -f option, default is flash.conf.

  5. Invoke 'pack' with the folder name as argument, pass flash
     parameters as arguments if required. A single image file will
     be created, out side the images folder, with .img suffix. Ex:
     my-pack.img

  6. Transfer the file into a valid SDRAM address and invoke the
     following U-Boot command to flash the images. Replace 0x41000000,
     with address location where the image has been loaded. The script
     expects the variable 'imgaddr' to be set.

     u-boot> imgaddr=0x88000000 source $imgaddr:script

Host-side Pre-req

  * Python >= 2.6
  * ordereddict >= 1.1 (for Python 2.6)
  * mkimage >= 2012.07
  * dtc >= 1.2.0

Target-side Pre-req

The following U-Boot config macros should be enabled, for the
generated flashing script to work.

  * CONFIG_FIT -- FIT image format support
  * CONFIG_SYS_HUSH_PARSER -- bash style scripting support
  * CONFIG_SYS_NULLDEV -- redirecting command output support
  * CONFIG_CMD_XIMG -- extracting sub-images support
  * CONFIG_CMD_NAND -- NAND Flash commands support
  * CONFIG_CMD_NAND_YAFFS -- NAND YAFFS2 write support
  * CONFIG_CMD_SF -- SPI Flash commands support
  * CONFIG_IPQ_MIBIB_RELOAD -- reloading part info from mibib support
  * CONFIG_IPQ_XTRACT_N_FLASH -- xtract_n_flash cmd support
"""

from os.path import getsize
from getopt import getopt
from getopt import GetoptError
from collections import namedtuple
from string import Template
from shutil import copy
from shutil import rmtree

import os
import sys
import os.path
import subprocess
import struct
import hashlib
import xml.etree.ElementTree as ET

version = "1.1"
ARCH_NAME = ""
SRC_DIR = ""
MODE = ""
image_type = "all"
memory_size = "default"
skip_4k_nand = "false"
atf = "false"
tiny_16m = "false"
supported_arch = ["ipq5332", "ipq5332_64"]
soc_hw_versions = {}
soc_hw_versions["ipq5332"] = { 0x201A0100, 0x201A0101 };

#
# Python 2.6 and earlier did not have OrderedDict use the backport
# from ordereddict package. If that is not available report error.
#
try:
    from collections import OrderedDict
except ImportError:
    try:
        from ordereddict import OrderedDict
    except ImportError:
        print("error: this script requires the 'ordereddict' class.")
        print("Try 'pip install --user ordereddict'")
        print("Or  'easy_install --user ordereddict'")
        sys.exit(1)

def error(msg, ex=None):
    """Print an error message and exit.

    msg -- string, the message to print
    ex -- exception, the associate exception, if any
    """

    sys.stderr.write("pack: %s" % msg)
    if ex != None: sys.stderr.write(": %s" % str(ex))
    sys.stderr.write("\n")
    sys.exit(1)

FlashInfo = namedtuple("FlashInfo", "type pagesize blocksize chipsize")
ImageInfo = namedtuple("ProgInfo", "name filename type")
PartInfo = namedtuple("PartInfo", "name offset length which_flash")

def hdrobj_byte2str(gpthdr):
    temp_tuple = tuple(gpthdr)
    gpthdr=[]
    for x in temp_tuple:
        if isinstance(x, bytes):
            try:
                x = x.decode("utf-8")
            except:
                x = 0
        gpthdr.append(x)

    gpthdr = tuple(gpthdr)
    return gpthdr

class GPT(object):
    GPTheader = namedtuple("GPTheader", "signature revision header_size"
                            " crc32 current_lba backup_lba first_usable_lba"
                            " last_usable_lba disk_guid start_lba_part_entry"
                            " num_part_entry part_entry_size part_crc32")
    GPT_SIGNATURE = 'EFI PART'
    GPT_REVISION = '\x00\x00\x01\x00'
    GPT_HEADER_SIZE = 0x5C
    GPT_HEADER_FMT = "<8s4sLL4xQQQQ16sQLLL"

    GPTtable = namedtuple("GPTtable", "part_type unique_guid first_lba"
                           " last_lba attribute_flag part_name")
    GPT_TABLE_FMT = "<16s16sQQQ72s"

    def __init__(self, filename, flinfo):
        self.filename = filename
        self.pagesize = flinfo.pagesize
        self.blocksize = flinfo.blocksize
        self.chipsize = flinfo.chipsize
        self.__partitions = OrderedDict()

    def __validate_and_read_parts(self, part_fp):
        """Validate the GPT and read the partition"""
        part_fp.seek(self.blocksize, os.SEEK_SET)
        gptheader_str = part_fp.read(struct.calcsize(GPT.GPT_HEADER_FMT))
        gptheader = struct.unpack(GPT.GPT_HEADER_FMT, gptheader_str)
        gptheader = hdrobj_byte2str(gptheader)
        gptheader = GPT.GPTheader._make(gptheader)

        if gptheader.signature != GPT.GPT_SIGNATURE:
            error("Invalid signature")

        if gptheader.revision != GPT.GPT_REVISION:
            error("Unsupported GPT Revision")

        if gptheader.header_size != GPT.GPT_HEADER_SIZE:
            error("Invalid Header size")

        # Adding GPT partition info. This has to be flashed first.
        # GPT Header starts at LBA1 so (current_lba -1) will give the
        # starting of primary GPT.
        # blocksize will equal to gptheader.first_usuable_lba - current_lba + 1

        name = "0:GPT"
        block_start = gptheader.current_lba - 1
        block_count = gptheader.first_usable_lba - gptheader.current_lba + 1
        which_flash = 0
        part_info = PartInfo(name, block_start, block_count, which_flash)
        self.__partitions[name] = part_info

        part_fp.seek(2 * self.blocksize, os.SEEK_SET)

        for i in range(gptheader.num_part_entry):
            gpt_table_str = part_fp.read(struct.calcsize(GPT.GPT_TABLE_FMT))
            gpt_table = struct.unpack(GPT.GPT_TABLE_FMT, gpt_table_str)
            gpt_table = hdrobj_byte2str(gpt_table)
            gpt_table = GPT.GPTtable._make(gpt_table)

            block_start = gpt_table.first_lba
            block_count = gpt_table.last_lba - gpt_table.first_lba + 1

            part_name = gpt_table.part_name.strip(chr(0))
            name = part_name.replace('\0','')
            part_info = PartInfo(name, block_start, block_count, which_flash)
            self.__partitions[name] = part_info

        # Adding the GPT Backup partition.
        # GPT header backup_lba gives block number where the GPT backup header will be.
        # GPT Backup header will start from offset of 32 blocks before
        # the GPTheader.backup_lba. Backup GPT size is 33 blocks.
        name = "0:GPTBACKUP"
        block_start = gptheader.backup_lba - 32
        block_count = 33
        part_info = PartInfo(name, block_start, block_count, which_flash)
        self.__partitions[name] = part_info

    def get_parts(self):
        """Returns a list of partitions present in the GPT."""

        try:
            with open(self.filename, "rb") as part_fp:
                self.__validate_and_read_parts(part_fp)
        except IOError as e:
            error("error opening %s" % self.filename, e)

        return self.__partitions

class MIBIB(object):
    Header = namedtuple("Header", "magic1 magic2 version age")
    HEADER_FMT = "<LLLL"
    HEADER_MAGIC1 = 0xFE569FAC
    HEADER_MAGIC2 = 0xCD7F127A
    HEADER_VERSION = 4

    Table = namedtuple("Table", "magic1 magic2 version numparts")
    TABLE_FMT = "<LLLL"
    TABLE_MAGIC1 = 0x55EE73AA
    TABLE_MAGIC2 = 0xE35EBDDB
    TABLE_VERSION_OTHERS = 4


    Entry = namedtuple("Entry", "name offset length"
                        " attr1 attr2 attr3 which_flash")
    ENTRY_FMT = "<16sLLBBBB"

    def __init__(self, filename, flinfo, nand_blocksize, nand_chipsize):
        self.filename = filename
        self.pagesize = flinfo.pagesize
        self.blocksize = flinfo.blocksize
        self.chipsize = flinfo.chipsize
        self.nand_blocksize = nand_blocksize
        self.nand_chipsize = nand_chipsize
        self.__partitions = OrderedDict()

    def __validate(self, part_fp):
        """Validate the MIBIB by checking for magic bytes."""

        mheader_str = part_fp.read(struct.calcsize(MIBIB.HEADER_FMT))
        mheader = struct.unpack(MIBIB.HEADER_FMT, mheader_str)
        mheader = hdrobj_byte2str(mheader)
        mheader = MIBIB.Header._make(mheader)

        if (mheader.magic1 != MIBIB.HEADER_MAGIC1
            or mheader.magic2 != MIBIB.HEADER_MAGIC2):
            """ mheader.magic1 = MIBIB.HEADER_MAGIC1
            mheader.magic2 = MIBIB.HEADER_MAGIC2 """
            error("invalid partition table, magic byte not present")

        if mheader.version != MIBIB.HEADER_VERSION:
            error("unsupport mibib version")

    def __read_parts(self, part_fp):
        """Read the partitions from the MIBIB."""
        global ARCH_NAME
        part_fp.seek(self.pagesize, os.SEEK_SET)
        mtable_str = part_fp.read(struct.calcsize(MIBIB.TABLE_FMT))
        mtable = struct.unpack(MIBIB.TABLE_FMT, mtable_str)
        mtable = hdrobj_byte2str(mtable)
        mtable = MIBIB.Table._make(mtable)

        if (mtable.magic1 != MIBIB.TABLE_MAGIC1
            or mtable.magic2 != MIBIB.TABLE_MAGIC2):
            """ mtable.magic1 = MIBIB.TABLE_MAGIC1
            mtable.magic2 = MIBIB.TABLE_MAGIC2 """
            error("invalid sys part. table, magic byte not present")

        if mtable.version != MIBIB.TABLE_VERSION_OTHERS:
            error("unsupported partition table version")

        for i in range(mtable.numparts):
            mentry_str = part_fp.read(struct.calcsize(MIBIB.ENTRY_FMT))
            mentry = struct.unpack(MIBIB.ENTRY_FMT, mentry_str)
            mentry = hdrobj_byte2str(mentry)
            mentry = MIBIB.Entry._make(mentry)
            self.flash_flag = self.blocksize
            self.chip_flag = self.chipsize

            if mentry.which_flash != 0:
                self.flash_flag = self.nand_blocksize
                self.chip_flag = self.nand_chipsize

            byte_offset = mentry.offset * self.flash_flag

            if mentry.length == 0xFFFFFFFF:
                byte_length = self.chip_flag - byte_offset
            else:
                byte_length = mentry.length * self.flash_flag

            part_name = mentry.name.strip(chr(0))
            part_info = PartInfo(part_name, byte_offset, byte_length, mentry.which_flash)
            self.__partitions[part_name] = part_info

    def get_parts(self):
        """Returns a list of partitions present in the MIBIB. CE """

        try:
            with open(self.filename, "rb") as part_fp:
                self.__validate(part_fp)
                self.__read_parts(part_fp)
        except IOError as e:
            error("error opening %s" % self.filename, e)

        return self.__partitions

class FlashScript(object):
    """Base class for creating flash scripts."""

    def __init__(self, flinfo):
        self.pagesize = flinfo.pagesize
        self.blocksize = flinfo.blocksize
        self.script = []
        self.parts = []
        self.curr_stdout = "serial"
        self.activity = None
        self.flash_type = flinfo.type

    def append(self, cmd, fatal=True):
        """Add a command to the script.

        Add additional code, to terminate on error. This can be
        supressed by passing 'fatal' as False.
        """

        if fatal:
            self.script.append(cmd + ' || exit 1\n')
        else:
            self.script.append(cmd + "\n")

    def dumps(self):
        """Return the created script as a string."""
        return "".join(self.script)

    def redirect(self, dev):
        """Generate code, to redirect command output to a device."""

        if self.curr_stdout == dev:
            return

        self.append("setenv stdout %s" % dev, fatal=False)
        self.curr_stdout = dev

    def imxtract_n_flash(self, part, part_name):
        """Generate code, to extract image location, from a multi-image blob
        and flash it.

        part -- string, name of the sub-image
        part_name -- string, partition name
        """
        self.append("xtract_n_flash $imgaddr %s %s" % (part, part_name))

    def echo(self, msg, nl=True, verbose=False):
        """Generate code, to print a message.

        nl -- bool, indicates whether newline is to be printed
        verbose -- bool, indicates whether printing in verbose mode
        """

        if not verbose:
            self.redirect("serial")

        if nl:
            self.append("echo %s" % msg, fatal=False)
        else:
            self.append("echo %s%s" % (r"\\c", msg), fatal=False)

        if not verbose:
            self.redirect("nulldev")

    def end(self):
        """Generate code, to indicate successful completion of script."""

        self.append("exit 0\n", fatal=False)

    def start_if(self, var, value):
        """Generate code, to check an environment variable.

        var -- string, variable to check
        value -- string, the value to compare with
        """

        self.append('if test "$%s" = "%s"; then\n' % (var, value),
                    fatal=False)

    def start_if_or(self, var, val_list):
        """Generate code, to check an environment variable.

        var -- string, variable to check
        value -- string, the list of values to compare with
        """

        n_val = len(val_list)
        item = 1
        cmd_str = "if "
        for val in val_list:
            cmd_str = cmd_str + str('test "$%s" = "%s"' % (var, val))
            #cmd_str = cmd_str + "\"$" + var + "\"" + "=" + "\"" + val + "\""
            if item <= (n_val - 1):
                cmd_str = cmd_str + " || "
            item = item + 1

        self.append('%s; then\n' % cmd_str, fatal=False)

    def end_if(self):
        """Generate code, to end if statement."""

        self.append('fi\n', fatal=False)

its_tmpl = Template("""
/dts-v1/;

/ {
        description = "${desc}";
        images {
${images}
        };
};
""")

its_image_tmpl = Template("""
                ${name} {
                        description = "${desc}";
                        data = /incbin/("./${fname}");
                        type = "${imtype}";
                        arch = "arm";
                        compression = "none";
                        hash@1 { algo = "crc32"; };
                };
""")

def sha1(message):
    """Returns SHA1 digest in hex format of the message."""

    m = hashlib.sha1()
    m.update(message.encode('utf-8'))
    return m.hexdigest()

class Pack(object):
    """Class to create a flashable, multi-image blob.

    Combine multiple images present in a directory, and generate a
    U-Boot script to flash the images.
    """

    def __init__(self):
        self.flinfo = None
        self.images_dname = None
        self.partitions = {}

        self.fconf_fname = None
        self.scr_fname = None
        self.its_fname = None
        self.img_fname = None
        self.emmc_page_size = 512
        self.emmc_block_size = 512

    def __get_machid(self, section):
        """Get the machid for a section.

        info -- ConfigParser object, containing image flashing info
        section -- section to retreive the machid from
        """
        try:
            machid = int(section.find(".//machid").text, 0)
            machid = "%x" % machid
        except ValueError as e:
            error("invalid value for machid, should be integer")

        return machid

    def __get_img_size(self, filename):
        """Get the size of the image to be flashed

        filaneme -- string, filename of the image to be flashed
        """

        if filename.lower() == "none":
            return 0
        try:
            return getsize(os.path.join(self.images_dname, filename))
        except OSError as e:
            error("error getting image size '%s'" % filename, e)

    def __get_part_info(self, partition):
        """Return partition info for the specified partition.

        partition -- string, partition name
        """
        try:
            return self.partitions[partition]
        except KeyError as e:
            return None

    def __gen_flash_script_bootconfig(self, entries, partition, flinfo, script, part_section):
        global ARCH_NAME
        fw_imgs = []
        skip_size_check = ""

        if flinfo.type != "emmc":
            fw_objs = part_section.findall('img_name')
            if (len(fw_objs) <= 1):
                return 0

            for i in fw_objs:
                fw_imgs.append(i.text)
        else:
            if 'bootconfig_type_max' in part_section.attrib and image_type == "all":
                max_files = int(part_section.attrib['bootconfig_type_max'])
            else:
                return 0;

            for fw_type in range(1, max_files+1):
                if 'filename_img' + str(fw_type) in part_section.attrib:
                    filename = part_section.attrib['filename_img' + str(fw_type)]
                    if filename == "":
                        continue
                    fw_imgs.append(filename)

        i = 0
        for filename in fw_imgs:
            machid_list = []
            i = i + 1

            for section in entries:
                file_type = section.find('.//bootconfig_type')
                if file_type == None:
                    continue

                file_type = str(section.find(".//bootconfig_type").text)
                if str(file_type) != str(i):
                    continue

                machid = int(section.find(".//machid").text, 0)
                machid = "%x" % machid
                machid_list.append(machid)

            img_size = self.__get_img_size(filename)
            part_info = self.__get_part_info(partition)

            section_label = partition.split(":")
            if len(section_label) != 1:
                section_conf = section_label[1]
            else:
                section_conf = section_label[0]
            section_conf = section_conf.lower()

            if self.flinfo.type != "emmc":
                if part_info == None:
                    if self.flinfo.type == 'norplusnand':
                        if count > 2:
                            error("More than 2 NAND images for NOR+NAND is not allowed")
                elif img_size > part_info.length:
                    print("img size is larger than part. len in '%s'" % section_conf)
                    return 0
            else:
                if part_info != None:
                    if (img_size > 0):
                        if img_size > (part_info.length * self.flinfo.blocksize):
                            print("img size is larger than part. len in '%s'" % section_conf)
                            return 0

            if part_info == None and self.flinfo.type != 'norplusnand':
                print("Flash type is norplusemmc")
                return 1

            if len(machid_list) > 0:
                script.start_if_or("machid", machid_list)

                if img_size > 0:
                    script.imxtract_n_flash(filename[:-4] + "-" + sha1(filename), part_info.name)

                script.end_if()

        return 1

    def __gen_flash_script_cdt(self, entries, partition, flinfo, script):
        global ARCH_NAME
        for section in entries:
            machid = self.__get_machid(section)
            board = section.find(".//board").text

            try:
                memory = section.find(".//memory").text
            except AttributeError as e:
                memory = "128M16"
            if memory_size != "default":
                filename = "cdt-" + board + "_" + memory + "_LM" + memory_size + ".bin"
            else:
                filename = "cdt-" + board + "_" + memory + ".bin"

            img_size = self.__get_img_size(filename)
            part_info = self.__get_part_info(partition)

            section_label = partition.split(":")
            if len(section_label) != 1:
                section_conf = section_label[1]
            else:
                section_conf = section_label[0]

            section_conf = section_conf.lower()

            if self.flinfo.type != "emmc":
                if part_info == None:
                    if self.flinfo.type == 'norplusnand':
                        if count > 2:
                            error("More than 2 NAND images for NOR+NAND is not allowed")
                elif img_size > part_info.length:
                    print("img size is larger than part. len in '%s'" % section_conf)
                    return 0
            else:
                if part_info != None:
                    if (img_size > 0):
                        if img_size > (part_info.length * self.flinfo.blocksize):
                            print("img size is larger than part. len in '%s'" % section_conf)
                            return 0

            if part_info == None and self.flinfo.type != 'norplusnand':
                print("Flash type is norplusemmc")
                continue

            if machid:
                script.start_if("machid", machid)

            if img_size > 0:
                script.imxtract_n_flash("ddr-" + board + "_" + memory + "-" + sha1(filename), part_info.name)

            if machid:
                script.end_if()

        return 1

    def __gen_flash_script_for_ubi_wififw(self, fw_filename, script, multi_fw_check):
        if multi_fw_check != None:
            script.append(multi_fw_check[0], fatal=False)

        script.imxtract_n_flash(fw_filename[:-13] + "-" + sha1(fw_filename), "wifi_fw")

        if multi_fw_check != None:
            for i in range(multi_fw_check[1]):
                script.end_if()

        return 1

    def __gen_flash_script_for_non_ubi_wififw(self, partition, filename, flinfo, script, multi_fw_check):

        img_size = self.__get_img_size(filename)
        part_info = self.__get_part_info(partition)

        section_label = partition.split(":")
        if len(section_label) != 1:
            section_conf = section_label[1]
        else:
            section_conf = section_label[0]
        section_conf = section_conf.lower()

        if self.flinfo.type != "emmc":
            if part_info == None:
                if self.flinfo.type == 'norplusnand':
                    if count > 2:
                        error("More than 2 NAND images for NOR+NAND is not allowed")
            elif img_size > part_info.length:
                print("img size is larger than part. len in '%s'" % section_conf)
                return 0
        else:
            if part_info != None:
                if (img_size > 0):
                    if img_size > (part_info.length * self.flinfo.blocksize):
                        print("img size is larger than part. len in '%s'" % section_conf)
                        return 0

        if part_info == None and self.flinfo.type != 'norplusnand':
            print("Flash type is norplusemmc")
            return 1

        if multi_fw_check != None:
            script.append(multi_fw_check[0], fatal=False)

        if img_size > 0:
            script.imxtract_n_flash(filename[:-13] + "-" + sha1(filename), part_info.name)

        if multi_fw_check != None:
            for i in range(multi_fw_check[1]):
                script.end_if()

        return 1

    def __gen_flash_script_update_for_wififw(self, partition, filename, flinfo, script, machid_list):
        script.start_if_or("machid", machid_list)

        if ver_check == True:
            combs = self.__find_wifi_fw_ver_combinations(filename)
            for k, v in combs.items():
                if self.flash_type in ["nand", "nand-4k", "norplusnand", "norplusnand-4k"]:
                    self.__gen_flash_script_for_ubi_wififw(k, script, v)
                else:
                    self.__gen_flash_script_for_non_ubi_wififw(partition, k, flinfo, script, v)
        else:
            if self.flash_type in ["nand", "nand-4k", "norplusnand", "norplusnand-4k"]:
                self.__gen_flash_script_for_ubi_wififw(filename, script, None)
            else:
                self.__gen_flash_script_for_non_ubi_wififw(partition, filename, flinfo, script, None)

        script.end_if()

    def __gen_flash_script_wififw(self, entries, partition, filename, wifi_fw_type, flinfo, script):
        machid_list = []
        for section in entries:

            wififw_type = section.find('.//wififw_name')
            if wififw_type == None:
                continue
            wififw_type = str(section.find(".//wififw_name").text)

            if str(wifi_fw_type) != str(wififw_type):
                continue

            machid = int(section.find(".//machid").text, 0)
            machid = "%x" % machid
            if self.flash_type == "nor":
                is_nor_flash = section.find(".//spi_nor")
                if is_nor_flash == None:
                    continue
                is_nor_flash = section.find(".//spi_nor").text
                if is_nor_flash != "true":
                    continue
                machid_list.append(machid)
            else:
                machid_list.append(machid)
        if machid_list:
            self.__gen_flash_script_update_for_wififw(partition, filename, flinfo, script, machid_list)

    def __gen_flash_script_bootldr(self, entries, partition, flinfo, script):
        for section in entries:

            machid = self.__get_machid(section)
            board = section.find(".//board").text
            memory = section.find(".//memory").text
            tiny_image = section.find('.//tiny_image')

            if tiny_image == None:
                continue

            if memory_size != "default":
                filename = "bootldr1_" + board + "_" + memory + "_LM" + memory_size + ".mbn"
            else:
                filename = "bootldr1_" + board + "_" + memory + ".mbn"

            img_size = self.__get_img_size(filename)
            part_info = self.__get_part_info(partition)

            section_label = partition.split(":")
            if len(section_label) != 1:
                section_conf = section_label[1]
            else:
                section_conf = section_label[0]

            section_conf = section_conf.lower()

            if self.flinfo.type != "emmc":
                if part_info == None:
                    if self.flinfo.type == 'norplusnand':
                        if count > 2:
                            error("More than 2 NAND images for NOR+NAND is not allowed")
                elif img_size > part_info.length:
                    print("img size is larger than part. len in '%s'" % section_conf)
                    return 0
            else:
                if part_info != None:
                    if (img_size > 0):
                        if img_size > (part_info.length * self.flinfo.blocksize):
                            print("img size is larger than part. len in '%s'" % section_conf)
                            return 0

            if part_info == None and self.flinfo.type != 'norplusnand':
                print("Flash type is norplusemmc")
                continue

            if machid:
                script.start_if("machid", machid)

            if img_size > 0:
                script.imxtract_n_flash("bootldr1_" + board + "_" + memory + "-" + sha1(filename), part_info.name)

            if machid:
                script.end_if()

        return 1

    def __gen_script_mibib(self, script, flinfo, parts, parts_length, cmd):

        for index in range(parts_length):
            partition = parts[index]
            pnames = partition.findall('name')
            if pnames[0].text == "0:MIBIB":
                imgs = partition.findall('img_name')
                filename = imgs[0].text
                if cmd == "mibib_reload":
                    self.mibib_reload(filename, pnames[0].text, flinfo, script)
                if cmd == "xtract_n_flash":
                    script.imxtract_n_flash("mibib-" + sha1(filename), "0:MIBIB")

    def mibib_reload(self, filename, partition, flinfo, script):

        img_size = self.__get_img_size(filename)
        part_info = self.__get_part_info(partition)

        section_label = partition.split(":")
        if len(section_label) != 1:
            section_conf = section_label[1]
        else:
            section_conf = section_label[0]

        section_conf = section_conf.lower()

        if img_size > 0:
            script.append("imxtract $imgaddr %s" % (section_conf + "-" + sha1(filename)))

        fl_type = 0 if self.flinfo.type == 'nand' else 1
        script.append("mibib_reload %x %x %x %x" % (fl_type, flinfo.pagesize, flinfo.blocksize,
                          flinfo.chipsize))

        return 1

    def __gen_flash_script_image(self, parts, parts_length, filename, soc_version, file_exists, machid, partition, flinfo, script):

        img_size = 0
        if file_exists == 1:
            img_size = self.__get_img_size(filename)
        part_info = self.__get_part_info(partition)

        section_label = partition.split(":")
        if len(section_label) != 1:
            section_conf = section_label[1]
        else:
            section_conf = section_label[0]

        section_conf = section_conf.lower()

        if self.flinfo.type != "emmc":
            if part_info == None:
                if self.flinfo.type == 'norplusnand':
                    if count > 2:
                        error("More than 2 NAND images for NOR+NAND is not allowed")
            elif img_size > part_info.length:
                print("img size is larger than part. len in '%s'" % section_conf)
                return 0
        else:
            if part_info != None:
                if (img_size > 0):
                    if img_size > (part_info.length * self.flinfo.blocksize):
                        print("img size is larger than part. len in '%s'" % section_conf)
                        return 0

        if part_info == None and self.flinfo.type != 'norplusnand':
            print("Flash type is norplusemmc")
            return 1

        if machid:
            script.start_if("machid", machid)

        if section_conf == "qsee":
            section_conf = "tz"
        elif section_conf == "appsbl":
            section_conf = "u-boot"
        elif section_conf == "rootfs" and self.flash_type in ["nand", "nand-4k", "norplusnand", "norplusnand-4k"]:
            section_conf = "ubi"
        elif section_conf == "wififw" and self.flash_type in ["nand", "nand-4k", "norplusnand", "norplusnand-4k"]:
            section_conf = "wififw_ubi"

        if file_exists == 0:
            script.append('setenv stdout serial && echo "error: binary image not found" && exit 1', fatal=False)
            return 1

        if img_size > 0:
            if section_conf == "mibib":
                self.__gen_script_mibib(script, flinfo, parts, parts_length, "xtract_n_flash")
            else:
                script.imxtract_n_flash(section_conf + "-" + sha1(filename), part_info.name)

        if machid:
            script.end_if()

        return 1

    def __gen_flash_script(self, script, flinfo, root, testmachid=False):
        """Generate the script to flash the images.

        info -- ConfigParser object, containing image flashing info
        script -- Script object, to append commands to
        """
        global MODE
        global SRC_DIR
        global ARCH_NAME
        global flash_size

        diff_files = ""
        count = 0
        soc_version = 0
        diff_soc_ver_files = 0
        file_exists = 1
        wifi_fw_type = ""

        if self.flash_type == "norplusemmc" and flinfo.type == "emmc":
            srcDir_part = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + flinfo.type + "-partition"+ flash_size +".xml"
        else:
            srcDir_part = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + self.flash_type.lower() + "-partition"+ flash_size +".xml"

        root_part = ET.parse(srcDir_part)
        if self.flash_type != "emmc" and flinfo.type != "emmc":
            parts = root_part.findall(".//partitions/partition")
        elif self.flash_type != "emmc" and flinfo.type == "emmc":
            parts = root_part.findall(".//physical_partition[@ref='norplusemmc']/partition")
        else:
            parts = root_part.findall(".//physical_partition[@ref='emmc']/partition")
        if flinfo.type == "emmc" and image_type == "all":
            parts_length = len(parts) + 2
        else:
            parts_length = len(parts)

        entries = root.findall(".//data[@type='MACH_ID_BOARD_MAP']/entry")

        global wifi_fw_list
        wifi_fw_list = []
        no_fw_mach_ids = []
        for segment in entries:
            if (memory_size != "default"):
                profiles = segment.find('.//profiles')
                if (profiles == None):
                    continue
                if memory_size not in profiles.text:
                    continue

            wififw_type = segment.find('.//wififw_name')
            if wififw_type == None:
                machid = int(segment.find(".//machid").text, 0)
                machid = "%x" % machid

                no_fw_mach_ids.append(machid)
                continue
            wififw_type = str(segment.find(".//wififw_name").text)
            if wififw_type in wifi_fw_list:
                pass
            else:
                wifi_fw_list.append(wififw_type)

        chip_count = 0
        for soc_hw_version in soc_hw_versions[ARCH_NAME]:
            chip_count = chip_count + 1
            if chip_count == 1:
                script.script.append('if test -n $soc_hw_version')
                script.script.append('; then\n')
                script.script.append('if test "$soc_hw_version" = "%x" ' % soc_hw_version)
            else:
                script.script.append('|| test "$soc_hw_version" = "%x" ' % soc_hw_version)
        if chip_count >= 1:
            script.script.append('; then\n')
            script.script.append('echo \'soc_hw_version : Validation success\'\n')
            script.script.append('else\n')
            script.script.append('echo \'soc_hw_version : did not match, aborting upgrade\'\n')
            script.script.append('exit 1\n')
            script.script.append('fi\n')
            script.script.append('else\n')
            script.script.append('echo \'soc_hw_version : unknown, skipping validation\'\n')
            script.script.append('fi\n')

        if testmachid:
            machid_count = 0
            for section in entries:
                machid = self.__get_machid(section)
                machid_count =  machid_count + 1
                if machid_count == 1:
                    script.script.append('if test "$machid" = "%s" ' % machid)
                else:
                    script.script.append('|| test "$machid" = "%s" ' % machid)
            if machid_count >= 1:
                script.script.append('; then\n')
                script.script.append('echo \'machid : Validation success\'\n')
                script.script.append('else\n')
                script.script.append('echo \'machid : unknown, aborting upgrade\'\n')
                script.script.append('exit 1\n')
                script.script.append('fi\n')
        first = False
        section = None
        part_index = 0

        if flinfo.type == "emmc" and image_type == "all":
            first = True

        if flinfo.type == "nand" or self.flash_type == "norplusnand":
            script.append("flashinit nand")
        elif flinfo.type == "emmc" or self.flash_type == "norplusemmc":
            script.append("flashinit mmc")
        if flinfo.type == "emmc":
            script.append("flupdate set mmc")

        if flinfo.type != "emmc" and image_type != "hlos":
            self.__gen_script_mibib(script, flinfo, parts, parts_length, "mibib_reload")

        for index in range(parts_length):
            filename = ""
            partition = ""
            if first:
                if self.flash_type == "norplusemmc":
                    part_info = root.find(".//data[@type='NORPLUSEMMC_PARAMETER']")
                else:
                    part_info = root.find(".//data[@type='EMMC_PARAMETER']")
                part_fname = part_info.find(".//partition_mbn")
                filename = part_fname.text
                partition = "0:GPT"
                first = False

            elif index == (parts_length - 1) and flinfo.type == "emmc" and image_type == "all":
                if self.flash_type == "norplusemmc":
                    part_info = root.find(".//data[@type='NORPLUSEMMC_PARAMETER']")
                else:
                    part_info = root.find(".//data[@type='EMMC_PARAMETER']")
                part_fname = part_info.find(".//partition_mbn_backup")
                filename = part_fname.text
                partition = "0:GPTBACKUP"

            else:
                section = parts[part_index]
                part_index += 1
                if flinfo.type != "emmc":
                    try:
                        if image_type == "all" or section[8].attrib['image_type'] == image_type:
                            filename = section[8].text
                            try:
                                if section[8].attrib['mode'] != MODE:
                                    filename = section[9].text
                                else:
                                    pass
                            except AttributeError as e:
                                pass
                            except KeyError as e:
                                pass
                        else:
                            continue
                    except IndexError as e:
                        if index == (parts_length - 1):
                            return
                        else:
                            continue
                    except KeyError as e:
                        continue
                    partition = section[0].text
                else:
                    try:
                        diff_files = section.attrib['diff_files']
                    except KeyError as e:
                        if tiny_16m == "true":
                            pass
                        elif 'bootconfig_type_max' in section.attrib and image_type == "all":
                            partition = section.attrib['label']
                        else:
                            try:
                                partition = section.attrib['label']
                                if image_type == "all" or section.attrib['image_type'] == image_type:
                                    filename = section.attrib['filename']
                                    if filename == "":
                                        continue
                            except KeyError as e:
                                print("Skipping partition '%s'" % section.attrib['label'])
                                pass

                    if diff_files == "true":
                        try:
                            if image_type == "all" or section.attrib['image_type'] == image_type:
                                filename = section.attrib['filename_' + MODE]
                                partition = section.attrib['label']
                            if filename == "":
                                continue
                        except KeyError as e:
                            print("Skipping partition '%s'" % section.attrib['label'])
                            pass
                        diff_files = "" # Clear for next iteration

            if "0:BOOTCONFIG" in partition:
                try:
                    ret = self.__gen_flash_script_bootconfig(entries, partition, flinfo, script, section)
                    if ret == 1:
                        continue
                except KeyError as e:
                    continue

            # Get machID
            if partition != "0:CDT" and partition != "0:DDRCONFIG":
                machid = None
            else:
                try:
                    if image_type == "all" or section.attrib['image_type'] == image_type:
                        ret = self.__gen_flash_script_cdt(entries, partition, flinfo, script)
                        if ret == 0:
                            return 0
                        continue
                except KeyError as e:
                    continue

            if partition == "0:BOOTLDR1":
                if image_type == "all" or section.attrib['image_type'] == image_type:
                    ret = self.__gen_flash_script_bootldr(entries, partition, flinfo, script)
                    if ret == 0:
                        return 0
                    continue

            if flinfo.type != "emmc" and flinfo.type != "nor":
                imgs = section.findall('img_name')
                for img in imgs:
                    memory_attr = img.get('memory')
                    if memory_attr != None and memory_attr == memory_size:
                        filename = img.text;

                    atf_image = img.get('atf')
                    if atf_image != None and atf == "true":
                        filename = img.text;

            else:
                if partition == "0:WIFIFW":

                    if ver_check == True:
                        script.append("qcn_detect", fatal=False)

                    if no_fw_mach_ids and filename != "":
                        self.__gen_flash_script_update_for_wififw(partition, filename, flinfo, script, no_fw_mach_ids)

                    if flinfo.type == "emmc":
                        section_img_type = section.attrib['image_type']
                    else:
                        section_img_type = section[8].attrib['image_type']

                    if image_type == "all" or section_img_type == image_type:
                        for wifi_fw_type in wifi_fw_list:
                            fw_name = wifi_fw_type
                            if fw_name == "":
                                continue
                            ret = self.__gen_flash_script_wififw(entries, partition, fw_name, wifi_fw_type, flinfo, script)
                            if ret == 0:
                                return 0
                            fw_name = ""
                            wifi_fw_type = ""

                    if filename != "":
                        if filename not in wifi_fw_list:
                            wifi_fw_list.append(filename)
                            filename = ""
                    continue

                if section != None and filename != "" and section.get('filename_mem' + memory_size) != None:
                    filename = section.get('filename_mem' + memory_size)

                if section != None and atf == "true" and section.get('filename_atf') != None:
                    filename = section.get('filename_atf')

            if filename != "":
                ret = self.__gen_flash_script_image(parts, parts_length, filename, soc_version, file_exists, machid, partition, flinfo, script)
                if ret == 0:
                    return 0

            if self.flash_type in [ "nand", "nand-4k", "norplusnand", "norplusnand-4k" ] and partition == "rootfs":

                if ver_check == True:
                    script.append("qcn_detect", fatal=False)

                for wifi_fw_type in wifi_fw_list:
                    filename = wifi_fw_type
                    if filename == "":
                        continue
                    ret = self.__gen_flash_script_wififw(entries, partition, filename, wifi_fw_type, flinfo, script)
                    if ret == 0:
                        return 0
                    filename = ""
                    wifi_fw_type = ""

                continue

        if flinfo.type == "emmc":
            script.append("flupdate clear")

        return 1

    def __gen_script_bootconfig(self, images, flinfo, part_info, section):
        global ARCH_NAME
        fw_imgs = []

        if flinfo.type != "emmc":
            fw_objs = section.findall('img_name')
            if (len(fw_objs) <= 1):
                return 0

            for i in fw_objs:
                fw_imgs.append(i.text)

        else:
            if 'bootconfig_type_max' in section.attrib:
                max_files = int(section.attrib['bootconfig_type_max'])
            else:
                return 0;

            for fw_type in range(1, max_files+1):
                if 'filename_img' + str(fw_type) in section.attrib:
                    filename = section.attrib['filename_img' + str(fw_type)]
                    if filename == "":
                        continue
                    fw_imgs.append(filename)

        if part_info == None and self.flinfo.type != 'norplusnand':
            return 0

        for filename in fw_imgs:
            image_info = ImageInfo(filename[:-4] + "-" + sha1(filename),
                                   filename, "firmware")
            if filename.lower() != "none":
                if image_info not in images:
                    images.append(image_info)

        return 1

    def __gen_script_cdt(self, images, flinfo, root, section_conf, partition):
        global ARCH_NAME

        entries = root.findall(".//data[@type='MACH_ID_BOARD_MAP']/entry")

        for section in entries:

            board = section.find(".//board").text
            try:
                memory = section.find(".//memory").text
            except AttributeError as e:
                memory = "128M16"

            if memory_size != "default":
                filename = "cdt-" + board + "_" + memory + "_LM" + memory_size + ".bin"
            else:
                filename = "cdt-" + board + "_" + memory + ".bin"
            file_info = "ddr-" + board + "_" + memory

            part_info = self.__get_part_info(partition)

            if part_info == None and self.flinfo.type != 'norplusnand':
                continue

            image_info = ImageInfo(file_info + "-" + sha1(filename),
                                   filename, "firmware")
            if filename.lower() != "none":
                if image_info not in images:
                    images.append(image_info)

    def __gen_script_bootldr(self, images, flinfo, root, section_conf, partition):
        global ARCH_NAME

        entries = root.findall(".//data[@type='MACH_ID_BOARD_MAP']/entry")

        for section in entries:

            board = section.find(".//board").text
            tiny_image = section.find('.//tiny_image')

            if tiny_image == None:
                continue

            try:
                memory = section.find(".//memory").text
            except AttributeError as e:
                memory = "128M16"

            if memory_size != "default":
                filename = "bootldr1_" + board + "_" + memory + "_LM" + memory_size + ".mbn"
            else:
                filename = "bootldr1_" + board + "_" + memory + ".mbn"
            file_info = "bootldr1_" + board + "_" + memory

            part_info = self.__get_part_info(partition)

            if part_info == None and self.flinfo.type != 'norplusnand':
                continue

            image_info = ImageInfo(file_info + "-" + sha1(filename),
                                   filename, "firmware")
            if filename.lower() != "none":
                if image_info not in images:
                    images.append(image_info)

    def __find_wifi_fw_ver_combinations(self, filename):
        global wifi_fws_avail

        wifi_fws_combs = dict()

        for a, i in zip(possible_fw_vers[0][0], possible_fw_vers[0][1]):
            if (1 == len(possible_fw_vers)):
                temp_name = filename
                temp_name = temp_name.replace(possible_fw_vers[0][0][0], a)

                if os.path.exists(os.path.join(self.images_dname, temp_name)):
                    if wifi_fws_combs.get(temp_name) == None:
                        wifi_fws_combs[temp_name] = [i, len(possible_fw_vers)];

            else:
                for b, j in zip(possible_fw_vers[1][0], possible_fw_vers[1][1]):
                    if (2 == len(possible_fw_vers)):
                        temp_name = filename
                        temp_name = temp_name.replace(possible_fw_vers[0][0][0], a)
                        temp_name = temp_name.replace(possible_fw_vers[1][0][0], b)

                        if os.path.exists(os.path.join(self.images_dname, temp_name)):
                            if wifi_fws_combs.get(temp_name) == None:
                                scr_name = i + j
                                wifi_fws_combs[temp_name] = [scr_name, len(possible_fw_vers)];
                    else:
                        for c, k in zip(possible_fw_vers[2][0], possible_fw_vers[2][1]):
                            if (3 == len(possible_fw_vers)):
                                temp_name = filename
                                temp_name = temp_name.replace(possible_fw_vers[0][0][0], a)
                                temp_name = temp_name.replace(possible_fw_vers[1][0][0], b)
                                temp_name = temp_name.replace(possible_fw_vers[2][0][0], c)

                                if os.path.exists(os.path.join(self.images_dname, temp_name)):
                                    if wifi_fws_combs.get(temp_name) == None:
                                        scr_name = i + j + k
                                        wifi_fws_combs[temp_name] = [scr_name, len(possible_fw_vers)];
                            else:
                                for d, l in zip(possible_fw_vers[3][0], possible_fw_vers[3][1]):
                                    if (4 == len(possible_fw_vers)):
                                        temp_name = filename
                                        temp_name = temp_name.replace(possible_fw_vers[0][0][0], a)
                                        temp_name = temp_name.replace(possible_fw_vers[1][0][0], b)
                                        temp_name = temp_name.replace(possible_fw_vers[2][0][0], c)
                                        temp_name = temp_name.replace(possible_fw_vers[3][0][0], d)

                                        if os.path.exists(os.path.join(self.images_dname, temp_name)):
                                            if wifi_fws_combs.get(temp_name) == None:
                                                scr_name = i + j + k + l
                                                wifi_fws_combs[temp_name] = [scr_name, len(possible_fw_vers)];

        wifi_fws_avail.update(wifi_fws_combs)
        return wifi_fws_combs


    def __gen_script_append_images(self, filename, soc_version, wifi_fw_type, images, flinfo, root, section_conf, partition):

        part_info = self.__get_part_info(partition)
        if part_info == None and self.flinfo.type != 'norplusnand':
            return

        if section_conf == "qsee":
            section_conf = "tz"
        elif section_conf == "appsbl":
            print(" Using u-boot...")
            section_conf = "u-boot"
        elif section_conf == "rootfs" and self.flash_type in ["nand", "nand-4k", "norplusnand", "norplusnand-4k"]:
            section_conf = "ubi"
        elif section_conf == "wififw" and self.flash_type in ["nand", "nand-4k", "norplusnand", "norplusnand-4k"]:
            section_conf = "wififw_ubi"
        elif section_conf == "wififw" and wifi_fw_type:
            section_conf = filename[:-13]

        image_info = ImageInfo(section_conf + "-" + sha1(filename),     filename, "firmware")
        if filename.lower() != "none":
            if image_info not in images:
                images.append(image_info)

    def __gen_script_append_images_wififw_ubi_volume(self, fw_filename, wifi_fw_type, images):

        image_info = ImageInfo(fw_filename[:-13] + "-" + sha1(fw_filename),
                                fw_filename, "firmware")
        if fw_filename.lower() != "none":
            if image_info not in images:
                images.append(image_info)

    def __gen_script(self, script_fp, script, images, flinfo, root):
        """Generate the script to flash the multi-image blob.

        script_fp -- file object, to write script to
        info_fp -- file object, to read flashing information from
        script -- Script object, to append the commands to
        images -- list of ImageInfo, appended to, based on images in config
        """
        global MODE
        global SRC_DIR
        global flash_size

        soc_version = 0
        diff_soc_ver_files = 0
        wifi_fw_type = ""
        diff_files = ""
        file_exists = 1

        ret = self.__gen_flash_script(script, flinfo, root, True)
        if ret == 0:
            return 0 #Stop packing this single-image

        if (self.flash_type == "norplusemmc" and flinfo.type == "emmc") or (self.flash_type != "norplusemmc"):
            script.end()

        if self.flash_type == "norplusemmc" and flinfo.type == "emmc":
            srcDir_part = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + flinfo.type + "-partition"+ flash_size +".xml"
        else:
            srcDir_part = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + self.flash_type.lower() + "-partition"+ flash_size +".xml"

        root_part = ET.parse(srcDir_part)
        if self.flash_type != "emmc" and flinfo.type != "emmc":
            parts = root_part.findall(".//partitions/partition")
        elif self.flash_type != "emmc" and flinfo.type == "emmc":
            parts = root_part.findall(".//physical_partition[@ref='norplusemmc']/partition")
        else:
            parts = root_part.findall(".//physical_partition[@ref='emmc']/partition")
        if flinfo.type == "emmc" and image_type == "all":
            parts_length = len(parts) + 2
        else:
            parts_length = len(parts)

        first = False
        section = None
        part_index = 0

        if flinfo.type == "emmc" and image_type == "all":
            first = True

        for index in range(parts_length):
            filename = ""
            partition = ""
            if first:
                if self.flash_type == "norplusemmc":
                    part_info = root.find(".//data[@type='NORPLUSEMMC_PARAMETER']")
                else:
                    part_info = root.find(".//data[@type='EMMC_PARAMETER']")
                part_fname = part_info.find(".//partition_mbn")
                filename = part_fname.text
                partition = "0:GPT"
                first = False

            elif index == (parts_length - 1) and flinfo.type == "emmc" and image_type == "all":
                if self.flash_type == "norplusemmc":
                    part_info = root.find(".//data[@type='NORPLUSEMMC_PARAMETER']")
                else:
                    part_info = root.find(".//data[@type='EMMC_PARAMETER']")
                part_fname = part_info.find(".//partition_mbn_backup")
                filename = part_fname.text
                partition = "0:GPTBACKUP"

            else:
                section = parts[part_index]
                part_index += 1
                if flinfo.type != "emmc":
                    try:
                        if image_type == "all" or section[8].attrib['image_type'] == image_type:
                            filename = section[8].text
                            try:
                                if section[8].attrib['mode'] != MODE:
                                    filename = section[9].text
                            except AttributeError as e:
                                pass
                            except KeyError as e:
                                pass
                    except IndexError as e:
                        if index == (parts_length - 1):
                            return
                        else:
                            continue
                    except KeyError as e:
                        continue
                    partition = section[0].text

                else:
                    try:
                        diff_files = section.attrib['diff_files']
                    except KeyError as e:
                        try:
                            diff_soc_ver_files = section.attrib['diff_soc_ver_files']
                            partition = section.attrib['label']
                        except KeyError as e:
                            if tiny_16m == "true":
                                pass
                            elif "bootconfig_type_max" in section.attrib and image_type == "all":
                                partition = section.attrib['label']
                            else:
                                try:
                                    partition = section.attrib['label']
                                    if partition != "0:WIFIFW":
                                        if image_type == "all" or section.attrib['image_type'] == image_type:
                                            filename = section.attrib['filename']
                                            if filename == "":
                                                continue
                                except KeyError as e:
                                    partition = ""
                                    print("Skipping partition '%s'" % section.attrib['label'])
                                    pass

                    if diff_files == "true":
                        try:
                            if image_type == "all" or section.attrib['image_type'] == image_type:
                                filename = section.attrib['filename_' + MODE]
                                partition = section.attrib['label']
                            if filename == "":
                                continue

                        except KeyError as e:
                            print("Skipping partition '%s'" % section.attrib['label'])
                            pass
                        diff_files = "" # Clear for next iteration

            part_info = self.__get_part_info(partition)

            section_label = partition.split(":")
            if len(section_label) != 1:
                section_conf = section_label[1]
            else:
                section_conf = section_label[0]

            section_conf = section_conf.lower()

            if section_conf == "bootconfig" or section_conf == "bootconfig1":
                try:
                    if image_type == "all" or section[8].attrib['image_type'] == image_type:
                        ret = self.__gen_script_bootconfig(images, flinfo, part_info, section)
                        if ret == 1:
                            continue
                except KeyError as e:
                    continue

            if section_conf == "cdt" or section_conf == "ddrconfig":
                try:
                    if image_type == "all" or section[8].attrib['image_type'] == image_type:
                        self.__gen_script_cdt(images, flinfo, root, section_conf, partition)
                        continue
                except KeyError as e:
                    continue

            if section_conf == "bootldr1":
                try:
                    if image_type == "all" or section[8].attrib['image_type'] == image_type:
                        self.__gen_script_bootldr(images, flinfo, root, section_conf, partition)
                        continue
                except KeyError as e:
                    continue

            if flinfo.type != "emmc":
                imgs = section.findall('img_name')
                for img in imgs:
                    memory_attr = img.get('memory')
                    if memory_attr != None and memory_attr == memory_size:
                        filename = img.text;

                    atf_image = img.get('atf')
                    if atf_image != None and atf == "true":
                        filename = img.text;

            else:
                if section != None and filename != "" and section.get('filename_mem' + memory_size) != None:
                    filename = section.get('filename_mem' + memory_size)

                if section != None and atf == "true" and section.get('filename_atf') != None:
                    filename = section.get('filename_atf')

            # wififw images specific for RDP based on machid
            if self.flash_type in [ "emmc" , "norplusemmc" , "tiny-nor", "tiny-nor-debug", "nor" ] and section_conf == "wififw":
                if ver_check:
                    for k, v in wifi_fws_avail.items():
                        self.__gen_script_append_images(k, soc_version, 1, images, flinfo, root, section_conf, partition)
                else:
                    for wifi_fw_type in wifi_fw_list:
                        fw_name = wifi_fw_type
                        if fw_name == "":
                            continue
                        if not os.path.exists(os.path.join(self.images_dname, fw_name)):
                            return 0
                        self.__gen_script_append_images(fw_name, soc_version, wifi_fw_type, images, flinfo, root, section_conf, partition)
                    wifi_fw_type = ""
                    fw_name = ""

                continue

            if filename != "":
                self.__gen_script_append_images(filename, soc_version, wifi_fw_type, images, flinfo, root, section_conf, partition)

            if self.flash_type in [ "nand", "nand-4k", "norplusnand", "norplusnand-4k" ] and section_conf == "rootfs":
                if ver_check:
                    for k, v in wifi_fws_avail.items():
                        self.__gen_script_append_images_wififw_ubi_volume(k, wifi_fw_type, images)
                else:
                    for wifi_fw_type in wifi_fw_list:
                        filename = wifi_fw_type
                        if filename == "":
                            continue
                        ret = self.__gen_script_append_images_wififw_ubi_volume(filename, wifi_fw_type, images)
                        if ret == 0:
                            return 0
                        filename = ""
                        wifi_fw_type = ""

                continue

        return 1

    def __mkimage(self, images):
        """Create the multi-image blob.

        images -- list of ImageInfo, containing images to be part of the blob
        """
        try:
            its_fp = open(self.its_fname, "wb")
        except IOError as e:
            error("error opening its file '%s'" % self.its_fname, e)

        desc = "Flashing %s %x %x"
        desc = desc % (self.flinfo.type, self.flinfo.pagesize,
                       self.flinfo.blocksize)

        image_data = []
        for (section, fname, imtype) in images:
            fname = fname.replace("\\", "\\\\")
            subs = dict(name=section, desc=fname, fname=fname, imtype=imtype)
            image_data.append(its_image_tmpl.substitute(subs))

        image_data = "".join(image_data)
        its_data = its_tmpl.substitute(desc=desc, images=image_data)

        if sys.version_info.major >= 3:
            its_data = bytes(its_data, 'utf-8')
        its_fp.write(its_data)
        its_fp.close()

        try:
            cmd = [SRC_DIR + "/mkimage", "-f", self.its_fname, self.img_fname]
            ret = subprocess.call(cmd)
            if ret != 0:
                print(ret)
                error("failed to create u-boot image from script")
        except OSError as e:
            error("error executing mkimage", e)

    def __create_fnames(self):
        """Populate the filenames."""

        self.scr_fname = os.path.join(self.images_dname, "flash.scr")
        self.its_fname = os.path.join(self.images_dname, "flash.its")

    def __gen_board_script(self, flinfo, part_fname, images, root):
        global SRC_DIR
        global ARCH_NAME
        global flash_size

        """Generate the flashing script for one board.

        board_section -- string, board section in board config file
        machid -- string, board machine ID in hex format
        flinfo -- FlashInfo object, contains board specific flash params
        part_fname -- string, partition file specific to the board
        fconf_fname -- string, flash config file specific to the board
        images -- list of ImageInfo, append images used by the board here
        """
        script_fp = open(self.scr_fname, "a")
        self.flinfo = flinfo
        script = FlashScript(flinfo)

        if flinfo.type != "emmc":
            if root.find(".//data[@type='NAND_PARAMETER']/entry") != None:
                if self.flash_type == "nand-4k" or self.flash_type == "norplusnand-4k":
                    flash_param = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='4k']")
                else:
                    flash_param = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='2k']")
            else:
                flash_param = root.find(".//data[@type='NAND_PARAMETER']")

            pagesize = int(flash_param.find(".//page_size").text)
            pages_per_block = int(flash_param.find(".//pages_per_block").text)
            blocksize = pages_per_block * pagesize
            blocks_per_chip = int(flash_param.find(".//total_block").text)
            chipsize = blocks_per_chip * blocksize

            mibib = MIBIB(part_fname, flinfo, blocksize, chipsize)
            self.partitions = mibib.get_parts()

        else:
            gpt = GPT(part_fname, flinfo)
            self.partitions = gpt.get_parts()

        ret = self.__gen_script(script_fp, script, images, flinfo, root)
        if ret == 0:
            return 0

        try:
            script_fp.write(script.dumps())
        except IOError as e:
            error("error writing to script '%s'" % script_fp.name, e)

        script_fp.close()
        return 1

    def __process_board_flash_emmc(self, ftype, images, root):
        """Extract board info from config and generate the flash script.

        ftype -- string, flash type 'emmc'
        board_section -- string, board section in config file
        machid -- string, board machine ID in hex format
        images -- list of ImageInfo, append images used by the board here
        """

        try:
            part_info = root.find(".//data[@type='" + self.flash_type.upper() + "_PARAMETER']")
            part_fname = part_info.find(".//partition_mbn")
            part_fname = part_fname.text
            part_fname = os.path.join(self.images_dname, part_fname)

            if ftype == "norplusemmc":
                part_info = root.find(".//data[@type='NORPLUSEMMC_PARAMETER']")
                pagesize = int(part_info.find(".//page_size_flash").text)
                part_info = root.find(".//data[@type='EMMC_PARAMETER']")
            else:
                pagesize = self.emmc_page_size
            blocksize = self.emmc_block_size
            chipsize = int(part_info.find(".//total_block").text)
            if ftype.lower() == "norplusemmc":
                ftype = "emmc"

        except ValueError as e:
            error("invalid flash info in section '%s'" % board_section.find('machid').text, e)

        flinfo = FlashInfo(ftype, pagesize, blocksize, chipsize)

        ret = self.__gen_board_script(flinfo, part_fname, images, root)
        if ret == 0:
            return 0

        return 1

    def __process_board_flash(self, ftype, images, root):
        global SRC_DIR
        global ARCH_NAME
        global MODE
        global flash_size

        try:
            if ftype == "tiny-nor" or ftype == "tiny-nor-debug":
                part_info = root.find(".//data[@type='" + "TINY_NOR_PARAMETER']")
            elif ftype in ["nand", "nand-4k"]:
                if root.find(".//data[@type='NAND_PARAMETER']/entry") != None:
                    if ftype == "nand":
                        part_info = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='2k']")
                    else:
                        part_info = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='4k']")
                else:
                    part_info = root.find(".//data[@type='" + "NAND_PARAMETER']")
            elif ftype == "norplusnand-4k":
                part_info = root.find(".//data[@type='" + "NORPLUSNAND_PARAMETER']")
            else:
                part_info = root.find(".//data[@type='" + ftype.upper() + "_PARAMETER']")

            MODE_APPEND = "_64" if MODE == "64" else ""

            UBINIZE_CFG_NAME = ARCH_NAME + "-ubinize" + MODE_APPEND + flash_size +".cfg"

            f1 = open(SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + UBINIZE_CFG_NAME, 'r')
            UBINIZE_CFG_NAME = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/tmp-" + UBINIZE_CFG_NAME
            f2 = open(UBINIZE_CFG_NAME, 'w')
            for line in f1:
                f2.write(line.replace('image=', "image=" + SRC_DIR + "/"))
            f1.close()
            f2.close()

            part_file = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + ftype + "-partition"+ flash_size +".xml"
            parts = ET.parse(part_file).findall('.//partitions/partition')
            for index in range(len(parts)):
                section = parts[index]
                if section[0].text == "rootfs":
                    rootfs_pos = 9 if MODE == "64" else 8
                    UBI_IMG_NAME = section[rootfs_pos].text

            if ftype in ["nand-4k", "norplusnand-4k"]:
                cmd = '%s -m 4096 -p 256KiB -o root.ubi %s' % ((SRC_DIR + "/ubinize") ,UBINIZE_CFG_NAME)
                ret = subprocess.call(cmd, shell=True)
                if ret != 0:
                    error("ubinization got failed")
                cmd = 'dd if=root.ubi of=%s bs=4k conv=sync' % (SRC_DIR + "/" + UBI_IMG_NAME)
                ret = subprocess.call(cmd, shell=True)
                if ret != 0:
                    error("ubi image copy operation failed")

            elif ftype in ["nand", "norplusnand"]:
                cmd = '%s -m 2048 -p 128KiB -o root.ubi %s' % ((SRC_DIR + "/ubinize") ,UBINIZE_CFG_NAME)
                ret = subprocess.call(cmd, shell=True)
                if ret != 0:
                    error("ubinization got failed")
                cmd = 'dd if=root.ubi of=%s bs=2k conv=sync' % (SRC_DIR + "/" + UBI_IMG_NAME)
                ret = subprocess.call(cmd, shell=True)
                if ret != 0:
                    error("ubi image copy operation failed")

            part_file = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + ftype + "-partition"+ flash_size +".xml"
            part_xml = ET.parse(part_file)
            if (part_xml.find(".//partitions/partition[name='0:MIBIB']")):
                partition = part_xml.find(".//partitions/partition[name='0:MIBIB']")
            else:
                partition = part_xml.find(".//partitions/partition[2]")
            part_fname = partition[8].text
            part_fname = os.path.join(self.images_dname, part_fname)
            pagesize = int(part_info.find(".//page_size").text)
            pages_per_block = int(part_info.find(".//pages_per_block").text)
            blocks_per_chip = int(part_info.find(".//total_block").text)

            if ftype in ["tiny-nor", "norplusnand", "norplusnand-4k", "norplusemmc", "tiny-nor-debug"]:
                ftype = "nor"
            if ftype in ["nand-4k"]:
                ftype = "nand"

        except ValueError as e:
            error("invalid flash info in section '%s'" % board_section.find('machid').text, e)

        blocksize = pages_per_block * pagesize
        chipsize = blocks_per_chip * blocksize

        flinfo = FlashInfo(ftype, pagesize, blocksize, chipsize)

        ret = self.__gen_board_script(flinfo, part_fname, images, root)
        return ret

    def __process_board(self, images, root):

        try:
            if self.flash_type in [ "nand", "nand-4k", "nor", "tiny-nor", "norplusnand", "norplusnand-4k", "tiny-nor-debug" ]:
                ret = self.__process_board_flash(self.flash_type, images, root)
            elif self.flash_type == "emmc":
                ret = self.__process_board_flash_emmc(self.flash_type, images, root)
            elif self.flash_type == "norplusemmc":
                ret = self.__process_board_flash("norplusemmc", images, root)
                if ret:
                    ret = self.__process_board_flash_emmc("norplusemmc", images, root)
            return ret
        except ValueError as e:
            error("error getting board info in section '%s'" % board_section.find('machid').text, e)

    def main_bconf(self, flash_type, images_dname, out_fname, root):
        """Start the packing process, using board config.

        flash_type -- string, indicates flash type, 'nand' or 'nor' or 'tiny-nor' or 'emmc' or 'norplusnand'
        images_dname -- string, name of images directory
        out_fname -- string, output file path
        """
        self.flash_type = flash_type
        self.images_dname = images_dname
        self.img_fname = out_fname

        self.__create_fnames()
        try:
            os.unlink(self.scr_fname)
        except OSError as e:
            pass

        images = []
        ret = self.__process_board(images, root)
        if ret != 0:
            images.insert(0, ImageInfo("script", "flash.scr", "script"))
            self.__mkimage(images)
        else:
            fail_img = out_fname.split("/")
            error("Failed to pack %s" % fail_img[-1])

class UsageError(Exception):
    """Indicates error in command arguments."""
    pass

class ArgParser(object):
    """Class to parse command-line arguments."""

    DEFAULT_TYPE = "nor,tiny-nor,nand,norplusnand,emmc,norplusemmc"

    def __init__(self):
        self.flash_type = None
        self.images_dname = None
        self.out_dname = None
        self.scr_fname = None
        self.its_fname = None

    def parse(self, argv):
        global MODE
        global SRC_DIR
        global ARCH_NAME
        global image_type
        global memory_size
        global atf
        global skip_4k_nand
        global flash_size
        flash_size = ""

        """Start the parsing process, and populate members with parsed value.

        argv -- list of string, the command line arguments
        """

        cdir = os.path.abspath(os.path.dirname(""))
        if len(sys.argv) > 1:
            try:
                opts, args = getopt(sys.argv[1:], "", ["arch=", "fltype=", "srcPath=", "inImage=", "outImage=", "image_type=", "memory=", "flash_size=", "skip_4k_nand", "atf"])
            except GetoptError as e:
                raise UsageError(e.msg)

            for option, value in opts:
                if option == "--arch":
                    ARCH_NAME = value

                elif option == "--fltype":
                    self.flash_type = value

                elif option == "--srcPath":
                    SRC_DIR = os.path.abspath(value)

                elif option == "--inImage":
                    self.images_dname = os.path.join(cdir, value)

                elif option == "--outImage":
                    self.out_dname = os.path.join(cdir, value)

                elif option == "--image_type":
                    image_type = value

                elif option == "--memory":
                    memory_size = value

                elif option == "--flash_size":
                    flash_size = "-" + value

                elif option =="--atf":
                    atf = "true"

                elif option =="--skip_4k_nand":
                    skip_4k_nand = "true"

#Verify Arguments passed by user

# Verify arch type
            if ARCH_NAME not in supported_arch:
                raise UsageError("Invalid arch type '%s'" % arch)

            MODE = "32"
            if ARCH_NAME[-3:] == "_64":
                MODE = "64"
                ARCH_NAME = ARCH_NAME[:-3]

# Set flash type to default type (nand) if not given by user
            if self.flash_type == None:
                self.flash_type = ArgParser.DEFAULT_TYPE
            for flash_type in self.flash_type.split(","):
                if flash_type not in [ "nand", "nor", "tiny-nor", "emmc", "norplusnand", "norplusemmc", "tiny-nor-debug" ]:
                    raise UsageError("invalid flash type '%s'" % flash_type)

# Verify src Path
            if SRC_DIR == "":
                raise UsageError("Source Path is not provided")

#Verify input image path
            if self.images_dname == None:
                raise UsageError("input images' Path is not provided")

#Verify Output image path
            if self.out_dname == None:
                raise UsageError("Output Path is not provided")

    def usage(self, msg):
        """Print error message and command usage information.

        msg -- string, the error message
        """
        print("pack: %s" % msg)
        print()
        print("Usage:")
        print("python pack_v2.py [options] [Value] ...")
        print()
        print("options:")
        print("  --arch \tARCH_TYPE [" + '/'.join(supported_arch) + "]")
        print("  --fltype \tFlash Type [nor/tiny-nor/nand/emmc/norplusnand/norplusemmc/tiny-nor-debug]")
        print(" \t\tMultiple flashtypes can be passed by a comma separated string")
        print(" \t\tDefault is all. i.e If \"--fltype\" is not passed image for all the flash-type will be created.\n")
        print("  --srcPath \tPath to the directory containg the meta scripts and configs")
        print()
        print("  --inImage \tPath to the direcory containg binaries and images needed for singleimage")
        print()
        print("  --outImage \tPath to the directory where single image will be generated")
        print()
        print("  --memory \tMemory size for low memory profile")
        print(" \t\tIf it is not specified CDTs with default memory size are taken for single-image packing.\n")
        print(" \t\tIf specified, CDTs created with specified memory size will be used for single-image.\n")
        print("  --flash_size \tFlash size")
        print()
        print("  --atf \t\tReplace tz with atf for QSEE partition")
        print("  --skip_4k_nand \tskip generating 4k nand images")
        print(" \t\tThis Argument does not take any value")
        print("Pack Version: %s" % version)

def main():
    """Main script entry point.

    Created to avoid polluting the global namespace.
    """

    global ver_check
    global tiny_16m
    try:
        parser = ArgParser()
        parser.parse(sys.argv)
    except UsageError as e:
        parser.usage(e.args[0])
        sys.exit(1)

    pack = Pack()

    if not os.path.exists(parser.out_dname):
        os.makedirs(parser.out_dname)

    config = SRC_DIR + "/" + ARCH_NAME + "/config.xml"
    root = ET.parse(config)

    ver_param = root.find(".//data[@type='VERSION_PARAMETER']")
    if ver_param == None:
        ver_check = False
    else:
        global soc_ver_list
        global def_ver_list
        global possible_fw_vers
        global wifi_fws_avail
        global flash_size

        wifi_fws_avail = dict()
        ver_check = True
        soc_ver_list = str(ver_param.find(".//version_check").text).split(",")
        def_ver_list = str(ver_param.find(".//default_version").text).split(",")
        def_ver_list = list(map(int, def_ver_list))

        if len(soc_ver_list) != len(def_ver_list):
            print("Invalid VERSION_PARAMETER!!! Please check " + config + " file.")
            sys.exit(1)

        possible_fw_vers = []
        for (fw, ver) in list(zip(soc_ver_list, def_ver_list)):
            temp = []

            def_v = fw
            if (ver > 1):
                def_v = fw + "_v" + str(ver)
            new_v = fw + "_v" + str(ver+1)
            if fw == ARCH_NAME:
                fw = "soc"

            def_scr = 'if test "$' + fw + '_version_major" = "' + str(ver) + '" || test "$' + fw + '_version_major" = ""; then '
            new_scr = 'if test "$' + fw + '_version_major" = "' + str(ver+1) + '"; then '

            temp.append([def_v, new_v])
            temp.append([def_scr, new_scr])
            possible_fw_vers.append(temp)

    if skip_4k_nand != "true":
        # Add nand-4k flash type, if nand flash type is specified
        if "nand" in parser.flash_type.split(",") and flash_size == "":
            if root.find(".//data[@type='NAND_PARAMETER']/entry") != None:
                parser.flash_type = parser.flash_type + ",nand-4k"

        # Add norplusnand-4k flash type, if norplusnand flash type is specified
        if "norplusnand" in parser.flash_type.split(",") and flash_size == "":
            if root.find(".//data[@type='NAND_PARAMETER']/entry") != None:
                parser.flash_type = parser.flash_type + ",norplusnand-4k"

# Format the output image name from Arch, flash type and mode
    for flash_type in parser.flash_type.split(","):
        if (flash_type == "tiny-nor" or flash_type == "tiny-nor-debug"):
            tiny_16m = "true"
        else:
            tiny_16m = "false"

        MODE_APPEND = "_64" if MODE == "64" else ""
        if image_type == "hlos":
            suffix = "-apps"+ flash_size + ".img"
        else:
            suffix = "-single" + flash_size + ".img"

        parser.out_fname = flash_type + "-" + ARCH_NAME + MODE_APPEND + suffix

        parser.out_fname = os.path.join(parser.out_dname, parser.out_fname)

        pack.main_bconf(flash_type, parser.images_dname,
                        parser.out_fname, root)

if __name__ == "__main__":
    main()
