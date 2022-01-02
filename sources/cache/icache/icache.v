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

module	icache
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32,
parameter	CACHEADDRBITS=5,
parameter	CACHESIZE=(2**CACHEADDRBITS),
parameter	LINENUM=4,
parameter	TTLBITS=8,
)
(
	// connection to the CPU core
	input	[ADDRBITS-1:0]	icache_addr,
	output	[DATABITS-1:0]	icache_out,
	output			icache_out_valid,
	input			icache_rdreq,
	output			icache_ready,

	// connection to the memory controller
	output	[ADDRBITS-1:0]	mem_addr,
	output	[DATABITS-1:0]	mem_in,
	input	[DATABITS-1:0]	mem_out,
	input			mem_out_valid,
	output			mem_rdreq,
	output			mem_wrreq,
	input	[15:0]		mem_burstlen,
	

	// system control lines
	input			reset_n,
	input			clk
);
		
	wire	[DATABITS-1:0]	line_out0;
	wire	[DATABITS-1:0]	line_out1;
	wire	[DATABITS-1:0]	line_out2;
	wire	[DATABITS-1:0]	line_out3;

	wire	[ADDRBITS-1:0]	line_memory_section0;
	wire	[ADDRBITS-1:0]	line_memory_section1;
	wire	[ADDRBITS-1:0]	line_memory_section2;
	wire	[ADDRBITS-1:0]	line_memory_section3;

	wire	[LINENUM-1:0]	line_out_valid;
	wire	[LINENUM-1:0]	line_miss;

	reg	[DATABITS-1:0]	m_icache_out;
	reg			m_icache_out_valid;


	wire	[DATABITS-1:0]	queue_out_data;
	wire	[ADDRBITS-1:0]	queue_out_addr;

	reg			queue_pop;
	wire			queue_not_empty;

	reg			flush_we;
	reg	[ADDRBITS-1:0]	flush_addr;
	reg	[DATABITS-1:0]	flush_in;
	reg			queue_mode;
	localparam	[2:0]	MSR_CACHING=3'b000,MSR_FILL=3'b010,MSR_QUEUE=3'b011,MSR_WAIT=3'b100;
	reg	[2:0]		msr;

	wire	[TTLBITS-1:0]	line_ttl0;
	wire	[TTLBITS-1:0]	line_ttl1;
	wire	[TTLBITS-1:0]	line_ttl2;
	wire	[TTLBITS-1:0]	line_ttl3;

	reg	[TTLBITS-1:0]	v_ttl01;
	reg	[TTLBITS-1:0]	v_ttl23;

	reg	[LINENUM-1:0]	flush_mode;
	reg	[LINENUM-1:0]	v_flush_mode01;
	reg	[LINENUM-1:0]	v_flush_mode23;
	reg	[LINENUM-1:0]	v_flush_mode;
	reg	[ADDRBITS-1:0]	v_memory_section01;
	reg	[ADDRBITS-1:0]	v_memory_section23;
	reg	[ADDRBITS-1:0]	v_memory_section;

	reg	[CACHEADDRBITS:0]	cnt_flush;
	reg	[15:0]			cnt_burst;

	reg	[DATABITS-1:0]		r_mem_in;
	reg	[ADDRBITS-1:0]		r_mem_addr;
	reg				r_mem_rdreq;
	reg				r_mem_wrreq;
	reg				r_icache_ready;

	assign	icache_out		=m_icache_out;
	assign	icache_out_valid	=m_icache_out_valid;
	assign	mem_in			=r_mem_in;
	assign	mem_addr		=r_mem_addr;
	assign	mem_rdreq		=r_mem_rdreq;
	assign	mem_wrreq		=r_mem_wrreq;
	assign	icache_ready		=r_icache_ready;

	always	@(line_out0,line_out1,line_out2,line_out3,line_out_valid)
	begin
		case (line_out_valid)
			4'b0001:	begin	m_icache_out_valid<=1'b1;m_icache_out<=line_out0;end
			4'b0010:	begin	m_icache_out_valid<=1'b1;m_icache_out<=line_out1;end
			4'b0100:	begin	m_icache_out_valid<=1'b1;m_icache_out<=line_out2;end
			4'b1000:	begin	m_icache_out_valid<=1'b1;m_icache_out<=line_out3;end
			default:	begin	m_icache_out_valid<=1'b0;m_icache_out<='b0;end
		endcase
	end

	icache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
		.CACHEADDRBITS	(CACHEADDRBITS),
		.TTLBITS	(TTLBITS)
	) ICACHE_LINE0 (
		.icache_addr		(icache_addr),
		.icache_rdreq		(icache_rdreq),
		.icache_in		(icache_in),
		.line_out		(line_out0),
		.line_out_valid		(line_out_valid[0]),
		.line_memory_section	(line_memory_section0),
	
		.line_miss		(line_miss[0]),
		.flush_mode		(flush_mode[0]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),

		.queue_mode		(queue_mode),
		.queue_addr		(queue_out_addr),
		.queue_data		(queue_out_data),

		.line_ttl		(line_ttl0),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	icache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
		.CACHEADDRBITS	(CACHEADDRBITS),
		.TTLBITS	(TTLBITS)
	) ICACHE_LINE1 (
		.icache_addr		(icache_addr),
		.icache_rdreq		(icache_rdreq),
		.icache_in		(icache_in),
		.line_out		(line_out1),
		.line_out_valid		(line_out_valid[1]),
		.line_memory_section	(line_memory_section1),
	
		.line_miss		(line_miss[1]),
		.flush_mode		(flush_mode[1]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),

		.queue_mode		(queue_mode),
		.queue_addr		(queue_out_addr),
		.queue_data		(queue_out_data),

		.line_ttl		(line_ttl1),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	icache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
		.CACHEADDRBITS	(CACHEADDRBITS),
		.TTLBITS	(TTLBITS)
	) ICACHE_LINE2 (
		.icache_addr		(icache_addr),
		.icache_rdreq		(icache_rdreq),
		.icache_in		(icache_in),
		.line_out		(line_out2),
		.line_out_valid		(line_out_valid[2]),
		.line_memory_section	(line_memory_section2),
	
		.line_miss		(line_miss[2]),
		.flush_mode		(flush_mode[2]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),

		.queue_mode		(queue_mode),
		.queue_addr		(queue_out_addr),
		.queue_data		(queue_out_data),

		.line_ttl		(line_ttl2),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	icache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
		.CACHEADDRBITS	(CACHEADDRBITS),
		.TTLBITS	(TTLBITS)
	) ICACHE_LINE3 (
		.icache_addr		(icache_addr),
		.icache_rdreq		(icache_rdreq),
		.icache_in		(icache_in),
		.line_out		(line_out3),
		.line_out_valid		(line_out_valid[3]),
		.line_memory_section	(line_memory_section3),
	
		.line_miss		(line_miss[3]),
		.flush_mode		(flush_mode[3]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),

		.queue_mode		(queue_mode),
		.queue_addr		(queue_out_addr),
		.queue_data		(queue_out_data),

		.line_ttl		(line_ttl3),

		.reset_n		(reset_n),
		.clk			(clk)
	);


	icache_queue	#(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS)
	)	icache_QUEUE (
		.queue_in_data		(icache_in),
		.queue_in_addr		(icache_addr),

		.queue_out_data		(queue_out_data),
		.queue_out_addr		(queue_out_addr),
		
		.queue_push		((line_miss==4'b1111) & (icache_rdreq|icache_wrreq)),
		.queue_pop		(queue_pop),
		.queue_not_empty	(queue_not_empty),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			queue_pop		<=1'b0;
			flush_we		<=1'b0;
			flush_addr		<='d0;	
			msr			<=MSR_CACHING;
			flush_mode		<='b0;

			r_mem_in		<='b0;
			r_mem_addr		<='b0;
			r_mem_rdreq		<=1'b0;
			r_mem_wrreq		<=1'b0;
			cnt_flush		<='d0;
			cnt_burst		<='d0;
			flush_we		<=1'b0;
			queue_mode		<=1'b0;
			r_icache_ready		<=1'b1;
		end else begin
			case (msr)
				MSR_CACHING:	begin
							r_icache_ready		<=1'b1;
							queue_pop	<=1'b0;
							queue_mode	<=queue_not_empty;
							if (queue_not_empty)
							begin
								msr		<=MSR_QUEUE;
							end 
						end
				MSR_FILL:	begin
							r_mem_wrreq	<=1'b0;
							if (cnt_flush==CACHESIZE)
							begin
								flush_mode	<=4'b0000;
								queue_mode	<=queue_not_empty;
								msr		<=MSR_QUEUE;
								flush_we	<=1'b0;	
								r_mem_rdreq	<=1'b0;
							end else if (cnt_burst==mem_burstlen) begin
								flush_we	<=1'b0;	
								cnt_burst	<='d0;
								r_mem_rdreq	<=1'b1;
							end else if (mem_out_valid) begin
								r_mem_addr	<=r_mem_addr+'d4;
								flush_addr	<=r_mem_addr;
								flush_we	<=1'b1;
								cnt_burst	<=cnt_burst+'d1;
								cnt_flush	<=cnt_flush+'d1;
								flush_in	<=mem_out;
							end else begin
								flush_we	<=1'b0;
							end
						end
				MSR_QUEUE:	begin
							r_icache_ready		<=1'b0;
							queue_mode	<=1'b0;
							v_flush_mode	=4'b0000;
							if (line_miss==4'b1111)
							begin
								queue_pop	<=1'b0;
								if (line_ttl0>=line_ttl1)
								begin
									v_ttl01			=line_ttl0;
									v_flush_mode01		=4'b0001;
									v_memory_section01	=line_memory_section0;
								end else begin
									v_ttl01			=line_ttl1;
									v_flush_mode01		=4'b0010;
									v_memory_section01	=line_memory_section1;
								end
								if (line_ttl2>=line_ttl3)
								begin
									v_ttl23			=line_ttl2;
									v_flush_mode23		=4'b0100;
									v_memory_section23	=line_memory_section2;
								end else begin
									v_ttl23			=line_ttl3;
									v_flush_mode23		=4'b1000;
									v_memory_section23	=line_memory_section3;
								end
								if (v_ttl01>=v_ttl23)
								begin
									v_flush_mode		=v_flush_mode01;
									v_memory_section	=v_memory_section01;
								end else begin
									v_flush_mode		=v_flush_mode23;
									v_memory_section	=v_memory_section23;
								end
								cnt_flush	<='d0;
								cnt_burst	<=mem_burstlen;
								flush_addr	<={queue_out_addr[ADDRBITS-1:CACHEADDRBITS+2],7'b0000000};
								r_mem_addr	<={queue_out_addr[ADDRBITS-1:CACHEADDRBITS+2],7'b0000000};
								msr		<=MSR_FILL;
							end else begin
								queue_pop	<=queue_not_empty;
								msr		<=MSR_WAIT;
							end
							flush_mode	<=v_flush_mode;
						end
				MSR_WAIT:	begin
							queue_pop	<=1'b0;
							queue_mode	<=1'b0;
							flush_mode	<='b0;
							msr		<=MSR_CACHING;
						end
			endcase
		end
	end
endmodule




