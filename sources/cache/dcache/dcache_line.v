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
`define	ADDRMSBBITS	(`ADDRBITS-CACHEADDRBITS-2-1)


module	dcache_line(
	input	[`ADDRBITS-1:0]		dcache_addr;
	input				dcache_rdreq;
	input				dcache_wrreq;
	input	[`DATABITS-1:0]		dcache_in;
	output	[`DATABITS-1:0]		line_out;
	output				line_valid;
	

	output	[`ADDRBITS-1:0]		mem_addr;
	output				mem_rdreq;
	input	[15:0]			mem_burstlen;
	input	[`DATABITS-1:0]		mem_dataout;
	input				mem_valid;


	


	output	[`TTLBITS-1:0]		ttl;
	output				miss;
	input				fill_req;

	input				reset_n;
	input				clk;
);
	reg	[`TTLBITS-1:0]		ttl;
	reg	[`TTLBITS-1:0]		v_ttl;
	reg				miss;
	reg				v_miss;
	reg	[`ADDRMSBBITS:0]	addrmsb;
	reg	[`ADDRMSBBITS:0]	addrmsb2;
	reg	[1:0]			msr;
	localparam	[1:0]	MSR_INIT=2'b00,MSR_FILL=2'b01,MSR_PREVALID=2'b10;


	reg				dirty;
	reg	[`ADDRBITS-1:0]]	r_dcache_addr;

	reg	[`ADDRBITS-1:0]		mem_addr;
	reg				v_mem_addr;
	reg				mem_rdreq;
	reg				v_mem_rdreq;

	reg	[15:0]			cnt_fill;
	reg	[15:0]			cnt_burst;

	reg	[`CACHEADDRBITS-1:0]	addr_flush;
	reg	[`CACHEADDRBITS-1:0]	dpram_waddr;
	reg	[`DATABITS-1:0]		dpram_datain;
	reg				dpram_we;

	reg	[`DATABITS-1:0]		line_out;
	reg				line_valid;

	reg				v_line_valid;
	reg				v_miss;
	reg				v_dpram_we;
	reg				r_rdreq;

	dpram_32x32	DPRAM0(
		.rdaddr			(dpram_rdaddr),
		.dataout		(line_out),
		.waddr			(dpram_waddr),
		.datain			(dpram_datain),
		.wr			(dpram_we),
		.clk			(clk)
	);

	always	@(msr,dcache_addr[`CACHEADDRBITS+2-1:2])
	begin
		if (msr==MSR_VALID)
		begin
			dpram_rdaddr<=dcache_addr[`CACHEADDRBITS+2-1:2];
		end else begin
			dpram_rdaddr<=addr_flush;
		end
	end



	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			ttl		<=`TTLBITS'd0;
			addrmsb		<=`ADDRMSBBITS'b0;
			dirty		<=1'b0;
			msr		<=MSR_INIT;
			miss		<=1'b1;
			cnt_burst	<=16'd0;
			cnt_fill	<=16'd0'
		end else begin
			r_dcache_addr	<=dcache_addr;
			v_dpram_we	=1'b0;
			v_ttl		=ttl;
			v_mem_addr	=`ADDRBITS'h0;
			v_mem_rdreq	=1'b0;
			v_miss		=1'b0;
			v_line_valid	=1'b0;

			r_wrreq		<=wrreq;
			case (msr)
				MSR_INIT: begin
					v_miss	=(rdreq | wrreq);
					if (fill_req)
					begin
						addrmsb		<=dcache_addr[`ADDRBITS:`CACHEADDRBITS+2];
						msr		<= MSR_FILL;
						v_mem_addr	={dcache_addr[`ADDRBITS-1:2,2'b00};
						v_mem_rdreq	=1'b1;
					end
				end
				MSR_FILL: begin
					v_mem_addr={dcache_addr[`ADDRBITS:`CACHEADDRBITS+2],cnt_fill[`CACHEADDRBITS-1:0],2'b00};
					if (cnt_fill==16'd`CACHEWORDS)
					begin
						cnt_burst	<=16'd0;
						cnt_fill	<=16'd0'
						msr		<=MSR_PREVALID;
						ttl		<=`MAXTTL;
					end else if (cnt_burst==mem_burstlen)
					begin
						v_mem_rdreq	=1'b1;
						cnt_burst	<=16'd0;
					end else if (mem_valid) begin
						cnt_burst	<=cnt_burst+16;d1;
						cnt_fill	<=cnt_fill +16'd1;
						// TODO: write to DPRAM
					end
				end
				MSR_PREVALID: begin
					// TODO: in the rdreq case: validate the output
					// in the wrreq case: write to dpram, mark as dirty
				end
				MSR_VALID: begin
					// in case rdreq & hit: output
					// in case wrreq & hit: write to dpram, mark as dirty
					// in case miss: miss
					// in case fill_req & dirty: --> MSR_FLUSH
					// in case fill_req & !dirty:--> MSR_FILL
	
					v_miss=1'b0;
					if (rdreq)
					begin
						if (dcache_addr[`ADDRBITS:`CACHEADDRBITS+2]==addrmsb)
						begin
							v_line_valid	=1'b1;
						end else begin
							v_miss		=1'b1;
							if (v_ttl!=`TTLBITS'd0)
							begin
								v_ttl	=v_ttl-`TTLBITS'd1;
							end
						end
					end
					if (wrreq)
					begin
						dirty	<=1'b1;
						if (dcache_addr[`ADDRBITS:`CACHEADDRBITS+2]==addrmsb)
						begin
							v_line_valid	=1'b1;
							v_dpram_we	=1'b1;
							dpram_datain	<=dache_in;
							dpram_waddr	<=dcache_addr[`CACHEADDRBITS+2-1:2];
						end else begin
							v_miss		=1'b1;
							if (v_ttl!=`TTLBITS'd0)
							begin
								v_ttl	=v_ttl-`TTLBITS'd1;
							end
						end
						
					end
					if (fill_req)
					begin
						addrmsb		<=dcache_addr[`ADDRBITS:`CACHEADDRBITS+2];
						addrmsb2	<=addrmsb;
						cnt_fill	<=16'd0;
						cnt_burst	<=16'd0;
						addr_flush	<=`CACHEADDRBITS'd0;
						msr		<=dirty? MSR_FLUSH:MSR_FILL;
					end
							
					line_valid	<=v_line_valid;
					miss		<=v_miss;
				end
				MSR_FLUSH: begin
					// flush out
					// then  --> msr_fill
				end
			endcase	


			ttl		<=v_ttl;
			miss		<=v_miss;
			line_valid	<=v_line_valid;
			mem_addr	<=v_mem_addr;
			mem_rdreq	<=v_mem_rdreq;
			dpram_we	<=v_dpram_we;
		end
	end
endmodule

