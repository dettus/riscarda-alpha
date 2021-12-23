#!/bin/sh

iverilog -tvvp -o tb.vvp ../dcache_line.v ../dpram_32x32.v tb.v

