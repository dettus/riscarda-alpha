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

module cache_line
#(
	parameter	ADDRBITS=32,
	parameter	DATABITS=32,
	parameter	LSBBITS=7,
	parameter	MAXLSBVALUE=(2**LSBBITS-4),
	parameter	TTLBITS=8,
	parameter	MAXTTL=((2**TTLBITS)-1),
	parameter	WORDLENBITS=2
)
(


	input	[ADDRBITS-1:0]		dcache_line_rdaddr,		//
	input				dcache_line_rdreq,		//
	output				dcache_line_out_valid,		//

	input	[ADDRBITS-1:0]		dcache_line_wraddr,		//
	input	[DATABITS-1:0]		dcache_line_in,			//
	input	[WORDLENBITS-1:0]	dcache_line_in_wordlen,		// 00=byte, 01=half word, 10=word
	input				dcache_line_wrreq,		//

	input	[ADDRBITS-1:0]		icache_line_rdaddr,		//
	input				icache_line_rdreq,		//
	output				icache_line_out_valid,		//


	output	[DATABITS-1:0]		cache_line_out,			// return value
	// connection to the controller
	output				cache_line_dirty,		// =1 in case there has been a write request
	output				cache_line_miss,		// // =1 if ALL of the requests failed
	input				cache_line_flush,		//
	input				cache_line_fill,		//
	input				cache_line_pause,		// in case the memory controller is overloaded
	output	[TTLBITS-1:0]		cache_line_ttl,			//
	input	[ADDRBITS-1:0]		cache_new_region,		//
	output				cache_line_ready,		//


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
	reg	[ADDRBITS-1:0]	r_memory_region;
	reg	[ADDRBITS-1:0]	r_next_memory_region;		// in case the line needs to be flushed first, it makes sense that the next region is already stored in the line
	reg			r_empty;
	wire			w_dcache_line_out_valid;
	wire			w_icache_line_out_valid;
	reg			r_queue_dcache_rdpop;
	reg			r_queue_dcache_wrpop;
	reg			r_queue_icache_rdpop;
	reg			r_cache_line_dirty;
	reg			v_cache_line_dirty;
	reg	[TTLBITS-1:0]	r_cache_line_ttl;
	reg	[ADDRBITS-1:0]	r_mem_addr;
	reg			r_mem_wrreq;
	reg			r_mem_rdreq;
	reg			v_mem_rdreq;

	wire			w_dcache_rd_line_miss;
	wire			w_dcache_wr_line_miss;
	wire			w_icache_line_miss;

	localparam [2:0]	MSR_CACHEING=3'b000,MSR_FILLING=3'b001,MSR_FLUSHING=3'b010,MSR_BETWEEN_FLUSHING_AND_FILLING=3'b011;
	reg	[2:0]		msr;


	// for the line memory
	reg	[LSBBITS-1:0]		r_line_mem_wraddr;
	reg	[LSBBITS-1:0]		v_line_mem_wraddr;
	reg	[LSBBITS-1:0]		r_line_mem_rdaddr;	// TODO: make this asynchronous, outside the flushing
	reg	[LSBBITS-1:0]		v_line_mem_rdaddr;
	reg	[DATABITS-1:0]		r_line_mem_in;
	reg	[WORDLENBITS-1:0]	r_line_mem_wordlen;
	reg				r_line_mem_we;

	reg				r_cache_line_ready;
	reg				v_cache_line_ready;

	reg	[LSBBITS-1:0]		m_line_mem_rdaddr;
	wire	[WORDLENBITS-1:0]	m_line_mem_in_wordlen;
	wire	[DATABITS-1:0]		line_mem_out;
	reg	[DATABITS-1:0]		r_mem_in;



	assign	w_dcache_rd_line_miss	=(dcache_line_rdaddr[ADDRBITS-1:LSBBITS]!=r_memory_region[ADDRBITS-1:LSBBITS])|r_empty;
	assign	w_dcache_wr_line_miss	=(dcache_line_wraddr[ADDRBITS-1:LSBBITS]!=r_memory_region[ADDRBITS-1:LSBBITS])|r_empty;
	assign	w_icache_line_miss	=(icache_line_rdaddr[ADDRBITS-1:LSBBITS]!=r_memory_region[ADDRBITS-1:LSBBITS])|r_empty;

	assign	w_dcache_line_out_valid	=!w_dcache_rd_line_miss&dcache_line_rdreq;
	assign	w_icache_line_out_valid	=!w_icache_line_miss&icache_line_rdreq;

	assign	cache_line_miss		=!w_dcache_line_out_valid & !w_icache_line_out_valid & (!w_dcache_wr_line_miss & dcache_line_wrreq);	

	assign	dcache_line_out_valid	=w_dcache_line_out_valid & r_cache_line_ready; // TODO & !flushing/filling	
	assign	icache_line_out_valid	=w_icache_line_out_valid & r_cache_line_ready; // TODO & !flushing/filling	
	assign	cache_line_ttl		=r_cache_line_ttl;
	assign	mem_addr		=r_mem_addr;
	assign	cache_line_ready	=r_cache_line_ready;
	assign	mem_in			=r_mem_in;

	assign	cache_line_dirty	=r_cache_line_dirty;

	/// the internal memory block gets the following inputs:
	// rd_addr can be one of three: 
	//    dcache_line_rdaddr, when dcache_line_rdreq & !miss
	//    icache_line_rdaddr, when icache_line_rdreq & !miss
	//    r_line_mem_rdaddr, when flushing
	// wr_addr
	// wr_value

	always	@(dcache_line_rdaddr,icache_line_rdaddr,r_cache_line_ready, r_line_mem_rdaddr,dcache_line_rdreq,icache_line_rdreq,w_icache_line_miss,w_dcache_rd_line_miss)
	begin
		m_line_mem_rdaddr	=r_line_mem_rdaddr;
		if (r_cache_line_ready & !w_dcache_rd_line_miss & dcache_line_rdreq)	begin	m_line_mem_rdaddr=dcache_line_rdaddr;end
		if (r_cache_line_ready & !w_icache_line_miss & icache_line_rdreq)	begin	m_line_mem_rdaddr=icache_line_rdaddr;end
	end
	assign	m_line_mem_in_wordlen=r_cache_line_ready?dcache_line_in_wordlen:2'b10;
	assign	cache_line_out		=line_mem_out;
	assign	mem_rdreq		=r_mem_rdreq;
	assign	mem_wrreq		=r_mem_wrreq;

	cache_memblock #(
		.DATABITS		(DATABITS),
		.ADDRBITS		(ADDRBITS),
		.LSBBITS		(LSBBITS),
		.WORDLENBITS		(WORDLENBITS)
	) CACHE_MEMBLOCK0
	(
		.line_mem_wraddr	(r_line_mem_wraddr),
		.line_mem_rdaddr	(m_line_mem_rdaddr),
		.line_mem_we		(r_line_mem_we),
		.line_mem_in		(r_line_mem_in),
		.line_mem_out		(line_mem_out),
		.line_mem_in_wordlen	(m_line_mem_in_wordlen),
		.clk			(clk)
	);

	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			r_memory_region		<='h0;
			r_next_memory_region	<='h0;
			r_empty			<=1'b1;
			r_queue_dcache_rdpop	<=1'b0;
			r_queue_dcache_wrpop	<=1'b0;
			r_queue_icache_rdpop	<=1'b0;
			r_cache_line_dirty	<=1'b0;
			r_cache_line_ttl	<=MAXTTL;
			r_mem_addr		<='h0;
			r_mem_wrreq		<=1'b0;
			r_mem_rdreq		<=1'b0;
			r_cache_line_ready	<=1'b1;


			r_line_mem_wordlen	<=2'b10;
			r_line_mem_we		<=1'b0;
			r_line_mem_wraddr	<='d0;
			r_line_mem_in		<='h0;
			msr			<=MSR_CACHEING;
		end else begin
			v_cache_line_dirty		=r_cache_line_dirty;
			if (!w_dcache_wr_line_miss & dcache_line_wrreq)
			begin
				v_cache_line_dirty	=1'b1;
			end
			case (msr)
				MSR_CACHEING:	begin
							v_cache_line_ready		=1'b1;
							r_mem_wrreq			<=1'b0;
							case ({cache_line_flush,cache_line_fill})
								2'b01:	begin
										r_memory_region			<=cache_new_region;
										r_mem_addr[ADDRBITS-1:LSBBITS]	<=cache_new_region;
										r_mem_addr[LSBBITS-1:0]		<='b0;
										r_mem_rdreq			<=1'b1;
										msr				<=MSR_FILLING;
										r_line_mem_wordlen		<=2'b10;
										r_line_mem_we			<=1'b0;
										r_line_mem_rdaddr		<='d0;
										r_line_mem_wraddr		<='d0-'d4;
										r_line_mem_in			<='h0;
										r_empty				<=1'b0;	// once the line has been filled, it is no longer empty
										v_cache_line_ready		=1'b0;
									end
								2'b10:	begin	// just flushing, no filling afterwards
										r_empty				<=1'b1;	// once the line has been flushed, it is empty
										r_mem_addr[ADDRBITS-1:LSBBITS]	<=r_memory_region[ADDRBITS-1:LSBBITS];
										r_mem_addr[LSBBITS-1:0]		<='b0;
										r_line_mem_we			<=1'b0;
										r_line_mem_rdaddr		<='d0;
										r_line_mem_wraddr		<='d0;
										msr				<=MSR_FLUSHING;
										v_cache_line_ready		=1'b0;
									end
								2'b11:	begin	// flushing, then filling
										r_empty				<=1'b0;	
										r_next_memory_region		<=cache_new_region;
										r_mem_addr[ADDRBITS-1:LSBBITS]	<=r_memory_region[ADDRBITS-1:LSBBITS];
										r_mem_addr[LSBBITS-1:0]		<='b0;
										r_line_mem_we			<=1'b0;
										r_line_mem_rdaddr		<='d0;
										r_line_mem_wraddr		<='d0;
										msr				<=MSR_FLUSHING;
										v_cache_line_ready		=1'b0;
									end
								default:begin
										if (dcache_line_wrreq & !w_dcache_wr_line_miss)
										begin
											v_cache_line_dirty	=1'b1;
											r_line_mem_we		<=1'b1;
											r_line_mem_wraddr	<=dcache_line_wraddr[LSBBITS-1:0];
											r_line_mem_wordlen	<=dcache_line_in_wordlen;
											r_line_mem_in		<=dcache_line_in;
										end else begin
											r_line_mem_we		<=1'b0;

										end
									end
							endcase
							r_cache_line_ready		<=v_cache_line_ready;
							
						end
				MSR_FILLING:	begin
							v_mem_rdreq			=1'b1;
							if (cache_line_pause)
							begin
								v_mem_rdreq			=1'b0;
							end else begin
								v_cache_line_dirty		=1'b0;
								if (r_mem_addr[LSBBITS-1:0]!=MAXLSBVALUE)
								begin
									r_mem_addr[LSBBITS-1:0]	<=r_mem_addr[LSBBITS-1:0]+'d4;
								end else begin
									v_mem_rdreq		=1'b0;
								end
							end
							if (mem_out_valid) 
							begin
								v_line_mem_wraddr	=r_line_mem_wraddr+'d4;
								r_line_mem_in		<=mem_out;
								r_line_mem_we		<=1'b1;
								r_line_mem_wraddr	<=v_line_mem_wraddr;
								if (v_line_mem_wraddr==MAXLSBVALUE)
								begin
									msr		<=MSR_CACHEING;
									v_mem_rdreq		=1'b0;
								end
							end else begin
								r_line_mem_we		<=1'b0;
							end
							r_mem_rdreq	<=v_mem_rdreq;
							r_mem_wrreq	<=1'b0;
						end
				MSR_FLUSHING:	begin	// just produce addr/data tuples until the line memory has been read
							v_cache_line_dirty		=1'b0;
							v_line_mem_rdaddr		=r_line_mem_rdaddr+'d4;
							r_mem_addr[LSBBITS-1:0]		<=r_line_mem_rdaddr;
							r_line_mem_rdaddr		<=v_line_mem_rdaddr;
							r_mem_wrreq			<=1'b1;
							r_mem_in			<=line_mem_out;
							if (v_line_mem_rdaddr==MAXLSBVALUE)
							begin
								if (r_empty)
								begin
									msr	<=MSR_CACHEING;
								end else begin
									msr	<=MSR_BETWEEN_FLUSHING_AND_FILLING;
								end
							end
						end
				MSR_BETWEEN_FLUSHING_AND_FILLING: begin	// transitional period
								r_mem_wrreq			<=1'b0;
								r_memory_region			<=r_next_memory_region;
								r_mem_addr[ADDRBITS-1:LSBBITS]	<=r_next_memory_region[ADDRBITS-1:LSBBITS];
								r_mem_addr[LSBBITS-1:0]		<='b0;
								r_mem_rdreq			<=1'b1;
								msr				<=MSR_FILLING;
								r_line_mem_wordlen		<=2'b10;
								r_line_mem_we			<=1'b0;
								r_line_mem_wraddr		<='d0-'d4;
								r_line_mem_in			<='h0;
								r_empty				<=1'b0;	// once the line has been filled, it is no longer empty
						end
			endcase
			r_cache_line_dirty		<=v_cache_line_dirty;
			
		end
	end
endmodule

