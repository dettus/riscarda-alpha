#!/bin/sh

iverilog -tvvp -o tb.vvp ../dcache_line.v ../dpram_32x32.v tb.v
iverilog -tvvp -o tb_hardware.vvp tb_hardware.v

ls -l *.vvp


