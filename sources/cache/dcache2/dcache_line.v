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

module dcache_line
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32,
parameter	CACHEDATABITS=8,
parameter	CACHEADDRBITS=5,
parameter	LSBITS=2,
parameter	MSBITS=(ADDRBITS-CACHEADDRBITS-LSBITS),
parameter	BANKNUM=(DATABITS/CACHEDATABITS),
parameter	CACHESIZE=2**CACHEADDRBITS,
parameter	CNTMISSBITS=8
)
(
	input	[ADDRBITS-1:0]		dcache_addr,
	input	[DATABITS-1:0]		dcache_in,
	output	[DATABITS-1:0]		line_out,
	output				line_valid,
	output				line_miss,
	output				line_dirty,
	input	[BANKNUM-1:0]		byteenable,

	input				dcache_rdreq,
	input				dcache_wrreq,

	output	[CNTMISSBITS-1:0]	flush_cnt_miss,
	input				flush_mode,	// flush mode FOR THIS LINE
	input				flush_write,	// flush write FOR ALL LINES
	input	[CACHEADDRBITS-1:0]	flush_addr,
	input				flush_dirty,	// =1 if the flush was triggered by a write request

	output	[ADDRBITS-1:0]		mem_addr,
	input	[DATABITS-1:0]		line_in,
	input				line_in_valid,

	input				reset_n,
	input				clk
);

	reg	[MSBITS-1:0]	addrmsb;
	reg			r_line_valid;
	reg			r_line_miss;
	reg			r_line_dirty;
	reg			r_init;
	reg	[DATABITS-1:0]	r_mem_addr;
	reg	[CNTMISSBITS-1:0]	r_flush_cnt_miss;

	assign	line_valid=	r_line_valid;
	assign	line_dirty	=r_line_dirty;
	assign	line_miss	=r_line_miss;
	assign	mem_addr	=r_mem_addr;
	assign	flush_cnt_miss	=r_flush_cnt_miss;

	dcache_memblock #(
		.DATABITS	(DATABITS),
		.CACHEDATABITS	(CACHEDATABITS),
		.CACHEADDRBITS	(CACHEADDRBITS),
		.BANKNUM	(BANKNUM),
		.CACHESIZE	(CACHESIZE)
	) DCACHE_MEMBLOCK0(
		.flush_mode	(flush_mode),
		
		.dcache_in	(dcache_in),
		.dcache_addr	(dcache_addr[CACHEADDRBITS+LSBITS-1:LSBITS]),
		.byteenable	(byteenable),
		.line_miss	(r_line_miss),
		.dcache_wrreq	(dcache_wrreq),

		.line_in	(line_in),
		.flush_addr	(flush_addr),
		.line_in_valid	(line_in_valid),
		.flush_write	(flush_write),
	
		.data_out	(line_out),
		.clk		(clk)
	);

	always	@(dcache_addr,addrmsb,r_init)
	begin
		r_line_miss<=r_init | (dcache_addr[ADDRBITS-CACHEADDRBITS-LSBITS:CACHEADDRBITS+LSBITS]!=addrmsb);
	end
	
	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			r_line_valid	<=1'b0;
			r_line_dirty	<=1'b1;
			r_init		<=1'b1;
		end else begin
			case ({r_line_miss,dcache_rdreq,dcache_wrreq,flush_mode,flush_write})
				5'b01000:begin
						r_line_valid	<=1'b1;
						if (r_flush_cnt_miss!='d0)
						begin
							r_flush_cnt_miss	<=r_flush_cnt_miss-'d1;
						end
					end
				5'b00100:begin
						r_line_dirty		<=1'b1;
						r_line_valid	<=1'b0;
						if (r_flush_cnt_miss!='d0)
						begin
							r_flush_cnt_miss	<=r_flush_cnt_miss-'d1;
						end
					end
				5'b10100:begin
						if (r_flush_cnt_miss!='d255)
						begin
							r_flush_cnt_miss	<=r_flush_cnt_miss+'d1;
						end
					end
				5'b11000:begin
						if (r_flush_cnt_miss!='d255)
						begin
							r_flush_cnt_miss	<=r_flush_cnt_miss+'d1;
						end
					end
				5'b10010:begin	// flushing out
						addrmsb		<=dcache_addr[ADDRBITS-CACHEADDRBITS-LSBITS:CACHEADDRBITS+LSBITS];
						r_mem_addr	<={addrmsb,7'd0};
						r_init		<=1'b0;
						r_flush_cnt_miss	<='d0;
					end
				5'b10011:begin
						r_line_dirty		<=flush_dirty;
						addrmsb		<=dcache_addr[ADDRBITS-CACHEADDRBITS-LSBITS:CACHEADDRBITS+LSBITS];
						r_init		<=1'b0;
						r_flush_cnt_miss	<='d0;
					end
				default:begin
						r_line_valid	<=1'b0;
					end
			endcase
		end
	end
endmodule
