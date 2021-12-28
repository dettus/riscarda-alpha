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
//


module	dcache_memblock
#(
parameter	DATABITS=32,
parameter	CACHEDATABITS=8,
parameter	CACHEADDRBITS=5,
parameter	BANKNUM=(DATABITS/CACHEDATABITS),
parameter	CACHESIZE=2**CACHEADDRBITS
)
(
	// this memory block has two modes
	input				flush_mode,

	// flush_mode=0: data comes from and goes to the cpu
	input	[DATABITS-1:0]		dcache_in,
	input	[CACHEADDRBITS-1:0]	dcache_addr,
	input	[BANKNUM-1:0]		byteenable,
	input				line_miss,
	input				dcache_wrreq,


	// flush_mode=1: data comes from and goes to the big memory
	input	[DATABITS-1:0]		line_in,
	input	[CACHEADDRBITS-1:0]	flush_addr,
	input				flush_write,
	input				line_in_valid,

	// regardless: this is the output
	output	[DATABITS-1:0]		data_out,
	input				clk
);
	reg	[DATABITS-1:0]	data_in;
	reg	[CACHEADDRBITS-1:0]	addr;
	reg	[BANKNUM-1:0]		v_we;
	reg	[BANKNUM-1:0]		we;
	
	always	@(dcache_in,line_in,flush_mode)
	begin
		data_in<=flush_mode?line_in:dcache_in;
	end

	always	@(dcache_addr,flush_addr,flush_mode)
	begin
		addr<=flush_mode?flush_addr:dcache_addr;
	end

	always	@(flush_mode,write_enable,byteenable,line_in_valid)
	begin
		if (flush_mode)
		begin
			we<=(flush_write&line_in_valid)?4'b1111:4'b0000;
		end else begin
			we<=(dcache_wrreq&!line_miss)?byteenable:4'b0000;
		end
	end

	spram_32x8	SPRAM0
	(
		.data_in		(data_in[ 7: 0]),
		.data_out		(data_out[ 7: 0]),
		.addr			(addr),
		.we			(we[0]),
		.clk			(clk)
	);	

	spram_32x8	SPRAM1
	(
		.data_in		(data_in[15: 8]),
		.data_out		(data_out[15: 8]),
		.addr			(addr),
		.we			(we[1]),
		.clk			(clk)
	);	
	spram_32x8	SPRAM2
	(
		.data_in		(data_in[23:16]),
		.data_out		(data_out[23:16]),
		.addr			(addr),
		.we			(we[2]),
		.clk			(clk)
	);	
	spram_32x8	SPRAM3
	(
		.data_in		(data_in[31:24]),
		.data_out		(data_out[31:24]),
		.addr			(addr),
		.we			(we[3]),
		.clk			(clk)
	);	
	
endmodule

