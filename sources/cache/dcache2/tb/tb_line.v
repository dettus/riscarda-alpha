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
	
	initial begin
		$dumpfile("tb_line.vcd");
		$dumpvars(0);
		#0	reset_n<=1'b1;clk<=1'b0;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go!");

		#1000	$finish();
		
	end
endmodule
