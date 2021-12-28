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
//



module	spram
#(
parameter	DATABITS=32,
parameter	ADDRBITS=9,
parameter	MEMSIZE=2**ADDRBITS
)

(
	input	[ADDRBITS-1:0]	addr,
	output	[DATABITS-1:0]	data_out,
	input	[DATABITS-1:0]	data_in,
	input		we,
	input		clk
);
	reg	[DATABITS-1:0]	memblock[MEMSIZE-1:0];
	always @(posedge clk)
	begin
		if (we)
		begin
			memblock[addr]<=data_in;
		end
	end
	assign data_out=memblock[addr];
endmodule



module	tb_dcache
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32
)
();
	// connection to the CPU
	reg	[ADDRBITS-1:0]		dcache_addr;
	reg	[DATABITS-1:0]		dcache_in;
	wire	[DATABITS-1:0]		dcache_out;	// 
	wire				dcache_valid;	//
	reg				dcache_rdreq;
	reg				dcache_wrreq;
	reg	[1:0]			dcache_wordlen;		// 0=byte; 1=halfword; 2=word

	wire				dcache_busy;

	// connection to the big memory
	wire	[ADDRBITS-1:0]		mem_addr;	//
	wire	[DATABITS-1:0]		mem_in;		//
	wire	[DATABITS-1:0]		mem_out;
	reg				mem_valid;
	wire				mem_rdreq;
	wire				mem_wrreq;

	// system control
	reg				reset_n;
	reg				clk;
	

	spram	SPRAM0
	(
		.addr		(mem_addr[10:2]),
		.data_out	(mem_out),
		.data_in	(mem_in),
		.we		(mem_wrreq),
		.clk		(clk)
	);
			
	dcache	
	#(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS)
	)
	DCACHE0(
		.dcache_addr	(dcache_addr),
		.dcache_in	(dcache_in),
		.dcache_out	(dcache_out),
		.dcache_valid	(dcache_valid),
		.dcache_rdreq	(dcache_rdreq),
		.dcache_wrreq	(dcache_wrreq),
		.dcache_wordlen	(dcache_wordlen),
		.dcache_busy	(dcache_busy),

		.mem_addr	(mem_addr),
		.mem_in		(mem_in),
		.mem_out	(mem_out),
		.mem_valid	(mem_valid),
		.mem_burstlen	(16'd1),
		.mem_rdreq	(mem_rdreq),
		.mem_wrreq	(mem_wrreq),

		.reset_n	(reset_n),
		.clk		(clk)		
	);

	always	#5	clk<=!clk;
	
	always	@(posedge clk)
	begin
		mem_valid<=mem_rdreq;
		if (dcache_valid)
		begin
			$display("dcache out: %08X",dcache_valid);
		end
	end

	initial begin
		#0	reset_n<=1'b1;clk<=1'b0;
			dcache_addr	<=32'h0;
			dcache_in	<=32'h0;
			dcache_rdreq	<=1'b0;
			dcache_wrreq	<=1'b0;
			dcache_wordlen	<=2'b10;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go!");

		#100	$display("write test");
		#10	dcache_addr	<=32'h00000080;dcache_in<=32'h0fff0001;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_wrreq	<=1'b0;
		#1000	dcache_addr	<=32'h00000080;dcache_in<=32'h0fff0001;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_addr	<=32'h00000084;dcache_in<=32'h0fff0002;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_addr	<=32'h00000088;dcache_in<=32'h0fff0003;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_addr	<=32'h0000008c;dcache_in<=32'h0fff0004;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		
		#10	dcache_addr	<=32'h00000090;dcache_in<=32'h0fff0011;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_addr	<=32'h00000094;dcache_in<=32'h0fff0012;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_addr	<=32'h00000098;dcache_in<=32'h0fff0013;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_addr	<=32'h0000009c;dcache_in<=32'h0fff0014;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		
		#10	dcache_addr	<=32'h000000a0;dcache_in<=32'h0fff0021;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_addr	<=32'h000000a4;dcache_in<=32'h0fff0022;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_addr	<=32'h000000a8;dcache_in<=32'h0fff0023;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_addr	<=32'h000000ac;dcache_in<=32'h0fff0024;dcache_wrreq<=1'b1;dcache_wordlen<=2'b10;
		#10	dcache_wrreq	<=1'b0;

		#100	$display("read test. expecting 0fff0001...0fff0010...0fff0024");
		#10	dcache_addr	<=32'h00000080;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h00000084;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h00000088;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h0000008c;dcache_rdreq<=1'b1;

		#10	dcache_addr	<=32'h00000090;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h00000094;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h00000098;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h0000009c;dcache_rdreq<=1'b1;

		#10	dcache_addr	<=32'h000000a0;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h000000a4;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h000000a8;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h000000ac;dcache_rdreq<=1'b1;
		#10	dcache_rdreq	<=1'b0;

		

		#1000	$finish();
	
	end
endmodule
