#!/bin/bash

for dir in bootloader kernel; do
	(cd "$dir" && ./compile.sh)
done
./mkimage.sh
