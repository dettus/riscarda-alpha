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
	reg	r_mem_out_valid;
	reg	[DATABITS-1:0]	r_mem_out;

	assign	mem_out=r_mem_out;
	assign	mem_out_valid=r_mem_out_valid;
	always	@(posedge clk)
	begin
		if (mem_wrreq) begin
			remember[mem_addr]<=mem_in;
			r_mem_out_valid<=1'b0;
		end else if (mem_rdreq) begin
			r_mem_out<=remember[mem_addr];
			r_mem_out_valid<=1'b1;
		end else begin
			r_mem_out_valid<=1'b1;
		end
	end
endmodule
module tb_line
#(
	parameter	ADDRBITS=32,
	parameter	DATABITS=32,
	parameter	LSBBITS=7,
	parameter	MAXLSBVALUE=(2**LSBBITS-4),
	parameter	MAXMISSBITS=8,
	parameter	MAXMISSCNT=((2**MAXMISSBITS)-1),
	parameter	WORDLENBITS=2
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
	wire	[MAXMISSBITS-1:0]		cache_line_misscnt;			//
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
		.mem_addr			(mem_addr[11:2]),
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
		.cache_line_misscnt			(cache_line_misscnt),
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
			$display("DCACHE OUT: %08x",cache_line_out);
		end
		if (icache_line_out_valid) begin
			$display("                      ICACHE OUT: %08x",cache_line_out);
		end
	end

	always	#5	clk<=!clk;

	initial begin
		$dumpfile("tb_line.vcd");
		$dumpvars(0);
		#0	reset_n<=1'b1;clk<=1'b0;
			dcache_line_rdaddr<=32'h00000000;
			dcache_line_rdreq<=1'b0;
			dcache_line_wraddr<=32'h00000000;
			dcache_line_wrreq<=1'b0;
			dcache_line_in<=32'h0;
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

		#200	$display("setting cached region to 80000000");
		#10	cache_line_fill<=1'b1;cache_new_region<=32'h80000000;
		#10	cache_line_fill<=1'b0;

		#1000	$display("filling memory address 80000000-8000003c with values 0fff0001-0fff0016");
		#10	dcache_line_wraddr<=32'h80000000;dcache_line_in<=32'h0fff0001;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h80000004;dcache_line_in<=32'h0fff0002;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h80000008;dcache_line_in<=32'h0fff0003;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h8000000c;dcache_line_in<=32'h0fff0004;dcache_line_wrreq<=1'b1;

		#10	dcache_line_wraddr<=32'h80000010;dcache_line_in<=32'h0fff0005;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h80000014;dcache_line_in<=32'h0fff0006;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h80000018;dcache_line_in<=32'h0fff0007;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h8000001c;dcache_line_in<=32'h0fff0008;dcache_line_wrreq<=1'b1;

		#10	dcache_line_wraddr<=32'h80000020;dcache_line_in<=32'h0fff0009;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h80000024;dcache_line_in<=32'h0fff0010;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h80000028;dcache_line_in<=32'h0fff0011;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h8000002c;dcache_line_in<=32'h0fff0012;dcache_line_wrreq<=1'b1;

		#10	dcache_line_wraddr<=32'h80000030;dcache_line_in<=32'h0fff0013;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h80000034;dcache_line_in<=32'h0fff0014;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h80000038;dcache_line_in<=32'h0fff0015;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=32'h8000003c;dcache_line_in<=32'h0fff0016;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wrreq<=1'b0;


		#400	$display("reading memory region 80000000-8000000c");
		#10	dcache_line_rdaddr<=32'h80000000;dcache_line_rdreq<=1'b1;
		#10	dcache_line_rdaddr<=32'h80000004;dcache_line_rdreq<=1'b1;
		#10	dcache_line_rdaddr<=32'h80000008;dcache_line_rdreq<=1'b1;
		#10	dcache_line_rdaddr<=32'h8000000c;dcache_line_rdreq<=1'b1;
		#10	dcache_line_rdreq<=1'b0;

		#100	$display("setting cached region to 12345678");
		#10	cache_line_flush<=1'b1;cache_line_fill<=1'b1;cache_new_region<=32'h12345678;
		#10	cache_line_flush<=1'b0;cache_line_fill<=1'b0;
		
		#500	$display("filling with values 00000000");
		#10	dcache_line_wraddr<=32'h12345600;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wraddr<=dcache_line_wraddr+'d4;dcache_line_in<=32'h00000000;dcache_line_wrreq<=1'b1;
		#10	dcache_line_wrreq<=1'b0;
		
		#500	$display("setting cached region to 80000000");
		#10	cache_line_flush<=1'b1;cache_line_fill<=1'b1;cache_new_region<=32'h80000000;
		#10	cache_line_flush<=1'b0;cache_line_fill<=1'b0;
	
		#4000	$display("reading memory region 80000010-8000001c");
		#10	icache_line_rdaddr<=32'h80000010;icache_line_rdreq<=1'b1;
		#10	icache_line_rdaddr<=32'h80000014;icache_line_rdreq<=1'b1;
		#10	icache_line_rdaddr<=32'h80000018;icache_line_rdreq<=1'b1;
		#10	icache_line_rdaddr<=32'h8000001c;icache_line_rdreq<=1'b1;
		#10	icache_line_rdreq<=1'b0;

		#1000	$display("reading the wrong adress");
		#10	icache_line_rdaddr<=32'h40000010;icache_line_rdreq<=1'b1;
		#10	icache_line_rdaddr<=32'h40000014;icache_line_rdreq<=1'b1;
		#10	icache_line_rdaddr<=32'h40000018;icache_line_rdreq<=1'b1;
		#10	icache_line_rdaddr<=32'h4000001c;icache_line_rdreq<=1'b1;
		#10	icache_line_rdreq<=1'b0;




		#1000	$finish();
	end
endmodule
