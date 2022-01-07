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


module	hybrid_cache
#(
	parameter	ADDRBITS=32,
	parameter	DATABITS=32,
	parameter	MAXHITBITS=8,
	parameter	WORDLENBITS=2,
	parameter	NUM_CACHELINES=8
)
(
	// cache control line

	// data cache connection, read
	input	[ADDRBITS-1:0]		dcache_rdaddr,
	input				dcache_rdreq,
	output	[DATABITS-1:0]		dcache_out,
	output				dcache_out_valid,
	output				dcache_rd_ready,

	// data cache connection, write
	input	[ADDRBITS-1:0]		dcache_wraddr,
	input				dcache_wrreq,
	input	[DATABITS-1:0]		dcache_in,
	input	[WORDLENBITS-1:0]	dcache_in_wordlen,
	output				dcache_wr_ready,
	

	// instruction cache connection, read
	input	[ADDRBITS-1:0]		icache_rdaddr,
	input				icache_rdreq,
	output	[DATABITS-1:0]		icache_out,
	output				icache_out_valid,
	output				icache_rd_ready,

	// connection to the memory
	output	[ADDRBITS-1:0]		mem_addr,		//
	output	[DATABITS-1:0]		mem_in,			//
	input	[DATABITS-1:0]		mem_out,		//
	input				mem_out_valid,		//
	output				mem_wrreq,		//
	output				mem_rdreq,		//

	// system 
	input				reset_n,
	input				clk
);


endmodule
