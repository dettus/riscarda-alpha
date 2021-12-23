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

module dcache(
	input	[31:0]	dcache_addr,
	input		dcache_rdreq,
	input		dcache_wrreq,
	input	[31:0]	dcache_datain,
	input	[ 1:0]	dcache_bytenum,
	output	[31:0]	dcache_dataout,
	output		dcache_valid,

	// connection to the main memory controller
	output	[31:0]	mem_addr,
	output		mem_rdreq,
	output		mem_wrreq,
	input	[15:0]	mem_burstlen,
	input	[31:0]	mem_datain,
	input	[31:0]	mem_dataout,
	input		mem_datavalid,

	input		clk,
	input		reset_n
);

	reg	[ 4:0]	dcache_raddr0,dcache_waddr0;
	reg	[ 4:0]	dcache_raddr1,dcache_waddr1;
	reg	[ 4:0]	dcache_raddr2,dcache_waddr2;
	reg	[ 4:0]	dcache_raddr3,dcache_waddr3;
	reg	[ 7:0]	dcache_in0,dcache_in1,dcache_in2,dcache_in3;
	reg		dcache_we0,dcache_we1,dcache_we2,dcache_we3;

	reg	[24:0]	addrmsb;
	reg	[ 2:0]	msr;

	reg	[31:0]	dcache_dataout;
	reg		dcache_valid;
	reg	[15:0]	cnt_flush;
	reg	[15:0]	cnt_fill;
	reg	[15:0]	cnt_burst;
	reg		dirty;


	reg	[31:0]	mem_addr;
	reg		mem_rdreq;
	reg		mem_wrreq;
	parameter	[2:0]	MSR_INIT=3'b000,MSR_FILL=3'b001,MSR_VALID=3'b010,
				MSR_FLUSH=3'b111;

	dpram_32x8	DCACHE0(
		.raddr		(dcache_raddr0),
		.dataout	(dcache_out0),
		.waddr		(dcache_waddr0),
		.datain		(dcache_in0),
		.we		(dcache_we0),
		.clk		(clk)
	);

	dpram_32x8	DCACHE1(
		.raddr		(dcache_raddr1),
		.dataout	(dcache_out1),
		.waddr		(dcache_waddr1),
		.datain		(dcache_in1),
		.we		(dcache_we1),
		.clk		(clk)
	);

	dpram_32x8	DCACHE2(
		.raddr		(dcache_raddr2),
		.dataout	(dcache_out2),
		.waddr		(dcache_waddr2),
		.datain		(dcache_in2),
		.we		(dcache_we2),
		.clk		(clk)
	);

	dpram_32x8	DCACHE3(
		.raddr		(dcache_raddr3),
		.dataout	(dcache_out3),
		.waddr		(dcache_waddr3),
		.datain		(dcache_in3),
		.we		(dcache_we3),
		.clk		(clk)
	);

	always	@(dcache_addr[6:0],msr,cnt_flush)
	begin
		if (msr==MSR_FLUSH)
		begin
			dcache_raddr0	<= cnt_flush[ 4:0];
			dcache_raddr1	<= cnt_flush[ 4:0];
			dcache_raddr2	<= cnt_flush[ 4:0];
			dcache_raddr3	<= cnt_flush[ 4:0];
		end else begin
			dcache_raddr0	<= dcache_addr[6:2]+(dcache_addr[1] | dcache_addr[0]);	// >= 1
			dcache_raddr1	<= dcache_addr[6:2]+(dcache_addr[1]);			// >= 2
			dcache_raddr2	<= dcache_addr[6:2]+(dcache_addr[1] & dcache_addr[0]);	// >= 3
			dcache_raddr3	<= dcache_addr[6:2];
		end
	end
	always	@(dcache_raddr[1:0],dcache_out0,dcache_out1,dcache_out2,dcache_out3)
	begin
		case (dcache_raddr[1:0])
			2'b00:	begin	dcache_dataout<={dcache_out3,dcache_out2,dcache_out1,dcache_out0};end
			2'b01:	begin	dcache_dataout<={dcache_out2,dcache_out1,dcache_out0,dcache_out3};end
			2'b10:	begin	dcache_dataout<={dcache_out1,dcache_out0,dcache_out3,dcache_out2};end
			default:begin	dcache_dataout<={dcache_out0,dcache_out3,dcache_out2,dcache_out1};end
		endcase
	end
	





	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			cmt_burst	<=16'd0;
			cmt_flush	<=16'd0;
			cmt_fill	<=16'd0;
			dcache_waddr0	<=5'd0;
			dcache_waddr1	<=5'd0;
			dcache_waddr2	<=5'd0;
			dcache_waddr3	<=5'd0;
			dcache_in0	<=8'h00;
			dcache_in1	<=8'h00;
			dcache_in2	<=8'h00;
			dcache_in3	<=8'h00;
			dcache_we0	<=1'b0;
			dcache_we1	<=1'b0;
			dcache_we2	<=1'b0;
			dcache_we3	<=1'b0;
			addrmsb		<=25'b0;
			msr		<=MSR_INIT;
			dcache_valid	<=1'b0;
			dirty		<=1'b0;

			mem_addr	<=32'h00000000;
			mem_rdreq	<=1'b0;
			mem_wrreq	<=1'b0;
		end else begin
			case (msr)
				MSR_INIT:	begin
					dcache_valid	<=1'b0;
					if (dcache_rdreq)		// TODO: wrreq
					begin
						addrmsb		<=dcache_addr[31:7];		// TODO: corner case: end+3 byte
						msr		<=MSR_FILL;
						cnt_burst	<=16'd0;
						cnt_fill	<=16'd0;
						mem_addr	<={dcache_addr[31:2],2'b00};
						mem_rdreq	<=1'b1;
						mem_wrreq	<=1'b0;
				
						dcache_waddr0	<=5'd31;	// TODO: corner case
						dcache_waddr1	<=5'd31		// TODO: corner case;
						dcache_waddr2	<=5'd31		// TODO: corner case;
						dcache_waddr3	<=5'd31;	// nothing todo here.
					end
				end
				MSR_FILL:	begin
					mem_addr	<={addr_msb[31:7],dcache_waddr0,2'b00};
					if (cnt_fill==16'd32)
					begin
						dcache_we0	<=1'b0;
						dcache_we1	<=1'b0;
						dcache_we2	<=1'b0;
						dcache_we3	<=1'b0;
						msr		<=MSR_VALID;
						mem_rdreq	<=1'b0;
						dcache_valid	<=1'b1;
					end else if (cnt_burst==mem_burstlen)
					begin
						dcache_we0	<=1'b0;
						dcache_we1	<=1'b0;
						dcache_we2	<=1'b0;
						dcache_we3	<=1'b0;
						mem_rdreq	<=1'b1;
					end else if (mem_datavalid)
					begin
						dcache_we0	<=1'b1;
						dcache_we1	<=1'b1;
						dcache_we2	<=1'b1;
						dcache_we3	<=1'b1;
						dcache_in0	<=mem_dataout[ 7: 0];
						dcache_in1	<=mem_dataout[15: 8];
						dcache_in2	<=mem_dataout[23:16];
						dcache_in3	<=mem_dataout[31:24];
						mem_rdreq	<=1'b0;
						cnt_fill	<=cnt_fill+16'd1;
						cnt_burst	<=cnt_burst+16'd1;
					end else begin
						dcache_we0	<=1'b0;
						dcache_we1	<=1'b0;
						dcache_we2	<=1'b0;
						dcache_we3	<=1'b0;
						mem_rdreq	<=1'b0;
					end
				end
				MSR_VALID:	begin

				end
			endcase
		end
	end
endmodule
