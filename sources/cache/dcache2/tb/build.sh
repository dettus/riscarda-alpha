#!/bin/sh

iverilog -tvvp -o tb_line.vvp tb_line.v ../dcache_line.v ../dcache_memblock.v ../spram_32x8.v

