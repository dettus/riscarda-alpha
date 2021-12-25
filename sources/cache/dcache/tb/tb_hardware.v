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
	output		line_fill,
	input		reset_n,
	input		clk
);
	reg	[31:0]	dcache_addr;
	reg	[31:0]	dcache_datain;
	reg		dcache_rdreq;
	reg		dcache_wrreq;	
	reg		line_fill;
	reg	[24:0]	cnter;

		
	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			cnter		<=24'd0;
			dcache_addr	<=32'b0;
			dcache_datain	<=32'b0;
			dcache_rdreq	<=1'b0;
			dcache_wrreq	<=1'b0;
			line_fill	<=1'b0;
		end else begin
			if (cnter!=24'hfffffc)
			begin
				cnter<=cnter+24'd1;
			end

			if (cnter[15:0]==16'hffff)
			begin
				case (cnter[23:16])
					8'h00:	begin	dcache_addr<=32'h00000000;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b1;line_fill<=1'b0;end
					8'h01:	begin	dcache_addr<=32'h00000000;dcache_datain<=32'h12345678;dcache_wrreq<=1'b1;dcache_rdreq<=1'b0;line_fill<=1'b0;end
					8'h02:	begin	dcache_addr<=32'h00000000;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b0;line_fill<=1'b1;end	// here, the cache line is being filled
					8'h03:	begin	dcache_addr<=32'h00000000;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b0;line_fill<=1'b0;end

					8'h04:	begin	dcache_addr<=32'h00000000;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b1;line_fill<=1'b0;end	// 12345678 is being read
					8'h05:	begin	dcache_addr<=32'h00000000;dcache_datain<=32'h9abcdef0;dcache_wrreq<=1'b1;dcache_rdreq<=1'b0;line_fill<=1'b0;end	// now, 9abcdef0 is stored at addr 0
					8'h06:	begin	dcache_addr<=32'h00000000;dcache_datain<=32'h00000000;dcache_wrreq<=1'b0;dcache_rdreq<=1'b0;line_fill<=1'b0;end	// here, the cache line is being filled
					8'h07:	begin	dcache_addr<=32'h00000004;dcache_datain<=32'h12345678;dcache_wrreq<=1'b1;dcache_rdreq<=1'b0;line_fill<=1'b0;end	// and 12345678 at addr 4

					8'h08:	begin	dcache_addr<=32'h00000104;dcache_datain<=32'h55555555;dcache_wrreq<=1'b1;dcache_rdreq<=1'b0;line_fill<=1'b0;end	// 55555555 should be stored at 104
					8'h09:	begin	dcache_addr<=32'h00000104;dcache_datain<=32'h55555555;dcache_wrreq<=1'b0;dcache_rdreq<=1'b0;line_fill<=1'b1;end	// 
					8'h0a:	begin	dcache_addr<=32'h00000104;dcache_datain<=32'h55555555;dcache_wrreq<=1'b1;dcache_rdreq<=1'b0;line_fill<=1'b0;end	// 
					8'h0b:	begin	dcache_addr<=32'h00000104;dcache_datain<=32'h55555555;dcache_wrreq<=1'b0;dcache_rdreq<=1'b1;line_fill<=1'b0;end	// 

					8'h0c:	begin	dcache_addr<=32'h00000108;dcache_datain<=32'h55555555;dcache_wrreq<=1'b1;dcache_rdreq<=1'b0;line_fill<=1'b0;end	// 55555555 should be stored at 104
					8'h0d:	begin	dcache_addr<=32'h0000010c;dcache_datain<=32'h66666666;dcache_wrreq<=1'b1;dcache_rdreq<=1'b0;line_fill<=1'b0;end	// 
					8'h0e:	begin	dcache_addr<=32'h00000110;dcache_datain<=32'h77777777;dcache_wrreq<=1'b1;dcache_rdreq<=1'b0;line_fill<=1'b0;end	// 
					8'h0f:	begin	dcache_addr<=32'h0000010c;dcache_datain<=32'h77777777;dcache_wrreq<=1'b0;dcache_rdreq<=1'b1;line_fill<=1'b0;end	// should return 66666666

					8'h10:	begin	dcache_addr<=32'h00000000;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b1;line_fill<=1'b0;end	// 
					8'h11:	begin	dcache_addr<=32'h00000000;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b0;line_fill<=1'b1;end	// should return 9abcdef0
					8'h12:	begin	dcache_addr<=32'h00000004;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b1;line_fill<=1'b0;end	// should return 12345678
					8'h13:	begin	dcache_addr<=32'h00000104;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b1;line_fill<=1'b0;end	// 

					8'h14:	begin	dcache_addr<=32'h00000104;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b0;line_fill<=1'b1;end	// should return 55555555
					8'h15:	begin	dcache_addr<=32'h0000010c;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b1;line_fill<=1'b0;end	// should return 66666666
					8'h16:	begin	dcache_addr<=32'h00000110;dcache_datain<=32'h12345678;dcache_wrreq<=1'b0;dcache_rdreq<=1'b1;line_fill<=1'b0;end	// should return 77777777

					default:begin
						dcache_addr	<=32'b0;
						dcache_datain	<=32'b0;
						dcache_rdreq	<=1'b0;
						dcache_wrreq	<=1'b0;
						line_fill	<=1'b0;
						end
				endcase
			end else begin
				dcache_addr	<=32'b0;
				dcache_datain	<=32'b0;
				dcache_rdreq	<=1'b0;
				dcache_wrreq	<=1'b0;
				line_fill	<=1'b0;
			end
		end
	end
endmodule	


module	uart_out(
	output		tx,
	output		ready,
	input	[31:0]	value,
	input		valid,
	input		reset_n,
	input		clk
	);
	
	reg	tx;
	reg	ready;
	reg	[9:0]	cnt_baud;
	reg	[3:0]	cnt_byte;
	reg	[9:0]	shift_char;
	reg	[31:0]	shift_value;
	reg	[31:0]	nxt_value;
	reg		nxt_valid;
	reg	[31:0]	v_nxt_value;
	reg		v_nxt_valid;


	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			tx		<=1'b1;
			cnt_baud	<=9'd434;		// 50000000/115200	= 434		every 434 cycles 1 bit equals 1152000 baud.
			cnt_byte	<=4'd0;
			shift_char	<=10'b0000000000;
			shift_value	<=32'h00000000;
			nxt_valid	<=1'b0;
			nxt_value	<=32'h0;
			ready		<=1'b0;
		end else begin
			v_nxt_valid	=nxt_valid|valid;
			v_nxt_value	=nxt_value|value;
			if (cnt_baud==9'd0)
			begin
				cnt_baud	<=9'd434;
				if (shift_char==10'b0000000000)
				begin
					case (cnt_byte)
						4'd0: begin	
							ready<=!nxt_valid;
							if (nxt_valid)
							begin
								v_nxt_valid	=valid;
								v_nxt_value	=value;
								shift_value	<=nxt_value;
								cnt_byte	<=4'd10;
							end
						end
						4'd1:	begin
							cnt_byte	<=4'd0;
							shift_char	<=10'b0000010101;	// 1 start bit =0, line feed=10 (msb first), 1 stop bit
						end
						4'd2:	begin
							cnt_byte	<=4'd1;
							shift_char	<=10'b0000011011;	// 1 start bit =0, carriage return=13 (msb first), 1 stop bit
						end
						default:begin
							cnt_byte	<=cnt_byte-4'd1;
							case (shift_value[31:28])
								4'h0:	begin shift_char<=10'b0001100001;end	// 0= 0x30
								4'h1:	begin shift_char<=10'b0001100011;end	// 1= 0x31
								4'h2:	begin shift_char<=10'b0001100101;end	// 2= 0x32
								4'h3:	begin shift_char<=10'b0001100111;end	// 3= 0x33

								4'h4:	begin shift_char<=10'b0001101001;end	// 4= 0x34
								4'h5:	begin shift_char<=10'b0001101011;end	// 5= 0x35
								4'h6:	begin shift_char<=10'b0001101101;end	// 6= 0x36
								4'h7:	begin shift_char<=10'b0001101111;end	// 7= 0x37

								4'h8:	begin shift_char<=10'b0001110001;end	// 8= 0x38
								4'h9:	begin shift_char<=10'b0001110011;end	// 9= 0x39
								4'hA:	begin shift_char<=10'b0010000011;end	// A= 0x41
								4'hB:	begin shift_char<=10'b0010000101;end	// B= 0x42

								4'hC:	begin shift_char<=10'b0010000111;end	// C= 0x43
								4'hD:	begin shift_char<=10'b0010001001;end	// D= 0x44
								4'hE:	begin shift_char<=10'b0010001011;end	// E= 0x45
								4'hF:	begin shift_char<=10'b0010001101;end	// F= 0x46
							endcase
							shift_value<={shift_value[27:0],4'b0000};
						end
					endcase
				end else begin
					ready		<=1'b0;
					tx		<=shift_char[9];
					shift_char	<={shift_char[8:0],1'b0};
				end
				
				nxt_valid	<=v_nxt_valid;
				nxt_value	<=v_nxt_value;	
			end else begin
				cnt_baud	<=cnt_baud-9'd1;
			end
			nxt_valid	<=v_nxt_valid;
			nxt_value	<=v_nxt_value;
		end
	end
endmodule

module	tbblock(
	output		tx,	
	input		reset_n,
	input		clk
);

	reg	[31:0]	cnt;
	wire		ready;
//	dcache_line	DCACHE_LINE0(
//		.dcache_addr		(dcache_addr),
//		.dcache_datain		(dcache_datain),
//		.dcache_rdreq		(dcache_rdreq),
//		.dcache_wrreq		(dcache_wrreq),
//		.line_fill		(line_fill),
//		.line_out		(line_out),
//		.line_valid		(line_valid),
//		.line_miss		(line_miss),
//
//		.mem_out		(mem_out),
//		.mem_burstlen		(mem_burstlen),
//		.mem_valid		(mem_valid),
//		.mem_addr		(mem_addr),
//		.mem_rdreq		(mem_rdreq),
//		.mem_wrreq		(mem_wrreq),
//
//		.reset_n		(reset_n),
//		.clk			(clk)	
//	);
	uart_out	UART_OUT0(
		.tx		(tx),
		.ready		(ready),
		.value		(cnt),
		.valid		(ready),
		.reset_n	(reset_n),
		.clk		(clk)
	);	
	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			cnt	<=32'd0;
		end else begin
			cnt	<=cnt+32'd1;
		end
	end
endmodule

module main();
	reg reset_n;	
	reg clk;
	wire tx;

	tbblock	TBBLOCK0(
		.tx		(tx),
		.reset_n	(reset_n),
		.clk		(clk)
	);	

	always	#5 clk<=!clk;
	
	initial begin
		$dumpfile("tb_hardware.vcd");
		$dumpvars(0);
		#0	reset_n<=1'b1;clk<=1'b1;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#8	$display("go!");

		#20000000	$finish();
	end
endmodule
