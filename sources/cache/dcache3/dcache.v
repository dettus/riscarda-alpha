// Copyright (c) 2022
// dettus@dettus.net
//
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
//
//    Redistributions of source code must retain the above copyright notice, this 
//    list of conditions and the following disclaimer.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
////////////////////////////////////////////////////////////////////////////////
// (SPDX short identifier: BSD-1-Clause)

module	dcache
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32,
parameter	LINENUM=4
)
(
	// connection to the CPU core
	input	[ADDRBITS-1:0]	dcache_addr,
	input	[DATABITS-1:0]	dcache_in,
	output	[DATABITS-1:0]	dcache_out,
	output			dcache_out_valid,
	input			dcache_rdreq,
	input			dcache_wrreq,
	input	[1:0]		dcache_wordlen,		// 00=byte, 01=half word, 10=word

	// connection to the memory controller
	output	[ADDRBITS-1:0]	mem_addr,
	output	[DATABITS-1:0]	mem_in,
	input	[DATABITS-1:0]	mem_out,
	input			mem_out_valid,
	output			mem_rdreq,
	output			mem_wrreq,
	input	[15:0]		mem_burstlen,
	

	// system control lines
	input			reset_n,
	input			clk
);
		

	dcache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
	) DCACHE_LINE0 (
		.dcache_addr		(dcache_addr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_in		(dcache_in),
		.line_out		(line_out0),
		.line_out_valid		(line_out_valid[0]),
		.byteenable		(byteenable),
	
		.line_miss		(line_miss[0]),
		.line_dirty		(line_dirty[0]),
		.flush_mode		(flush_mode[0]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
	) DCACHE_LINE1 (
		.dcache_addr		(dcache_addr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_in		(dcache_in),
		.line_out		(line_out1),
		.line_out_valid		(line_out_valid[1]),
		.byteenable		(byteenable),
	
		.line_miss		(line_miss[1]),
		.line_dirty		(line_dirty[1]),
		.flush_mode		(flush_mode[1]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
	) DCACHE_LINE2 (
		.dcache_addr		(dcache_addr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_in		(dcache_in),
		.line_out		(line_out2),
		.line_out_valid		(line_out_valid[2]),
		.byteenable		(byteenable),
	
		.line_miss		(line_miss[2]),
		.line_dirty		(line_dirty[2]),
		.flush_mode		(flush_mode[2]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_line #(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
	) DCACHE_LINE3 (
		.dcache_addr		(dcache_addr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_in		(dcache_in),
		.line_out		(line_out3),
		.line_out_valid		(line_out_valid[3]),
		.byteenable		(byteenable),
	
		.line_miss		(line_miss[3]),
		.line_dirty		(line_dirty[3]),
		.flush_mode		(flush_mode[3]),
		.flush_we		(flush_we),
		.flush_addr		(flush_addr),
		.flush_in		(flush_in),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_queue	#(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS),	
	)	DCACHE_QUEUE (
		.queue_in_data		(queue_in_data),
		.queue_in_addr		(queue_in_addr),
		.queue_in_rdreq		(queue_in_rdreq),
		.queue_in_wrreq		(queue_in_wrreq),

		.queue_out_data		(queue_out_data),
		.queue_out_addr		(queue_out_addr),
		.queue_out_rdreq	(queue_out_rdreq),
		.queue_out_wrreq	(queue_out_wrreq),
		
		.queue_push		(queue_push),
		.queue_pop		(queue_pop),
		.queue_not_empty	(queue_not_empty),

		.reset_n		(reset_n),
		.clk			(clk)
	);
	// remember: the dcache_out can become valid in FIVE cases: the four lines, AND when the flush has read the address for the rdreq in the queue.
endmodule


