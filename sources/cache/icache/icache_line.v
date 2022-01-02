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

module icache_line
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32,
parameter	CACHEADDRBITS=5,
parameter	BANKNUM=4,
parameter	TTLBITS=8,
parameter	MAXTTL=(2**TTLBITS-1)
)
(
	// connection to the CPU core
	input	[ADDRBITS-1:0]	icache_addr,
	input			icache_rdreq,
	output	[DATABITS-1:0]	line_out,
	output			line_out_valid,
	output	[ADDRBITS-1:0]	line_memory_section,

	// connection to the flush controller
	output			line_miss,
	input			flush_mode,
	input			flush_we,
	input	[ADDRBITS-1:0]	flush_addr,
	input	[DATABITS-1:0]	flush_in,

	input			queue_mode,
	input	[ADDRBITS-1:0]	queue_addr,
	input	[DATABITS-1:0]	queue_data,

	output	[TTLBITS-1:0]	line_ttl,

	// system control lines
	input			reset_n,
	input			clk	
);
	wire			v_line_miss;
	wire	[ADDRBITS-1:0]			int_addr;
	wire	[CACHEADDRBITS-1:0]		lsb_addr;
	wire	[DATABITS-CACHEADDRBITS-2-1:0]	msb_addr;
	wire	[DATABITS-CACHEADDRBITS-2-1:0]	flush_msb_addr;
	reg	[DATABITS-CACHEADDRBITS-2-1:0]	r_memory_section;	// to remember which memory section this cache line is from
	reg					r_init;			// after a reset, this one is =1
	wire					v_line_req;
	reg	[TTLBITS-1:0]			r_line_ttl;

	assign	line_ttl					=r_line_ttl;

	assign	int_addr					=queue_mode?queue_addr:icache_addr;
	assign	lsb_addr					=int_addr[CACHEADDRBITS+2-1:2];
	assign	msb_addr					=int_addr[DATABITS-1:CACHEADDRBITS+2];
	assign	flush_msb_addr					=flush_addr[DATABITS-1:CACHEADDRBITS+2];
	assign	v_line_miss					=(msb_addr!=r_memory_section)|r_init;
	assign	line_miss					=v_line_miss;
	assign	line_out_valid					=(flush_mode=='b0) & !v_line_miss & (queue_mode?1'b1:icache_rdreq);
	assign	line_memory_section[DATABITS-1:CACHEADDRBITS+2]	=r_memory_section;
	assign	line_memory_section[CACHEADDRBITS+2-1:0]	='b0;
	

	assign v_line_req					=queue_mode?(1'b1):(icache_rdreq);

	icache_memblock
	#(
		.DATABITS		(DATABITS),
		.ADDRBITS		(CACHEADDRBITS),
	) ICACHE_MEMBLOCK0(
		.addr			(lsb_addr),
		.data_in		(queue_mode?queue_data:icache_in),
		.data_out		(line_out),
		.we			(!v_line_miss & (queue_mode?queue_wrreq:icache_wrreq)),
		.byteenable		(queue_mode?queue_byteenable:byteenable),

		.flush_mode		(flush_mode),
		.flush_addr		(flush_addr[CACHEADDRBITS+2-1:2]),
		.flush_in		(flush_in),
		.flush_we		(flush_we),

		.reset_n		(reset_n),
		.clk			(clk)
	);


	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			r_init			<=1'b1;
			r_memory_section	<='b0;
			r_line_ttl		<='d0;
		end else begin
			if (flush_mode)
			begin
				r_init		<=1'b0;
				r_line_ttl	<='d0;
				if (flush_we)
				begin
					r_memory_section	<=flush_msb_addr;
				end
			end else begin
				
				if (!v_line_miss)
				begin
					if (r_line_ttl!='d0 & v_line_req) 
					begin
						r_line_ttl<=r_line_ttl-'d1;
					end
				end else begin
					if (r_line_ttl!=MAXTTL & v_line_req)
					begin
						r_line_ttl<=r_line_ttl+'d1;
					end
				end
			end
		end	
	end
endmodule
