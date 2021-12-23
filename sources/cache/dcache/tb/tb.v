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

`define	ADDRBITS	32
`define	DATABITS	32
`define	MAXTTL		255
`define	TTLBITS		8

`define	CACHEWORDS	32
`define	CACHEADDRBITS	5
`define	ADDRMSBBITS	(`ADDRBITS-`CACHEADDRBITS-2)


module tb();

	// connection to the CPU core
	reg	[`ADDRBITS-1:0]	dcache_addr;
	reg	[`DATABITS-1:0]	dcache_datain;
	reg			dcache_rdreq;
	reg			dcache_wrreq;
	// connection to the controller
	reg			line_fill;
	wire	[`DATABITS-1:0]	line_out;
	wire			line_valid;
	wire			line_miss;


	// connection to the memory controller
	reg	[`DATABITS-1:0]	mem_out;
	reg	[15:0]		mem_burstlen;
	reg			mem_valid;
	wire	[`ADDRBITS-1:0]	mem_addr;
	wire			mem_rdreq;
	wire			mem_wrreq;
	

	
	reg		reset_n;
	reg		clk;



	dcache_line	DCACHE_LINE0(
		.dcache_addr	(dcache_addr),
		.dcache_datain	(dcache_datain),
		.dcache_rdreq	(dcache_rdreq),
		.dcache_wrreq	(dcache_wrreq),

		.line_fill	(line_fill),
		.line_out	(line_out),
		.line_valid	(line_valid),
		.line_miss	(line_miss),
		
		.mem_out	(mem_out),
		.mem_burstlen	(mem_burstlen),
		.mem_valid	(mem_valid),
		.mem_addr	(mem_addr),
		.mem_rdreq	(mem_rdreq),
		.mem_wrreq	(mem_wrreq),

		.reset_n	(reset_n),
		.clk		(clk)
	);


	always	#5	clk<=!clk;

	always	@(posedge clk)
	begin
		if (mem_wrreq)
		begin
			$display("                     MEM WRITE %08x  @%08x",line_out,mem_addr);
		end
		if (mem_rdreq)
		begin
			$display("MEM READ @%08x",mem_addr);
		end
		if (line_valid)
		begin
			$display("CACHE OUT %08x @%08x",line_out,dcache_addr);
		end
	end

	initial begin
		$dumpfile("tb.vcd");
		$dumpvars(0);
		#0	reset_n<=1'b1;clk<=1'b0;
			dcache_addr	<=`ADDRBITS'hd00faffc;
			dcache_datain	<=`DATABITS'b0;
			dcache_rdreq	<=1'b0;
			dcache_wrreq	<=1'b0;
			line_fill	<=1'b0;
			mem_out		<=`ADDRBITS'h0;
			mem_burstlen	<=16'd32;
			mem_valid	<=1'b0;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go go!");
		
		#100	dcache_rdreq	<=1'b1;
		#10	dcache_rdreq	<=1'b0;

		#100	dcache_wrreq	<=1'b1;
		#10	dcache_wrreq	<=1'b0;


		#500	line_fill	<=1'b1;
		#10	line_fill	<=1'b0;
		#50	mem_out		<=`DATABITS'h100;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h101;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h102;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h103;mem_valid<=1'b0;
		#10	mem_out		<=`DATABITS'h103;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h104;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h105;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h106;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h107;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h108;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h109;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h110;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h111;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h112;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd113;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd114;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd115;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd116;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd117;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd118;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd119;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd120;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd121;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd122;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd123;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd124;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd125;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd126;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd127;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd128;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd129;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd130;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd131;mem_valid<=1'b1;
		#10	mem_valid	<=1'b0;

		#500	dcache_datain	<=`DATABITS'hdeadbeef;dcache_wrreq<=1'b1;
		#10	dcache_wrreq	<=1'b0;
		#100	dcache_rdreq	<=1'b1;
		#10	dcache_rdreq	<=1'b0;

		#1000	dcache_addr	<=`ADDRBITS'hcccccccc;dcache_rdreq<=1'b1;
		#10	dcache_rdreq	<=1'b0;
		#20	line_fill	<=1'b1;
		#10	line_fill	<=1'b0;

		#2000	mem_out		<=`DATABITS'h200;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h201;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h202;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h203;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h204;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h205;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h206;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h207;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h208;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h209;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h210;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h211;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'h212;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd213;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd214;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd215;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd216;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd217;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd218;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd219;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd220;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd221;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd222;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd223;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd224;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd225;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd226;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd227;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd228;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd229;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd230;mem_valid<=1'b1;
		#10	mem_out		<=`DATABITS'd231;mem_valid<=1'b1;
		#10	mem_valid	<=1'b0;


		#2000	$finish();
	end
endmodule

