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
`define	ADDRBITS	32
`define	DATABITS	32
`define	BANKNUM		4
`define	LINENUM		4

`define	TTLBITS		8
`define	MEM_BURSTLEN	16'd1


module	dcache(
	//  connection to the CPU core
	input	[`ADDRBITS-1:0]	dcache_addr,
	input	[`DATABITS-1:0]	dcache_datain,
	input			dcache_rdreq,
	input			dcache_wrreq,
	input	[ 1:0]		dcache_wordlen,		// 0=8 bit, 1=16 bit, 2=32 bit

	output	[`DATABITS-1:0]	dcache_dataout,
	output			dcache_valid,

	// connection to the memory controller
	input	[`DATABITS-1:0]	mem_out,
	input			mem_valid,
	output	[`ADDRBITS-1:0]	mem_addr,
	output	[`DATABITS-1:0]	mem_in,
	output			mem_wrreq,
	output			mem_rdreq,
	
	// system control
	input			reset_n,
	input			clk
);
	reg	[`DATABITS-1:0] r_dcache_dataout;
	reg			r_dcache_valid;
	
	reg	[`DATABITS-1:0]	r_mem_in;
	reg			r_mem_wrreq;
	reg			r_mem_rdreq;
	reg	[`BANKNUM-1:0]	r_dcache_be;

	reg	[`LINENUM-1:0]	r_line_fill;
	wire	[`DATABITS-1:0]	line_out0;
	wire	[`DATABITS-1:0]	line_out1;
	wire	[`DATABITS-1:0]	line_out2;
	wire	[`DATABITS-1:0]	line_out3;

	reg	[`ADDRBITS-1:0]	r_mem_addr;
	wire	[`ADDRBITS-1:0]	mem_addr0;
	wire	[`ADDRBITS-1:0]	mem_addr1;
	wire	[`ADDRBITS-1:0]	mem_addr2;
	wire	[`ADDRBITS-1:0]	mem_addr3;

	wire	[`LINENUM-1:0]	line_valid;
	wire	[`LINENUM-1:0]	line_miss;

	wire	[`LINENUM-1:0]	int_mem_wrreq;
	wire	[`LINENUM-1:0]	int_mem_rdreq;

	reg	[`TTLBITS-1:0]	ttl0;
	reg	[`TTLBITS-1:0]	ttl1;
	reg	[`TTLBITS-1:0]	ttl2;
	reg	[`TTLBITS-1:0]	ttl3;

	reg	[`TTLBITS-1:0]	v_low01;
	reg	[`TTLBITS-1:0]	v_low23;

	reg	[`LINENUM-1:0]	v_fill01;
	reg	[`LINENUM-1:0]	v_fill23;
	reg	[`LINENUM-1:0]	v_fill;
	reg			r_dcache_req;
	

	assign	dcache_dataout	=r_dcache_dataout;
	assign	dcache_valid	=r_dcache_valid;
	assign	mem_in		=r_mem_in;
	assign	mem_wrreq	=r_mem_wrreq;
	assign	mem_rdreq	=r_mem_rdreq;
	assign	mem_addr	=r_mem_addr;


	always	@(dcache_addr,dcache_wordlen)
	begin
		case({dcache_addr[1:0],dcache_wordlen})
			// 8 bit byte enables
			4'b0000:	begin	r_dcache_be<=4'b0001;end
			4'b0100:	begin	r_dcache_be<=4'b0010;end
			4'b1000:	begin	r_dcache_be<=4'b0100;end
			4'b1100:	begin	r_dcache_be<=4'b1000;end
			// 16 bit byte enables
			4'b0001:	begin	r_dcache_be<=4'b0011;end
			4'b1001:	begin	r_dcache_be<=4'b1100;end
			// 32 bit byte enables
			4'b0010:	begin	r_dcache_be<=4'b1111;end
			// alignment problem
			default:	begin	r_dcache_be<=4'b0000;end
		endcase
	end

	always	@(mem_addr0,mem_addr1,mem_addr2,mem_addr3,int_mem_rdreq,int_mem_wrreq)
	begin
		case (int_mem_rdreq|int_mem_wrreq)
			4'b0001:	begin	r_mem_addr<=mem_addr0;r_mem_rdreq<=int_mem_rdreq[0];r_mem_wrreq<=int_mem_wrreq[0];end
			4'b0010:	begin	r_mem_addr<=mem_addr1;r_mem_rdreq<=int_mem_rdreq[1];r_mem_wrreq<=int_mem_wrreq[1];end
			4'b0100:	begin	r_mem_addr<=mem_addr2;r_mem_rdreq<=int_mem_rdreq[2];r_mem_wrreq<=int_mem_wrreq[2];end
			4'b1000:	begin	r_mem_addr<=mem_addr3;r_mem_rdreq<=int_mem_rdreq[3];r_mem_wrreq<=int_mem_wrreq[3];end
			default:	begin	r_mem_addr<=32'b0;r_mem_rdreq<=1'b0;r_mem_wrreq<=1'b0;end
		endcase
	end
	always	@(line_out0,line_out1,line_out2,line_out3,int_mem_wrreq)
	begin
		case(int_mem_wrreq)
			4'b0001:	begin	r_mem_in<=line_out0;end
			4'b0010:	begin	r_mem_in<=line_out1;end
			4'b0100:	begin	r_mem_in<=line_out2;end
			4'b1000:	begin	r_mem_in<=line_out3;end
			default:	begin	r_mem_in<=32'b0;end
		endcase
	end
	always	@(line_out0,line_out1,line_out2,line_out3,line_valid)
	begin
		case(line_valid)
			4'b0001:	begin	r_dcache_dataout<=line_out0;r_dcache_valid<=line_valid[0];end
			4'b0010:	begin	r_dcache_dataout<=line_out1;r_dcache_valid<=line_valid[1];end
			4'b0100:	begin	r_dcache_dataout<=line_out2;r_dcache_valid<=line_valid[2];end
			4'b1000:	begin	r_dcache_dataout<=line_out3;r_dcache_valid<=line_valid[3];end
			default:	begin	r_dcache_dataout<=32'b0;r_dcache_valid<=1'b0;end
		endcase
	end
	dcache_line	DCACHE_LINE0(
		.dcache_addr		(dcache_addr),
		.dcache_datain		(dcache_datain),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_be		(r_dcache_be),

		.line_fill		(r_line_fill[0]),
		.line_out		(line_out0),
		.line_valid		(line_valid[0]),
		.line_miss		(line_miss[0]),

		.mem_out		(mem_out),
		.mem_burstlen		(`MEM_BURSTLEN),
		.mem_valid		(mem_valid),
		.mem_addr		(mem_addr0),
		.mem_rdreq		(int_mem_rdreq[0]),
		.mem_wrreq		(int_mem_wrreq[0]),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_line	DCACHE_LINE1(
		.dcache_addr		(dcache_addr),
		.dcache_datain		(dcache_datain),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_be		(r_dcache_be),

		.line_fill		(r_line_fill[1]),
		.line_out		(line_out1),
		.line_valid		(line_valid[1]),
		.line_miss		(line_miss[1]),

		.mem_out		(mem_out),
		.mem_burstlen		(`MEM_BURSTLEN),
		.mem_valid		(mem_valid),
		.mem_addr		(mem_addr1),
		.mem_rdreq		(int_mem_rdreq[1]),
		.mem_wrreq		(int_mem_wrreq[1]),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_line	DCACHE_LINE2(
		.dcache_addr		(dcache_addr),
		.dcache_datain		(dcache_datain),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_be		(r_dcache_be),

		.line_fill		(r_line_fill[2]),
		.line_out		(line_out2),
		.line_valid		(line_valid[2]),
		.line_miss		(line_miss[2]),

		.mem_out		(mem_out),
		.mem_burstlen		(`MEM_BURSTLEN),
		.mem_valid		(mem_valid),
		.mem_addr		(mem_addr2),
		.mem_rdreq		(int_mem_rdreq[2]),
		.mem_wrreq		(int_mem_wrreq[2]),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	dcache_line	DCACHE_LINE3(
		.dcache_addr		(dcache_addr),
		.dcache_datain		(dcache_datain),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_be		(r_dcache_be),

		.line_fill		(r_line_fill[3]),
		.line_out		(line_out3),
		.line_valid		(line_valid[3]),
		.line_miss		(line_miss[3]),

		.mem_out		(mem_out),
		.mem_burstlen		(`MEM_BURSTLEN),
		.mem_valid		(mem_valid),
		.mem_addr		(mem_addr3),
		.mem_rdreq		(int_mem_rdreq[3]),
		.mem_wrreq		(int_mem_wrreq[3]),

		.reset_n		(reset_n),
		.clk			(clk)
	);

	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			r_dcache_dataout	<=`DATABITS'b0;
			r_dcache_valid		<=1'b0;
			r_mem_in		<=`DATABITS'b0;
			r_mem_wrreq		<=1'b0;
			r_mem_rdreq		<=1'b0;
			r_dcache_req		<=1'b0;
			r_dcache_be		<=1'b0;
			r_line_fill		<=`LINENUM'b0;
			ttl0			<=`TTLBITS'd0;	
			ttl1			<=`TTLBITS'd0;	
			ttl2			<=`TTLBITS'd0;	
			ttl3			<=`TTLBITS'd0;	
			
		end else begin
			v_fill	= `LINENUM'b0;
			if (r_dcache_req)
			begin
				if (line_miss==4'b1111)
				begin
					v_low01	=ttl0;
					v_fill01=`LINENUM'b0001;
					v_low23	=ttl2;
					v_fill23=`LINENUM'b0100;

					if (ttl0<=ttl1)
					begin
						v_low01	=ttl1;
						v_fill01=`LINENUM'b0010;
					end
					if (ttl2<=ttl3)
					begin
						v_low23	=ttl3;
						v_fill23=`LINENUM'b1000;
					end

			
					if (v_low01<=v_low23)
					begin
						v_fill	=v_fill23;
					end else begin
						v_fill	=v_fill01;
					end
				end else begin
					if (line_miss[0] & ttl0!=`TTLBITS'd255)
					begin
						ttl0<=ttl0+`TTLBITS'd1;
					end else if (line_valid[0]) 
					begin
						ttl0<=`TTLBITS'd0;
					end
					if (line_miss[1] & ttl1!=`TTLBITS'd255)
					begin
						ttl1<=ttl1+`TTLBITS'd1;
					end else if (line_valid[1]) 
					begin
						ttl1<=`TTLBITS'd1;
					end
					if (line_miss[2] & ttl2!=`TTLBITS'd255)
					begin
						ttl2<=ttl2+`TTLBITS'd1;
					end else if (line_valid[2]) 
					begin
						ttl2<=`TTLBITS'd0;
					end
					if (line_miss[3] & ttl3!=`TTLBITS'd255)
					begin
						ttl3<=ttl3+`TTLBITS'd1;
					end else if (line_valid[3]) 
					begin
						ttl3<=`TTLBITS'd0;
					end

				end
			end
			r_dcache_req	<=dcache_rdreq|dcache_wrreq;
			r_line_fill	<= v_fill;
		end
	end
endmodule
