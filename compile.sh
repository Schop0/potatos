#!/bin/bash

nasm -f bin potatos.asm
qemu-system-x86_64 -drive file=potatos,format=raw
