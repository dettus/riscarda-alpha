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
module	myqueue
#(
	parameter	DATABITS=8,
	parameter	QUEUECNTBITS=4,
	parameter	QUEUESIZE=(2**QUEUECNTBITS),
	parameter	QUEUEWARNLEVEL=(QUEUESIZE-3)
)
(
	input	[DATABITS-1:0]	queue_in,
	input			queue_push,
	output			queue_warning,
	
	input			queue_pop,
	output	[DATABITS-1:0]	queue_out,
	output			queue_not_empty,
	
	input			reset_n,
	input			clk
);
	reg	[QUEUECNTBITS-1:0]	inaddr;
	reg	[QUEUECNTBITS-1:0]	outaddr;
	reg	[QUEUECNTBITS-1:0]	level;
	reg	[QUEUECNTBITS-1:0]	v_level;

	reg	[DATABITS-1:0]		queuemem[QUEUESIZE-1:0];

	assign	queue_not_empty	=(inaddr!=outaddr);
	assign	queue_warning	=(level>=QUEUEWARNLEVEL);
	assign	queue_out	=queuemem[outaddr];

	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			inaddr	<='d0;
			outaddr	<='d0;
			level	<='d0;
		end else begin
			v_level	=level;
			if (queue_push)
			begin
				queuemem[inaddr]	<=queue_in;
				inaddr		<=inaddr+'d1;
				v_level		=v_level+'d1;
			end
			if (queue_pop)
			begin
				outaddr		<=outaddr+'d1;
				v_level		=v_level-'d1;
			end
			level	=v_level;
		end
	end
endmodule
	
