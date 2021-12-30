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

module tb_queue
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32
)
();
	reg	[DATABITS-1:0]	queue_in_data;
	reg	[ADDRBITS-1:0]	queue_in_addr;
	reg			queue_in_rdreq;
	reg			queue_in_wrreq;


	wire	[DATABITS-1:0]	queue_out_data;
	wire	[ADDRBITS-1:0]	queue_out_addr;
	wire			queue_out_rdreq;
	wire			queue_out_wrreq;
	
	reg			queue_push;
	reg			queue_pop;
	wire			queue_not_empty;

	// connection to the system control
	reg			reset_n;
	reg			clk;

	dcache_queue
	#(
		.DATABITS	(DATABITS),
		.ADDRBITS	(ADDRBITS)
	) DCACHE_QUEUE0(
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

	always	#5	clk<=!clk;

	initial begin
		$dumpfile("tb_queue.vcd");
		$dumpvars(0);
		#0	reset_n<=1'b1;clk<=1'b0;
			queue_pop<=1'b0;
			queue_push<=1'b0;

		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go");

		#10	queue_in_data<=32'hd00faffe;queue_in_addr<=32'hdeadbeef;queue_in_rdreq<=1'b0;queue_in_wrreq<=1'b1;
		#10	queue_push<=1'b1;
		#10	queue_push<=1'b0;

		#50	queue_pop<=1'b1;
		#10	queue_pop<=1'b0;

		#100	$finish;

	
	end
endmodule
