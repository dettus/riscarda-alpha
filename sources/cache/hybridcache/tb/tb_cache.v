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

module tb_cache
#(
	parameter	ADDRBITS=32,
	parameter	DATABITS=32,
	parameter	WORDLENBITS=2
)
();

	// data cache connection, read
	reg	[ADDRBITS-1:0]		dcache_rdaddr;		//
	reg				dcache_rdreq;		//
	wire	[DATABITS-1:0]		dcache_out;		//
	wire				dcache_out_valid;	//
	wire				dcache_rd_ready;	//

	// data cache connection; write
	reg	[ADDRBITS-1:0]		dcache_wraddr;		//
	reg				dcache_wrreq;		//
	reg	[DATABITS-1:0]		dcache_in;		//
	reg	[WORDLENBITS-1:0]	dcache_in_wordlen;	//
	wire				dcache_wr_ready;	//
	

	// instruction cache connection; read
	reg	[ADDRBITS-1:0]		icache_rdaddr;		//
	reg				icache_rdreq;		//
	wire	[DATABITS-1:0]		icache_out;		//
	wire				icache_out_valid;	//
	wire				icache_rd_ready;	//

	reg				reset_n;
	reg				clk;


	wire	[ADDRBITS-1:0]		mem_addr;		//
	wire	[DATABITS-1:0]		mem_in;			//
	wire	[DATABITS-1:0]		mem_out;		//
	wire				mem_out_valid;		//
	wire				mem_wrreq;		//
	wire				mem_rdreq;		//


	bigmem		BIGMEM0(
		.mem_addr			(mem_addr[11:2]),
		.mem_in				(mem_in),
		.mem_out			(mem_out),
		.mem_out_valid			(mem_out_valid),
		.mem_wrreq			(mem_wrreq),
		.mem_rdreq			(mem_rdreq),

		.clk				(clk)
	);

	hybrid_cache	
	#(
		.ADDRBITS		(ADDRBITS),
		.DATABITS		(DATABITS),
		.WORDLENBITS		(WORDLENBITS)
	)
	HYBRID_CACHE0
	(
		.dcache_rdaddr		(dcache_rdaddr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_out		(dcache_out),
		.dcache_out_valid	(dcache_out_valid),
		.dcache_rd_ready	(dcache_rd_ready),

		.dcache_wraddr		(dcache_wraddr),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_in		(dcache_in),
		.dcache_in_wordlen	(dcache_in_wordlen),
		.dcache_wr_ready	(dcache_wr_ready),

		.icache_rdaddr		(icache_rdaddr),
		.icache_rdreq		(icache_rdreq),
		.icache_out		(icache_out),
		.icache_out_valid	(icache_out_valid),
		.icache_rd_ready	(icache_rd_ready),

		.mem_addr		(mem_addr),
		.mem_in			(mem_in),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_wrreq		(mem_wrreq),
		.mem_rdreq		(mem_rdreq),
		
		.reset_n		(reset_n),
		.clk			(clk)
	);	


	always	@(posedge clk)
	begin
		if (dcache_out_valid) begin
			$display("DCACHE OUT: %08x",dcache_out);
		end
		if (icache_out_valid) begin
			$display("                      ICACHE OUT: %08x",icache_out);
		end
	end

	always	#5	clk<=!clk;
	initial begin
		$dumpfile("tb_cache.vcd");
		$dumpvars(0);
		#0	reset_n<=1'b1;clk<=1'b0;
			dcache_rdaddr		<=32'h0;
			dcache_rdreq		<=1'b0;
			dcache_wraddr		<=32'h0;
			dcache_wrreq		<=1'b0;
			dcache_in		<=32'h0;
			dcache_in_wordlen	<=2'b10;
			icache_rdaddr		<=32'h0;
			icache_rdreq		<=1'b0;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go!");

		#100	$display("write test. writing 0fff0001... 0fff0004 to 80000000..8000000c");
		#10	dcache_wraddr<=32'h80000000;dcache_in<=32'h0fff0001;dcache_wrreq<=1'b1;
		#10	dcache_wraddr<=32'h80000004;dcache_in<=32'h0fff0002;dcache_wrreq<=1'b1;
		#10	dcache_wraddr<=32'h80000008;dcache_in<=32'h0fff0003;dcache_wrreq<=1'b1;
		#10	dcache_wraddr<=32'h8000000c;dcache_in<=32'h0fff0004;dcache_wrreq<=1'b1;
		#10	dcache_wrreq<=1'b0;

		#4000	$finish();

	end
endmodule
