######################################################################
# Copyright (c) 2017, 2019, The Linux Foundation. All rights reserved.
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
lk = "false"
skip_4k_nand = "false"
atf = "false"
tiny_16m = "false"
multi_wifi_fw = "false"

# Note: ipq806x didn't expose any relevant version */
soc_hw_version_ipq40xx = { 0x20050100 };
soc_hw_version_ipq807x = { 0x200D0100, 0x200D0101, 0x200D0102, 0x200D0200 };
soc_hw_version_ipq6018 = { 0x20170100 };
soc_hw_version_ipq5018 = { 0x20180100, 0x20180101 };
soc_hw_version_ipq9574 = { 0x20190100 };
soc_hw_version_ipq5332 = { 0x201A0100, 0x201A0101 };

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

def roundup(value, roundto):
    """Return the next largest multiple of 'roundto'."""

    return ((value + roundto - 1) // roundto) * roundto

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

    def __init__(self, filename, pagesize, blocksize, chipsize):
        self.filename = filename
        self.pagesize = pagesize
        self.blocksize = blocksize
        self.chipsize = chipsize
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
    TABLE_VERSION_IPQ806X = 3
    TABLE_VERSION_OTHERS = 4


    Entry = namedtuple("Entry", "name offset length"
                        " attr1 attr2 attr3 which_flash")
    ENTRY_FMT = "<16sLLBBBB"

    def __init__(self, filename, pagesize, blocksize, chipsize, nand_blocksize, nand_chipsize):
        self.filename = filename
        self.pagesize = pagesize
        self.blocksize = blocksize
        self.chipsize = chipsize
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
        if ARCH_NAME == "ipq806x":
            if mtable.version != MIBIB.TABLE_VERSION_IPQ806X:
                error("unsupported partition table version")
        else:
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

        self.script.append('if test "x$verbose" = "x"; then\n')
        self.script.append("failedmsg='[failed]'\n")
        self.script.append('else\n')
        self.script.append("failedmsg='%s Failed'\n" % ("#" * 40))
        self.script.append('fi\n')

    def append(self, cmd, fatal=True):
        """Add a command to the script.

        Add additional code, to terminate on error. This can be
        supressed by passing 'fatal' as False.
        """

        if fatal:
            """Check cmd strings to display reason for failure."""

            if "imxtract" in cmd:
                self.script.append("failreason='error: failed on image extraction'\n")
            elif "erase" in cmd:
                self.script.append("failreason='error: failed on partition erase'\n")
            elif "write" in cmd:
                self.script.append("failreason='error: failed on partition write'\n")
            else:
                pass

            self.script.append(cmd
                               + ' || setenv stdout serial'
                               + ' && echo "$failedmsg"'
                               + ' && echo "$failreason"'
                               + ' && exit 1\n')
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

    def start_activity(self, activity):
        """Generate code, to indicate start of an activity."""

        self.script.append('if test "x$verbose" = "x"; then\n')
        self.echo("'%-55.55s'" % activity, nl=False)
        self.script.append('else\n')
        self.echo("'%s %s Started'" % ("#" * 40, activity), verbose=True)
        self.script.append('fi\n')
        self.activity = activity

    def finish_activity(self):
        """Generate code, to indicate end of an activity."""

        self.script.append('if test "x$verbose" = "x"; then\n')
        self.echo("'[ done ]'")
        self.redirect("serial")
        self.script.append('else\n')
        self.echo("'%s %s Done'" % ("#" * 40, self.activity), verbose=True)
        self.script.append('fi\n')

    def imxtract(self, part):
        """Generate code, to extract image location, from a multi-image blob.

        part -- string, name of the sub-image

        Sets the $fileaddr environment variable, to point to the
        location of the sub-image.
        """

        self.append("imxtract $imgaddr %s" % part)

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

class Flash_Script(FlashScript):
    """Class for creating NAND flash scripts."""

    def __init__(self, *args):
        FlashScript.__init__(self, args[0])
        if args[0].type == "nand":
            self.ipq_nand = args[1]
        elif args[0].type == "nor" or args[0].type == "norplusnand":
            self.nand_pagesize = args[1]

    def erase(self, offset, size):
        """Generate code, to erase the specified partition."""

        if self.flash_type != "emmc":
            size = roundup(size, self.blocksize)

        if self.flash_type == "nand":
            self.append("nand device 0 && nand erase 0x%08x 0x%08x" % (offset, size))
        elif self.flash_type == "nor":
            self.append("sf erase 0x%08x +0x%08x" % (offset, size))
        elif self.flash_type == "emmc":
            self.append("mmc erase 0x%08x %x" % (offset, size))

    def nand_write(self, offset, part_size, img_size, spi_nand):
        """Handle the NOR + NAND case
           All binaries upto HLOS will go to NOR and Root FS will go to NAND
           Assumed all nand page sizes are less than are equal to 8KB
           """

        if spi_nand == "true":
            self.append("nand device 1 && nand erase 0x%08x 0x%08x" % (offset, part_size))
        else:
            self.append("nand device 0 && nand erase 0x%08x 0x%08x" % (offset, part_size))

        if img_size > 0:
            self.append("nand write $fileaddr 0x%08x 0x%08x" % (offset, img_size))

    def write(self, offset, size):
        """Generate code, to write to a partition."""

        if self.flash_type == "nand":
            if size > 0:
                size = roundup(size, self.pagesize)
                self.append("nand write $fileaddr 0x%08x 0x%08x" % (offset, size))

        elif self.flash_type == "nor":
            if size > 0:
                self.append("sf write $fileaddr 0x%08x 0x%08x" % (offset, size))

        elif self.flash_type == "emmc":
            if size > 0:
                size = roundup(size, self.blocksize)
                blk_cnt = int(size / self.blocksize)
                self.append("mmc write $fileaddr 0x%08x %x" % (offset, blk_cnt))

    def probe(self):
        if self.flash_type == "nand":
            pass
        elif self.flash_type == "nor":
            self.append("sf probe")
        else:
            pass

    def switch_layout(self, layout):
        if self.flash_type == "nand":
            self.append("ipq_nand %s" % layout)
        else:
            pass

    def switch_layout_qpic(self, layout):
        self.append("qpic_nand %s" % layout)

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
    # The maximum rootfs size is 64MB
    norplusnand_rootfs_img_size = (64 * 1024 * 1024)

    def __init__(self):
        self.flinfo = None
        self.images_dname = None
        self.ipq_nand = None
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
            machid = int(section.find("./machid").text, 0)
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
            if 'bootconfig_type_max' in part_section.attrib:
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

            if self.flinfo.type == 'nand':
                size = roundup(img_size, flinfo.pagesize)
                tr = ' | tr \"\\000\" \"\\377\"'

            if self.flinfo.type == 'emmc':
                size = roundup(img_size, flinfo.blocksize)
                tr = ''

            if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
                pad_size = size - img_size
                filename_abs = os.path.join(self.images_dname, filename)
                filename_abs_pad = filename_abs + ".padded"
                cmd = 'cat %s > %s' % (filename_abs, filename_abs_pad)
                ret = subprocess.call(cmd, shell=True)
                if ret != 0:
                    error("failed to copy image")
                cmd = 'dd if=/dev/zero count=1 bs=%s %s >> %s' % (pad_size, tr, filename_abs_pad)
                cmd = '(' + cmd + ') 1>/dev/null 2>/dev/null'
                ret = subprocess.call(cmd, shell=True)
                if ret != 0:
                    error("failed to create padded image from script")

            if self.flinfo.type != "emmc":
                if part_info == None:
                    if self.flinfo.type == 'norplusnand':
                        if count > 2:
                            error("More than 2 NAND images for NOR+NAND is not allowed")
                elif img_size > part_info.length:
                    print("img size is larger than part. len in '%s'" % section_conf)
                    return 0
            else:
                if (skip_size_check == "" or wifi_fw_type < skip_size_check):
                    if part_info != None:
                        if (img_size > 0):
                            if img_size > (part_info.length * self.flinfo.blocksize):
                                print("img size is larger than part. len in '%s'" % section_conf)
                                return 0
                else:
                    print("EMMC: size check skipped for '%s'" % filename)

            if part_info == None and self.flinfo.type != 'norplusnand':
                print("Flash type is norplusemmc")
                return 1

            script.start_if_or("machid", machid_list)
            script.start_activity("Flashing %s:" % ( filename[:-4] ))

            if img_size > 0:
                filename_pad = filename + ".padded"
                if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
                    script.imxtract(filename[:-4] + "-" + sha1(filename_pad))
                else:
                    script.imxtract(filename[:-4] + "-" + sha1(filename))

            part_size = Pack.norplusnand_rootfs_img_size
            if part_info == None:
                if self.flinfo.type == 'norplusnand':
                    offset = count * Pack.norplusnand_rootfs_img_size
                    script.nand_write(offset, part_size, img_size, spi_nand)
                    count = count + 1
            else:
                if part_info.which_flash == 0:
                    offset = part_info.offset
                    script.erase(offset, part_info.length)
                    script.write(offset, img_size)
                else:
                    offset = part_info.offset
                    script.nand_write(offset, part_info.length, img_size, spi_nand)

            script.finish_activity()
            script.end_if()

        return 1

    def __gen_flash_script_cdt(self, entries, partition, flinfo, script):
        global ARCH_NAME
        for section in entries:
            machid = int(section.find(".//machid").text, 0)
            machid = "%x" % machid
            board = section.find(".//board").text
            spi_nand = section.find(".//spi_nand").text
            if ARCH_NAME != "ipq806x":
                try:
                    memory = section.find(".//memory").text
                except AttributeError as e:
                    memory = "128M16"
                if memory_size != "default":
                    filename = "cdt-" + board + "_" + memory + "_LM" + memory_size + ".bin"
                else:
                    filename = "cdt-" + board + "_" + memory + ".bin"
            else:
                filename = "cdt-" + board + ".bin"

            img_size = self.__get_img_size(filename)
            part_info = self.__get_part_info(partition)

            section_label = partition.split(":")
            if len(section_label) != 1:
                section_conf = section_label[1]
            else:
                section_conf = section_label[0]

            section_conf = section_conf.lower()

            if self.flinfo.type == 'nand':
                size = roundup(img_size, flinfo.pagesize)
                tr = ' | tr \"\\000\" \"\\377\"'

            if self.flinfo.type == 'emmc':
                size = roundup(img_size, flinfo.blocksize)
                tr = ''

            if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
                pad_size = size - img_size
                filename_abs = os.path.join(self.images_dname, filename)
                filename_abs_pad = filename_abs + ".padded"
                cmd = 'cat %s > %s' % (filename_abs, filename_abs_pad)
                ret = subprocess.call(cmd, shell=True)
                if ret != 0:
                    error("failed to copy image")
                cmd = 'dd if=/dev/zero count=1 bs=%s %s >> %s' % (pad_size, tr, filename_abs_pad)
                cmd = '(' + cmd + ') 1>/dev/null 2>/dev/null'
                ret = subprocess.call(cmd, shell=True)
                if ret != 0:
                    error("failed to create padded image from script")

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
            if ARCH_NAME != "ipq806x":
                script.start_activity("Flashing ddr-%s_%s:" % ( board, memory ))
                if img_size > 0:
                    filename_pad = filename + ".padded"
                    if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
                        script.imxtract("ddr-" + board + "_" + memory + "-" + sha1(filename_pad))
                    else:
                        script.imxtract("ddr-" + board + "_" + memory + "-" + sha1(filename))
                        """ script.imxtract("cdt-" + board + "_" + memory + ".bin-" + sha1(filename_pad))
                    else:
                        script.imxtract("cdt-" + board + "_" + memory + ".bin-" + sha1(filename)) """

            else:
                script.start_activity("Flashing ddr-%s:" % (board))
                script.switch_layout("sbl")
                if img_size > 0:
                    filename_pad = filename + ".padded"
                    if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
                        script.imxtract("ddr-" + board + "-" + sha1(filename_pad))
                    else:
                        script.imxtract("ddr-" + board + "-" + sha1(filename))
                        """ script.imxtract("cdt-" + board + ".bin-" + sha1(filename_pad))
                    else:
                        script.imxtract("cdt-" + board + ".bin-" + sha1(filename)) """

            part_size = Pack.norplusnand_rootfs_img_size
            if part_info == None:
                if self.flinfo.type == 'norplusnand':
                    offset = count * Pack.norplusnand_rootfs_img_size
                    script.nand_write(offset, part_size, img_size, spi_nand)
                    count = count + 1
            else:
                if part_info.which_flash == 0:
                    offset = part_info.offset
                    script.erase(offset, part_info.length)
                    script.write(offset, img_size)
                else:
                    offset = part_info.offset
                    script.nand_write(offset, part_info.length, img_size, spi_nand)

            script.finish_activity()

            if machid:
                script.end_if()

        return 1
    def __gen_flash_script_wififw_ubi_volume(self, entries, fw_filename, wifi_fw_type, script):

        machid_list = []
        for section in entries:

            wififw_type = section.find('.//wififw_type')
            if wififw_type == None:
                continue
            wififw_type = str(section.find(".//wififw_type").text)

            if str(wifi_fw_type) != str(wififw_type):
                continue

            machid = int(section.find(".//machid").text, 0)
            machid = "%x" % machid

            machid_list.append(machid)

        script.start_if_or("machid", machid_list)
        script.start_activity("Flashing " + fw_filename[:-13] + ":")
        script.imxtract(fw_filename[:-13] + "-" + sha1(fw_filename))

        rootfs_info = self.__get_part_info("rootfs")
        rootfs_offset = rootfs_info.offset
        rootfs_len = rootfs_info.length

        wifi_fw_cmd = "setenv mtdids nand0=nand0\n"
        wifi_fw_cmd += "setenv mtdparts mtdparts=nand0:0x%x@0x%x(rootfs)\n" % (rootfs_len,rootfs_offset)
        wifi_fw_cmd += "ubi part rootfs\n"
        img_size = self.__get_img_size(fw_filename)
        wifi_fw_cmd += "ubi write $fileaddr wifi_fw %x" % img_size
        script.append(wifi_fw_cmd, fatal=False)

        #Enable the below lines for debugging purpose
        """
        script.append("mtdparts", fatal=False)
        script.append("ubi info layout", fatal=False)
        """

        script.finish_activity()
        script.end_if()

        return 1

    def __gen_flash_script_wififw(self, entries, partition, filename, wifi_fw_type, flinfo, script, skip_size_check):

        machid_list = []
        for section in entries:

            wififw_type = section.find('.//wififw_type')
            if wififw_type == None:
                continue
            wififw_type = str(section.find(".//wififw_type").text)

            if str(wifi_fw_type) != str(wififw_type):
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

        if self.flinfo.type == 'nand':
            size = roundup(img_size, flinfo.pagesize)
            tr = ' | tr \"\\000\" \"\\377\"'

        if self.flinfo.type == 'emmc':
            size = roundup(img_size, flinfo.blocksize)
            tr = ''

        if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
            pad_size = size - img_size
            filename_abs = os.path.join(self.images_dname, filename)
            filename_abs_pad = filename_abs + ".padded"
            cmd = 'cat %s > %s' % (filename_abs, filename_abs_pad)
            ret = subprocess.call(cmd, shell=True)
            if ret != 0:
                error("failed to copy image")
            cmd = 'dd if=/dev/zero count=1 bs=%s %s >> %s' % (pad_size, tr, filename_abs_pad)
            cmd = '(' + cmd + ') 1>/dev/null 2>/dev/null'
            ret = subprocess.call(cmd, shell=True)
            if ret != 0:
                error("failed to create padded image from script")

        if self.flinfo.type != "emmc":
            if part_info == None:
                if self.flinfo.type == 'norplusnand':
                    if count > 2:
                        error("More than 2 NAND images for NOR+NAND is not allowed")
            elif img_size > part_info.length:
                print("img size is larger than part. len in '%s'" % section_conf)
                return 0
        else:
            if (skip_size_check == "" or wifi_fw_type < skip_size_check):
                if part_info != None:
                    if (img_size > 0):
                        if img_size > (part_info.length * self.flinfo.blocksize):
                            print("img size is larger than part. len in '%s'" % section_conf)
                            return 0
            else:
                print("EMMC: size check skipped for '%s'" % filename)

        if part_info == None and self.flinfo.type != 'norplusnand':
            print("Flash type is norplusemmc")
            return 1

        script.start_if_or("machid", machid_list)
        script.start_activity("Flashing %s:" % ( filename[:-13] ))

        if img_size > 0:
            filename_pad = filename + ".padded"
            if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
                script.imxtract(filename[:-13] + "-" + sha1(filename_pad))
            else:
                script.imxtract(filename[:-13] + "-" + sha1(filename))

        part_size = Pack.norplusnand_rootfs_img_size
        if part_info == None:
            if self.flinfo.type == 'norplusnand':
                offset = count * Pack.norplusnand_rootfs_img_size
                script.nand_write(offset, part_size, img_size, spi_nand)
                count = count + 1
        else:
            if part_info.which_flash == 0:
                offset = part_info.offset
                script.erase(offset, part_info.length)
                script.write(offset, img_size)
            else:
                offset = part_info.offset
                script.nand_write(offset, part_info.length, img_size, spi_nand)

        script.finish_activity()
        script.end_if()

        return 1

    def __gen_flash_script_bootldr(self, entries, partition, flinfo, script):
        for section in entries:

            machid = int(section.find(".//machid").text, 0)
            machid = "%x" % machid
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

            if self.flinfo.type == 'nand':
                size = roundup(img_size, flinfo.pagesize)
                tr = ' | tr \"\\000\" \"\\377\"'

            if self.flinfo.type == 'emmc':
                size = roundup(img_size, flinfo.blocksize)
                tr = ''

            if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
                pad_size = size - img_size
                filename_abs = os.path.join(self.images_dname, filename)
                filename_abs_pad = filename_abs + ".padded"
                cmd = 'cat %s > %s' % (filename_abs, filename_abs_pad)
                ret = subprocess.call(cmd, shell=True)
                if ret != 0:
                    error("failed to copy image")
                cmd = 'dd if=/dev/zero count=1 bs=%s %s >> %s' % (pad_size, tr, filename_abs_pad)
                cmd = '(' + cmd + ') 1>/dev/null 2>/dev/null'
                ret = subprocess.call(cmd, shell=True)
                if ret != 0:
                    error("failed to create padded image from script")

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

            script.start_activity("Flashing bootldr1-%s_%s:" % ( board, memory ))
            if img_size > 0:
                filename_pad = filename + ".padded"
                if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
                    script.imxtract("bootldr1_" + board + "_" + memory + "-" + sha1(filename_pad))
                else:
                    script.imxtract("bootldr1_" + board + "_" + memory + "-" + sha1(filename))

            part_size = Pack.norplusnand_rootfs_img_size
            if part_info == None:
                if self.flinfo.type == 'norplusnand':
                    offset = count * Pack.norplusnand_rootfs_img_size
                    script.nand_write(offset, part_size, img_size, spi_nand)
                    count = count + 1
            else:
                if part_info.which_flash == 0:
                    offset = part_info.offset
                    script.erase(offset, part_info.length)
                    script.write(offset, img_size)
                else:
                    offset = part_info.offset
                    script.nand_write(offset, part_info.length, img_size, spi_nand)

            script.finish_activity()

            if machid:
                script.end_if()

        return 1

    def __gen_flash_script_image(self, filename, soc_version, file_exists, machid, partition, flinfo, script):

        global IF_QCN9000
        global IF_QCN9224

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
        spi_nand = False

        if self.flinfo.type == 'nand':
            size = roundup(img_size, flinfo.pagesize)
            tr = ' | tr \"\\000\" \"\\377\"'

        if self.flinfo.type == 'emmc':
            size = roundup(img_size, flinfo.blocksize)
            tr = ''

        if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
            pad_size = size - img_size
            filename_abs = os.path.join(self.images_dname, filename)
            filename_abs_pad = filename_abs + ".padded"
            cmd = 'cat %s > %s' % (filename_abs, filename_abs_pad)
            ret = subprocess.call(cmd, shell=True)
            if ret != 0:
                error("failed to copy image")
            cmd = 'dd if=/dev/zero count=1 bs=%s %s >> %s' % (pad_size, tr, filename_abs_pad)
            cmd = '(' + cmd + ') 1>/dev/null 2>/dev/null'
            ret = subprocess.call(cmd, shell=True)
            if ret != 0:
                error("failed to create padded image from script")

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

        if section_conf == "mibib" and IF_QCN9000:
            section_conf = "mibib_qcn9000"
        if section_conf == "mibib" and IF_QCN9224:
            section_conf = "mibib_qcn9224"
        if section_conf == "gpt" and IF_QCN9224:
            section_conf = "gpt_qcn9224"
        if section_conf == "gptbackup" and IF_QCN9224:
            section_conf = "gptbackup_qcn9224"
        if section_conf == "qsee":
            section_conf = "tz"
        elif section_conf == "appsbl":
            if lk == "true":
                section_conf = "lkboot"
            else:
                section_conf = "u-boot"
        elif section_conf == "rootfs" and self.flash_type in ["nand", "nand-4k", "nand-audio", "nand-audio-4k", "norplusnand", "norplusnand-4k"]:
            section_conf = "ubi"
        elif section_conf == "wififw" and self.flash_type in ["nand", "nand-4k", "nand-audio", "nand-audio-4k", "norplusnand", "norplusnand-4k"]:
            section_conf = "wififw_ubi"
            if IF_QCN9000:
                section_conf = "wififw_ubi_qcn9000"

        if soc_version:
            section_conf = section_conf + "_v" + str(soc_version)
            if str(soc_version) == "1":
                script.append('if test "$soc_version_major" = "1" || test "$soc_version_major" = ""; then\n', fatal=False)
            else:
                script.start_if("soc_version_major", soc_version)

        script.start_activity("Flashing %s:" % section_conf)

        if file_exists == 0:
            script.append('setenv stdout serial && echo "error: binary image not found" && exit 1', fatal=False)
            if soc_version:
                script.end_if()
            return 1

        if ARCH_NAME == "ipq806x":
            script.switch_layout(layout)
        if img_size > 0:
            filename_pad = filename + ".padded"
            if ((self.flinfo.type == 'nand' or self.flinfo.type == 'emmc') and (size != img_size)):
                script.imxtract(section_conf + "-" + sha1(filename_pad))
            else:
                script.imxtract(section_conf + "-" + sha1(filename))

        part_size = Pack.norplusnand_rootfs_img_size
        if part_info == None:
            if self.flinfo.type == 'norplusnand':
                offset = count * Pack.norplusnand_rootfs_img_size
                img_size = Pack.norplusnand_rootfs_img_size
                script.nand_write(offset, part_size, img_size, spi_nand)
                count = count + 1
        else:
            if part_info.which_flash == 0:
                offset = part_info.offset
                script.erase(offset, part_info.length)
                if ARCH_NAME in ["ipq5018", "ipq5018_64", "ipq9574", "ipq9574_64"]:
                    if self.flash_type == "nand-4k" and section_conf == "sbl1":
                        script.switch_layout_qpic("sbl")
                script.write(offset, img_size)
                if ARCH_NAME in ["ipq5018", "ipq5018_64", "ipq9574", "ipq9574_64"]:
                    if self.flash_type == "nand-4k" and section_conf == "sbl1":
                        script.switch_layout_qpic("linux")
            else:
                offset = part_info.offset
                script.nand_write(offset, part_info.length, img_size, spi_nand)

        script.finish_activity()

        if soc_version:
            script.end_if()

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
        global IF_QCN9000
        global IF_QCN9224
        global flash_size

        diff_files = ""
        count = 0
        soc_version = 0
        diff_soc_ver_files = 0
        file_exists = 1
        wifi_fw_type = ""
        wifi_fw_type_min = ""
        wifi_fw_type_max = ""
        skip_size_check = ""

        if self.flash_type == "norplusemmc" and flinfo.type == "emmc":
            srcDir_part = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + flinfo.type + "-partition"+ flash_size +".xml"
        else:
            if IF_QCN9000:
                srcDir_part = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + self.flash_type.lower() + "-partition-qcn9000"+ flash_size +".xml"
            elif IF_QCN9224 and flinfo.type != "emmc":
                srcDir_part = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + self.flash_type.lower() + "-partition-qcn9224"+ flash_size +".xml"
            else:
                srcDir_part = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + self.flash_type.lower() + "-partition"+ flash_size +".xml"

        root_part = ET.parse(srcDir_part)
        if self.flash_type != "emmc" and flinfo.type != "emmc":
            parts = root_part.findall(".//partitions/partition")
        elif self.flash_type != "emmc" and flinfo.type == "emmc":
            if IF_QCN9224:
                parts = root_part.findall(".//physical_partition[@ref='norplusemmc_qcn9224']/partition")
            else:
                parts = root_part.findall(".//physical_partition[@ref='norplusemmc']/partition")
        else:
            if IF_QCN9224:
                parts = root_part.findall(".//physical_partition[@ref='emmc_qcn9224']/partition")
            else:
                parts = root_part.findall(".//physical_partition[@ref='emmc']/partition")
        if flinfo.type == "emmc" and image_type == "all":
            parts_length = len(parts) + 2
        else:
            parts_length = len(parts)
        entries = root.findall(".//data[@type='MACH_ID_BOARD_MAP']/entry")

        # Note: Skipping validation for ipq806x. It didn't expose any relevant ID. */
        if ARCH_NAME == "ipq40xx":
            soc_hw_versions = soc_hw_version_ipq40xx
        if ARCH_NAME == "ipq807x" or ARCH_NAME == "ipq807x_64":
            soc_hw_versions = soc_hw_version_ipq807x
        if ARCH_NAME == "ipq6018" or ARCH_NAME == "ipq6018_64":
            soc_hw_versions = soc_hw_version_ipq6018
        if ARCH_NAME == "ipq5018" or ARCH_NAME == "ipq5018_64":
            soc_hw_versions = soc_hw_version_ipq5018
        if ARCH_NAME == "ipq9574" or ARCH_NAME == "ipq9574_64":
            soc_hw_versions = soc_hw_version_ipq9574
        if ARCH_NAME == "ipq5332" or ARCH_NAME == "ipq5332_64":
            soc_hw_versions = soc_hw_version_ipq5332

        chip_count = 0
        for soc_hw_version in soc_hw_versions:
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
                machid = int(section.find(".//machid").text, 0)
                machid = "%x" % machid
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

        if ARCH_NAME in ["ipq5332"]:
            if flinfo.type == "nand" or self.flash_type == "norplusnand":
                script.append("flashinit nand")
            elif flinfo.type == "emmc" or self.flash_type == "norplusemmc":
                script.append("flashinit mmc")

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
                if IF_QCN9224 and flinfo.type == "emmc":
                    if self.flash_type == "emmc":
                        filename = filename[:-5] + "2.bin"
                    elif self.flash_type == "norplusemmc":
                        filename = filename[:-5] + "3.bin"
                partition = "0:GPT"
                first = False

            elif index == (parts_length - 1) and flinfo.type == "emmc" and image_type == "all":
                if self.flash_type == "norplusemmc":
                    part_info = root.find(".//data[@type='NORPLUSEMMC_PARAMETER']")
                else:
                    part_info = root.find(".//data[@type='EMMC_PARAMETER']")
                part_fname = part_info.find(".//partition_mbn_backup")
                filename = part_fname.text
                if IF_QCN9224 and flinfo.type == "emmc":
                    if self.flash_type == "emmc":
                        filename = filename[:-5] + "2.bin"
                    elif self.flash_type == "norplusemmc":
                        filename = filename[:-5] + "3.bin"
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
                        try:
                            diff_soc_ver_files = section.attrib['diff_soc_ver_files']
                        except KeyError as e:
                            if (multi_wifi_fw == "true" or tiny_16m == "true") and 'wififw_type_min' in section.attrib:
                                wifi_fw_type_min = section.attrib['wififw_type_min']
                                wifi_fw_type_max = section.attrib['wififw_type_max']
                            elif 'bootconfig_type_max' in section.attrib and image_type == "all":
                                partition = section.attrib['label']
                            else:
                                try:
                                    if image_type == "all" or section.attrib['image_type'] == image_type:
                                        filename = section.attrib['filename']
                                        if filename == "":
                                            continue
                                        partition = section.attrib['label']
                                        if lk == "true" and "u-boot" in filename:
                                            filename = filename.replace("u-boot", "lkboot")
                                except KeyError as e:
                                    print("Skipping partition '%s'" % section.attrib['label'])
                                    pass

                    if diff_files == "true":
                        try:
                            if image_type == "all" or section.attrib['image_type'] == image_type:
                                filename = section.attrib['filename_' + MODE]
                                if lk == "true" and "uImage" in filename:
                                    if MODE == "32":
                                        filename = 'openwrt-' + ARCH_NAME + '-kernelboot.img'
                                    if MODE == "64":
                                        filename = 'openwrt-' + ARCH_NAME + '_' + MODE + '-kernelboot.img'
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
            if partition != "0:CDT" and partition != "0:CDT_1" and partition != "0:DDRCONFIG":
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

            if ARCH_NAME == "ipq806x":
            # Get Layout
                try:
                    layout = section[9].text
                except:
                    layout  = None

                if layout not in ("sbl", "linux", None):
                    error("invalid layout in '%s'" % section)

            if flinfo.type != "emmc":
                img = section.find('img_name')

                if img != None and 'wififw_type' in img.attrib and (multi_wifi_fw == "true" or tiny_16m == "true"):
                    imgs = section.findall('img_name')
                    try:
                        for img in imgs:
                            filename = img.text
                            if 'optional' in img.attrib:
                                if not os.path.exists(os.path.join(self.images_dname, filename)):
                                    continue
                            wifi_fw_type = img.get('wififw_type')
                            ret = self.__gen_flash_script_wififw(entries, partition, filename, wifi_fw_type, flinfo, script, "")
                            if ret == 0:
                                return 0
                            wifi_fw_type = ""
                        continue
                    except KeyError as e:
                        continue

                if img != None and 'soc_version' in img.attrib:
                    imgs = section.findall('img_name')
                    try:
                        for img in imgs:
                            filename = img.text
                            soc_version = img.get('soc_version')
                            if 'optional' in img.attrib:
                                if not os.path.exists(os.path.join(self.images_dname, filename)):
                                    file_exists = 0
                            ret = self.__gen_flash_script_image(filename, soc_version, file_exists, machid, partition, flinfo, script)
                            if ret == 0:
                                return 0
                            file_exists = 1 # generating flash script is mandatory by default

                        soc_version = 0 # Clear soc_version for next iteration
                        continue
                    except KeyError as e:
                        continue

                imgs = section.findall('img_name')
                for img in imgs:
                    memory_attr = img.get('memory')
                    if memory_attr != None and memory_attr == memory_size:
                        filename = img.text;

                    atf_image = img.get('atf')
                    if atf_image != None and atf == "true":
                        filename = img.text;

            else:
                if wifi_fw_type_min:
                    partition = section.attrib['label']

                    if 'skip_size_check' in section.attrib:
                        skip_size_check = section.attrib['skip_size_check']

                    for fw_type in range(int(wifi_fw_type_min), int(wifi_fw_type_max) + 1):

                        if image_type == "all" or section.attrib['image_type'] == image_type:
                            if 'filename_img' + str(fw_type) in section.attrib:
                                filename = section.attrib['filename_img' + str(fw_type)]

                            if filename == "":
                                continue
                            wifi_fw_type = str(fw_type)
                            ret = self.__gen_flash_script_wififw(entries, partition, filename, wifi_fw_type, flinfo, script, skip_size_check)
                            if ret == 0:
                                return 0
                            wifi_fw_type = ""
                            filename = ""

                    wifi_fw_type_min = ""
                    wifi_fw_type_max = "" # Clear for next partition
                    continue

                if diff_soc_ver_files:
                    try:
                        for version in range(1, int(diff_soc_ver_files)+1):
                            if image_type == "all" or section.attrib['image_type'] == image_type:
                                filename = section.attrib['filename_v' + str(version)]
                                partition = section.attrib['label']
                            if filename == "":
                                continue
                            if 'optional' in section.attrib:
                                if not os.path.exists(os.path.join(self.images_dname, filename)):
                                    file_exists = 0
                            ret = self.__gen_flash_script_image(filename, version, file_exists, machid, partition, flinfo, script)
                            if ret == 0:
                                return 0
                            file_exists = 1
                        diff_soc_ver_files = 0 # Clear diff_soc_ver_files for next iteration
                        continue
                    except KeyError as e:
                        print("Skipping partition '%s'" % section.attrib['label'])
                        pass

                if section != None and filename != "" and section.get('filename_mem' + memory_size) != None:
                    filename = section.get('filename_mem' + memory_size)

                if section != None and atf == "true" and section.get('filename_atf') != None:
                    filename = section.get('filename_atf')

            if filename != "":
                ret = self.__gen_flash_script_image(filename, soc_version, file_exists, machid, partition, flinfo, script)
                if ret == 0:
                    return 0

            if self.flash_type in [ "nand", "nand-4k", "norplusnand", "norplusnand-4k" ] and partition == "rootfs" and multi_wifi_fw == "true":

                fw_imgs = section.findall('img_name')
                for fw_img in fw_imgs:
                    wifi_fw_type = fw_img.get('wififw_type')
                    if wifi_fw_type != None:
                        fw_filename = fw_img.text
                        if fw_filename != "":
                            ret = self.__gen_flash_script_wififw_ubi_volume(entries, fw_filename, wifi_fw_type, script)
                            if ret == 0:
                                return 0
                    wifi_fw_type = ""
                continue

        return 1

    def __gen_script_bootconfig(self, images, flinfo, partition, section):
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

        for filename in fw_imgs:
            part_info = self.__get_part_info(partition)
            if part_info == None and self.flinfo.type != 'norplusnand':
                continue

            if self.flinfo.type == 'nand':
                img_size = self.__get_img_size(filename)
                size = roundup(img_size, flinfo.pagesize)
                if ( size != img_size ):
                    filename = filename + ".padded"
            if self.flinfo.type == 'emmc':
                img_size = self.__get_img_size(filename)
                size = roundup(img_size, flinfo.blocksize)
                if ( size != img_size ):
                    filename = filename + ".padded"
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
            if ARCH_NAME != "ipq806x":
                try:
                    memory = section.find(".//memory").text
                except AttributeError as e:
                    memory = "128M16"

                if memory_size != "default":
                    filename = "cdt-" + board + "_" + memory + "_LM" + memory_size + ".bin"
                else:
                    filename = "cdt-" + board + "_" + memory + ".bin"
                file_info = "ddr-" + board + "_" + memory
            else:
                filename = "cdt-" + board + ".bin"
                file_info = "ddr-" + board

            part_info = self.__get_part_info(partition)

            if part_info == None and self.flinfo.type != 'norplusnand':
                continue

            if self.flinfo.type == 'nand':
                img_size = self.__get_img_size(filename)
                size = roundup(img_size, flinfo.pagesize)
                if ( size != img_size ):
                    filename = filename + ".padded"
            if self.flinfo.type == 'emmc':
                img_size = self.__get_img_size(filename)
                size = roundup(img_size, flinfo.blocksize)
                if ( size != img_size ):
                    filename = filename + ".padded"
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

            if ARCH_NAME != "ipq806x":
                try:
                    memory = section.find(".//memory").text
                except AttributeError as e:
                    memory = "128M16"

                if memory_size != "default":
                    filename = "bootldr1_" + board + "_" + memory + "_LM" + memory_size + ".mbn"
                else:
                    filename = "bootldr1_" + board + "_" + memory + ".mbn"
                file_info = "bootldr1_" + board + "_" + memory
            else:
                filename = "bootldr1_" + board + ".mbn"
                file_info = "bootldr1_" + board

            part_info = self.__get_part_info(partition)

            if part_info == None and self.flinfo.type != 'norplusnand':
                continue

            if self.flinfo.type == 'nand':
                img_size = self.__get_img_size(filename)
                size = roundup(img_size, flinfo.pagesize)
                if ( size != img_size ):
                    filename = filename + ".padded"
            if self.flinfo.type == 'emmc':
                img_size = self.__get_img_size(filename)
                size = roundup(img_size, flinfo.blocksize)
                if ( size != img_size ):
                    filename = filename + ".padded"
            image_info = ImageInfo(file_info + "-" + sha1(filename),
                                   filename, "firmware")
            if filename.lower() != "none":
                if image_info not in images:
                    images.append(image_info)


    def __gen_script_append_images(self, filename, soc_version, wifi_fw_type, images, flinfo, root, section_conf, partition):

        global QCN9000
        global QCN9224

        part_info = self.__get_part_info(partition)
        if part_info == None and self.flinfo.type != 'norplusnand':
            return

        if self.flinfo.type == 'nand':
            img_size = self.__get_img_size(filename)
            size = roundup(img_size, flinfo.pagesize)
            if ( size != img_size ):
                filename = filename + ".padded"
        if self.flinfo.type == 'emmc':
            img_size = self.__get_img_size(filename)
            size = roundup(img_size, flinfo.blocksize)
            if ( size != img_size ):
                filename = filename + ".padded"
        if section_conf == "qsee":
            section_conf = "tz"
        elif section_conf == "appsbl":
            if lk == "true":
                section_conf = "lkboot"
            else:
                print(" Using u-boot...")
                section_conf = "u-boot"
        elif section_conf == "rootfs" and self.flash_type in ["nand", "nand-4k", "nand-audio", "nand-audio-4k", "norplusnand", "norplusnand-4k"]:
            section_conf = "ubi"
        elif section_conf == "wififw" and self.flash_type in ["nand", "nand-4k", "nand-audio", "nand-audio-4k", "norplusnand", "norplusnand-4k"]:
            section_conf = "wififw_ubi"
        elif section_conf == "wififw" and wifi_fw_type:
            section_conf = filename[:-13]

        if soc_version:
            section_conf = section_conf + "_v" + str(soc_version)

        image_info = ImageInfo(section_conf + "-" + sha1(filename),
                                filename, "firmware")
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
        global QCN9000
        global QCN9224
        global flash_size

        soc_version = 0
        diff_soc_ver_files = 0
        wifi_fw_type = ""
        wifi_fw_type_min = ""
        wifi_fw_type_max = ""
        diff_files = ""
        file_exists = 1

        ret = self.__gen_flash_script(script, flinfo, root, True)
        if ret == 0:
            return 0 #Stop packing this single-image

        if QCN9000:
            script.end_if() #end if started for hk+pine
        if QCN9224:
            script.end_if() #end if started for al+waikiki

        if (self.flash_type == "norplusemmc" and flinfo.type == "emmc") or (self.flash_type != "norplusemmc"):
            if flinfo.type == "emmc":
                srcDir_part = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + flinfo.type + "-partition"+ flash_size +".xml"
                rpart = ET.parse(srcDir_part)
                parts = rpart.findall(".//physical_partition[@ref='emmc']/partition")
                for index in range(len(parts)):
                    section = parts[index]
                    if section.attrib['label'] == "rootfs_data":
                        script.start_activity("Flashing rootfs_data:")
                        part_info = self.partitions["rootfs_data"]
                        script.erase(part_info.offset, part_info.length)
                        script.finish_activity()
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
                            if (multi_wifi_fw == "true" or tiny_16m == "true") and 'wififw_type_min' in section.attrib:
                                wifi_fw_type_min = section.attrib['wififw_type_min']
                                wifi_fw_type_max = section.attrib['wififw_type_max']
                                partition = section.attrib['label']
                            elif "bootconfig_type_max" in section.attrib and image_type == "all":
                                partition = section.attrib['label']
                            else:
                                try:
                                    if image_type == "all" or section.attrib['image_type'] == image_type:
                                        filename = section.attrib['filename']
                                        if filename == "":
                                            continue
                                        partition = section.attrib['label']
                                        if lk == "true" and "u-boot" in filename:
                                            filename = filename.replace("u-boot", "lkboot")
                                except KeyError as e:
                                    print("Skipping partition '%s'" % section.attrib['label'])
                                    pass

                    if diff_files == "true":
                        try:
                            if image_type == "all" or section.attrib['image_type'] == image_type:
                                filename = section.attrib['filename_' + MODE]
                                if lk == "true" and "uImage" in filename:
                                    if MODE == "32":
                                        filename = 'openwrt-' + ARCH_NAME + '-kernelboot.img'
                                    if MODE == "64":
                                        filename = 'openwrt-' + ARCH_NAME + '_' + MODE + '-kernelboot.img'
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
                    ret = self.__gen_script_bootconfig(images, flinfo, partition, section)
                    if ret == 1:
                        continue
                except KeyError as e:
                    continue

            if section_conf == "cdt" or section_conf == "cdt_1" or section_conf == "ddrconfig":
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

            if section_conf == "gpt" and QCN9224:
                if self.flash_type == "emmc":
                    filename_qcn9224 = filename[:-5] + "2.bin"
                elif self.flash_type == "norplusemmc":
                    filename_qcn9224 = filename[:-5] + "3.bin"
                section_conf_qcn9224 = section_conf + "_qcn9224"
                self.__gen_script_append_images(filename_qcn9224, soc_version, wifi_fw_type, images, flinfo, root, section_conf_qcn9224, partition)

            if section_conf == "gptbackup" and QCN9224:
                if self.flash_type == "emmc":
                    filename_qcn9224 = filename[:-5] + "2.bin"
                elif self.flash_type == "norplusemmc":
                    filename_qcn9224 = filename[:-5] + "3.bin"
                section_conf_qcn9224 = section_conf + "_qcn9224"
                self.__gen_script_append_images(filename_qcn9224, soc_version, wifi_fw_type, images, flinfo, root, section_conf_qcn9224, partition)

            if flinfo.type != "emmc":

                img = section.find('img_name')

                if img != None and 'wififw_type' in img.attrib and (multi_wifi_fw == "true" or tiny_16m == "true"):
                    imgs = section.findall('img_name')
                    try:
                        for img in imgs:
                            wifi_fw_type = img.get('wififw_type')
                            filename = img.text
                            if 'optional' in img.attrib:
                                if not os.path.exists(os.path.join(self.images_dname, filename)):
                                    continue
                            self.__gen_script_append_images(filename, soc_version, wifi_fw_type, images, flinfo, root, section_conf, partition)
                            wififw_type = ""
                        continue
                    except KeyError as e:
                        continue

                if img != None and 'soc_version' in img.attrib:

                    imgs = section.findall('img_name')
                    try:
                        for img in imgs:
                            soc_version = img.get('soc_version')
                            filename = img.text
                            if QCN9000 and section_conf == "wififw":
                                filename_qcn9000 = filename.replace("wifi_fw_ubi", "wifi_fw_ipq8074_qcn9000_ubi")
                                if os.path.exists(os.path.join(self.images_dname, filename_qcn9000)):
                                    section_conf_qcn9000 = section_conf + "_ubi_qcn9000"
                                    self.__gen_script_append_images(filename_qcn9000, soc_version, wifi_fw_type, images, flinfo, root, section_conf_qcn9000, partition)
                            if 'optional' in img.attrib:
                                if not os.path.exists(os.path.join(self.images_dname, filename)):
                                    file_exists = 0

                            if file_exists == 1:
                                self.__gen_script_append_images(filename, soc_version, wifi_fw_type, images, flinfo, root, section_conf, partition)
                            file_exists = 1
                        soc_version = 0 # Clear soc_version for next iteration
                        continue
                    except KeyError as e:
                        continue

                imgs = section.findall('img_name')
                for img in imgs:
                    memory_attr = img.get('memory')
                    if memory_attr != None and memory_attr == memory_size:
                        filename = img.text;

                    atf_image = img.get('atf')
                    if atf_image != None and atf == "true":
                        filename = img.text;

                # system-partition specific for HK+PINE
                if section_conf == "mibib" and QCN9000:
                    img = section.find('img_name')
                    if flash_size == "":
                        filename_qcn9000 = img.text[:-4] + "-qcn9000.bin"
                    else:
                        filename_qcn9000 = img.text[:-9] + "-qcn9000"+ flash_size+ ".bin"
                    section_conf_qcn9000 = section_conf + "_qcn9000"
                    self.__gen_script_append_images(filename_qcn9000, soc_version, wifi_fw_type, images, flinfo, root, section_conf_qcn9000, partition)
                # system-partition specific for AL+WAIKIKI
                if section_conf == "mibib" and QCN9224:
                    img = section.find('img_name')
                    if flash_size == "":
                        filename_qcn9224 = img.text[:-4] + "-qcn9224.bin"
                    else:
                        filename_qcn9224 = img.text[:-9] + "-qcn9224"+ flash_size +".bin"

                    section_conf_qcn9224 = section_conf + "_qcn9224"
                    self.__gen_script_append_images(filename_qcn9224, soc_version, wifi_fw_type, images, flinfo, root, section_conf_qcn9224, partition)
            else:
                # wififw images specific for RDP based on machid
                if wifi_fw_type_min:

                    for fw_type in range(int(wifi_fw_type_min), int(wifi_fw_type_max) + 1):
                        if image_type == "all" or section.attrib['image_type'] == image_type:
                            if 'filename_img' + str(fw_type) in section.attrib:
                                filename = section.attrib['filename_img' + str(fw_type)]
                        if filename == "":
                            continue
                        if 'optional' in section.attrib:
                            if not os.path.exists(os.path.join(self.images_dname, filename)):
                                continue
                        wifi_fw_type = str(fw_type)
                        self.__gen_script_append_images(filename, soc_version, wifi_fw_type, images, flinfo, root, section_conf, partition)
                        wifi_fw_type = ""
                        filename = ""

                    wifi_fw_type_min = ""
                    wifi_fw_type_max = "" # Clean for next partition
                    continue

                if diff_soc_ver_files:
                    try:
                        for version in range(1, int(diff_soc_ver_files)+1):
                            if image_type == "all" or section.attrib['image_type'] == image_type:
                                filename = section.attrib['filename_v' + str(version)]
                            if filename == "":
                                continue
                            if 'optional' in section.attrib:
                                if not os.path.exists(os.path.join(self.images_dname, filename)):
                                    file_exists = 0

                            if file_exists == 1:
                                self.__gen_script_append_images(filename, version, wifi_fw_type, images, flinfo, root, section_conf, partition)
                            file_exists = 1

                        diff_soc_ver_files = 0 # Clear diff_soc_ver_files for next iteration
                        continue
                    except KeyError as e:
                        print("Skipping partition '%s'" % section.attrib['label'])
                        pass

                if section != None and filename != "" and section.get('filename_mem' + memory_size) != None:
                    filename = section.get('filename_mem' + memory_size)

                if section != None and atf == "true" and section.get('filename_atf') != None:
                    filename = section.get('filename_atf')

            if filename != "":
                self.__gen_script_append_images(filename, soc_version, wifi_fw_type, images, flinfo, root, section_conf, partition)

            if self.flash_type in [ "nand", "nand-4k", "norplusnand", "norplusnand-4k" ] and section_conf == "rootfs" and multi_wifi_fw == "true":

                fw_imgs = section.findall('img_name')
                try:
                    for fw_img in fw_imgs:
                        wifi_fw_type = fw_img.get('wififw_type')
                        if wifi_fw_type != None:
                            fw_filename = fw_img.text
                            ret = self.__gen_script_append_images_wififw_ubi_volume(fw_filename, wifi_fw_type, images)
                            if ret == 0:
                                return 0
                        wifi_fw_type = ""
                    continue
                except KeyError as e:
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
        global QCN9000
        global IF_QCN9000
        global QCN9224
        global IF_QCN9224
        global flash_size

        """Generate the flashing script for one board.

        board_section -- string, board section in board config file
        machid -- string, board machine ID in hex format
        flinfo -- FlashInfo object, contains board specific flash params
        part_fname -- string, partition file specific to the board
        fconf_fname -- string, flash config file specific to the board
        images -- list of ImageInfo, append images used by the board here
        """
        IF_QCN9000 = False
        IF_QCN9224 = False
        script_fp = open(self.scr_fname, "a")
        self.flinfo = flinfo

        if flinfo.type != "emmc":
            if root.find(".//data[@type='NAND_PARAMETER']/entry") != None:
                if self.flash_type == "nand-4k" or self.flash_type == "norplusnand-4k":
                    flash_param = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='4k']")
                elif self.flash_type == "nand-audio":
                    flash_param = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='audio-2k']")
                elif self.flash_type == "nand-audio-4k":
                    flash_param = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='audio-4k']")
                else:
                    flash_param = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='2k']")
            else:
                flash_param = root.find(".//data[@type='NAND_PARAMETER']")

            pagesize = int(flash_param.find(".//page_size").text)
            pages_per_block = int(flash_param.find(".//pages_per_block").text)
            blocksize = pages_per_block * pagesize
            blocks_per_chip = int(flash_param.find(".//total_block").text)
            chipsize = blocks_per_chip * blocksize

            if flinfo.type == "nand":
                script = Flash_Script(flinfo, self.ipq_nand)
            elif flinfo.type == "nor":
                script = Flash_Script(flinfo, pagesize)

            script.probe()
            # system-partition specific for HK+PINE
            if QCN9000:
                IF_QCN9000 = True
                if flash_size == "":
                    part_fname_qcn9000 = part_fname[:-4] + "-qcn9000.bin"
                else:
                    part_fname_qcn9000 = part_fname[:-9] + "-qcn9000"+ flash_size +".bin"
                mibib_qcn9000 = MIBIB(part_fname_qcn9000, flinfo.pagesize, flinfo.blocksize,
                                   flinfo.chipsize, blocksize, chipsize)
                self.partitions = mibib_qcn9000.get_parts()

                script.append('if test "$machid" = "801000e" || test "$machid" = "801010e" || test "$machid" = "8010012" || test "$machid" = "8010013" || test "$machid" = "8010500"; then\n', fatal=False)
                ret = self.__gen_flash_script(script, flinfo, root, True)
                if ret == 0:
                    return 0 #Issue in packing hk+pine single-image

                script.append('else', fatal=False)
                self.partitions = {}
                IF_QCN9000 = False
            # system-partition specific for ALDER+WAIKIKI
            if QCN9224:
                IF_QCN9224 = True
                if flash_size == "":
                    part_fname_qcn9224 = part_fname[:-4] + "-qcn9224.bin"
                else:
                    part_fname_qcn9224 = part_fname[:-9] + "-qcn9224"+ flash_size +".bin"
                mibib_qcn9224 = MIBIB(part_fname_qcn9224, flinfo.pagesize, flinfo.blocksize,
                                   flinfo.chipsize, blocksize, chipsize)
                self.partitions = mibib_qcn9224.get_parts()

                script.append('if test "$machid" = "8050301" || test "$machid" = "8050501"  || test "$machid" = "8050601" || test "$machid" = "8050701" || test "$machid" = "8050801" || test "$machid" = "8050901" || test "$machid" = "8050a01" || test "$machid" = "8050b01" || test "$machid" = "8050c01" || test "$machid" = "8050d01" || test "$machid" = "8050e01" || test "$machid" = "8050f01" || test "$machid" = "8051001" || test "$machid" = "0x8051101" || test "$machid" = "8051201" || test "$machid" = "8051301" || test "$machid" = "8050002" || test "$machid" = "8050102" || test "$machid" = "8050003" || test "$machid" = "8050004"; then\n', fatal=False)
                ret = self.__gen_flash_script(script, flinfo, root, True)
                if ret == 0:
                    return 0 #Issue in packing al+wkk single-image

                script.append('else', fatal=False)
                self.partitions = {}
                IF_QCN9224 = False

            mibib = MIBIB(part_fname, flinfo.pagesize, flinfo.blocksize,
                          flinfo.chipsize, blocksize, chipsize)
            self.partitions = mibib.get_parts()

        else:
            script = Flash_Script(flinfo)

            # system-partition specific for ALDER+WAIKIKI
            if QCN9224:
                IF_QCN9224 = True
                if self.flash_type == "emmc":
                    part_fname_qcn9224 = part_fname[:-5] + "2.bin"
                elif self.flash_type == "norplusemmc":
                    part_fname_qcn9224 = part_fname[:-5] + "3.bin"
                gpt = GPT(part_fname_qcn9224, flinfo.pagesize, flinfo.blocksize, flinfo.chipsize)
                self.partitions = gpt.get_parts()

                script.append('if test "$machid" = "8050301" || test "$machid" = "8050501"  || test "$machid" = "8050601" || test "$machid" = "8050701" || test "$machid" = "8050801" || test "$machid" = "8050901" || test "$machid" = "8050a01" || test "$machid" = "8050b01" || test "$machid" = "8050c01" || test "$machid" = "8050d01" || test "$machid" = "8050e01" || test "$machid" = "8050f01" || test "$machid" = "8051001" || test "$machid" = "0x8051101" || test "$machid" = "8051201" || test "$machid" = "8051301" || test "$machid" = "8050002" || test "$machid" = "8050102" || test "$machid" = "8050003" || test "$machid" = "8050004"; then\n', fatal=False)
                ret = self.__gen_flash_script(script, flinfo, root, True)
                if ret == 0:
                    return 0 #Issue in packing al+wkk single-image

                script.append('else', fatal=False)
                self.partitions = {}
                IF_QCN9224 = False

            gpt = GPT(part_fname, flinfo.pagesize, flinfo.blocksize, flinfo.chipsize)
            self.partitions = gpt.get_parts()

        ret = self.__gen_script(script_fp, script, images, flinfo, root)
        if ret == 0:
            return 0

        if QCN9000:
            QCN9000 = False
        if QCN9224:
            QCN9224 = False

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
        global QCN9224

        try:
            part_info = root.find(".//data[@type='" + self.flash_type.upper() + "_PARAMETER']")
            part_fname = part_info.find(".//partition_mbn")
            part_fname = part_fname.text
            part_fname = os.path.join(self.images_dname, part_fname)

            if ARCH_NAME == "ipq9574":
                QCN9224 = True

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
        global QCN9000
        global QCN9224
        global flash_size

        try:
            if ftype == "tiny-nor" or ftype == "tiny-nor-debug":
                part_info = root.find(".//data[@type='" + "NOR_PARAMETER']")
            elif ftype in ["nand", "nand-4k", "nand-audio", "nand-audio-4k"]:
                if root.find(".//data[@type='NAND_PARAMETER']/entry") != None:
                    if ftype == "nand":
                        part_info = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='2k']")
                    elif ftype == "nand-audio":
                        part_info = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='audio-2k']")
                    elif ftype == "nand-audio-4k":
                        part_info = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='audio-4k']")
                    else:
                        part_info = root.find(".//data[@type='NAND_PARAMETER']/entry[@type='4k']")
                else:
                    part_info = root.find(".//data[@type='" + "NAND_PARAMETER']")
            elif ftype == "norplusnand-4k":
                part_info = root.find(".//data[@type='" + "NORPLUSNAND_PARAMETER']")
            else:
                part_info = root.find(".//data[@type='" + ftype.upper() + "_PARAMETER']")

            if ARCH_NAME in ["ipq6018", "ipq5018", "ipq807x", "ipq9574", "ipq5332"]:
                MODE_APPEND = "_64" if MODE == "64" else ""

                if ftype in ["nand-audio", "nand-audio-4k"]:
                    UBINIZE_CFG_NAME = ARCH_NAME + "-ubinize" + MODE_APPEND + "-audio.cfg"
                else:
                    UBINIZE_CFG_NAME = ARCH_NAME + "-ubinize" + MODE_APPEND + flash_size + ".cfg"

                f1 = open(SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + UBINIZE_CFG_NAME, 'r')
                UBINIZE_CFG_NAME = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/tmp-" + UBINIZE_CFG_NAME
                f2 = open(UBINIZE_CFG_NAME, 'w')
                for line in f1:
                    f2.write(line.replace('image=', "image=" + SRC_DIR + "/"))
                f1.close()
                f2.close()

                part_file = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + ftype + "-partition" + flash_size + ".xml"
                parts = ET.parse(part_file).findall('.//partitions/partition')
                for index in range(len(parts)):
                    section = parts[index]
                    if section[0].text == "rootfs":
                        rootfs_pos = 9 if MODE == "64" else 8
                        UBI_IMG_NAME = section[rootfs_pos].text

                if ftype in ["nand-4k", "nand-audio-4k", "norplusnand-4k"]:
                    cmd = '%s -m 4096 -p 256KiB -o root.ubi %s' % ((SRC_DIR + "/ubinize") ,UBINIZE_CFG_NAME)
                    ret = subprocess.call(cmd, shell=True)
                    if ret != 0:
                        error("ubinization got failed")
                    cmd = 'dd if=root.ubi of=%s bs=4k conv=sync' % (SRC_DIR + "/" + UBI_IMG_NAME)
                    ret = subprocess.call(cmd, shell=True)
                    if ret != 0:
                        error("ubi image copy operation failed")

                elif ftype in ["nand", "nand-audio", "norplusnand"]:
                    cmd = '%s -m 2048 -p 128KiB -o root.ubi %s' % ((SRC_DIR + "/ubinize") ,UBINIZE_CFG_NAME)
                    ret = subprocess.call(cmd, shell=True)
                    if ret != 0:
                        error("ubinization got failed")
                    cmd = 'dd if=root.ubi of=%s bs=2k conv=sync' % (SRC_DIR + "/" + UBI_IMG_NAME)
                    ret = subprocess.call(cmd, shell=True)
                    if ret != 0:
                        error("ubi image copy operation failed")

            part_file = SRC_DIR + "/" + ARCH_NAME + "/flash_partition/" + ftype + "-partition" + flash_size + ".xml"
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

            if ARCH_NAME == "ipq807x" and (ftype == "norplusnand" or ftype == "nand"):
                QCN9000 = True
            if ARCH_NAME == "ipq9574" and (ftype in ["norplusnand", "nand", "norplusemmc", "norplusnand-4k", "nand-4k"]):
                QCN9224 = True

            if ftype in ["tiny-nor", "norplusnand", "norplusnand-4k", "norplusemmc", "tiny-nor-debug"]:
                ftype = "nor"
            if ftype in ["nand-4k", "nand-audio", "nand-audio-4k"]:
                ftype = "nand"

        except ValueError as e:
            error("invalid flash info in section '%s'" % board_section.find('machid').text, e)

        blocksize = pages_per_block * pagesize
        chipsize = blocks_per_chip * blocksize

        flinfo = FlashInfo(ftype, pagesize, blocksize, chipsize)

        ret = self.__gen_board_script(flinfo, part_fname, images, root)
        return ret

    def __process_board(self, images, root):

        global QCN9000
        global QCN9224

        QCN9000 = False
        QCN9224 = False
        try:
            if self.flash_type in [ "nand", "nand-4k", "nand-audio", "nand-audio-4k", "nor", "tiny-nor", "norplusnand", "norplusnand-4k", "tiny-nor-debug" ]:
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
        global lk
        global atf
        global skip_4k_nand
        global multi_wifi_fw
        global flash_size
        flash_size = ""

        """Start the parsing process, and populate members with parsed value.

        argv -- list of string, the command line arguments
        """

        cdir = os.path.abspath(os.path.dirname(""))
        if len(sys.argv) > 1:
            try:
                opts, args = getopt(sys.argv[1:], "", ["arch=", "fltype=", "srcPath=", "inImage=", "outImage=", "image_type=", "memory=", "lk", "skip_4k_nand", "atf", "qcn6122", "multi_wifi_fw", "flash_size="])
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

                elif option =="--lk":
                    lk = "true"

                elif option =="--atf":
                    atf = "true"

                elif option =="--skip_4k_nand":
                    skip_4k_nand = "true"

                elif option == "--qcn6122":
                    multi_wifi_fw = "true"

                elif option == "--multi_wifi_fw":
                    multi_wifi_fw = "true"

                elif option == "--flash_size":
                    flash_size = "-" + value

#Verify Arguments passed by user

# Verify arch type
            if ARCH_NAME not in ["ipq40xx", "ipq806x", "ipq807x", "ipq807x_64", "ipq6018", "ipq6018_64", "ipq5018", "ipq5018_64", "ipq9574", "ipq9574_64", "ipq5332", "ipq5332_64"]:
                raise UsageError("Invalid arch type '%s'" % arch)

            if ARCH_NAME == "ipq807x" or ARCH_NAME == "ipq5018" or ARCH_NAME == "ipq9574" or ARCH_NAME == "ipq5332":
                MODE = "32"
            elif ARCH_NAME == "ipq807x_64" or ARCH_NAME == "ipq5018_64" or ARCH_NAME == "ipq9574_64" or ARCH_NAME == "ipq5332_64":
                MODE = "64"
                ARCH_NAME = ARCH_NAME[:-3]

            if ARCH_NAME == "ipq6018":
                MODE = "32"
            elif ARCH_NAME == "ipq6018_64":
                MODE = "64"
                ARCH_NAME = "ipq6018"

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
        print("python pack_hk.py [options] [Value] ...")
        print()
        print("options:")
        print("  --arch \tARCH_TYPE [ipq40xx/ipq806x/ipq807x/ipq807x_64/ipq6018/ipq6018_64/ipq5018/ipq5018_64/ipq9574/ipq9574_64/ipq5332/ipq5332_64]")
        print()
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
        print()
        print("  --lk \t\tReplace u-boot with lkboot for appsbl")
        print("  --flash_size \tFlash size")
        print("  --atf \t\tReplace tz with atf for QSEE partition")
        print("  --skip_4k_nand \tskip generating 4k nand images")
        print(" \t\tThis Argument does not take any value")
        print("Pack Version: %s" % version)

def gen_kernelboot_img(parser):
    """Generate kernelboot.img needed by LK bootloader"""

    SKALES_DIR = parser.images_dname
    TMP_DIR = parser.images_dname + "/tmp_dir"

    try:

        if os.path.exists(TMP_DIR):
            rmtree(TMP_DIR)
        os.makedirs(TMP_DIR)

        if ARCH_NAME == "ipq807x":
            BOARD_NAME = ARCH_NAME + "-hk01"
        elif ARCH_NAME == "ipq6018":
            BOARD_NAME = ARCH_NAME + "-cp02-c1"
        else:
            error("Error: Arch not supported")

        if MODE == "64":
            KERNEL_IMG_NAME = "openwrt-" + ARCH_NAME + "_" + MODE + "-kernelboot.img"
            BASE_ADDR = "0x41078000"
        else:
            KERNEL_IMG_NAME = "openwrt-" + ARCH_NAME + "-kernelboot.img"
            if ARCH_NAME == "ipq807x":
                BASE_ADDR = "0x41200000"
            elif ARCH_NAME == "ipq6018":
                BASE_ADDR = "0x41000000"

        src = parser.images_dname + "/qcom-" + BOARD_NAME + ".dtb"

        #alternate name(alt_src) for linux-5.4 dtbs
        alt_src = parser.images_dname + "/" + BOARD_NAME + ".dtb"
        if ARCH_NAME == "ipq807x":
            alt_src = parser.images_dname + "/ipq8074-hk01.dtb"

        if not os.path.exists(src):
            if os.path.exists(alt_src):
                src = alt_src
            else:
                error("%s file not found" % src)
        copy(src, TMP_DIR)

        src = parser.images_dname + "/Image"
        if not os.path.exists(src):
            error("%s file not found" % src)
        copy(src, TMP_DIR)

        cmd = [SKALES_DIR + "/dtbTool -o " + TMP_DIR + "/qcom-" + BOARD_NAME + "-dt.img " + TMP_DIR]
        ret = subprocess.call(cmd, shell=True)
        if ret != 0:
            print(ret)
            error("Error executing dtbTools")

        cmd = ["gzip -9 " + TMP_DIR + "/Image"]
        ret = subprocess.call(cmd, shell=True)
        if ret != 0:
            print(ret)
            error("Error executing gzip")

        cmd = [SKALES_DIR + "/mkbootimg",
                "--kernel=" + TMP_DIR + "/Image.gz",
                "--dt=" + TMP_DIR + "/qcom-" + BOARD_NAME + "-dt.img",
                "--cmdline=\'rootfsname=rootfs rootwait\'",
                "--output=" + parser.images_dname + "/" + KERNEL_IMG_NAME,
                "--base=" + BASE_ADDR]
        ret = subprocess.call(cmd)
        if ret != 0:
            print(ret)
            error("Error executing mkbootimg")

        rmtree(TMP_DIR)
    except OSError as e:
        error("error generating kernelboot.img", e)

def main():
    """Main script entry point.

    Created to avoid polluting the global namespace.
    """

    global tiny_16m
    global flash_size

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

        if ARCH_NAME == "ipq5018" and (flash_type == "tiny-nor" or flash_type == "tiny-nor-debug"):
            tiny_16m = "true"
        else:
            tiny_16m = "false"

        if image_type == "hlos":
            if MODE == "64":
                parser.out_fname = flash_type + "-" + ARCH_NAME + "_" + MODE + "-apps" + flash_size + ".img"
            else:
                parser.out_fname = flash_type + "-" + ARCH_NAME + "-apps" + flash_size + ".img"
        else:
            if flash_type == "emmc" and lk == "true":
                suffix = "-single-lkboot.img"
                gen_kernelboot_img(parser)

            else:
                suffix = "-single" + flash_size + ".img"

            if MODE == "64":
                parser.out_fname = flash_type + "-" + ARCH_NAME + "_" + MODE + suffix
            else:
                parser.out_fname = flash_type + "-" + ARCH_NAME + suffix

        parser.out_fname = os.path.join(parser.out_dname, parser.out_fname)

        pack.main_bconf(flash_type, parser.images_dname,
                        parser.out_fname, root)

if __name__ == "__main__":
    main()
