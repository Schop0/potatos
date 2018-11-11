#!/bin/bash

BOOTLOADER="bootloader/potatos"
KERNEL="kernel/bin/main.bin"
IMAGE="potatos.img"

# Exit on any error
set -e

# Always cleanup when exiting for any reason
trap "rm -f MBR.bin" EXIT

# Report missing files
for file in "$BOOTLOADER" "$KERNEL"; do
	if [ ! -f "$file" ]; then
		echo "$file is missing"
		exit 1
	fi
done

# Extract MBR from bootloader, ignoring any extra code
dd if="$BOOTLOADER" bs=512 count=1 of=MBR.bin 2> /dev/null

# Combine MBR with kernel into a disk image
cat MBR.bin "$KERNEL" > "$IMAGE"

echo "Created $IMAGE"
