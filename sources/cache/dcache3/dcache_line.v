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

module	dcache_line
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32,
parameter	CACHEADDRBITS=5,
parameter	BANKNUM=4
)
(
	// connection to the CPU core
	input	[ADDRBITS-1:0]	dcache_addr,
	input			dcache_rdreq,
	input			dcache_wrreq,
	input	[DATABITS-1:0]	dcache_in,
	output	[DATABITS-1:0]	line_out,
	output			line_out_valid,
	input	[BANKNUM-1:0]	byteenable,

	// connection to the flush controller
	output			line_miss,
	output			line_dirty,
	input			flush_mode,
	input			flush_we,
	input	[ADDRBITS-1:0]	flush_addr,
	input	[DATABITS-1:0]	flush_in,

	// system control lines
	input				reset_n,
	input				clk
);

	wire					v_line_miss;	
	wire	[CACHEADDRBITS-1:0]		lsb_addr;
	wire	[DATABITS-CACHEADDRBITS-2-1:0]	msb_addr;
	reg	[DATABITS-CACHEADDRBITS-2-1:0]	r_memory_section;	// to remember which memory section this cache line is from
	reg					r_line_dirty;
	reg					r_init;			// after a reset, this one is =1

	assign	lsb_addr	=dcache_addr[CACHEADDRBITS+2-1:2];
	assign	msb_addr	=dcache_addr[DATABITS-1:CACHEADDRBITS+2];
	assign	v_line_miss	=(msb_addr!=r_memory_section)|r_init;
	assign	line_miss	=r_line_miss;
	assign	line_dirty	=r_line_dirty;
	assign	line_out_valid	=!v_line_miss & dcache_rdreq;

	dcache_memblock	
	#(
		.DATABITS		(DATABITS),
		.ADDRBITS		(CACHEADDRBITS),
		.BANKNUM		(BANKNUM)
	) DCACHE_MEMBLOCK0(
		.addr			(lsb_addr),
		.data_in		(dcache_in),
		.data_out		(line_out),
		.we			(!v_line_miss & dcache_wrreq),
		.byteenable		(byteenable),

		.flush_mode		(flush_mode),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),
		.flush_we		(flush_we),

		.reset_n		(reset_n),
		.clk			(clk)
	);	


	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			r_line_dirty		<=1'b0;
			r_init			<=1'b1;
			r_memory_section	<='b0;
		end else begin
			if (flush_mode)
			begin
				r_init		<=1'b0;
				if (flush_we)
				begin
					r_line_dirty		<=1'b0;
					r_memory_section	<=flush_addr[DATABITS-1:CACHEADDRBITS+2];
				end
			end else begin
				if (dcache_wrreq)
				begin
					r_line_dirty		<=!r_init;
				end	
			end
		end	
	end
endmodule
