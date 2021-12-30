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

module	dcache
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32,
parameter	CACHEADDRBITS=5,
parameter	CACHESIZE=(2**CACHEADDRBITS),
parameter	LINENUM=4,
parameter	TTLBITS=8,
parameter	MAXTTL='d255,
parameter	BANKNUM=4
)
(
	// connection to the CPU core
	input	[ADDRBITS-1:0]	dcache_addr,
	input	[DATABITS-1:0]	dcache_in,
	output	[DATABITS-1:0]	dcache_out,
	output			dcache_out_valid,
	input			dcache_rdreq,
	input			dcache_wrreq,
	input	[1:0]		dcache_wordlen,		// 00=byte, 01=half word, 10=word

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
	wire	[BANKNUM-1:0]	flush_byteenable;
	reg	[BANKNUM-1:0]	byteenable;

	reg	[DATABITS-1:0]	m_dcache_out;
	reg			m_dcache_out_valid;


	wire	[DATABITS-1:0]	queue_out_data;
	wire	[ADDRBITS-1:0]	queue_out_addr;
	wire			queue_out_rdreq;
	wire			queue_out_wrreq;

	reg			queue_pop;
	wire			queue_not_empty;


	reg			flush_we;
	reg	[ADDRBITS-1:0]	flush_addr;

	localparam	[1:0]	MSR_CACHING=2'b00,MSR_FLUSHING=2'b01,MSR_FILL=2'b10,MSR_QUEUE=2'b11;
	reg	[1:0]		msr;

	reg	[TTLBITS-1:0]	ttl0;
	reg	[TTLBITS-1:0]	ttl1;
	reg	[TTLBITS-1:0]	ttl2;
	reg	[TTLBITS-1:0]	ttl3;

	reg	[TTLBITS-1:0]	v_ttl01;
	reg	[TTLBITS-1:0]	v_ttl23;

	reg	[LINENUM-1:0]	flush_mode;
	reg	[LINENUM-1:0]	v_flush_mode01;
	reg	[LINENUM-1:0]	v_flush_mode23;
	reg	[LINENUM-1:0]	v_flush_mode;
	reg	[ADDRBITS-1:0]	v_memory_section01;
	reg	[ADDRBITS-1:0]	v_memory_section23;
	reg	[ADDRBITS-1:0]	v_memory_section;
	reg			v_dirty01;
	reg			v_dirty23;
	reg			v_dirty;

	reg	[CACHEADDRBITS:0]	cnt_flush;
	reg	[15:0]			cnt_burst;

	reg	[DATABITS-1:0]		r_mem_in;
	reg	[ADDRBITS-1:0]		r_mem_addr;
	reg				r_mem_rdreq;
	reg				r_mem_wrreq;


	

	assign	dcache_out		=m_dcache_out;
	assign	dcache_out_valid	=m_dcache_out_valid;
	assign	mem_in			=r_mem_in;
	assign	mem_addr		=r_mem_addr;
	assign	mem_rdreq		=r_mem_rdreq;
	assign	mem_wrreq		=r_mem_wrreq;


	always	@(dcache_wordlen,dcache_addr[1:0])
	begin
		case ({dcache_wordlen,dcache_addr[1:0]})
			// byte 
			4'b0000:	begin	byteenable<=4'b0001;end	
			4'b0001:	begin	byteenable<=4'b0010;end	
			4'b0010:	begin	byteenable<=4'b0100;end	
			4'b0011:	begin	byteenable<=4'b1000;end	
			// half word
			4'b0100:	begin	byteenable<=4'b0011;end	
			4'b0110:	begin	byteenable<=4'b1100;end	
			// word
			4'b1000:	begin	byteenable<=4'b1111;end
			// anything else: alignment error
			default:	begin	byteenable<=4'b0000;end
		endcase
	end

	always	@(line_out0,line_out1,line_out2,line_out3,line_out_valid)
	begin
		// FIXME: this is not enough for a queued READ
		// but what I can do is to add a new input "queue" to the lines, and have them set the _out_valid in the last cycle of the flush mode.
		case (line_out_valid)
			4'b0001:	begin	m_dcache_out_valid<=1'b1;m_dcache_out<=line_out0;end
			4'b0010:	begin	m_dcache_out_valid<=1'b1;m_dcache_out<=line_out1;end
			4'b0100:	begin	m_dcache_out_valid<=1'b1;m_dcache_out<=line_out2;end
			4'b1000:	begin	m_dcache_out_valid<=1'b1;m_dcache_out<=line_out3;end
			default:	begin	m_dcache_out_valid<=1'b0;m_dcache_out<='b0;end
		endcase
	end


	dcache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
		.CACHEADDRBITS	(CACHEADDRBITS)
	) DCACHE_LINE0 (
		.dcache_addr		(dcache_addr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_in		(dcache_in),
		.line_out		(line_out0),
		.line_out_valid		(line_out_valid[0]),
		.byteenable		(byteenable),
		.line_memory_section	(line_memory_section0),
	
		.line_miss		(line_miss[0]),
		.line_dirty		(line_dirty[0]),
		.flush_mode		(flush_mode[0]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),
		.flush_byteenable	(flush_byteenable),
		.flush_queue_rdreq	(flush_queue_rdreq),
		.flush_queue_wrreq	(flush_queue_wrreq),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
		.CACHEADDRBITS	(CACHEADDRBITS)
	) DCACHE_LINE1 (
		.dcache_addr		(dcache_addr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_in		(dcache_in),
		.line_out		(line_out1),
		.line_out_valid		(line_out_valid[1]),
		.byteenable		(byteenable),
		.line_memory_section	(line_memory_section1),
	
		.line_miss		(line_miss[1]),
		.line_dirty		(line_dirty[1]),
		.flush_mode		(flush_mode[1]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),
		.flush_byteenable	(flush_byteenable),
		.flush_queue_rdreq	(flush_queue_rdreq),
		.flush_queue_wrreq	(flush_queue_wrreq),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
		.CACHEADDRBITS	(CACHEADDRBITS)
	) DCACHE_LINE2 (
		.dcache_addr		(dcache_addr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_in		(dcache_in),
		.line_out		(line_out2),
		.line_out_valid		(line_out_valid[2]),
		.byteenable		(byteenable),
		.line_memory_section	(line_memory_section2),
	
		.line_miss		(line_miss[2]),
		.line_dirty		(line_dirty[2]),
		.flush_mode		(flush_mode[2]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),
		.flush_byteenable	(flush_byteenable),
		.flush_queue_rdreq	(flush_queue_rdreq),
		.flush_queue_wrreq	(flush_queue_wrreq),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
		.CACHEADDRBITS	(CACHEADDRBITS)
	) DCACHE_LINE3 (
		.dcache_addr		(dcache_addr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_in		(dcache_in),
		.line_out		(line_out3),
		.line_out_valid		(line_out_valid[3]),
		.byteenable		(byteenable),
		.line_memory_section	(line_memory_section3),
	
		.line_miss		(line_miss[3]),
		.line_dirty		(line_dirty[3]),
		.flush_mode		(flush_mode[3]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),
		.flush_byteenable	(flush_byteenable),
		.flush_queue_rdreq	(flush_queue_rdreq),
		.flush_queue_wrreq	(flush_queue_wrreq),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_queue	#(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS)
	)	DCACHE_QUEUE (
		.queue_in_data		(dcache_addr),
		.queue_in_addr		(dcache_in),
		.queue_in_rdreq		(dcache_rdreq),
		.queue_in_wrreq		(dcache_wrreq),
		.queue_in_wordlen	(dcache_wordlen),

		.queue_out_data		(queue_out_data),
		.queue_out_addr		(queue_out_addr),
		.queue_out_rdreq	(queue_out_rdreq),
		.queue_out_wrreq	(queue_out_wrreq),
		.queue_out_wordlen	(queue_out_wordlen),
		
		.queue_push		(line_miss==4'b1111 & (dcache_rdreq|dcache_wrreq)),
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
			ttl0			<='d0;
			ttl1			<='d0;
			ttl2			<='d0;
			ttl3			<='d0;
			flush_mode		<='b0;

			r_mem_in		<='b0;
			r_mem_addr		<='b0;
			r_mem_rdreq		<=1'b0;
			r_mem_wrreq		<=1'b0;
			cnt_flush		<='d0;
			cnt_burst		<='d0;
			flush_we		<=1'b0;
			flush_queue_rdreq	<=1'b0;
			flush_queue_wrreq	<=1'b0;
		end else begin
			case (msr)
				MSR_CACHING:	begin
							flush_we		<=1'b0;
							flush_queue_rdreq	<=1'b0;
							flush_queue_wrreq	<=1'b0;
							queue_pop		<=1'b0;
							flush_queue_rdreq	<=1'b0;
							cnt_flush		<='d0;
							if (dcache_rdreq|dcache_wrreq)
							begin
								ttl0	<=line_miss[0]?(ttl0+(ttl0!=MAXTTL)):(ttl0-(ttl0!='d0));
								ttl1	<=line_miss[1]?(ttl1+(ttl1!=MAXTTL)):(ttl1-(ttl1!='d0));
								ttl2	<=line_miss[2]?(ttl2+(ttl2!=MAXTTL)):(ttl2-(ttl2!='d0));
								ttl3	<=line_miss[3]?(ttl3+(ttl3!=MAXTTL)):(ttl3-(ttl3!='d0));
							end
							v_flush_mode		<=4'b0000;
							if (queue_not_empty)
							begin
								if (ttl0>=ttl1)
								begin
									v_ttl01			=ttl0;
									v_flush_mode01		=4'b0001;
									v_memory_section01	=line_memory_section0;
									v_dirty01		=line_dirty[0];
								end else begin
									v_ttl01			=ttl1;
									v_flush_mode01		=4'b0010;
									v_memory_section01	=line_memory_section1;
									v_dirty01		=line_dirty[1];
								end	
								if (ttl2>=ttl3)
								begin
									v_ttl23			=ttl2;
									v_flush_mode23		=4'b0100;
									v_memory_section23	=line_memory_section2;
									v_dirty01		=line_dirty[2];
								end else begin
									v_ttl23			=ttl3;
									v_flush_mode23		=4'b1000;
									v_memory_section23	=line_memory_section3;
									v_dirty01		=line_dirty[3];
								end	
								if (v_ttl01>=v_ttl23)
								begin
									v_flush_mode		<=v_flush_mode01;
									v_dirty			=v_dirty01;
									v_memory_section	=v_memory_section01;
								end else begin
									v_flush_mode		<=v_flush_mode23;
									v_dirty			=v_dirty23;
									v_memory_section	=v_memory_section23;
								end
								msr		<=v_dirty?MSR_FLUSH:MSR_FILL;
								flush_addr	<=v_dirty?v_memory_section:{queue_out_addr[ADDRBITS:7],7'b0000000};	// TODO: parameterize
								cnt_burst	<=mem_burstlen;
								flush_we	<=1'b0;
								
							end
							r_flush_mode	<=v_flush_mode;
						end
				MSR_FLUSH:	begin
							flush_we		<=1'b0;
							flush_queue_rdreq	<=1'b0;
							r_mem_rdreq		<=1'b0;
							if (cnt_flush==CACHESIZE)
							begin
								msr		<=MSR_FILL;
								flush_addr	<={queue_out_addr[ADDRBITS-1:7],7'b0000000};	// TODO: parameterize
								r_mem_addr	<={queue_out_addr[ADDRBITS-1:7],7'b0000000};	// TODO: parameterize
								cnt_burst	<=mem_burstlen;
								cnt_flush	<='d0;
								r_mem_wrreq	<=1'b0;
							end else begin
								cnt_flush	<=cnt_flush+1'd1;
								if (cnt_burst==mem_burst_len)
								begin
									cnt_burst	<=cnt_burst+1'd1;
									r_mem_wrreq	<=1'b1;
								end else begin
									cnt_burst	<='d0;
									r_mem_wrreq	<=1'b0;
								end
								r_mem_addr	<=flush_addr;
								flush_addr	<=flush_addr+BANKNUM;
							end
						end
				MSR_FILL:	begin
							r_mem_wrreq		<=1'b0;
							flush_queue_rdreq	<=1'b0;
							queue_pop		<=1'b0;
							if (cnt_flush==CACHESIZE)
							begin
								msr		<=MSR_QUEUE;
								cnt_burst	<='d0;
								cnt_flush	<='d0;
								r_mem_rdreq	<=1'b0;
								flush_we	<=1'b0;
							end else if (cnt_flush==mem_burstlen) begin
								r_mem_rdreq	<=1'b1;
								cnt_burst	<='d0;
								r_mem_rdreq	<=1'b1;
								flush_we	<=1'b0;
								flush_addr	<=r_mem_addr;
							end else begin
								if (mem_valid)
								begin
									flush_in		<=mem_in;
									flush_byteenable	<=4'b1111;
									flush_addr		<=r_mem_addr;
									r_mem_addr		<=r_mem_addr+BANKNUM;
									flush_we		<=1'b1;
									cnt_burst		<=cnt_burst+'d1;
									cnt_flush		<=cnt_flush+'d1;
								end else begin
									flush_we		<=1'b0;
								end
							end
							
						end
				MSR_QUEUE:	begin
							case (flush_mode)
								4'b0001:	begin	ttl0<='d0;end
								4'b0010:	begin	ttl1<='d0;end
								4'b0100:	begin	ttl2<='d0;end
								4'b1000:	begin	ttl3<='d0;end
							endcase
							queue_pop		<=1'b1;
							msr			<=MSR_CACHING;
							flush_addr		<=queue_out_addr;
							flush_in		<=queue_out_data;
							flush_we		<=queue_out_wrreq;
							flush_queue_rdreq	<=queue_out_rdreq;
							flush_queue_wrreq	<=queue_out_wrreq;
							case ({queue_out_wordlen,queue_out_addr[1:0]})
								// byte 
								4'b0000:	begin	flush_byteenable<=4'b0001;end	
								4'b0001:	begin	flush_byteenable<=4'b0010;end	
								4'b0010:	begin	flush_byteenable<=4'b0100;end	
								4'b0011:	begin	flush_byteenable<=4'b1000;end	
								// half word
								4'b0100:	begin	flush_byteenable<=4'b0011;end	
								4'b0110:	begin	flush_byteenable<=4'b1100;end	
								// word
								4'b1000:	begin	flush_byteenable<=4'b1111;end
								default:	begin	flush_byteenable<=4'b0000;end
							endcase

						end
			endcase
		end
	end
endmodule


