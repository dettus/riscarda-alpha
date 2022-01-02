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



module	th_bardware_uart
#(
parameter	BAUDRATE=115200,
parameter	MASTERCLOCK=50000000,
parameter	SAMPLECLOCK=(MASTERCLOCK/BAUDRATE)
)
(
	output		tx,
	output		ready,
	
	input		[31:0]	value,
	input		value_good,
	
	input		clk,
	input		reset_n
);


	reg	r_tx;
	reg	r_ready;
	reg	[8:0]	baudcnt;
	reg	[9:0] shifter;
	
	reg	[3:0]	bytecnt;
	reg	[31:0]	shiftval;
	
	assign	tx=r_tx;
	assign	ready=r_ready;
	
	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			r_tx		<=1'b1;
			r_ready	<=1'b0;
			baudcnt	<=SAMPLECLOCK;
			shifter	<=10'b0000000000;
			bytecnt	<=4'd0;
		end else begin
			if (shifter!=10'b0000000000)
			begin
				if (baudcnt==9'd0)
				begin
					baudcnt<=SAMPLECLOCK;
					r_tx<=shifter[0];
					shifter<={1'b0,shifter[9:1]};
				end else begin
					baudcnt<=baudcnt-9'd1;
				end
			end else begin
				case (bytecnt)
					4'd0:	begin
							r_ready<=!value_good;
							if (value_good)
							begin
								shiftval<=value;
								bytecnt<=4'd10;
							end
						end
					4'd1:	begin
							bytecnt<=bytecnt-4'd1;
							shifter<={1'b1,8'h0a,1'b0};			// line feed
						end
					4'd2:	begin
							bytecnt<=bytecnt-4'd1;
							shifter<={1'b1,8'h0d,1'b0};			// carriage return
						end
					default:begin
							bytecnt<=bytecnt-4'd1;
							shiftval<={shiftval[27:0],4'b0000};
							case (shiftval[31:28])
								4'h0:		begin	shifter<={1'b1,8'h30,1'b0};	end
								4'h1:		begin	shifter<={1'b1,8'h31,1'b0};	end
								4'h2:		begin	shifter<={1'b1,8'h32,1'b0};	end
								4'h3:		begin	shifter<={1'b1,8'h33,1'b0};	end
								
								4'h4:		begin	shifter<={1'b1,8'h34,1'b0};	end
								4'h5:		begin	shifter<={1'b1,8'h35,1'b0};	end
								4'h6:		begin	shifter<={1'b1,8'h36,1'b0};	end
								4'h7:		begin	shifter<={1'b1,8'h37,1'b0};	end
								

								4'h8:		begin	shifter<={1'b1,8'h38,1'b0};	end
								4'h9:		begin	shifter<={1'b1,8'h39,1'b0};	end
								4'ha:		begin	shifter<={1'b1,8'h41,1'b0};	end
								4'hb:		begin	shifter<={1'b1,8'h42,1'b0};	end
								
								4'hc:		begin	shifter<={1'b1,8'h43,1'b0};	end
								4'hd:		begin	shifter<={1'b1,8'h44,1'b0};	end
								4'he:		begin	shifter<={1'b1,8'h45,1'b0};	end
								default:	begin	shifter<={1'b1,8'h46,1'b0};	end
							endcase
						end
				endcase
			end
		end
	end
endmodule


