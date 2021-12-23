//Copyright (c) 2022
//dettus@dettus.net
//
//Redistribution and use in source and binary forms, with or without modification, 
//are permitted provided that the following conditions are met:
//
//   Redistributions of source code must retain the above copyright notice, this 
//   list of conditions and the following disclaimer.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
//DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
//SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
//CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
//OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
//OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
///////////////////////////////////////////////////////////////////////////////
//(SPDX short identifier: BSD-1-Clause)
//

`define	ADDRBITS	32
`define	DATABITS	32
`define	MAXTTL		255
`define	TTLBITS		8

`define	CACHEWORDS	32
`define	CACHEADDRBITS	5
`define	ADDRMSBBITS	(`ADDRBITS-`CACHEADDRBITS-2)


module tb();

	// connection to the CPU core
	reg	[`ADDRBITS-1:0]	dcache_addr;
	reg	[`DATABITS-1:0]	dcache_datain;
	reg			dcache_rdreq;
	reg			dcache_wrreq;
	// connection to the controller
	reg			line_fill;
	wire	[`DATABITS-1:0]	line_out;
	wire			line_valid;


	// connection to the memory controller
	reg	[`DATABITS-1:0]	mem_out;
	reg	[15:0]		mem_burstlen;
	reg			mem_valid;
	wire	[`ADDRBITS-1:0]	mem_addr;
	wire			mem_rdreq;
	wire			mem_wrreq;
	

	
	reg		reset_n;
	reg		clk;
	

	always	#5	clk<=!clk;

	initial begin
		$dumpfile("tb.vcd");
		$dumpvars(0);
		#0	reset_n<=1'b1;clk<=1'b0;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go!");

		#2000	$finish();
	end
endmodule

