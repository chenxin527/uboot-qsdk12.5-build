/*
 * Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
 * SPDX-License-Identifier: GPL-2.0-only
*/

#!/usr/bin/env python3

"""
This script encrypts the provided image in blocks of 512.
Currently only AES XTS is supported. For other modes use
standard OpenSSL tool.

Usage: python3 encrypt_image.py <input image> <key> <output image name>

"""

import os
import sys
from typing import BinaryIO

# Import the pre-requisites
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.ciphers import Cipher
from cryptography.hazmat.primitives.ciphers.algorithms import AES
from cryptography.hazmat.primitives.ciphers.modes import XTS

sectorsize = 512
sec_dbl = sectorsize * 2

def xts_encrypt(rawfile: BinaryIO, key: bytes, encrypted_file: BinaryIO):

    algorithm = AES(key)
    sec_cnt = 0

    while True:
        rawsector = rawfile.read(sectorsize)
        if not rawsector:
            break

        # Pad data to 512
        if len(rawsector) < sectorsize:
            raw_mul = (sectorsize - len(rawsector))
            rawsector += (b'\x00' * raw_mul)
        xts_tweak_bytes = sec_cnt.to_bytes(length=16, byteorder='little')
        encryptor = Cipher(algorithm=algorithm, mode=XTS(xts_tweak_bytes), backend=default_backend()).encryptor()
        xts_output = encryptor.update(rawsector) + encryptor.finalize()

        encrypted_file.write(xts_output)
        sec_cnt += 1

    plain_size = sec_cnt * sectorsize
    pad_check = (plain_size % (sec_dbl * 4))
    if (pad_check != 0):
        pad_length = ((plain_size // sec_dbl) + 4) * sec_dbl
        pad_length = (pad_length - plain_size)
        encrypted_file.write(b'\x00' * pad_length)

if __name__ == '__main__':

    if len(sys.argv) != 4:
      print("Usage: python3 encrypt_image.py <input image> <key> <output image name>")
      sys.exit(1)

    plain_image = sys.argv[1]
    cipher_image = sys.argv[3]
    enc_key =   sys.argv[2]

    with open(enc_key, 'rb') as f:
        rootfs_key = f.read()

    with open(plain_image, 'rb') as rootfs_img, open(cipher_image, 'wb') as rootfs_enc:
        xts_encrypt(rootfs_img, rootfs_key, rootfs_enc)

