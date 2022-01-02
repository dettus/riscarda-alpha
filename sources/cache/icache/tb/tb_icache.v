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
	input		reset_n

);
	reg	[DATABITS-1:0]	memblock[MEMSIZE-1:0];
	always @(negedge reset_n)
	begin
		$readmemh("romblock.hex",memblock);
	end
	assign data_out=memblock[addr];
endmodule

module	tb_icache
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32
)
();
	// connection to the CPU
	reg	[ADDRBITS-1:0]		icache_addr;
	wire	[DATABITS-1:0]		icache_out;	// 
	wire				icache_out_valid;	//
	reg				icache_rdreq;
	wire				icache_ready;


	wire	[ADDRBITS-1:0]	mem_addr;
	wire	[DATABITS-1:0]	mem_in;
	wire	[DATABITS-1:0]	mem_out;
	reg			mem_out_valid;
	wire			mem_rdreq;
	wire			mem_wrreq;
	wire	[15:0]		mem_burstlen;
	

	// system control lines
	reg			reset_n;
	reg			clk;


	icache	ICACHE0(
		.icache_addr		(icache_addr),
		.icache_out		(icache_out),
		.icache_out_valid	(icache_out_valid),
		.icache_rdreq		(icache_rdreq),
		.icache_ready		(icache_ready),

		.mem_addr		(mem_addr),
		.mem_in			(mem_in),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_rdreq		(mem_rdreq),
		.mem_wrreq		(mem_wrreq),
		.mem_burstlen		(16'd1),

		.reset_n		(reset_n),
		.clk			(clk)
	);
	spram	SPRAM0
	(
		.addr			(mem_addr[10:2]),
		.data_out		(mem_out),
		.reset_n		(reset_n)
	);

	always	@(posedge clk)
	begin
		mem_out_valid	<=mem_rdreq;
		if (icache_out_valid)
		begin
			$display("icache out: %08x",icache_out);
		end
	end

	always	#5	clk<=!clk;

	initial begin
		$dumpfile("tb_icache.vcd");
		$dumpvars(0);
		#0	reset_n<=1'b1;clk<=1'b0;
			icache_addr<=32'h00000000;
			icache_rdreq<=1'b0;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go");
		#100	icache_addr<=32'h00000080;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;
		#100	icache_addr<=32'h00000084;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;
		#100	icache_addr<=32'h00000088;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;

		#1000	$finish();
	end
endmodule


