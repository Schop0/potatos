#!/bin/bash
BOOTLOADER="bootloader.bin"

cd stage0 && ./compile.sh "$@" || exit 1
cd - >/dev/null
cd stage1 && ./compile.sh "$@" || exit 1
cd - >/dev/null

if [ "$1" == "clean" ]; then
        rm -vf "$BOOTLOADER"
        exit
fi

cat stage0/stage0 stage1/stage1 > "$BOOTLOADER"
echo "Created $BOOTLOADER"

if [ "$1" == "run" ]; then
	echo "Running $BOOTLOADER"
	qemu-system-x86_64 -drive file="$BOOTLOADER",format=raw
fi
