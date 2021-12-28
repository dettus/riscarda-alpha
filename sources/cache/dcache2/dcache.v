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

module dcache
#(
parameter	DATABITS=32,
parameter	ADDRBITS=32,
parameter	LINENUM=4,
parameter	LSBITS=2,
parameter	CACHEADDRBITS=5,
parameter	CACHESIZE=2**CACHEADDRBITS,
parameter	CNTMISSBITS=8,
parameter	BANKNUM=4
)
(
	// connection to the CPU
	input	[ADDRBITS-1:0]		dcache_addr,
	input	[DATABITS-1:0]		dcache_in,
	output	[DATABITS-1:0]		dcache_out,	// 
	output				dcache_valid,	//
	input				dcache_rdreq,
	input				dcache_wrreq,
	input	[1:0]			dcache_wordlen,		// 0=byte, 1=halfword, 2=word

	output				dcache_busy,

	// connection to the big memory
	output	[ADDRBITS-1:0]		mem_addr,	//
	output	[DATABITS-1:0]		mem_in,		//
	input	[DATABITS-1:0]		mem_out,
	input				mem_valid,
	input	[15:0]			mem_burstlen,
	output				mem_rdreq,
	output				mem_wrreq,

	// system control
	input				reset_n,
	input				clk
);
	reg				r_dcache_busy;


	reg	[DATABITS-1:0]		r_dcache_out;	//
	reg				r_dcache_valid;
	reg	[ADDRBITS-1:0]		r_mem_addr;	//
	reg	[DATABITS-1:0]		r_mem_in;	//
	reg				r_mem_rdreq;
	reg				r_mem_wrreq;

	wire	[ADDRBITS-1:0]		line_mem_addr0;
	wire	[ADDRBITS-1:0]		line_mem_addr1;
	wire	[ADDRBITS-1:0]		line_mem_addr2;
	wire	[ADDRBITS-1:0]		line_mem_addr3;

	wire	[DATABITS-1:0]		line_out0;
	wire	[DATABITS-1:0]		line_out1;
	wire	[DATABITS-1:0]		line_out2;
	wire	[DATABITS-1:0]		line_out3;

	wire	[CNTMISSBITS-1:0]	flush_cnt_miss0;
	wire	[CNTMISSBITS-1:0]	flush_cnt_miss1;
	wire	[CNTMISSBITS-1:0]	flush_cnt_miss2;
	wire	[CNTMISSBITS-1:0]	flush_cnt_miss3;
	
	wire	[LINENUM-1:0]		line_valid;
	wire	[LINENUM-1:0]		line_miss;
	wire	[LINENUM-1:0]		line_dirty;
	

	reg	[LINENUM-1:0]		flush_mode;	
	reg				flush_write;
	reg	[CACHEADDRBITS-1:0]	flush_addr;
	reg				flush_dirty;
	reg	[BANKNUM-1:0]		byteenable;	//

	reg	[DATABITS-1:0]		line_in;
	reg				line_in_valid;
	reg	[CACHEADDRBITS-1:0]	flush_addr_mem;

	reg	[LINENUM-1:0]		v_flush_mode;
	reg	[LINENUM-1:0]		v_flush_mode01;
	reg	[LINENUM-1:0]		v_flush_mode23;
	reg	[CNTMISSBITS-1:0]	v_flush_cnt_miss01;
	reg	[CNTMISSBITS-1:0]	v_flush_cnt_miss23;
	reg				v_dirty;
	reg				v_dirty01;
	reg				v_dirty23;

	reg	[15:0]			cnt_flush;
	reg	[15:0]			cnt_burst;

	localparam [1:0]	MSR_VALID=2'b00,MSR_FLUSH_OUT=2'b01,MSR_FILL=2'b10;	
	reg	[1:0]			msr;
	

	assign	dcache_out=	r_dcache_out;
	assign	dcache_valid=	r_dcache_valid;
	assign	mem_rdreq=	r_mem_rdreq;
	assign	mem_wrreq=	r_mem_wrreq;

	assign	dcache_busy=	r_dcache_busy;




	always	@(dcache_addr[1:0],dcache_wordlen)
	begin
		case({dcache_wordlen,dcache_addr[LSBITS-2:0]})
			// bytes
			4'b0000:	begin	byteenable<=4'b0001;end
			4'b0001:	begin	byteenable<=4'b0010;end
			4'b0010:	begin	byteenable<=4'b0100;end
			4'b0011:	begin	byteenable<=4'b1000;end
			// half words
			4'b0100:	begin	byteenable<=4'b0011;end
			4'b0110:	begin	byteenable<=4'b1100;end
			// words
			4'b1000:	begin	byteenable<=4'b1111;end
			// otherwise: ALIGNMENT ERROR
			default:	begin	byteenable<=4'b0000;end
		endcase
	end

	always	@(line_valid,line_out0,line_out1,line_out2,line_out3)
	begin
		case(line_valid)
			4'b0001:	begin	r_dcache_out<=line_out0;r_dcache_valid<=1'b1;end
			4'b0010:	begin	r_dcache_out<=line_out1;r_dcache_valid<=1'b1;end
			4'b0100:	begin	r_dcache_out<=line_out2;r_dcache_valid<=1'b1;end
			4'b1000:	begin	r_dcache_out<=line_out3;r_dcache_valid<=1'b1;end
			default:	begin	r_dcache_out<='h0;r_dcache_valid<=1'b0;end
		endcase
	end

	always	@(flush_mode,flush_addr_mem,line_mem_addr0,line_mem_addr1,line_mem_addr2,line_mem_addr3)
	begin
		case (flush_mode)
			4'b0001:	begin	r_mem_addr<={line_mem_addr0[ADDRBITS-1:CACHEADDRBITS+LSBITS],flush_addr_mem,2'b0};end
			4'b0010:	begin	r_mem_addr<={line_mem_addr1[ADDRBITS-1:CACHEADDRBITS+LSBITS],flush_addr_mem,2'b0};end
			4'b0100:	begin	r_mem_addr<={line_mem_addr2[ADDRBITS-1:CACHEADDRBITS+LSBITS],flush_addr_mem,2'b0};end
			4'b1000:	begin	r_mem_addr<={line_mem_addr3[ADDRBITS-1:CACHEADDRBITS+LSBITS],flush_addr_mem,2'b0};end
			default:	begin	r_mem_addr<='b0;end
		endcase
	end
	
	always	@(flush_mode,line_out0,line_out1,line_out2,line_out3)
	begin
		case(flush_mode)
			4'b0001:	begin	r_mem_in<=line_out0;end
			4'b0010:	begin	r_mem_in<=line_out1;end
			4'b0100:	begin	r_mem_in<=line_out2;end
			4'b1000:	begin	r_mem_in<=line_out3;end
			default:	begin	r_mem_in<='h0;end
		endcase
	end

	dcache_line	
	#(
		.DATABITS		(DATABITS),
		.ADDRBITS		(ADDRBITS),
		.LSBITS			(LSBITS),
		.CACHEADDRBITS		(CACHEADDRBITS),
		.CACHESIZE		(CACHESIZE),
		.CNTMISSBITS		(CNTMISSBITS)
	)DCACHE_LINE0(
		.dcache_addr		(dcache_addr),
		.dcache_in		(dcache_in),
		.line_out		(line_out0),
		.line_valid		(line_valid[0]),
		.line_miss		(line_miss[0]),
		.line_dirty		(line_dirty[0]),
		.byteenable		(byteenable),
		
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),

		.flush_cnt_miss		(flush_cnt_miss0),
		.flush_mode		(flush_mode[0]),
		.flush_write		(flush_write),
		.flush_addr		(flush_addr),
		.flush_dirty		(flush_dirty),
		
		.mem_addr		(line_mem_addr0),
		.line_in		(line_in),
		.line_in_valid		(line_in_valid),

		.reset_n		(reset_n),
		.clk			(clk)
	);		


	dcache_line	
	#(
		.DATABITS		(DATABITS),
		.ADDRBITS		(ADDRBITS),
		.LSBITS			(LSBITS),
		.CACHEADDRBITS		(CACHEADDRBITS),
		.CACHESIZE		(CACHESIZE),
		.CNTMISSBITS		(CNTMISSBITS)
	)DCACHE_LINE1(
		.dcache_addr		(dcache_addr),
		.dcache_in		(dcache_in),
		.line_out		(line_out1),
		.line_valid		(line_valid[1]),
		.line_miss		(line_miss[1]),
		.line_dirty		(line_dirty[1]),
		.byteenable		(byteenable),
		
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),

		.flush_cnt_miss		(flush_cnt_miss1),
		.flush_mode		(flush_mode[1]),
		.flush_write		(flush_write),
		.flush_addr		(flush_addr),
		.flush_dirty		(flush_dirty),
		
		.mem_addr		(line_mem_addr1),
		.line_in		(line_in),
		.line_in_valid		(line_in_valid),

		.reset_n		(reset_n),
		.clk			(clk)
	);		


	dcache_line	
	#(
		.DATABITS		(DATABITS),
		.ADDRBITS		(ADDRBITS),
		.LSBITS			(LSBITS),
		.CACHEADDRBITS		(CACHEADDRBITS),
		.CACHESIZE		(CACHESIZE),
		.CNTMISSBITS		(CNTMISSBITS)
	)DCACHE_LINE2(
		.dcache_addr		(dcache_addr),
		.dcache_in		(dcache_in),
		.line_out		(line_out0),
		.line_valid		(line_valid[2]),
		.line_miss		(line_miss[2]),
		.line_dirty		(line_dirty[2]),
		.byteenable		(byteenable),
		
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),

		.flush_cnt_miss		(flush_cnt_miss2),
		.flush_mode		(flush_mode[2]),
		.flush_write		(flush_write),
		.flush_addr		(flush_addr),
		.flush_dirty		(flush_dirty),
		
		.mem_addr		(line_mem_addr2),
		.line_in		(line_in),
		.line_in_valid		(line_in_valid),

		.reset_n		(reset_n),
		.clk			(clk)
	);		


	dcache_line	
	#(
		.DATABITS		(DATABITS),
		.ADDRBITS		(ADDRBITS),
		.LSBITS			(LSBITS),
		.CACHEADDRBITS		(CACHEADDRBITS),
		.CACHESIZE		(CACHESIZE),
		.CNTMISSBITS		(CNTMISSBITS)
	)DCACHE_LINE3(
		.dcache_addr		(dcache_addr),
		.dcache_in		(dcache_in),
		.line_out		(line_out3),
		.line_valid		(line_valid[3]),
		.line_miss		(line_miss[3]),
		.line_dirty		(line_dirty[3]),
		.byteenable		(byteenable),
		
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wrreq		(dcache_wrreq),

		.flush_cnt_miss		(flush_cnt_miss3),
		.flush_mode		(flush_mode[3]),
		.flush_write		(flush_write),
		.flush_addr		(flush_addr),
		.flush_dirty		(flush_dirty),
		
		.mem_addr		(line_mem_addr3),
		.line_in		(line_in),
		.line_in_valid		(line_in_valid),

		.reset_n		(reset_n),
		.clk			(clk)
	);		

	


	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			r_dcache_busy	<=1'b0;
			r_mem_rdreq	<=1'b0;
			r_mem_wrreq	<=1'b0;
			flush_mode	<=4'b0000;
			flush_write	<=1'b0;
			flush_addr	<=5'd0;
			flush_dirty	<=1'b0;
			flush_addr_mem	<=5'd0;
			msr		<=MSR_VALID;
		end else begin
			v_flush_mode	=4'b0000;
			v_dirty		=1'b0;
			if (flush_cnt_miss0>=flush_cnt_miss1)
			begin
				v_flush_mode01		=4'b0001;
				v_flush_cnt_miss01	=flush_cnt_miss0;
				v_dirty01		=line_dirty[0];
			end else begin
				v_flush_mode01=4'b0010;
				v_flush_cnt_miss01	=flush_cnt_miss1;
				v_dirty01		=line_dirty[1];
			end
			if (flush_cnt_miss2>=flush_cnt_miss3)
			begin
				v_flush_mode23=4'b0100;
				v_flush_cnt_miss23	=flush_cnt_miss2;
				v_dirty23		=line_dirty[2];
			end else begin
				v_flush_mode23=4'b1000;
				v_flush_cnt_miss23	=flush_cnt_miss3;
				v_dirty23		=line_dirty[3];
			end

			if (v_flush_cnt_miss01>=v_flush_cnt_miss23)
			begin
				v_flush_mode	=v_flush_mode01;
				v_dirty		=v_dirty01;
			end else begin
				v_flush_mode	=v_flush_mode23;
				v_dirty		=v_dirty23;
			end
		
			case (msr)
			MSR_VALID: begin
				if (line_miss==4'b1111)
				begin
					if (dcache_rdreq | dcache_wrreq)
					begin
						cnt_flush	<=16'd0;
						cnt_burst	<=16'd0;
						flush_addr_mem	<='d0;
						flush_addr	<='d0;
						flush_mode	<=v_flush_mode;
						msr		<=v_dirty? MSR_FLUSH_OUT:MSR_FILL;
						r_mem_rdreq	<=!v_dirty;
						r_dcache_busy	<=1'b1;
					end
				end
			end
			MSR_FLUSH_OUT:	begin
				if (cnt_flush==CACHESIZE)
				begin
					cnt_flush	<='d0;
					cnt_burst	<='d0;
					flush_addr_mem	<='d0;
					flush_addr	<='d0;
					r_dcache_busy	<=1'b0;
					msr		<=MSR_FILL;
					r_mem_rdreq	<=1'b0;
					flush_write	<=1'b1;
				end else if (cnt_burst==mem_burstlen)
				begin
					cnt_burst	<='d0;
					r_mem_wrreq	<=1'b1;
					flush_write	<=1'b0;
				end else begin
					cnt_flush	<=cnt_flush+'d1;
					cnt_burst	<=cnt_burst+'d1;
					flush_addr_mem	<=cnt_flush;
					flush_addr	<=flush_addr+'d1;
					r_mem_wrreq	<=1'b1;
				end				
			end
			MSR_FILL: begin
				if (cnt_flush==CACHESIZE)
				begin
					r_dcache_busy	<=1'b0;
					flush_mode	<=4'b0000;	
					msr		<=MSR_VALID;
					r_mem_rdreq	<=1'b0;
					flush_write	<=1'b0;
					line_in_valid	<=1'b0;
				end else if (cnt_burst==mem_burstlen)
				begin
					cnt_burst	<='d0;
					r_mem_rdreq	<=1'b1;
					flush_write	<=1'b1;
					line_in_valid	<=1'b0;
				end else if (mem_valid) begin
					r_mem_rdreq	<=1'b0;
					cnt_burst	<=cnt_burst+'d1;
					cnt_flush	<=cnt_flush+'d1;
					flush_addr_mem	<=flush_addr_mem+'d1;
					flush_addr	<=cnt_flush;
					flush_write	<=1'b1;
					line_in		<=mem_out;
					line_in_valid	<=1'b1;
				end
			end
				
			endcase
		end
	end
endmodule