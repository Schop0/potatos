#!/bin/bash
set -e

if [ "$1" == "clean" ]; then
	rm -vf stage0
	exit
fi

nasm -f bin stage0.asm
echo "Created stage0"
