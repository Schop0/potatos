#!/bin/bash

BOOTLOADER="bootloader/potatos"
IMAGE="potatos.img"
PART_SIZE="100M"	# syntax must be compatible with both dd and fdisk
HELP_TEXT='
To use this image:
1.	Write it to a spare USB stick or similar
2.	Copy the potatos kernel ($KERNEL) onto it
3.	Boot from your USB stick using qemu
4.	To update the kernel, simple overwrite the file and reboot
DO NOT boot an actual PC with this unless you are ready to lose all data on all drives (or disconnect them first)'

setup()
{
	# Exit with a (slightly) informative message on any error
	set -e
	trap 'echo "There was an error on line $LINENO of $0" >&2' ERR

	# Clean up whenever we exit for any reason
	trap 'rm -f MBR.bin FS.part' EXIT

	# Report missing files
	if [ ! -f "$BOOTLOADER" ]; then
		echo "$BOOTLOADER is missing, compile it first"
		exit 1
	fi
}

mkimage()
{
	# Extract MBR from bootloader, ignoring any extra code
	dd if="$BOOTLOADER" bs=512 count=1 of=MBR.bin 2>/dev/null

	# Create a partition image and format it as FAT32
	dd if=/dev/zero bs=$PART_SIZE count=0 seek=1 of=FS.part 2>/dev/null
	mkfs.vfat FS.part >/dev/null

	# Combine the MBR and partition to a full-disk image
	# Note that the first partition is aligned to 1MB as required by fdisk
	mv MBR.bin "$IMAGE"
	dd if=FS.part bs=1M seek=1 of="$IMAGE" 2>/dev/null

	# Fdisk has a quirk where it allocates one sector too much when specifying the last sector relatively, which we do
	# Workaround: give it an extra sector to work with
	dd if=/dev/zero bs=512 count=1 >> "$IMAGE" 2>/dev/null

	# Create a valid partition table using fdisk with the following commands:
	# Create a new partition (n) using fdisk defaults (3 newlines)
	# Change the type (t) to fat32 (b)
	# Set the partition as active (a)
	# write out the changes (w)
	fdisk "$IMAGE" <<EOF >/dev/null 2>&1
n



+$PART_SIZE
t
b
a
w
EOF

	echo "Created $IMAGE"
}

setup

mkimage

echo "$HELP_TEXT"
