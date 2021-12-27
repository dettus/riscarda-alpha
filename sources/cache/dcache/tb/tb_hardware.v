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

module	tbstimuli(
	output	[31:0]	dcache_addr,
	output	[31:0]	dcache_datain,
	output		dcache_rdreq,
	output		dcache_wrreq,	
	output	[3:0]	dcache_be,
	output		line_fill,
	input		reset_n,
	input		clk
);
	reg	[31:0]	r_dcache_addr;
	reg	[31:0]	r_dcache_datain;
	reg		r_dcache_rdreq;
	reg		r_dcache_wrreq;	
	reg	[ 3:0]	r_dcache_be;
	reg		r_line_fill;
	reg	[24:0]	cnter;


	assign	dcache_addr	=r_dcache_addr;
	assign	dcache_datain	=r_dcache_datain;
	assign	dcache_rdreq	=r_dcache_rdreq;
	assign	dcache_wrreq	=r_dcache_wrreq;
	assign	dcache_be	=r_dcache_be;
	assign	line_fill	=r_line_fill;
		
	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			cnter		<=24'd0;
			r_dcache_addr	<=32'b0;
			r_dcache_datain	<=32'b0;
			r_dcache_rdreq	<=1'b0;
			r_dcache_wrreq	<=1'b0;
			r_dcache_be	<=4'b1111;
			r_line_fill	<=1'b0;
		end else begin
			if (cnter!=24'hfffffc)
			begin
				cnter<=cnter+24'd1;
			end

			if (cnter[15:0]==16'hffff)
			begin
				case (cnter[23:16])
					8'h00:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end
					8'h01:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b1;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end
					8'h02:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b1;end	// here, the cache line is being filled
					8'h03:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end

					8'h04:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// 12345678 is being read
					8'h05:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h9abcdef0;r_dcache_wrreq<=1'b1;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// now, 9abcdef0 is stored at addr 0
					8'h06:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h00000000;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// here, the cache line is being filled
					8'h07:	begin	r_dcache_addr<=32'h00000004;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b1;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// and 12345678 at addr 4

					8'h08:	begin	r_dcache_addr<=32'h00000104;r_dcache_datain<=32'h55555555;r_dcache_wrreq<=1'b1;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// 55555555 should be stored at 104
					8'h09:	begin	r_dcache_addr<=32'h00000104;r_dcache_datain<=32'h55555555;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b1;end	// 
					8'h0a:	begin	r_dcache_addr<=32'h00000104;r_dcache_datain<=32'h55555555;r_dcache_wrreq<=1'b1;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// 
					8'h0b:	begin	r_dcache_addr<=32'h00000104;r_dcache_datain<=32'h55555555;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// 

					8'h0c:	begin	r_dcache_addr<=32'h00000108;r_dcache_datain<=32'h55555555;r_dcache_wrreq<=1'b1;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// 55555555 should be stored at 104
					8'h0d:	begin	r_dcache_addr<=32'h0000010c;r_dcache_datain<=32'h66666666;r_dcache_wrreq<=1'b1;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// 
					8'h0e:	begin	r_dcache_addr<=32'h00000110;r_dcache_datain<=32'h77777777;r_dcache_wrreq<=1'b1;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// 
					8'h0f:	begin	r_dcache_addr<=32'h0000010c;r_dcache_datain<=32'h77777777;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// should return 66666666

					8'h10:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// 
					8'h11:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b1;end	// should return 9abcdef0
					8'h12:	begin	r_dcache_addr<=32'h00000004;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// should return 12345678
					8'h13:	begin	r_dcache_addr<=32'h00000104;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// 

					8'h14:	begin	r_dcache_addr<=32'h00000104;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b1;end	// should return 55555555
					8'h15:	begin	r_dcache_addr<=32'h0000010c;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// should return 66666666
					8'h16:	begin	r_dcache_addr<=32'h00000110;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// should return 77777777
					8'h17:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// 
					8'h18:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b0;r_dcache_be<=4'b1111;r_line_fill<=1'b1;end	// 
					8'h19:	begin	r_dcache_addr<=32'h00000000;r_dcache_datain<=32'h12345678;r_dcache_wrreq<=1'b0;r_dcache_rdreq<=1'b1;r_dcache_be<=4'b1111;r_line_fill<=1'b0;end	// should return 9abcdef0

					default:begin
						r_dcache_addr	<=32'b0;
						r_dcache_datain	<=32'b0;
						r_dcache_rdreq	<=1'b0;
						r_dcache_wrreq	<=1'b0;
						r_dcache_be	<=4'b0000;
						r_line_fill	<=1'b0;
						end
				endcase
			end else begin
				r_dcache_addr	<=32'b0;
				r_dcache_datain	<=32'b0;
				r_dcache_rdreq	<=1'b0;
				r_dcache_wrreq	<=1'b0;
				r_dcache_be	<=4'b0000;
				r_line_fill	<=1'b0;
			end
		end
	end
endmodule	


module	uart_out(
	output			tx,
	output			ready,

	
	input		[31:0]	value,
	input					value_good,
	
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
			baudcnt	<=9'd434;
			shifter	<=10'b0000000000;
			bytecnt	<=4'd0;
		end else begin
			if (shifter!=10'b0000000000)
			begin
				if (baudcnt==9'd0)
				begin
					baudcnt<=9'd434;
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
										$display("output value %08X",value);
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
						default:	begin
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


module	tbblock(
	output		tx,	
	input		reset_n,
	input		clk
);


	wire	[31:0]	dcache_addr;
	wire	[31:0]	dcache_datain;
	wire		dcache_rdreq;
	wire		dcache_wrreq;
	wire		line_fill;
	wire	[31:0]	line_out;
	wire		line_valid;
	wire		line_miss;
	wire	[31:0]	mem_out;
	wire	[31:0]	mem_addr;
	reg		mem_valid;
	wire		mem_rdreq;
	wire		mem_wrreq;


	tbstimuli TBSTIMULI0(
		.dcache_addr	(dcache_addr),
		.dcache_datain	(dcache_datain),
		.dcache_rdreq	(dcache_rdreq),
		.dcache_wrreq	(dcache_wrreq),
		.line_fill	(line_fill),
		.reset_n	(reset_n),
		.clk		(clk)
	);


	spram_512x32	BIGRAM0(
		.datain		(line_out),
		.we		(mem_wrreq),
		.addr		(mem_addr[8:0]),
		.dataout	(mem_out),
		.clk		(clk)
	);
	
	dcache_line	DCACHE_LINE0(
		.dcache_addr		(dcache_addr),
		.dcache_datain		(dcache_datain),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.line_fill		(line_fill),
		.line_out		(line_out),
		.line_valid		(line_valid),
		.line_miss		(line_miss),

		.mem_out		(mem_out),
		.mem_burstlen		(16'd1),
		.mem_valid		(mem_valid),
		.mem_addr		(mem_addr),
		.mem_rdreq		(mem_rdreq),
		.mem_wrreq		(mem_wrreq),

		.reset_n		(reset_n),
		.clk			(clk)	
	);

	uart_out	UART_OUT0(
		.tx		(tx),
		.ready		(open),
		.value		(line_out),
		.value_good	(line_valid),
		.reset_n	(reset_n),
		.clk		(clk)
	);

	always	@(posedge clk)
	begin
		mem_valid	<=mem_rdreq|mem_wrreq;
	end
endmodule

module tb();
	reg	clk;
	reg	reset_n;
	wire	tx;

	tbblock	TBBLOCK0(
		.tx		(tx),
		.reset_n	(reset_n),
		.clk		(clk)
	);

	always	#5	clk<=!clk;

	initial begin
		$dumpfile("tb_hardware.vcd");
		$dumpvars(0);

		#0	reset_n<=1'b1;clk<=1'b1;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go");

		#50000000 $finish();
	end
endmodule
