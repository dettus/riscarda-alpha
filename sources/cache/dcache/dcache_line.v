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
`define	BANKNUM		4

`define	CACHEWORDS	32
`define	CACHEADDRBITS	5
`define	ADDRMSBBITS	25		// ADDRBITS-CACHEADDRBITS-2


module	dcache_line(
	// connection to the CPU core
	input	[`ADDRBITS-1:0]	dcache_addr,
	input	[`DATABITS-1:0]	dcache_datain,
	input			dcache_rdreq,
	input			dcache_wrreq,
	input	[`BANKNUM-1:0]	dcache_be,
	// connection to the controller
	input			line_fill,
	output	[`DATABITS-1:0]	line_out,
	output			line_valid,
	output			line_miss,


	// connection to the memory controller
	input	[`DATABITS-1:0]	mem_out,
	input	[15:0]		mem_burstlen,
	input			mem_valid,
	output	[`ADDRBITS-1:0]	mem_addr,
	output			mem_rdreq,
	output			mem_wrreq,
	

	
	input		reset_n,
	input		clk
);
	reg				r_line_valid;
	reg				v_line_valid;
	reg				r_line_miss;

	reg	[`ADDRBITS-1:0]		r_mem_addr;
	reg				r_mem_rdreq;
	reg				r_mem_wrreq;
	

	reg	[`CACHEADDRBITS-1:0]	dpram_flushaddr;
	reg	[`CACHEADDRBITS-1:0]	dpram_raddr;
	reg	[`CACHEADDRBITS-1:0]	dpram_waddr;
	reg	[`CACHEADDRBITS-1:0]	v_dpram_waddr;
	reg	[`DATABITS-1:0]		dpram_datain;
	reg	[`BANKNUM-1:0]		dpram_we;
	reg				v_dpram_we;

	reg	[2:0]			msr;

	reg	[15:0]			cnt_burst;
	reg	[15:0]			cnt_fill;

	reg	[`ADDRMSBBITS-1:0]	addrmsb1;
	reg	[`ADDRMSBBITS-1:0]	addrmsb2;

	reg				dirty;
	reg				write_request;
	reg	[`CACHEADDRBITS-1:0]	write_addr;
	reg	[`DATABITS-1:0]		write_value;
	reg				v_line_miss;


	localparam	[2:0]	MSR_INIT=3'b000,MSR_FILL=3'b001,MSR_VALID=3'b010,MSR_FLUSH=3'b011,MSR_BREATHER=3'b100;

	always @(dpram_flushaddr,msr,dcache_addr[`CACHEADDRBITS+1-1:2])
	begin
		dpram_raddr<=(msr==MSR_FLUSH)?dpram_flushaddr:dcache_addr[`CACHEADDRBITS+2:2];	// TODO: why not +2-1?
	end

	dpram_32x8	DPRAM0(
		.raddr		(dpram_raddr),
		.dataout	(line_out[ 7: 0]),
		.waddr		(dpram_waddr),
		.datain		(dpram_datain[ 7: 0]),
		.we		(dpram_we[0]),
		.clk		(clk)
	);

	dpram_32x8	DPRAM1(
		.raddr		(dpram_raddr),
		.dataout	(line_out[15: 8]),
		.waddr		(dpram_waddr),
		.datain		(dpram_datain[15: 8]),
		.we		(dpram_we[1]),
		.clk		(clk)
	);

	dpram_32x8	DPRAM2(
		.raddr		(dpram_raddr),
		.dataout	(line_out[23:16]),
		.waddr		(dpram_waddr),
		.datain		(dpram_datain[23:16]),
		.we		(dpram_we[2]),
		.clk		(clk)
	);

	dpram_32x8	DPRAM3(
		.raddr		(dpram_raddr),
		.dataout	(line_out[31:24]),
		.waddr		(dpram_waddr),
		.datain		(dpram_datain[31:24]),
		.we		(dpram_we[3]),
		.clk		(clk)
	);

	assign	line_valid	=r_line_valid;
	assign	line_miss	=r_line_miss;
	assign	mem_addr	=r_mem_addr;
	assign	mem_rdreq	=r_mem_rdreq;
	assign	mem_wrreq	=r_mem_wrreq;

	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			msr		<=MSR_INIT;
			r_line_valid	<=1'b0;
			r_line_miss	<=1'b0;
			r_mem_addr	<=`ADDRBITS'b0;
			r_mem_rdreq	<=1'b0;
			r_mem_wrreq	<=1'b0;
			dirty		<=1'b0;
			dpram_flushaddr	<=`CACHEADDRBITS'b0;
			dpram_datain	<=`DATABITS'b0;
			dpram_we	<=4'b0;
			cnt_burst	<=16'd0;
			cnt_fill	<=16'd0;
			addrmsb1	<=`ADDRMSBBITS'b0;
			addrmsb2	<=`ADDRMSBBITS'b0;
			write_request	<=1'b0;
			write_addr	<=`CACHEADDRBITS'd0;
			write_value	<=`DATABITS'h0;
		end else begin
			v_line_miss	=1'b0;
			case (msr)
				MSR_INIT:	begin
					if (dcache_rdreq | dcache_wrreq)
					begin
						write_request	<=dcache_wrreq;
						write_value	<=dcache_datain;
						write_addr	<=dcache_addr[`CACHEADDRBITS+2-1:2];
						v_line_miss	=1'b1;
					end
					if (line_fill)
					begin
						addrmsb2	<=addrmsb1;
						addrmsb1	<=dcache_addr[`ADDRBITS-1:`CACHEADDRBITS+2];
						dpram_waddr	<=`CACHEADDRBITS'd0;
						cnt_fill	<=16'd0;
						cnt_burst	<=mem_burstlen;
						msr		<=MSR_FILL;
					end
				end
				MSR_FILL:	begin
					if (cnt_fill==16'd`CACHEWORDS)
					begin
						msr		<=MSR_BREATHER;
						dpram_we	<=4'b0;
						r_mem_rdreq	<=1'b0;
						r_line_valid	<=1'b0;
					end else if (cnt_burst==mem_burstlen)
					begin
						dpram_we	<=4'b0;
						r_mem_addr	<={addrmsb1,dpram_waddr,2'b00};
						dpram_waddr     <=dpram_waddr-`CACHEADDRBITS'd1;
						r_mem_rdreq	<=1'b1;
						cnt_burst	<=16'd0;
					end else if (mem_valid)
					begin
						cnt_burst	<=cnt_burst+16'd1;
						cnt_fill	<=cnt_fill+16'd1;
						dpram_waddr	<=dpram_waddr+`CACHEADDRBITS'd1;
						dpram_we	<=4'b1111;
						if (write_request & (dpram_waddr==write_addr))	// in case the last cache request was a WRITE
						begin
							write_request	<=1'b0;
							dpram_datain	<=write_value;
						end else begin
							dpram_datain	<=mem_out;
						end
						r_mem_rdreq	<=1'b0;
					end else begin
						r_mem_rdreq	<=1'b0;
						dpram_we	<=4'b1111;
					end
				end
				MSR_BREATHER: begin
					r_line_valid	<=1'b1;
					msr		<=MSR_VALID;
				end
				MSR_VALID: begin
					v_line_valid	=1'b0;
					v_dpram_we	=1'b0;
					v_dpram_waddr	=dpram_waddr;	
				
					if ((dcache_rdreq|dcache_wrreq)&(dcache_addr[`ADDRBITS-1:`CACHEADDRBITS+2]!=addrmsb1))	// TODO: really? or +2+1??
					begin
						v_line_miss	=1'b1;
						write_request	<=dcache_wrreq;
						write_value	<=dcache_datain;
						write_addr	<=dcache_addr[`CACHEADDRBITS+2-1:2];
					end

					if (dcache_rdreq & (dcache_addr[`ADDRBITS-1:`CACHEADDRBITS+2]==addrmsb1))	// TODO: really? or +2+1??
					begin
						v_line_valid	=1'b1;
					end
					if (dcache_wrreq & (dcache_addr[`ADDRBITS-1:`CACHEADDRBITS+2]==addrmsb1))	// TODO: really? or +2+1??
					begin
						dirty		<=1'b1;
						v_line_valid	=1'b1;
						v_dpram_we	=1'b1;
						dpram_datain	<=dcache_datain;
						v_dpram_waddr	=dcache_addr[`CACHEADDRBITS+2-1:2];
					end
					
					if (line_fill)
					begin
						addrmsb2	<=addrmsb1;
						addrmsb1	<=dcache_addr[`ADDRBITS-1:`CACHEADDRBITS+2];
						v_dpram_waddr	=`CACHEADDRBITS'd0;
						dpram_flushaddr	<=`CACHEADDRBITS'd0;
						cnt_fill	<=16'd0;
						cnt_burst	<=mem_burstlen;
						msr		<=dirty? MSR_FLUSH:MSR_FILL;
					end
					r_line_valid	<=v_line_valid;
					dpram_we	<=v_dpram_we?dcache_be:4'b0000;
					dpram_waddr	<=v_dpram_waddr;
				end
				MSR_FLUSH: begin
					dirty		<=1'b0;
					if (cnt_fill==16'd`CACHEWORDS)
					begin
						dpram_waddr	<=`CACHEADDRBITS'd0;
						cnt_fill	<=16'd0;
						cnt_burst	<=mem_burstlen;
						msr		<=MSR_FILL;
						r_mem_wrreq	<=1'b0;
					end else begin
						cnt_fill	<=cnt_fill+16'd1;
						if (cnt_burst==mem_burstlen)
						begin
						 	cnt_burst	<=16'd0;
							r_mem_wrreq	<=1'b1;
						end else begin
							r_mem_wrreq	<=1'b1;
							cnt_burst	<=cnt_burst+16'd1;
						end
						r_mem_addr	<={addrmsb2,dpram_flushaddr,2'b00};
						dpram_flushaddr	<=dpram_flushaddr+`CACHEADDRBITS'd1;
					end
				end
			endcase
			r_line_miss<=v_line_miss;
		end
	end
endmodule

