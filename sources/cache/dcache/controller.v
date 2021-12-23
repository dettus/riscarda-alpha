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
`define	LINES		 4
`define	TTLBITS		8
`define	CACHEADDRBITS	5
`define	ADDRMSBBITS	(`ADDRBITS-CACHEADDRBITS-2-1)

module	dcache_controller
(


	input	[`TTLBITS-1:0]	ttl0;
	input	[`TTLBITS-1:0]	ttl1;
	input	[`TTLBITS-1:0]	ttl2;
	input	[`TTLBITS-1:0]	ttl3;
	output	[`LINES-1:0]	fill_req;
	input	[`LINES-1:0]	miss;
	
	input	reset_n;
	input	clk;
);
	reg	[`LINES-1:0]	fill_req;
	reg	[`TTLBITS-1:0]	v_min01;
	reg	[`TTLBITS-1:0]	v_min23;
	reg	[1:0]		v_lowest01;
	reg	[1:0]		v_lowest23;
	reg			v_hit;


	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			fill_req	<=4'b0000;
		end else begin
			v_lowest01	=2'b01;
			v_min01		=ttl0;
			if (ttl1<=ttl0)
			begin
				v_lowest01	=2'b10;
				v_min01		=ttl1;
					
			end 
			v_lowest23	=2'b01;
			v_min23		=ttl2;
			if (ttl3<=ttl2)
			begin
				v_lowest23	=2'b10;
				v_min23		=ttl3;
					
			end 
			
			if (miss==`LINES'b1111)
			begin
				if (v_lowest01<=v_lowest23)
				begin
					fill_req	<={2'b00,v_lowest01};
				end else begin
					fill_req	<={v_lowest23,2'b00};
				end
			end else begin
				fill_req	<=`LINES'b0;
			end
		end
	end
endmodule


