#!/bin/bash

for dir in bootloader kernel; do
	(cd "$dir" && ./compile.sh)
done
./mkimage.sh
qemu-system-x86_64 -drive file=potatos.img,format=raw
