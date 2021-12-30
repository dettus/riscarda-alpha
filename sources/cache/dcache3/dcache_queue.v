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


module	dcache_queue
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32,
parameter	QUEUECNTBITS=3,
parameter	QUEUESIZE=(2**QUEUECNTBITS)
)
(
	input	[DATABITS-1:0]	queue_in_data,
	input	[ADDRBITS-1:0]	queue_in_addr,
	input			queue_in_rdreq,
	input			queue_in_wrreq,


	output	[DATABITS-1:0]	queue_out_data,
	output	[ADDRBITS-1:0]	queue_out_addr,
	output			queue_out_rdreq,
	output			queue_out_wrreq,
	
	input			queue_push,
	input			queue_pop,
	output			queue_not_empty,

	// connection to the system control
	input			reset_n,
	input			clk
);
	reg	[QUEUECNTBITS-1:0]	inaddr;
	reg	[QUEUECNTBITS-1:0]	outaddr;
	
	reg	[DATABITS+ADDRBITS+1+1-1:0]	queue_memory[QUEUESIZE-1:0];
	wire	[DATABITS+ADDRBITS+1+1-1:0]	queue_out;

	
	assign	queue_not_empty	=(inaddr!=outaddr);

	assign	queue_out	=queue_memory[outaddr];
	assign	queue_out_data	=queue_out[31: 0];
	assign	queue_out_addr	=queue_out[63:32];
	assign	queue_out_rdreq	=queue_out[64];
	assign	queue_out_wrreq	=queue_out[65];

	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			inaddr	<='d0;
			outaddr	<='d0;
		end else begin
			if (queue_push)
			begin
				queue_memory[inaddr]	<={queue_in_wrreq,queue_in_rdreq,queue_in_addr,queue_in_data};
				inaddr			<=inaddr+'d1;	
			end
			if (queue_pop)
			begin
				outaddr			<=outaddr+'d1;
			end
		end
	end

endmodule

