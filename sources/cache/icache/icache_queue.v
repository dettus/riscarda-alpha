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


module	icache_queue
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32,
parameter	QUEUECNTBITS=3,
parameter	QUEUESIZE=(2**QUEUECNTBITS)
)
(
	input	[ADDRBITS-1:0]	queue_in_addr,
	input	[1:0]		queue_in_wordlen,


	output	[ADDRBITS-1:0]	queue_out_addr,
	output	[1:0]		queue_out_wordlen,
	
	input			queue_push,
	input			queue_pop,
	output			queue_not_empty,

	// connection to the system control
	input			reset_n,
	input			clk
);
	reg	[QUEUECNTBITS-1:0]	inaddr;
	reg	[QUEUECNTBITS-1:0]	outaddr;
	
	reg	[ADDRBITS-1:0]	queue_memory[QUEUESIZE-1:0];
	wire	[ADDRBITS-1:0]	queue_out;

	
	assign	queue_not_empty	=(inaddr!=outaddr);

	assign	queue_out		=queue_memory[outaddr];
	assign	queue_out_addr		=queue_out[31: 0];

	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			inaddr	<='d0;
			outaddr	<='d0;
		end else begin
			if (queue_push)
			begin
				queue_memory[inaddr]	<={queue_in_addr};
				inaddr			<=inaddr+'d1;	
			end
			if (queue_pop)
			begin
				outaddr			<=outaddr+'d1;
			end
		end
	end

endmodule

