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

module icache(
	// connection to the CPU
	input	[31:0]	icache_rdaddr,
	input		icache_rdreq,
	output	[31:0]	icache_dataout,
	output		icache_valid,
	// TODO:in case the dcache is being written to and the same region is being cached, it needs to be flagged as "dirty"
//	input	[31:0]	dcache_wraddr,
//	input		dcache_wrreq,

	// connection to the main memory controller
	output	[31:0]	mem_rdaddr,
	output		mem_rdreq,
	input	[15:0]	mem_burstlen,
	input	[31:0]	mem_dataout,
	input		mem_datavalid,

	
	input		clk,
	input		reset_n
);
	reg		icache_valid;
	reg	[31:0]	mem_rdaddr;
	reg		mem_rdreq;

	reg	[15:0]	cnt_burst;
	reg	[15:0]	cnt_fill;
	parameter	[1:0]	MSR_INIT=2'b00,
				MSR_FILL=2'b01,
				MSR_VALID=2'b11;
	reg	[ 1:0]	msr;
	reg	[31:0]	r_mem_dataout;
	reg	[ 4:0]	mem_waddr;
	reg		r_mem_datavalid;
	reg	[24:0]	addrmsb;


	dpram_32x32	CACHEMEM0
	(
		.raddr		(icache_rdaddr[6:2]),
		.dataout	(icache_dataout),
		.waddr		(mem_waddr),
		.datain		(r_mem_dataout),
		.we		(r_mem_datavalid),
		.clk		(clk)
	);

	always @(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			msr		<= MSR_INIT;
			icache_valid	<=1'b0;
			mem_rdreq	<=1'b0;
			cnt_burst	<=16'd0;
			cnt_fill	<=16'd0;
			addrmsb		<=25'd0;
			r_mem_dataout	<=32'b0;
			r_mem_datavalid	<=1'b0;
			mem_waddr	<=5'd0;
		end else begin
			r_mem_dataout	<=mem_dataout;
			case(msr)
				MSR_INIT: begin
					icache_valid	<=1'b0;
					if (icache_rdreq)
					begin
						addrmsb		<=icache_rdaddr[31:7];
						cnt_burst	<=16'd0;
						cnt_fill	<=16'd0;
						mem_waddr	<=5'd31;
						msr		<=MSR_FILL;
						mem_rdaddr	<={icache_rdaddr[31:2],2'b00};
						mem_rdreq	<=1'b1;
					end
				end
				MSR_FILL: begin
					mem_rdaddr	<={addrmsb,mem_waddr,2'b00};
					if (cnt_fill==16'd32)
					begin
						r_mem_datavalid	<=1'b0;
						msr		<=MSR_VALID;
						mem_rdreq	<=1'b0;
						icache_valid	<=1'b1;
					end else if (cnt_burst==mem_burstlen)
					begin
						r_mem_datavalid	<=1'b0;
						cnt_burst	<=16'd0;
						mem_rdreq	<=1'b1;
					end else if (mem_datavalid)
					begin
						r_mem_datavalid	<=1'b1;
						mem_rdreq	<=1'b0;
						cnt_burst	<=cnt_burst+16'd1;
						cnt_fill	<=cnt_fill+16'd1;
						mem_waddr	<=mem_waddr+5'd1;
					end else begin
						r_mem_datavalid	<=1'b0;
						mem_rdreq	<=1'b0;
					end
				end
				MSR_VALID: begin
					if (icache_rdreq)
					begin
						if (icache_rdaddr[31:7]==addrmsb)
						begin
							icache_valid	<=1'b1;
						end else begin
							icache_valid	<=1'b0;
							addrmsb		<=icache_rdaddr[31:7];
							cnt_burst	<=16'd0;
							cnt_fill	<=16'd0;
							mem_waddr	<=5'd31;
							msr		<=MSR_FILL;
							mem_rdaddr	<={icache_rdaddr[31:2],2'b00};
							mem_rdreq	<=1'b1;
						end
					end else begin
						icache_valid	<=1'b0;
					end
				end

			endcase
		end
	end
endmodule
