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
`define	MAXTTL		255
`define	TTLBITS		8

`define	CACHEWORDS	32
`define	CACHEADDRBITS	5
`define	ADDRMSBBITS	25		// ADDRBITS-CACHEADDRBITS-2


module	dcache_line(
	// connection to the CPU core
	input	[`ADDRBITS-1:0]	dcache_addr,
	input	[`DATABITS-1:0]	dcache_datain,
	input			dcache_rdreq,
	input			dcache_wrreq,
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
	reg				line_valid;
	reg				v_line_valid;
	reg				line_miss;

	reg	[`ADDRBITS-1:0]		mem_addr;
	reg				mem_rdreq;
	reg				mem_wrreq;
	

	reg	[`CACHEADDRBITS-1:0]	dpram_flushaddr;
	reg	[`CACHEADDRBITS-1:0]	dpram_raddr;
	reg	[`CACHEADDRBITS-1:0]	dpram_waddr;
	reg	[`CACHEADDRBITS-1:0]	v_dpram_waddr;
	reg	[`DATABITS-1:0]		dpram_datain;
	reg				dpram_we;
	reg				v_dpram_we;

	reg	[2:0]			msr;

	reg	[15:0]			cnt_burst;
	reg	[15:0]			cnt_fill;

	reg	[`ADDRMSBBITS-1:0]	addrmsb1;
	reg	[`ADDRMSBBITS-1:0]	addrmsb2;

	reg				dirty;


	localparam	[2:0]	MSR_INIT=3'b000,MSR_FILL=3'b001,MSR_VALID=3'b010,MSR_FLUSH=3'b011;

	always @(dpram_flushaddr,msr,dcache_addr[`CACHEADDRBITS+1-1:2])
	begin
		dpram_raddr<=(msr==MSR_FLUSH)?dpram_flushaddr:dcache_addr[`CACHEADDRBITS+1-1:2];
	end

	dpram_32x32	DPRAM0(
		.raddr		(dpram_raddr),
		.dataout	(line_out),
		.waddr		(dpram_waddr),
		.datain		(dpram_datain),
		.we		(dpram_we),
		.clk		(clk)
	);


	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			msr		<=MSR_INIT;
			line_valid	<=1'b0;
			line_miss	<=1'b1;
			mem_addr	<=`ADDRBITS'b0;
			mem_rdreq	<=1'b0;
			mem_wrreq	<=1'b0;
			dirty		<=1'b0;
			dpram_flushaddr	<=`CACHEADDRBITS'b0;
			dpram_datain	<=`DATABITS'b0;
			cnt_burst	<=16'd0;
			cnt_fill	<=16'd0;
			addrmsb1	<=`ADDRMSBBITS'b0;
			addrmsb2	<=`ADDRMSBBITS'b0;
		end else begin
			case (msr)
				MSR_INIT:	begin
					line_miss	<=1'b1;
					if (line_fill)
					begin
						addrmsb2	<=addrmsb1;
						addrmsb1	<=dcache_addr[`ADDRBITS-1:`CACHEADDRBITS+2-1];
						dpram_waddr	<=`CACHEADDRBITS'd0;
						cnt_fill	<=16'd0;
						cnt_burst	<=mem_burstlen;
						msr		<=MSR_FILL;
					end
				end
				MSR_FILL:	begin
					line_miss	<=1'b0;
					if (cnt_fill==16'd`CACHEWORDS)
					begin
						msr		<=MSR_VALID;
						dpram_we	<=1'b0;
						mem_rdreq	<=1'b0;
					end else if (cnt_burst==mem_burstlen)
					begin
						dpram_we	<=1'b0;
						mem_addr	<={addrmsb1,dpram_waddr,2'b00};
						dpram_waddr     <=dpram_waddr-`CACHEADDRBITS'd1;
						mem_rdreq	<=1'b1;
						cnt_burst	<=16'd0;
					end else if (mem_valid)
					begin
						cnt_burst	<=cnt_burst+16'd1;
						cnt_fill	<=cnt_fill+16'd1;
						dpram_waddr	<=dpram_waddr+`CACHEADDRBITS'd1;
						dpram_we	<=1'b1;
						dpram_datain	<=mem_out;
						mem_rdreq	<=1'b0;
					end else begin
						mem_rdreq	<=1'b0;
						dpram_we	<=1'b0;
					end
				end
				MSR_VALID: begin
					v_line_valid	=1'b0;
					v_dpram_we	=1'b0;
					v_dpram_waddr	=dpram_waddr;	
				
					line_miss<= (dcache_rdreq|dcache_wrreq)&(dcache_addr[`ADDRBITS-1:`CACHEADDRBITS+2-1]!=addrmsb1);

					if (dcache_rdreq & (dcache_addr[`ADDRBITS-1:`CACHEADDRBITS+2-1]!=addrmsb1))
					begin
						v_line_valid	=1'b1;
					end
					if (dcache_wrreq & (dcache_addr[`ADDRBITS-1:`CACHEADDRBITS+2-1]!=addrmsb1))
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
						addrmsb1	<=dcache_addr[`ADDRBITS-1:`CACHEADDRBITS+2-1];
						v_dpram_waddr	=`CACHEADDRBITS'd0;
						dpram_flushaddr	<=`CACHEADDRBITS'd0;
						cnt_fill	<=16'd0;
						cnt_burst	<=mem_burstlen;
						msr		<=dirty? MSR_FLUSH:MSR_FILL;
					end
					line_valid	=v_line_valid;
					dpram_we	=v_dpram_we;
					dpram_waddr	=v_dpram_waddr;
				end
				MSR_FLUSH: begin
					line_miss	<=1'b0;
					dirty		<=1'b0;
					if (cnt_fill==16'd`CACHEWORDS)
					begin
						dpram_waddr	<=`CACHEADDRBITS'd0;
						cnt_fill	<=16'd0;
						cnt_burst	<=mem_burstlen;
						msr		<=MSR_FILL;
						mem_wrreq	<=1'b0;
					end else begin
						cnt_fill	<=cnt_fill+16'd1;
						if (cnt_burst==mem_burstlen)
						begin
						 	cnt_burst	<=16'd0;
							mem_wrreq	<=1'b1;
						end else begin
							mem_wrreq	<=1'b0;
							cnt_burst	<=cnt_burst+16'd1;
						end
						mem_addr	<={addrmsb2,dpram_flushaddr,2'b00};
						dpram_flushaddr	<=dpram_flushaddr+`CACHEADDRBITS'd1;
					end
				end
			endcase
		end
	end
endmodule

