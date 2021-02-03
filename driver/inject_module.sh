#!/bin/bash

# build the driver kernel module
make all

# remove old device file
rm -rf /dev/xpcie

# create new device file
#
# Syntax:
# 	/dev/xpcie	name of device file
#	c			[c]haracter device
#				[b]lock device
#				[p]ipe device (FIFO)
#	100			major version => MUST MATCH WITH C-CODE DEF IN xpcie.c
#	1			minor version
mknod /dev/xpcie c 100 1

# change owner of device to root
chown root /dev/xpcie

# change rights:
#	6	owner: RW
#	4	group: R
#	4	other: R
chmod 0644 /dev/xpcie

# output created device to console
ls -al /dev/xpcie

# remove the previous version from the kernel
rmmod xpcie

# insert the new version
insmod xpcie.ko

# print debug information
dmesg
