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


module	bigmem
#(
	parameter	ADDRBITS=10,
	parameter	DATABITS=32,
	parameter	MEMSIZE=(2**ADDRBITS)
)
(
	input	[ADDRBITS-1:0]	mem_addr,
	output	[DATABITS-1:0]	mem_out,
	output			mem_out_valid,
	input	[DATABITS-1:0]	mem_in,
	input			mem_wrreq,
	input			mem_rdreq,
	input			clk
);
	reg	[DATABITS-1:0]	remember[MEMSIZE-1:0];
	always	@(posedge clk)
	begin
		if (mem_wrreq)
		begin
			remember[mem_addr]<=mem_in;
		end
	end
	assign	mem_out_valid=mem_rdreq;
	assign	mem_out=remember[mem_addr];
endmodule
module tb_line
#(
	parameter	ADDRBITS=32,
	parameter	DATABITS=32,
	parameter	LSBBITS=7,
	parameter	MAXLSBVALUE=(2**LSBBITS-4),
	parameter	TTLBITS=8,
	parameter	MAXTTL=((2**TTLBITS)-1)
)
();
	reg	[ADDRBITS-1:0]		dcache_line_rdaddr;		//
	reg				dcache_line_rdreq;		//
	wire				dcache_line_out_valid;		//

	reg	[ADDRBITS-1:0]		dcache_line_wraddr;		//
	reg	[DATABITS-1:0]		dcache_line_in;			//
	reg	[WORDLENBITS-1:0]	dcache_line_in_wordlen;		//
	reg				dcache_line_wrreq;		//

	reg	[ADDRBITS-1:0]		icache_line_rdaddr;		//
	reg				icache_line_rdreq;		//
	wire				icache_line_out_valid;		//


	wire	[DATABITS-1:0]		cache_line_out;			// return value
	// connection to the controller
	wire				cache_line_dirty;		// =1 in case there has been a write request
	wire				cache_line_miss;		// // =1 if ALL of the requests failed
	reg				cache_line_flush;		//
	reg				cache_line_fill;		//
	reg				cache_line_pause;		// in case the memory controller is overloaded
	wire	[TTLBITS-1:0]		cache_line_ttl;			//
	reg	[ADDRBITS-1:0]		cache_new_region;		//
	wire				cache_line_ready;		//


	// connection to the memory
	wire	[ADDRBITS-1:0]		mem_addr;		//
	wire	[DATABITS-1:0]		mem_in;			//
	wire	[DATABITS-1:0]		mem_out;		//
	wire				mem_out_valid;		//
	wire				mem_wrreq;		//
	wire				mem_rdreq;		//

	// system 
	reg				reset_n;
	reg				clk;

	bigmem		BIGMEM0(
		.mem_addr			(mem_addr),
		.mem_in				(mem_in),
		.mem_out			(mem_out),
		.mem_out_valid			(mem_out_valid),
		.mem_wrreq			(mem_wrreq),
		.mem_rdreq			(mem_rdreq),

		.clk				(clk)
	);

	cache_line	CACHE_LINE0(
		.dcache_line_rdaddr		(dcache_line_rdaddr),
		.dcache_line_rdreq		(dcache_line_rdreq),
		.dcache_line_out_valid		(dcache_line_out_valid),

		.dcache_line_wraddr		(dcache_line_wraddr),
		.dcache_line_in			(dcache_line_in),
		.dcache_line_in_wordlen		(dcache_line_in_wordlen),
		.dcache_line_wrreq		(dcache_line_wrreq),

		.icache_line_rdaddr		(icache_line_rdaddr),
		.icache_line_rdreq		(icache_line_rdreq),
		.icache_line_out_valid		(icache_line_out_valid),

		.cache_line_out			(cache_line_out),
		.cache_line_dirty		(cache_line_dirty),
		.cache_line_miss		(cache_line_miss),
		.cache_line_flush		(cache_line_flush),
		.cache_line_fill		(cache_line_fill),
		.cache_line_pause		(cache_line_pause),
		.cache_line_ttl			(cache_line_ttl),
		.cache_new_region		(cache_new_region),
		.cache_line_ready		(cache_line_ready),

		.mem_addr			(mem_addr),
		.mem_in				(mem_in),
		.mem_out			(mem_out),
		.mem_out_valid			(mem_out_valid),
		.mem_wrreq			(mem_wrreq),
		.mem_rdreq			(mem_rdreq),

		.reset_n			(reset_n),
		.clk				(clk)
	);	

	always	@(posedge clk)
	begin
		if (dcache_line_out_valid) begin
			$display("DCACHE OUT: %08x",dcache_line_out);
		end
		if (icache_line_out_valid) begin
			$display("                      ICACHE OUT: %08x",icache_line_out);
		end
	end

	always	#5	clk<=!clk;

	initial begin
		#0	reset_n<=1'b1;clk<=1'b0;
			dcache_line_rdaddr<=32'h00000000;
			dcache_line_rdreq<=1'b0;
			dcache_line_wraddr<=32'h00000000;
			dcache_line_wrreq<=1'b0;
			dcache_line_in_wordlen<=2'b10;
			dcache_line_wrreq<=1'b0;
			icache_line_rdaddr<=32'h00000000;
			icache_line_rdreq<=1'b0;

			cache_line_flush<=1'b0;
			cache_line_fill<=1'b0;
			cache_line_pause<=1'b0;
			cache_new_region<=32'h0;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go");

		#1000	$finish();
	end
endmodule
