#!/bin/bash

# Do not use any filenames with spaces or special characters. I'm too lazy to support them.
SOURCES="src/crt0.c src/main.c"
OUT_DIR=bin
OUTPUT=$OUT_DIR/main.bin
LINKERSCRIPT=sector2.ld

LINKER_OPTS="--script=$LINKERSCRIPT"
GCC_OPTS="-m32 -Os -nostdlib -march=i386 -ffreestanding -fno-pie -Wl,$LINKER_OPTS"

mkdir -p bin || exit
gcc $GCC_OPTS -o $OUTPUT $SOURCES || exit
echo "Created $OUTPUT"
chmod -x $OUTPUT
