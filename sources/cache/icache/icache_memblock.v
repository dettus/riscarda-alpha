// Copyright (c) 2022
// dettus@dettus.net
//
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
//
//    Redistributions of source code must retain the above copyright notice, this 
//    list of conditions and the following disclaimer.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
////////////////////////////////////////////////////////////////////////////////
// (SPDX short identifier: BSD-1-Clause)


module	icache_memblock
#(
parameter	DATABITS=32,
parameter	ADDRBITS=5,
parameter	MEMSIZE=2**ADDRBITS
)
(
	// connection to the CPU core
	input	[ADDRBITS-1:0]		addr,
	input	[DATABITS-1:0]		data_in,
	output	[DATABITS-1:0]		data_out,
	input				we,

	// connection to the flush controller
	input				flush_mode,
	input	[ADDRBITS-1:0]		flush_addr,
	input	[DATABITS-1:0]		flush_in,
	input				flush_we,

	// system control lines
	input				reset_n,
	input				clk
);

	wire	[ADDRBITS-1:0]	int_addr;
	wire	[DATABITS-1:0]	int_data;
	

	assign	int_addr=flush_mode?flush_addr:addr;
	assign	int_data=flush_mode?flush_in:data_in;

	spram_32x32	SPRAM0
	(
		.addr		(int_addr),
		.data_out	(data_out),
		.data_in	(int_data),
		.we		(flush_mode&flush_mode_we),
		.clk		(clk)
	);

	
endmodule


