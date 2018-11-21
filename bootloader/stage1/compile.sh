#!/bin/bash

if [ "$1" == "clean" ]; then
        rm -vf stage1
        exit
fi

# Do not use any filenames with spaces or special characters. I'm too lazy to support them.
SOURCES="src/crt0.c src/main.c"
OUTPUT=stage1
LINKERSCRIPT=sector2.ld

LINKER_OPTS="--script=$LINKERSCRIPT"
GCC_OPTS="-m16 -Os -nostdlib -march=i386 -ffreestanding -fno-pie -Wl,$LINKER_OPTS"

gcc $GCC_OPTS -o $OUTPUT $SOURCES || exit
echo "Created $OUTPUT"
chmod -x $OUTPUT
