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
	input	[31:0]	mem_dataout,
	input		mem_datavalid,

	
	input		clk,
	input		reset_n
);
	reg		icache_valid;
	reg	[31:0]	mem_rdaddr;
	reg		mem_rdreq;
	reg	[ 4:0]	r_wraddr;
	reg	[31:0]	r_mem_dataout;
	reg		r_mem_datavalid;
	reg		r_datavalid;
	reg	[ 1:0]	msr;

	reg	[26:0]	addr_msb;
	reg		r_icache_rdreq;

	localparam [1:0] 
		MSR_INIT=2'b00,
		MSR_VALID=2'b01,
		MSR_REQUEST=2'b10,
		MSR_FILL=2'b11;


	dpram_32x32	ICACHERAM0(
		.raddr		(icache_rdaddr[6:2]),
		.dataout	(icache_dataout),
		.waddr		(r_wraddr),
		.datain		(r_mem_dataout),
		.we		(r_mem_datavalid),
		.clk		(clk)
		
	);

	always @(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			icache_valid	<=1'b0;
			mem_rdaddr	<=32'b0;
			mem_rdreq	<=1'b0;
			msr		<=MSR_INIT;
			r_wraddr	<=5'd0;
			r_mem_dataout	<=32'b0;
			r_mem_datavalid	<=1'b0;
			addr_msb	<=27'd0;
			r_icache_rdreq	<=1'b0;
		end else begin
			case (msr)
				MSR_INIT: begin
					r_datavalid	<=1'b0;
					if (icache_rdreq)
					begin
						msr		<=MSR_REQUEST;
						addr_msb	<=icache_rdaddr[31:5];
						mem_rdaddr	<=icache_rdaddr;
						mem_rdreq	<=1'b1;
						r_icache_rdreq	<=1'b1;
					end
				end
				MSR_REQUEST: begin
					r_mem_datavalid	<=mem_datavalid;
					r_mem_dataout	<=mem_dataout;
					mem_rdreq	<=1'b0;
					r_wraddr		<=5'd0;
					if (mem_datavalid)
					begin
						msr		<=MSR_FILL;
					end
				end
				MSR_FILL: begin
					r_mem_datavalid	<=mem_datavalid;
					r_mem_dataout	<=mem_dataout;
					if (mem_datavalid)
					begin
						r_wraddr<=r_wraddr+5'd1;
						if (r_wraddr==5'd31)
						begin
							msr	<=MSR_VALID;
						end
					end
				end
				MSR_VALID: begin
					r_mem_datavalid	<=1'b0;
					if (r_icache_rdreq | icache_rdreq)
					begin
						if (addr_msb==icache_rdaddr[31:5])
						begin
							r_icache_rdreq	<=1'b0;
							r_datavalid	<=1'b1;
						end else begin
							msr		<=MSR_REQUEST;
							addr_msb	<=icache_rdaddr[31:5];
							mem_rdaddr	<=icache_rdaddr;
							mem_rdreq	<=1'b1;
							r_icache_rdreq	<=1'b1;
							r_datavalid	<=1'b0;
						end
					end
				end
			endcase
		end
	end
endmodule
