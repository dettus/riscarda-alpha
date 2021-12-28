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

module tb_line
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32,
parameter	CACHEDATABITS=8,
parameter	CACHEADDRBITS=5,
parameter	LSBITS=2,
parameter	MSBITS=(ADDRBITS-CACHEADDRBITS-LSBITS),
parameter	BANKNUM=(DATABITS/CACHEDATABITS),
parameter	CACHESIZE=2**CACHEADDRBITS,
parameter	CNTMISSBITS=8
)();
	reg	[ADDRBITS-1:0]		dcache_addr;
	reg	[DATABITS-1:0]		dcache_in;
	wire	[DATABITS-1:0]		line_out;
	wire				line_valid;
	wire				line_miss;
	wire				line_dirty;
	reg	[BANKNUM-1:0]		byteenable;

	reg				dcache_rdreq;
	reg				dcache_wrreq;

	wire	[CNTMISSBITS-1:0]	flush_cnt_miss;
	reg				flush_mode;	// flush mode FOR THIS LINE
	reg				flush_write;	// flush write FOR ALL LINES
	reg	[CACHEADDRBITS-1:0]	flush_addr;
	reg				flush_dirty;	// =1 if the flush was triggered by a write request

	wire	[ADDRBITS-1:0]		mem_addr;
	reg	[DATABITS-1:0]		line_in;
	reg				line_in_valid;

	reg				reset_n;
	reg				clk;
	

	dcache_line DCACHE_LINE0(
		.dcache_addr		(dcache_addr),
		.dcache_in		(dcache_in),
		.line_out		(line_out),
		.line_valid		(line_valid),
		.line_miss		(line_miss),
		.line_dirty		(line_dirty),
		.byteenable		(byteenable),

		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		
		.flush_cnt_miss		(flush_cnt_miss),
		.flush_mode		(flush_mode),
		.flush_write		(flush_write),
		.flush_addr		(flush_addr),
		.flush_dirty		(flush_dirty),

		.mem_addr		(mem_addr),
		.line_in		(line_in),
		.line_in_valid		(line_in_valid),
	
		.reset_n		(reset_n),
		.clk			(clk)
	);

	always	#5	clk<=!clk;
	always	@(posedge clk)
	begin
		if (line_valid)
		begin
			$display("line_out: %08X",line_out);
		end
	end
	
	initial begin
		$dumpfile("tb_line.vcd");
		$dumpvars(0);
		#0	reset_n<=1'b1;clk<=1'b0;
			dcache_addr	<=32'h00000080;
			dcache_in	<=32'hffffffff;
			byteenable	<=4'b1111;
			dcache_rdreq	<=1'b0;
			dcache_wrreq	<=1'b0;
			flush_mode	<=1'b0;
			flush_write	<=1'b0;
			flush_addr	<=5'd0;
			flush_dirty	<=1'b0;
			line_in		<=32'h0000affe;
			line_in_valid	<=1'b0;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go!");

		#10	dcache_addr	<=32'h00000080;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd0;flush_dirty<=1'b0;line_in<=32'h0fff0000;line_in_valid<=1'b0;flush_write<=1'b1;
		#10	dcache_addr	<=32'h00000080;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd00;flush_dirty<=1'b0;line_in<=32'h0fff0000;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h00000084;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd01;flush_dirty<=1'b0;line_in<=32'h0fff0001;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h00000088;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd02;flush_dirty<=1'b0;line_in<=32'h0fff0002;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h0000008c;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd03;flush_dirty<=1'b0;line_in<=32'h0fff0003;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h00000090;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd04;flush_dirty<=1'b0;line_in<=32'h0fff0004;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h00000094;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd05;flush_dirty<=1'b0;line_in<=32'h0fff0005;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h00000098;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd06;flush_dirty<=1'b0;line_in<=32'h0fff0006;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000ac;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd07;flush_dirty<=1'b0;line_in<=32'h0fff0007;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000a0;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd08;flush_dirty<=1'b0;line_in<=32'h0fff0008;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000a4;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd09;flush_dirty<=1'b0;line_in<=32'h0fff0009;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000a8;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd10;flush_dirty<=1'b0;line_in<=32'h0fff000a;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000ac;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd11;flush_dirty<=1'b0;line_in<=32'h0fff000b;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000b0;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd12;flush_dirty<=1'b0;line_in<=32'h0fff000c;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000b4;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd13;flush_dirty<=1'b0;line_in<=32'h0fff000d;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000b8;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd14;flush_dirty<=1'b0;line_in<=32'h0fff000e;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000bc;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd15;flush_dirty<=1'b0;line_in<=32'h0fff000f;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000c0;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd16;flush_dirty<=1'b0;line_in<=32'h0fff0010;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000c4;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd17;flush_dirty<=1'b0;line_in<=32'h0fff0011;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000c8;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd18;flush_dirty<=1'b0;line_in<=32'h0fff0012;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000cc;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd19;flush_dirty<=1'b0;line_in<=32'h0fff0013;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000d0;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd20;flush_dirty<=1'b0;line_in<=32'h0fff0014;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000d4;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd21;flush_dirty<=1'b0;line_in<=32'h0fff0015;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000d8;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd22;flush_dirty<=1'b0;line_in<=32'h0fff0016;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000dc;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd23;flush_dirty<=1'b0;line_in<=32'h0fff0017;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000e0;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd24;flush_dirty<=1'b0;line_in<=32'h0fff0018;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000e4;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd25;flush_dirty<=1'b0;line_in<=32'h0fff0019;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000e8;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd26;flush_dirty<=1'b0;line_in<=32'h0fff001a;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000ec;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd27;flush_dirty<=1'b0;line_in<=32'h0fff001b;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000f0;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd28;flush_dirty<=1'b0;line_in<=32'h0fff001c;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000f4;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd29;flush_dirty<=1'b0;line_in<=32'h0fff001d;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000f8;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd30;flush_dirty<=1'b0;line_in<=32'h0fff001e;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000fc;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b1;flush_addr<=5'd31;flush_dirty<=1'b0;line_in<=32'h0fff001f;line_in_valid<=1'b1;
		#10	dcache_addr	<=32'h000000fc;dcache_in<=32'h0000001;byteenable<=4'b1111;dcache_rdreq<=1'b0;flush_mode<=1'b0;flush_addr<=5'd31;flush_dirty<=1'b0;line_in<=32'h0fff001f;line_in_valid<=1'b0;flush_write<=1'b0;

		#1000	$display("read test");
		#10	dcache_addr	<=32'h00000080;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h00000084;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h00000088;dcache_rdreq<=1'b1;
		#10	dcache_addr	<=32'h0000008c;dcache_rdreq<=1'b1;
		#10	dcache_rdreq	<=1'b0;
		
		

		#1000	$finish();
		
	end
endmodule
