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

	
	wire				queue_drd_not_empty;
	wire	[NUM_CACHELINES-1:0]	dcache_line_rdhit;
	wire				queue_drd_warning;
	wire	[ADDRBITS-1:0]		queue_drd_addr;


	wire				queue_dwr_not_empty;
	wire	[NUM_CACHELINES-1:0]	dcache_line_wrhit;
	wire				queue_dwr_warning;
	wire	[ADDRBITS-1:0]		queue_dwr_addr;
	wire	[DATABITS-1:0]		queue_dwr_data;
	wire	[WORDLENBITS-1:0]	queue_dwr_wordlen;

	wire				queue_ird_not_empty;
	wire	[NUM_CACHELINES-1:0]	icache_line_rdhit;
	wire				queue_ird_warning;
	wire	[ADDRBITS-1:0]		queue_ird_addr;


	wire	[NUM_CACHELINES-1:0]	dcache_line_out_valid;
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

	wire	[NUM_CACHELINES-1:0]	icache_line_out_valid;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt0;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt1;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt2;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt3;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt4;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt5;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt6;
	wire	[MAXHITBITS-1:0]	cache_line_hitcnt7;
	wire	[NUM_CACHELINES-1:0]	cache_line_ready;
	
	wire	[ADDRBITS-1:0]		mem_addr0;
	wire	[ADDRBITS-1:0]		mem_addr1;
	wire	[ADDRBITS-1:0]		mem_addr2;
	wire	[ADDRBITS-1:0]		mem_addr3;
	wire	[ADDRBITS-1:0]		mem_addr4;
	wire	[ADDRBITS-1:0]		mem_addr5;
	wire	[ADDRBITS-1:0]		mem_addr6;
	wire	[ADDRBITS-1:0]		mem_addr7;

	wire	[DATABITS-1:0]		mem_in0;
	wire	[DATABITS-1:0]		mem_in1;
	wire	[DATABITS-1:0]		mem_in2;
	wire	[DATABITS-1:0]		mem_in3;
	wire	[DATABITS-1:0]		mem_in4;
	wire	[DATABITS-1:0]		mem_in5;
	wire	[DATABITS-1:0]		mem_in6;
	wire	[DATABITS-1:0]		mem_in7;

	wire	[NUM_CACHELINES-1:0]	int_mem_rdreq;
	wire	[NUM_CACHELINES-1:0]	int_mem_wrreq;
	


	

	reg	[NUM_CACHELINES-1:0]	cache_line_flush;
	reg	[NUM_CACHELINES-1:0]	cache_line_fill;
	reg	[NUM_CACHELINES-1:0]	cache_line_pause;
	reg	[ADDRBITS-1:0]		cache_new_region;
	reg				queue_drd_pop;
	reg				queue_dwr_pop;
	reg				queue_ird_pop;
	reg				queue_drd_req;
	reg				queue_dwr_req;
	reg				queue_ird_req;

	reg	[ADDRBITS-1:0]		r_mem_addr;
	reg	[DATABITS-1:0]		r_mem_in;
	reg				r_mem_wrreq;
	reg				r_mem_rdreq;

	reg	[MAXHITBITS-1:0]	v_min_cache_line_hitcnt;
	reg	[NUM_CACHELINES-1:0]	v_candidate;
	reg	[NUM_CACHELINES-1:0]	r_candidate;

	reg	[DATABITS-1:0]		r_dcache_out;
	reg				r_dcache_out_valid;
	reg	[DATABITS-1:0]		r_icache_out;
	reg				r_icache_out_valid;



	localparam	[2:0]	MSR_NORMAL=3'b000,MSR_CHECK=3'b001,MSR_WAIT_FOR_ACK=3'b010,MSR_WAIT_FOR_FINISH=3'b011,MSR_WAIT_FOR_POP=3'b111;
	reg	[2:0]		msr;
	assign	dcache_rd_ready=!queue_drd_warning;
	assign	dcache_wr_ready=!queue_dwr_warning;
	assign	icache_rd_ready=!queue_ird_warning;
	
	assign	mem_addr		=r_mem_addr;
	assign	mem_in			=r_mem_in;
	assign	mem_wrreq		=r_mem_wrreq;
	assign	mem_rdreq		=r_mem_rdreq;

	assign	dcache_out		=r_dcache_out;
	assign	dcache_out_valid	=r_dcache_out_valid;
	assign	icache_out		=r_icache_out;
	assign	icache_out_valid	=r_icache_out_valid;

	myqueue
	#(
		.DATABITS		(ADDRBITS)
	) HYBRID_CACHE_QUEUE_DRD (
		.queue_in		(dcache_rdaddr),
		.queue_push		(dcache_rdreq&(queue_drd_not_empty|(dcache_line_rdhit=='b0))),
		.queue_warning		(queue_drd_warning),

//		.queue_pop		(queue_drd_not_empty&queue_drd_req&(dcache_line_rdhit!='b0)),
		.queue_pop		(queue_drd_pop),
		.queue_out		(queue_drd_addr),
		.queue_not_empty	(queue_drd_not_empty),

		.reset_n		(reset_n),
		.clk			(clk)
	);


	myqueue
	#(
		.DATABITS		(ADDRBITS+DATABITS+WORDLENBITS)
	) HYBRID_CACHE_QUEUE_DWR (
		.queue_in		({dcache_wraddr,dcache_in,dcache_in_wordlen}),
		.queue_push		(dcache_wrreq&(queue_dwr_not_empty|(dcache_line_wrhit=='b0))),
		.queue_warning		(queue_dwr_warning),

	//	.queue_pop		(queue_dwr_not_empty&queue_dwr_req&(dcache_line_wrhit!='b0)),
		.queue_pop		(queue_dwr_pop),
		.queue_out		({queue_dwr_addr,queue_dwr_data,queue_dwr_wordlen}),
		.queue_not_empty	(queue_dwr_not_empty),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	myqueue
	#(
		.DATABITS		(ADDRBITS)
	) HYBRID_CACHE_QUEUE_IRD (
		.queue_in		(icache_rdaddr),
		.queue_push		(icache_rdreq&(queue_ird_not_empty|(icache_line_rdhit=='b0))),
		.queue_warning		(queue_ird_warning),

	//	.queue_pop		(queue_ird_not_empty&queue_ird_req&(icache_line_rdhit!='b0)),
		.queue_pop		(queue_ird_pop),
		.queue_out		(queue_ird_addr),
		.queue_not_empty	(queue_ird_not_empty),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	hybrid_cache_line
	#(
		.ADDRBITS		(ADDRBITS),
		.DATABITS		(DATABITS),
		.WORDLENBITS		(WORDLENBITS),
		.MAXHITBITS		(MAXHITBITS)
	)
	HYBRID_CACHE_LINE0
	(
		.dcache_line_rdaddr	(queue_drd_not_empty?queue_drd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_drd_not_empty?queue_drd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[0]),
		.dcache_line_rdhit	(dcache_line_rdhit[0]),

		.dcache_line_wraddr	(queue_dwr_not_empty?queue_dwr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dwr_not_empty?queue_dwr_data:dcache_in),
		.dcache_line_in_wordlen	(queue_dwr_not_empty?queue_dwr_wordlen:dcache_in_wordlen),
		.dcache_line_wrreq	(queue_dwr_not_empty?queue_dwr_req:dcache_wrreq),
		.dcache_line_wrhit	(dcache_line_wrhit[0]),

		.icache_line_rdaddr	(queue_ird_not_empty?queue_ird_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_ird_not_empty?queue_ird_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[0]),
		.icache_line_rdhit	(icache_line_rdhit[0]),

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
		.WORDLENBITS		(WORDLENBITS),
		.MAXHITBITS		(MAXHITBITS)
	)
	HYBRID_CACHE_LINE1
	(
		.dcache_line_rdaddr	(queue_drd_not_empty?queue_drd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_drd_not_empty?queue_drd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[1]),
		.dcache_line_rdhit	(dcache_line_rdhit[1]),

		.dcache_line_wraddr	(queue_dwr_not_empty?queue_dwr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dwr_not_empty?queue_dwr_data:dcache_in),
		.dcache_line_in_wordlen	(queue_dwr_not_empty?queue_dwr_wordlen:dcache_in_wordlen),
		.dcache_line_wrreq	(queue_dwr_not_empty?queue_dwr_req:dcache_wrreq),
		.dcache_line_wrhit	(dcache_line_wrhit[1]),

		.icache_line_rdaddr	(queue_ird_not_empty?queue_ird_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_ird_not_empty?queue_ird_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[1]),
		.icache_line_rdhit	(icache_line_rdhit[1]),

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
		.WORDLENBITS		(WORDLENBITS),
		.MAXHITBITS		(MAXHITBITS)
	)
	HYBRID_CACHE_LINE2
	(
		.dcache_line_rdaddr	(queue_drd_not_empty?queue_drd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_drd_not_empty?queue_drd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[2]),
		.dcache_line_rdhit	(dcache_line_rdhit[2]),

		.dcache_line_wraddr	(queue_dwr_not_empty?queue_dwr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dwr_not_empty?queue_dwr_data:dcache_in),
		.dcache_line_in_wordlen	(queue_dwr_not_empty?queue_dwr_wordlen:dcache_in_wordlen),
		.dcache_line_wrreq	(queue_dwr_not_empty?queue_dwr_req:dcache_wrreq),
		.dcache_line_wrhit	(dcache_line_wrhit[2]),

		.icache_line_rdaddr	(queue_ird_not_empty?queue_ird_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_ird_not_empty?queue_ird_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[2]),
		.icache_line_rdhit	(icache_line_rdhit[2]),

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
		.WORDLENBITS		(WORDLENBITS),
		.MAXHITBITS		(MAXHITBITS)
	)
	HYBRID_CACHE_LINE3
	(
		.dcache_line_rdaddr	(queue_drd_not_empty?queue_drd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_drd_not_empty?queue_drd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[3]),
		.dcache_line_rdhit	(dcache_line_rdhit[3]),

		.dcache_line_wraddr	(queue_dwr_not_empty?queue_dwr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dwr_not_empty?queue_dwr_data:dcache_in),
		.dcache_line_in_wordlen	(queue_dwr_not_empty?queue_dwr_wordlen:dcache_in_wordlen),
		.dcache_line_wrreq	(queue_dwr_not_empty?queue_dwr_req:dcache_wrreq),
		.dcache_line_wrhit	(dcache_line_wrhit[3]),

		.icache_line_rdaddr	(queue_ird_not_empty?queue_ird_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_ird_not_empty?queue_ird_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[3]),
		.icache_line_rdhit	(icache_line_rdhit[3]),

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
		.WORDLENBITS		(WORDLENBITS),
		.MAXHITBITS		(MAXHITBITS)
	)
	HYBRID_CACHE_LINE4
	(
		.dcache_line_rdaddr	(queue_drd_not_empty?queue_drd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_drd_not_empty?queue_drd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[4]),
		.dcache_line_rdhit	(dcache_line_rdhit[4]),

		.dcache_line_wraddr	(queue_dwr_not_empty?queue_dwr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dwr_not_empty?queue_dwr_data:dcache_in),
		.dcache_line_in_wordlen	(queue_dwr_not_empty?queue_dwr_wordlen:dcache_in_wordlen),
		.dcache_line_wrreq	(queue_dwr_not_empty?queue_dwr_req:dcache_wrreq),
		.dcache_line_wrhit	(dcache_line_wrhit[4]),

		.icache_line_rdaddr	(queue_ird_not_empty?queue_ird_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_ird_not_empty?queue_ird_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[4]),
		.icache_line_rdhit	(icache_line_rdhit[4]),

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
		.WORDLENBITS		(WORDLENBITS),
		.MAXHITBITS		(MAXHITBITS)
	)
	HYBRID_CACHE_LINE5
	(
		.dcache_line_rdaddr	(queue_drd_not_empty?queue_drd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_drd_not_empty?queue_drd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[5]),
		.dcache_line_rdhit	(dcache_line_rdhit[5]),

		.dcache_line_wraddr	(queue_dwr_not_empty?queue_dwr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dwr_not_empty?queue_dwr_data:dcache_in),
		.dcache_line_in_wordlen	(queue_dwr_not_empty?queue_dwr_wordlen:dcache_in_wordlen),
		.dcache_line_wrreq	(queue_dwr_not_empty?queue_dwr_req:dcache_wrreq),
		.dcache_line_wrhit	(dcache_line_wrhit[5]),

		.icache_line_rdaddr	(queue_ird_not_empty?queue_ird_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_ird_not_empty?queue_ird_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[5]),
		.icache_line_rdhit	(icache_line_rdhit[5]),

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
		.WORDLENBITS		(WORDLENBITS),
		.MAXHITBITS		(MAXHITBITS)
	)
	HYBRID_CACHE_LINE6
	(
		.dcache_line_rdaddr	(queue_drd_not_empty?queue_drd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_drd_not_empty?queue_drd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[6]),
		.dcache_line_rdhit	(dcache_line_rdhit[6]),

		.dcache_line_wraddr	(queue_dwr_not_empty?queue_dwr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dwr_not_empty?queue_dwr_data:dcache_in),
		.dcache_line_in_wordlen	(queue_dwr_not_empty?queue_dwr_wordlen:dcache_in_wordlen),
		.dcache_line_wrreq	(queue_dwr_not_empty?queue_dwr_req:dcache_wrreq),
		.dcache_line_wrhit	(dcache_line_wrhit[6]),

		.icache_line_rdaddr	(queue_ird_not_empty?queue_ird_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_ird_not_empty?queue_ird_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[6]),
		.icache_line_rdhit	(icache_line_rdhit[6]),

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
		.WORDLENBITS		(WORDLENBITS),
		.MAXHITBITS		(MAXHITBITS)
	)
	HYBRID_CACHE_LINE7
	(
		.dcache_line_rdaddr	(queue_drd_not_empty?queue_drd_addr:dcache_rdaddr),
		.dcache_line_rdreq	(queue_drd_not_empty?queue_drd_req:dcache_rdreq),
		.dcache_line_out_valid	(dcache_line_out_valid[7]),
		.dcache_line_rdhit	(dcache_line_rdhit[7]),

		.dcache_line_wraddr	(queue_dwr_not_empty?queue_dwr_addr:dcache_wraddr),
		.dcache_line_in		(queue_dwr_not_empty?queue_dwr_data:dcache_in),
		.dcache_line_in_wordlen	(queue_dwr_not_empty?queue_dwr_wordlen:dcache_in_wordlen),
		.dcache_line_wrreq	(queue_dwr_not_empty?queue_dwr_req:dcache_wrreq),
		.dcache_line_wrhit	(dcache_line_wrhit[7]),

		.icache_line_rdaddr	(queue_ird_not_empty?queue_ird_addr:icache_rdaddr),
		.icache_line_rdreq	(queue_ird_not_empty?queue_ird_req:icache_rdreq),
		.icache_line_out_valid	(icache_line_out_valid[7]),
		.icache_line_rdhit	(icache_line_rdhit[7]),

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

	// TODO: add a "non cached" line here

	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			cache_line_flush	<='b0;
			cache_line_fill		<='b0;
			cache_line_pause	<='b0;
			cache_new_region	<='h0;
			r_mem_addr		<='h0;
			r_mem_in		<='h0;
			r_mem_wrreq		<=1'b0;
			r_mem_rdreq		<=1'b0;
			r_candidate		<='b0;
			queue_drd_req		<=1'b0;
			queue_dwr_req		<=1'b0;
			queue_ird_req		<=1'b0;
			queue_drd_pop		<=1'b0;
			queue_dwr_pop		<=1'b0;
			queue_ird_pop		<=1'b0;

			r_dcache_out		<='h0;
			r_dcache_out_valid	<=1'b0;
			r_icache_out		<='h0;
			r_icache_out_valid	<=1'b0;
			msr			<=MSR_NORMAL;
		end else begin
			// in case there is no hit, find a candidate
			// it is the one with the lowest hit cnt
			v_min_cache_line_hitcnt	=cache_line_hitcnt0;
			v_candidate		=8'b00000001;

			// TODO: rewrite this as a tree
			if (v_min_cache_line_hitcnt>cache_line_hitcnt1)
			begin
				v_min_cache_line_hitcnt	=cache_line_hitcnt1;
				v_candidate		=8'b00000010;
			end
			if (v_min_cache_line_hitcnt>cache_line_hitcnt2)
			begin
				v_min_cache_line_hitcnt	=cache_line_hitcnt2;
				v_candidate		=8'b00000100;
			end
			if (v_min_cache_line_hitcnt>cache_line_hitcnt3)
			begin
				v_min_cache_line_hitcnt	=cache_line_hitcnt3;
				v_candidate		=8'b00001000;
			end
			if (v_min_cache_line_hitcnt>cache_line_hitcnt4)
			begin
				v_min_cache_line_hitcnt	=cache_line_hitcnt4;
				v_candidate		=8'b00010000;
			end
			if (v_min_cache_line_hitcnt>cache_line_hitcnt5)
			begin
				v_min_cache_line_hitcnt	=cache_line_hitcnt5;
				v_candidate		=8'b00100000;
			end
			if (v_min_cache_line_hitcnt>cache_line_hitcnt6)
			begin
				v_min_cache_line_hitcnt	=cache_line_hitcnt6;
				v_candidate		=8'b01000000;
			end
			if (v_min_cache_line_hitcnt>cache_line_hitcnt7)
			begin
				v_min_cache_line_hitcnt	=cache_line_hitcnt7;
				v_candidate		=8'b10000000;
			end

			// multiplex the memory requests
			case	(int_mem_wrreq|int_mem_rdreq)
				8'b00000001:	begin	r_mem_in<=mem_in0;r_mem_addr<=mem_addr0;r_mem_wrreq<=int_mem_wrreq[0];r_mem_rdreq<=int_mem_rdreq[0];end	
				8'b00000010:	begin	r_mem_in<=mem_in1;r_mem_addr<=mem_addr1;r_mem_wrreq<=int_mem_wrreq[1];r_mem_rdreq<=int_mem_rdreq[1];end	
				8'b00000100:	begin	r_mem_in<=mem_in2;r_mem_addr<=mem_addr2;r_mem_wrreq<=int_mem_wrreq[2];r_mem_rdreq<=int_mem_rdreq[2];end	
				8'b00001000:	begin	r_mem_in<=mem_in3;r_mem_addr<=mem_addr3;r_mem_wrreq<=int_mem_wrreq[3];r_mem_rdreq<=int_mem_rdreq[3];end	
				8'b00010000:	begin	r_mem_in<=mem_in4;r_mem_addr<=mem_addr4;r_mem_wrreq<=int_mem_wrreq[4];r_mem_rdreq<=int_mem_rdreq[4];end	
				8'b00100000:	begin	r_mem_in<=mem_in5;r_mem_addr<=mem_addr5;r_mem_wrreq<=int_mem_wrreq[5];r_mem_rdreq<=int_mem_rdreq[5];end	
				8'b01000000:	begin	r_mem_in<=mem_in6;r_mem_addr<=mem_addr6;r_mem_wrreq<=int_mem_wrreq[6];r_mem_rdreq<=int_mem_rdreq[6];end	
				8'b10000000:	begin	r_mem_in<=mem_in7;r_mem_addr<=mem_addr7;r_mem_wrreq<=int_mem_wrreq[7];r_mem_rdreq<=int_mem_rdreq[7];end	

				default:	begin	r_mem_wrreq<=1'b0;r_mem_rdreq<=1'b0;end
			endcase

			// demultiplex the dcache/icache outputs
			case (dcache_out_valid)
				8'b00000001:	begin	r_dcache_out<=cache_line_out0;r_dcache_out_valid<=1'b1;end
				8'b00000010:	begin	r_dcache_out<=cache_line_out1;r_dcache_out_valid<=1'b1;end
				8'b00000100:	begin	r_dcache_out<=cache_line_out2;r_dcache_out_valid<=1'b1;end
				8'b00001000:	begin	r_dcache_out<=cache_line_out3;r_dcache_out_valid<=1'b1;end
				8'b00010000:	begin	r_dcache_out<=cache_line_out4;r_dcache_out_valid<=1'b1;end
				8'b00100000:	begin	r_dcache_out<=cache_line_out5;r_dcache_out_valid<=1'b1;end
				8'b01000000:	begin	r_dcache_out<=cache_line_out6;r_dcache_out_valid<=1'b1;end
				8'b10000000:	begin	r_dcache_out<=cache_line_out7;r_dcache_out_valid<=1'b1;end

				default:	begin	r_dcache_out_valid<=1'b0;end
			endcase
			case (icache_out_valid)
				8'b00000001:	begin	r_icache_out<=cache_line_out0;r_icache_out_valid<=1'b1;end
				8'b00000010:	begin	r_icache_out<=cache_line_out1;r_icache_out_valid<=1'b1;end
				8'b00000100:	begin	r_icache_out<=cache_line_out2;r_icache_out_valid<=1'b1;end
				8'b00001000:	begin	r_icache_out<=cache_line_out3;r_icache_out_valid<=1'b1;end
				8'b00010000:	begin	r_icache_out<=cache_line_out4;r_icache_out_valid<=1'b1;end
				8'b00100000:	begin	r_icache_out<=cache_line_out5;r_icache_out_valid<=1'b1;end
				8'b01000000:	begin	r_icache_out<=cache_line_out6;r_icache_out_valid<=1'b1;end
				8'b10000000:	begin	r_icache_out<=cache_line_out7;r_icache_out_valid<=1'b1;end

				default:	begin	r_icache_out_valid<=1'b0;end
			endcase
			
			case (msr)
				MSR_WAIT_FOR_POP:begin
						queue_drd_pop	<=1'b0;
						queue_dwr_pop	<=1'b0;
						queue_ird_pop	<=1'b0;
						msr	<=MSR_NORMAL;
				end
				MSR_NORMAL:	begin
							// in case one of the request is queued, start the flush/fill operation
							queue_drd_pop	<=1'b0;
							queue_dwr_pop	<=1'b0;
							queue_ird_pop	<=1'b0;
							if (queue_drd_not_empty)
							begin
								cache_new_region	<=queue_drd_addr;
								msr			<=MSR_CHECK;
								queue_drd_req		<=1'b1;
								queue_dwr_req		<=1'b0;
								queue_ird_req		<=1'b0;
							end else if (queue_dwr_not_empty)
							begin
								cache_new_region	<=queue_dwr_addr;
								msr			<=MSR_CHECK;
								queue_drd_req		<=1'b0;
								queue_dwr_req		<=1'b1;
								queue_ird_req		<=1'b0;
							end else if (queue_ird_not_empty)
							begin
								cache_new_region	<=queue_ird_addr;
								msr			<=MSR_CHECK;
								queue_drd_req		<=1'b0;
								queue_dwr_req		<=1'b0;
								queue_ird_req		<=1'b1;
							end else begin
								queue_drd_req		<=1'b0;
								queue_dwr_req		<=1'b0;
								queue_ird_req		<=1'b0;
							end
						end
				MSR_CHECK:	begin
							queue_drd_req		<=1'b0;
							queue_dwr_req		<=1'b0;
							queue_ird_req		<=1'b0;
							// check if the pop was successful
							if (	(queue_drd_req&(dcache_line_rdhit=='b0))|
								(queue_dwr_req&(dcache_line_wrhit=='b0))|
								(queue_ird_req&(icache_line_rdhit=='b0)))
							begin	// no
								r_candidate		<=v_candidate;
								cache_line_fill		<=v_candidate;
								cache_line_flush	<=v_candidate&cache_line_dirty;
								msr	<=MSR_WAIT_FOR_ACK;
							end else begin	// yes
								queue_drd_pop	<=queue_drd_req;
								queue_dwr_pop	<=queue_dwr_req;
								queue_ird_pop	<=queue_ird_req;
								msr	<=MSR_WAIT_FOR_POP;	// yes: resume normal operation
							end
						end
				MSR_WAIT_FOR_ACK:	begin
							cache_line_fill		<='b0;
							cache_line_flush	<='b0;
							if ((cache_line_ready&r_candidate)=='b0)	// ready for the line went from high to low.
							begin
								msr	<=MSR_WAIT_FOR_FINISH;	
							end
						end
				MSR_WAIT_FOR_FINISH:	begin
							if ((cache_line_ready&r_candidate)!='b0)	// ready for the line went from low to high
							begin
								msr	<=MSR_NORMAL;	// resume normal operation
							end

						end
				endcase
			end
		end
endmodule
