#!/bin/sh

iverilog -tvvp -o tb_dcache.vvp ../dcache.v ../dcache_line.v ../dpram_32x8.v tb_dcache.v
iverilog -tvvp -o tb_line.vvp ../dcache_line.v ../dpram_32x8.v tb_line.v
iverilog -tvvp -o tb_hardware.vvp ../dcache_line.v ../dpram_32x8.v ../spram_512x32.v tb_hardware.v

ls -l *.vvp


