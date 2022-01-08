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
	input	[ADDRBITS-1:0]		dcache_rdaddr,		//
	input				dcache_rdreq,		//
	output	[DATABITS-1:0]		dcache_out,		//
	output				dcache_out_valid,	//
	output				dcache_rd_ready,	//

	// data cache connection, write
	input	[ADDRBITS-1:0]		dcache_wraddr,		//
	input				dcache_wrreq,		//
	input	[DATABITS-1:0]		dcache_in,		//
	input	[WORDLENBITS-1:0]	dcache_in_wordlen,	//
	output				dcache_wr_ready,	//
	

	// instruction cache connection, read
	input	[ADDRBITS-1:0]		icache_rdaddr,		//
	input				icache_rdreq,		//
	output	[DATABITS-1:0]		icache_out,		//
	output				icache_out_valid,	//
	output				icache_rd_ready,	//

	// connection to the memory
	output	[ADDRBITS-1:0]		mem_addr,		//
	output	[DATABITS-1:0]		mem_in,			//
	input	[DATABITS-1:0]		mem_out,		//
	input				mem_out_valid,		//
	output				mem_wrreq,		//
	output				mem_rdreq,		//

	// system 
	input				reset_n,		//
	input				clk			//
);

	wire	[ADDRBITS-1:0]		queue_dcache_rd_addr;
	wire	[ADDRBITS-1:0]		queue_dcache_wr_addr;
	wire	[DATABITS-1:0]		queue_dcache_wr_in;
	wire	[WORDLENBITS-1:0]	queue_dcache_wr_wordlen;
	wire	[ADDRBITS-1:0]		queue_icache_rd_addr;

	reg	queue_dcache_rd_push;
	reg	queue_dcache_wr_push;
	reg	queue_icache_rd_push;

	reg	queue_dcache_rd_pop;
	reg	queue_dcache_wr_pop;
	reg	queue_icache_rd_pop;

	wire	queue_dcache_rd_warning;
	wire	queue_dcache_wr_warning;
	wire	queue_icache_rd_warning;

	reg	queue_dcache_rd_req;
	reg	queue_dcache_wr_req;
	reg	queue_icache_rd_req;

	wire	[NUM_CACHELINES-1:0]	dcache_line_out_valid;
	wire	[NUM_CACHELINES-1:0]	dcache_line_hit;	// FIXME: possible racing condition. split it up into cache_line_hit_rd and cache_line_hit_wr
	wire	[NUM_CACHELINES-1:0]	icache_line_out_valid;
	wire	[NUM_CACHELINES-1:0]	icache_line_hit;

	wire	[DATABITS-1:0]		cache_line_out0;
	wire	[DATABITS-1:0]		cache_line_out1;
	wire	[DATABITS-1:0]		cache_line_out2;
	wire	[DATABITS-1:0]		cache_line_out3;
	wire	[DATABITS-1:0]		cache_line_out4;
	wire	[DATABITS-1:0]		cache_line_out5;
	wire	[DATABITS-1:0]		cache_line_out6;
	wire	[DATABITS-1:0]		cache_line_out7;

	wire	[NUM_CACHELINES-1:0]	cache_line_dirty;
	wire	[NUM_CACHELINES-1:0]	cache_line_hit;
	reg	[NUM_CACHELINES-1:0]	cache_line_flush;
	reg	[NUM_CACHELINES-1:0]	cache_line_fill;
	reg	[NUM_CACHELINES-1:0]	cache_line_pause;

	wire	[MAXHITBITS-1:0]	cache_line_hitcnt0;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt1;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt2;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt3;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt4;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt5;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt7;

	reg	[ADDRBITS-1:0]		cache_new_region;
	wire	[NUM_CACHELINES-1:0]	cache_line_ready;

	reg	[ADDRBITS-1:0]		r_mem_addr;
	wire	[ADDRBITS-1:0]		mem_addr0;
	wire	[ADDRBITS-1:0]		mem_addr1;
	wire	[ADDRBITS-1:0]		mem_addr2;
	wire	[ADDRBITS-1:0]		mem_addr3;
	wire	[ADDRBITS-1:0]		mem_addr4;
	wire	[ADDRBITS-1:0]		mem_addr5;
	wire	[ADDRBITS-1:0]		mem_addr7;

	reg	[DATABITS-1:0]		r_mem_in;
	wire	[DATABITS-1:0]		mem_in0;
	wire	[DATABITS-1:0]		mem_in1;
	wire	[DATABITS-1:0]		mem_in2;
	wire	[DATABITS-1:0]		mem_in3;
	wire	[DATABITS-1:0]		mem_in4;
	wire	[DATABITS-1:0]		mem_in5;
	wire	[DATABITS-1:0]		mem_in6;
	wire	[DATABITS-1:0]		mem_in7;

	reg				r_mem_wrreq;
	reg				r_mem_rdreq;
	wire	[NUM_CACHELINES-1:0]	int_mem_wrreq;
	wire	[NUM_CACHELINES-1:0]	int_mem_rdreq;

	reg	[MAXHITSBITS-1:0]	v_candidate_hitcnt;
	reg	[NUM_CACHELINES-1:0]	v_candidate_fill;

	reg	[NUM_CACHELINES-1:0]	readymask;

	localparam	[1:0]	MSR_NORMAL=2'b00,MSR_REQUEST_SENT=2'b01,MSR_WAIT_FOR_FINISH=2'b10;
	reg	[1:0]		msr;
	

	assign	dcache_rd_ready=!queue_dcache_rd_warning;
	assign	dcache_wr_ready=!queue_dcache_wr_warning;
	assign	icache_rd_ready=!queue_icache_rd_warning;

	

	myqueue	#(
		.DATABITS		(ADDRBITS)
	) QUEUE_DCACHE_RD (
		.queue_in		(dcache_rdaddr),
		.queue_push		(queue_dcache_rd_push|(queue_dcache_rd_not_empty&dcache_rdreq)),
		.queue_warning		(queue_dcache_rd_warning),
		.queue_pop		(queue_dcache_rd_pop),
		.queue_out		(queue_dcache_rd_addr),
		.queue_not_empty	(queue_dcache_rd_not_empty),
		.reset_n		(reset_n),
		.clk			(clk)
	);

	myqueue	#(
		.DATABITS		(ADDRBITS+DATABITS+WORDLENBITS)
	) QUEUE_DCACHE_WR (
		.queue_in		({dcache_wraddr,dcache_in,dcache_in_wordlen}),
		.queue_push		(queue_dcache_wr_push|(queue_dcache_wr_not_empty&dcache_wrreq)),
		.queue_warning		(queue_dcache_wr_warning),
		.queue_pop		(queue_dcache_wr_pop),
		.queue_out		({queue_dcache_wr_addr,queue_dcache_wr_in,queue_dcache_wr_wordlen),
		.queue_not_empty	(queue_dcache_wr_not_empty),
		.reset_n		(reset_n),
		.clk			(clk)
	);

	myqueue	#(
		.DATABITS		(ADDRBITS)
	) QUEUE_ICACHE_RD (
		.queue_in		(icache_rdaddr),
		.queue_push		(queue_icache_rd_push|(queue_icache_rd_not_empty&icache_rdreq)),
		.queue_warning		(queue_icache_rd_warning),
		.queue_pop		(queue_icache_rd_pop),
		.queue_out		(queue_icache_rd_addr),
		.queue_not_empty	(queue_icache_rd_not_empty),
		.reset_n		(reset_n),
		.clk			(clk)
	);


	hybrid_cache_line
	#(
		.ADDRBITS		(ADDRBITS),
		.DATABITS		(DATABITS),
		.MAXHITBITS		(MAXHITBITS),
		.WORDLENBITS		(WORDLENBITS)
	) CACHE_LINE0 (
		.dcache_line_rdaddr	(queue_dcache_rd_not_empty?queue_dcache_rd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_dcache_rd_not_empty?queue_dcache_rd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[0]),
		.dcache_line_hit	(dcache_line_hit[0]),

		.dcache_line_wraddr	(queue_dcache_wr_not_empty?queue_dcache_wr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dcache_wr_not_empty?queue_dcache_wr_in:dcache_line_in),
		.dcache_line_in_wordlen	(queue_dcache_wr_not_empty?queue_dcache_wr_wordlen:dcache_line_in_wordlen),
		.dcache_line_wrreq	(queue_dcache_wr_not_empty?queue_dcache_wr_req:dcache_wrreq),

		.icache_line_rdaddr	(queue_icache_rd_not_empty?queue_icache_rd_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_icache_rd_not_empty?queue_icache_rd_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[0]),
		.icache_line_hit	(icache_line_hit[0]),


		.cache_line_out		(cache_line_out0),
		.cache_line_dirty	(cache_line_dirty[0]),
		.cache_line_hit		(cache_line_hit[0]),
		.cache_line_flush	(cache_line_flush[0]),
		.cache_line_fill	(cache_line_fill[0]),
		.cache_line_pause	(cache_line_pause[0]),
		.cache_line_hitcnt	(cache_line_hitcnt0),
		.cache_new_region	(cache_new_region),
		.cache_line_ready	(cache_line_ready[0]),
		
		.mem_addr		(mem_addr0),
		.mem_in			(mem_in0),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_wrreq		(int_mem_wrreq[0]),
		.mem_rdreq		(int_mem_rdreq[0]),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	hybrid_cache_line
	#(
		.ADDRBITS		(ADDRBITS),
		.DATABITS		(DATABITS),
		.MAXHITBITS		(MAXHITBITS),
		.WORDLENBITS		(WORDLENBITS)
	) CACHE_LINE1 (
		.dcache_line_rdaddr	(queue_dcache_rd_not_empty?queue_dcache_rd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_dcache_rd_not_empty?queue_dcache_rd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[1]),
		.dcache_line_hit	(dcache_line_hit[1]),

		.dcache_line_wraddr	(queue_dcache_wr_not_empty?queue_dcache_wr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dcache_wr_not_empty?queue_dcache_wr_in:dcache_line_in),
		.dcache_line_in_wordlen	(queue_dcache_wr_not_empty?queue_dcache_wr_wordlen:dcache_line_in_wordlen),
		.dcache_line_wrreq	(queue_dcache_wr_not_empty?queue_dcache_wr_req:dcache_wrreq),

		.icache_line_rdaddr	(queue_icache_rd_not_empty?queue_icache_rd_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_icache_rd_not_empty?queue_icache_rd_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[1]),
		.icache_line_hit	(icache_line_hit[1]),


		.cache_line_out		(cache_line_out1),
		.cache_line_dirty	(cache_line_dirty[1]),
		.cache_line_hit		(cache_line_hit[1]),
		.cache_line_flush	(cache_line_flush[1]),
		.cache_line_fill	(cache_line_fill[1]),
		.cache_line_pause	(cache_line_pause[1]),
		.cache_line_hitcnt	(cache_line_hitcnt1),
		.cache_new_region	(cache_new_region),
		.cache_line_ready	(cache_line_ready[1]),
		
		.mem_addr		(mem_addr1),
		.mem_in			(mem_in1),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_wrreq		(int_mem_wrreq[1]),
		.mem_rdreq		(int_mem_rdreq[1]),

		.reset_n		(reset_n),
		.clk			(clk)
	);


	hybrid_cache_line
	#(
		.ADDRBITS		(ADDRBITS),
		.DATABITS		(DATABITS),
		.MAXHITBITS		(MAXHITBITS),
		.WORDLENBITS		(WORDLENBITS)
	) CACHE_LINE2 (
		.dcache_line_rdaddr	(queue_dcache_rd_not_empty?queue_dcache_rd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_dcache_rd_not_empty?queue_dcache_rd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[2]),
		.dcache_line_hit	(dcache_line_hit[2]),

		.dcache_line_wraddr	(queue_dcache_wr_not_empty?queue_dcache_wr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dcache_wr_not_empty?queue_dcache_wr_in:dcache_line_in),
		.dcache_line_in_wordlen	(queue_dcache_wr_not_empty?queue_dcache_wr_wordlen:dcache_line_in_wordlen),
		.dcache_line_wrreq	(queue_dcache_wr_not_empty?queue_dcache_wr_req:dcache_wrreq),

		.icache_line_rdaddr	(queue_icache_rd_not_empty?queue_icache_rd_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_icache_rd_not_empty?queue_icache_rd_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[2]),
		.icache_line_hit	(icache_line_hit[2]),


		.cache_line_out		(cache_line_out2),
		.cache_line_dirty	(cache_line_dirty[2]),
		.cache_line_hit		(cache_line_hit[2]),
		.cache_line_flush	(cache_line_flush[2]),
		.cache_line_fill	(cache_line_fill[2]),
		.cache_line_pause	(cache_line_pause[2]),
		.cache_line_hitcnt	(cache_line_hitcnt2),
		.cache_new_region	(cache_new_region),
		.cache_line_ready	(cache_line_ready[2]),
		
		.mem_addr		(mem_addr2),
		.mem_in			(mem_in2),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_wrreq		(int_mem_wrreq[2]),
		.mem_rdreq		(int_mem_rdreq[2]),

		.reset_n		(reset_n),
		.clk			(clk)
	);


	hybrid_cache_line
	#(
		.ADDRBITS		(ADDRBITS),
		.DATABITS		(DATABITS),
		.MAXHITBITS		(MAXHITBITS),
		.WORDLENBITS		(WORDLENBITS)
	) CACHE_LINE3 (
		.dcache_line_rdaddr	(queue_dcache_rd_not_empty?queue_dcache_rd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_dcache_rd_not_empty?queue_dcache_rd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[3]),
		.dcache_line_hit	(dcache_line_hit[3]),

		.dcache_line_wraddr	(queue_dcache_wr_not_empty?queue_dcache_wr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dcache_wr_not_empty?queue_dcache_wr_in:dcache_line_in),
		.dcache_line_in_wordlen	(queue_dcache_wr_not_empty?queue_dcache_wr_wordlen:dcache_line_in_wordlen),
		.dcache_line_wrreq	(queue_dcache_wr_not_empty?queue_dcache_wr_req:dcache_wrreq),

		.icache_line_rdaddr	(queue_icache_rd_not_empty?queue_icache_rd_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_icache_rd_not_empty?queue_icache_rd_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[3]),
		.icache_line_hit	(icache_line_hit[3]),


		.cache_line_out		(cache_line_out3),
		.cache_line_dirty	(cache_line_dirty[3]),
		.cache_line_hit		(cache_line_hit[3]),
		.cache_line_flush	(cache_line_flush[3]),
		.cache_line_fill	(cache_line_fill[3]),
		.cache_line_pause	(cache_line_pause[3]),
		.cache_line_hitcnt	(cache_line_hitcnt3),
		.cache_new_region	(cache_new_region),
		.cache_line_ready	(cache_line_ready[3]),
		
		.mem_addr		(mem_addr3),
		.mem_in			(mem_in3),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_wrreq		(int_mem_wrreq[3]),
		.mem_rdreq		(int_mem_rdreq[3]),

		.reset_n		(reset_n),
		.clk			(clk)
	);


	hybrid_cache_line
	#(
		.ADDRBITS		(ADDRBITS),
		.DATABITS		(DATABITS),
		.MAXHITBITS		(MAXHITBITS),
		.WORDLENBITS		(WORDLENBITS)
	) CACHE_LINE4 (
		.dcache_line_rdaddr	(queue_dcache_rd_not_empty?queue_dcache_rd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_dcache_rd_not_empty?queue_dcache_rd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[4]),
		.dcache_line_hit	(dcache_line_hit[4]),

		.dcache_line_wraddr	(queue_dcache_wr_not_empty?queue_dcache_wr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dcache_wr_not_empty?queue_dcache_wr_in:dcache_line_in),
		.dcache_line_in_wordlen	(queue_dcache_wr_not_empty?queue_dcache_wr_wordlen:dcache_line_in_wordlen),
		.dcache_line_wrreq	(queue_dcache_wr_not_empty?queue_dcache_wr_req:dcache_wrreq),

		.icache_line_rdaddr	(queue_icache_rd_not_empty?queue_icache_rd_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_icache_rd_not_empty?queue_icache_rd_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[4]),
		.icache_line_hit	(icache_line_hit[4]),


		.cache_line_out		(cache_line_out4),
		.cache_line_dirty	(cache_line_dirty[4]),
		.cache_line_hit		(cache_line_hit[4]),
		.cache_line_flush	(cache_line_flush[4]),
		.cache_line_fill	(cache_line_fill[4]),
		.cache_line_pause	(cache_line_pause[4]),
		.cache_line_hitcnt	(cache_line_hitcnt4),
		.cache_new_region	(cache_new_region),
		.cache_line_ready	(cache_line_ready[4]),
		
		.mem_addr		(mem_addr4),
		.mem_in			(mem_in4),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_wrreq		(int_mem_wrreq[4]),
		.mem_rdreq		(int_mem_rdreq[4]),

		.reset_n		(reset_n),
		.clk			(clk)
	);


	hybrid_cache_line
	#(
		.ADDRBITS		(ADDRBITS),
		.DATABITS		(DATABITS),
		.MAXHITBITS		(MAXHITBITS),
		.WORDLENBITS		(WORDLENBITS)
	) CACHE_LINE5 (
		.dcache_line_rdaddr	(queue_dcache_rd_not_empty?queue_dcache_rd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_dcache_rd_not_empty?queue_dcache_rd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[5]),
		.dcache_line_hit	(dcache_line_hit[5]),

		.dcache_line_wraddr	(queue_dcache_wr_not_empty?queue_dcache_wr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dcache_wr_not_empty?queue_dcache_wr_in:dcache_line_in),
		.dcache_line_in_wordlen	(queue_dcache_wr_not_empty?queue_dcache_wr_wordlen:dcache_line_in_wordlen),
		.dcache_line_wrreq	(queue_dcache_wr_not_empty?queue_dcache_wr_req:dcache_wrreq),

		.icache_line_rdaddr	(queue_icache_rd_not_empty?queue_icache_rd_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_icache_rd_not_empty?queue_icache_rd_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[5]),
		.icache_line_hit	(icache_line_hit[5]),


		.cache_line_out		(cache_line_out5),
		.cache_line_dirty	(cache_line_dirty[5]),
		.cache_line_hit		(cache_line_hit[5]),
		.cache_line_flush	(cache_line_flush[5]),
		.cache_line_fill	(cache_line_fill[5]),
		.cache_line_pause	(cache_line_pause[5]),
		.cache_line_hitcnt	(cache_line_hitcnt5),
		.cache_new_region	(cache_new_region),
		.cache_line_ready	(cache_line_ready[5]),
		
		.mem_addr		(mem_addr5),
		.mem_in			(mem_in5),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_wrreq		(int_mem_wrreq[5]),
		.mem_rdreq		(int_mem_rdreq[5]),

		.reset_n		(reset_n),
		.clk			(clk)
	);


	hybrid_cache_line
	#(
		.ADDRBITS		(ADDRBITS),
		.DATABITS		(DATABITS),
		.MAXHITBITS		(MAXHITBITS),
		.WORDLENBITS		(WORDLENBITS)
	) CACHE_LINE6 (
		.dcache_line_rdaddr	(queue_dcache_rd_not_empty?queue_dcache_rd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_dcache_rd_not_empty?queue_dcache_rd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[6]),
		.dcache_line_hit	(dcache_line_hit[6]),

		.dcache_line_wraddr	(queue_dcache_wr_not_empty?queue_dcache_wr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dcache_wr_not_empty?queue_dcache_wr_in:dcache_line_in),
		.dcache_line_in_wordlen	(queue_dcache_wr_not_empty?queue_dcache_wr_wordlen:dcache_line_in_wordlen),
		.dcache_line_wrreq	(queue_dcache_wr_not_empty?queue_dcache_wr_req:dcache_wrreq),

		.icache_line_rdaddr	(queue_icache_rd_not_empty?queue_icache_rd_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_icache_rd_not_empty?queue_icache_rd_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[6]),
		.icache_line_hit	(icache_line_hit[6]),


		.cache_line_out		(cache_line_out6),
		.cache_line_dirty	(cache_line_dirty[6]),
		.cache_line_hit		(cache_line_hit[6]),
		.cache_line_flush	(cache_line_flush[6]),
		.cache_line_fill	(cache_line_fill[6]),
		.cache_line_pause	(cache_line_pause[6]),
		.cache_line_hitcnt	(cache_line_hitcnt6),
		.cache_new_region	(cache_new_region),
		.cache_line_ready	(cache_line_ready[6]),
		
		.mem_addr		(mem_addr6),
		.mem_in			(mem_in6),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_wrreq		(int_mem_wrreq[6]),
		.mem_rdreq		(int_mem_rdreq[6]),

		.reset_n		(reset_n),
		.clk			(clk)
	);


	hybrid_cache_line
	#(
		.ADDRBITS		(ADDRBITS),
		.DATABITS		(DATABITS),
		.MAXHITBITS		(MAXHITBITS),
		.WORDLENBITS		(WORDLENBITS)
	) CACHE_LINE7 (
		.dcache_line_rdaddr	(queue_dcache_rd_not_empty?queue_dcache_rd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_dcache_rd_not_empty?queue_dcache_rd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[7]),
		.dcache_line_hit	(dcache_line_hit[7]),

		.dcache_line_wraddr	(queue_dcache_wr_not_empty?queue_dcache_wr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dcache_wr_not_empty?queue_dcache_wr_in:dcache_line_in),
		.dcache_line_in_wordlen	(queue_dcache_wr_not_empty?queue_dcache_wr_wordlen:dcache_line_in_wordlen),
		.dcache_line_wrreq	(queue_dcache_wr_not_empty?queue_dcache_wr_req:dcache_wrreq),

		.icache_line_rdaddr	(queue_icache_rd_not_empty?queue_icache_rd_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_icache_rd_not_empty?queue_icache_rd_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[7]),
		.icache_line_hit	(icache_line_hit[7]),


		.cache_line_out		(cache_line_out7),
		.cache_line_dirty	(cache_line_dirty[7]),
		.cache_line_hit		(cache_line_hit[7]),
		.cache_line_flush	(cache_line_flush[7]),
		.cache_line_fill	(cache_line_fill[7]),
		.cache_line_pause	(cache_line_pause[7]),
		.cache_line_hitcnt	(cache_line_hitcnt7),
		.cache_new_region	(cache_new_region),
		.cache_line_ready	(cache_line_ready[7]),
		
		.mem_addr		(mem_addr7),
		.mem_in			(mem_in7),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_wrreq		(int_mem_wrreq[7]),
		.mem_rdreq		(int_mem_rdreq[7]),

		.reset_n		(reset_n),
		.clk			(clk)
	);



	assign	mem_wrreq	=r_mem_wrreq;
	assign	mem_rdreq	=r_mem_rdreq;
	assign	mem_addr	=r_mem_addr;
	assign	mem_in		=r_mem_in;

	assign	dcache_out		=r_dcache_out;
	assign	dcache_out_valid	=r_dcache_out_valid;
	assign	icache_out		=r_icache_out;
	assign	icache_out_valid	=r_icache_out_valid;


	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			queue_dcache_rd_push		<=1'b0;
			queue_dcache_wr_push		<=1'b0;
			queue_icache_rd_push		<=1'b0;
			queue_dcache_rd_pop		<=1'b0;
			queue_dcache_wr_pop		<=1'b0;
			queue_icache_rd_pop		<=1'b0;
			queue_dcache_rd_req		<=1'b0;
			queue_dcache_wr_req		<=1'b0;
			queue_icache_rd_req		<=1'b0;

			cache_line_flush		<='b0;
			cache_line_fill			<='b0;
			cache_line_pause		<='b0;

			cache_new_region		<='h0;	

			msr				<=MSR_NORMAL;
			readymask			<='b0;
			popmask				<='b0;

			r_mem_wrreq			<=1'b0;
			r_mem_rdreq			<=1'b0;
			r_mem_addr			<=32'h0;
			r_mem_in			<=32'h0;

			r_dcache_out			<='h0;
			r_dcache_out_valid		<='b0;
			r_icache_out			<='h0;
			r_icache_out_valid		<='b0;
		end else begin

			// multiplex the memory access
			case ({int_mem_wrreq|int_mem_rdreq})
				8'b00000001:	begin	r_mem_wrreq<=int_mem_wrreq[0];r_mem_rdreq<=int_mem_rdreq[0];r_mem_addr<=mem_addr0;r_mem_in<=mem_in0;end
				8'b00000010:	begin	r_mem_wrreq<=int_mem_wrreq[1];r_mem_rdreq<=int_mem_rdreq[1];r_mem_addr<=mem_addr1;r_mem_in<=mem_in1;end
				8'b00000100:	begin	r_mem_wrreq<=int_mem_wrreq[2];r_mem_rdreq<=int_mem_rdreq[2];r_mem_addr<=mem_addr2;r_mem_in<=mem_in2;end
				8'b00001000:	begin	r_mem_wrreq<=int_mem_wrreq[3];r_mem_rdreq<=int_mem_rdreq[3];r_mem_addr<=mem_addr3;r_mem_in<=mem_in3;end
				8'b00010000:	begin	r_mem_wrreq<=int_mem_wrreq[4];r_mem_rdreq<=int_mem_rdreq[4];r_mem_addr<=mem_addr4;r_mem_in<=mem_in4;end
				8'b00100000:	begin	r_mem_wrreq<=int_mem_wrreq[5];r_mem_rdreq<=int_mem_rdreq[5];r_mem_addr<=mem_addr5;r_mem_in<=mem_in5;end
				8'b01000000:	begin	r_mem_wrreq<=int_mem_wrreq[6];r_mem_rdreq<=int_mem_rdreq[6];r_mem_addr<=mem_addr6;r_mem_in<=mem_in6;end
				8'b10000000:	begin	r_mem_wrreq<=int_mem_wrreq[7];r_mem_rdreq<=int_mem_rdreq[7];r_mem_addr<=mem_addr7;r_mem_in<=mem_in7;end

				default:	begin	r_mem_wrreq<=1'b0;r_mem_rdreq<=1'b0;end;
			endcase

			// multiplex the dcache output
			case (dcache_line_out_valid)
				8'b00000001:		begin	r_dcache_out<=cache_line_out0;r_dcache_out_valid<=1'b1;end	
				8'b00000010:		begin	r_dcache_out<=cache_line_out1;r_dcache_out_valid<=1'b1;end	
				8'b00000100:		begin	r_dcache_out<=cache_line_out2;r_dcache_out_valid<=1'b1;end	
				8'b00001000:		begin	r_dcache_out<=cache_line_out3;r_dcache_out_valid<=1'b1;end	
				8'b00010000:		begin	r_dcache_out<=cache_line_out4;r_dcache_out_valid<=1'b1;end	
				8'b00100000:		begin	r_dcache_out<=cache_line_out5;r_dcache_out_valid<=1'b1;end	
				8'b01000000:		begin	r_dcache_out<=cache_line_out6;r_dcache_out_valid<=1'b1;end	
				8'b10000000:		begin	r_dcache_out<=cache_line_out7;r_dcache_out_valid<=1'b1;end	
	
				default:		begin	r_dcache_out_valid<=1'b0;end
			endcase

			// multiplex the icache output
			case (icache_line_out_valid)
				8'b00000001:		begin	r_icache_out<=cache_line_out0;r_icache_out_valid<=1'b1;end	
				8'b00000010:		begin	r_icache_out<=cache_line_out1;r_icache_out_valid<=1'b1;end	
				8'b00000100:		begin	r_icache_out<=cache_line_out2;r_icache_out_valid<=1'b1;end	
				8'b00001000:		begin	r_icache_out<=cache_line_out3;r_icache_out_valid<=1'b1;end	
				8'b00010000:		begin	r_icache_out<=cache_line_out4;r_icache_out_valid<=1'b1;end	
				8'b00100000:		begin	r_icache_out<=cache_line_out5;r_icache_out_valid<=1'b1;end	
				8'b01000000:		begin	r_icache_out<=cache_line_out6;r_icache_out_valid<=1'b1;end	
				8'b10000000:		begin	r_icache_out<=cache_line_out7;r_icache_out_valid<=1'b1;end	
	
				default:		begin	r_icache_out_valid<=1'b0;end
			endcase

			// the cahce line with the lowest hitcnt is the one which will be flushed/filled next time.
			// TODO: Rewrite it as a tree
			v_candidate_hitcnt		=cache_line_hitcnt0;
			v_candidate_fill		=8'b00000001;

			if (cache_line_hitcnt1<v_candidate_hitcnt)
			begin
				v_candidate_hitcnt		=cache_line_hitcnt1;
				v_candidate_fill		=8'b00000010;
			end
			if (cache_line_hitcnt2<v_candidate_hitcnt)
			begin
				v_candidate_hitcnt		=cache_line_hitcnt2;
				v_candidate_fill		=8'b00000100;
			end
			if (cache_line_hitcnt3<v_candidate_hitcnt)
			begin
				v_candidate_hitcnt		=cache_line_hitcnt3;
				v_candidate_fill		=8'b00001000;
			end
			if (cache_line_hitcnt4<v_candidate_hitcnt)
			begin
				v_candidate_hitcnt		=cache_line_hitcnt4;
				v_candidate_fill		=8'b00010000;
			end
			if (cache_line_hitcnt5<v_candidate_hitcnt)
			begin
				v_candidate_hitcnt		=cache_line_hitcnt5;
				v_candidate_fill		=8'b00100000;
			end
			if (cache_line_hitcnt6<v_candidate_hitcnt)
			begin
				v_candidate_hitcnt		=cache_line_hitcnt6;
				v_candidate_fill		=8'b01000000;
			end
			if (cache_line_hitcnt7<v_candidate_hitcnt)
			begin
				v_candidate_hitcnt		=cache_line_hitcnt7;
				v_candidate_fill		=8'b10000000;
			end
			// at this point, v_candidate_fill and v_candidate flush cann become
			// cache_line_flush	<=cache_line_dirty&v_candidate_fill;
			// cache_line_fill	<=v_candidate_fill;


			// in case a request came, but there was no hit on any cache line: queue it.
			queue_dcache_rd_push<=(dcache_rdreq & dcache_line_hit=='b0);
			queue_dcache_wr_push<=(dcache_wrreq & dcache_line_hit=='b0);
			queue_icache_rd_push<=(icache_rdreq & icache_line_hit=='b0);


			case (msr)
				MSR_NORMAL:	begin
							queue_dcache_rd_pop		<=1'b0;
							queue_dcache_wr_pop		<=1'b0;
							queue_icache_rd_pop		<=1'b0;
							if (queue_dcache_rd_not_empty)
							begin
								cache_new_region	<=queue_dcache_rd_addr;
							end else if (queue_dcache_wr_not_empty)
							begin
								cache_new_region	<=queue_dcache_wr_addr;
							end else if (queue_icache_rd_not_empty)
							begin
								cache_new_region	<=queue_icache_rd_addr;
							end
							if (queue_dcache_rd_not_empty|queue_dcache_wr_not_empty|queue_icache_rd_not_empty)
							begin
								msr			<=MSR_REQUEST_SENT;
								cache_line_flush	<=cache_line_dirty&v_candidate_fill;
								cache_line_fill		<=v_candidate_fill;
								readymask		<=v_candidate_fill;
							end
						end
				MSR_REQUEST_SENT:	begin
							cache_line_flush		<='b0;
							cache_line_fill			<='b0;
							if ((readymask&cache_line_ready)=='b0) begin	// wait until the cache line has acknowledged the request
								msr			<=MSR_WAIT_FOR_FINISH;
							end
						end
				MSR_WAIT_FOR_FINISH:	begin
							cache_line_flush		<='b0;
							cache_line_fill			<='b0;
							if ((readymask&cache_line_ready)!='b0) begin	// wait until the cache line has finished the request
								msr			<=MSR_NORMAL;
								queue_dcache_rd_pop	<=(queue_dcache_rd_not_empty & dcache_line_hit!='b0);
								queue_dcache_wr_pop	<=(queue_dcache_wr_not_empty & dcache_line_hit!='b0);
								queue_icache_rd_pop	<=(queue_icache_rd_not_empty & icache_line_hit!='b0);
							end
						end
			endcase	

		end
	end	
endmodule
