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

module	tbmem(
	input	[31:0]	mem_rdaddr,
	input		mem_rdreq,
	output	[31:0]	mem_dataout,
	output		mem_datavalid,
	input		clk,
	input		reset_n
);

	reg	[31:0]	mem_dataout;
	reg		mem_datavalid;
	reg	[ 5:0]	burstcnt;


	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			burstcnt	<=6'd0;
			mem_datavalid	<=1'b0;
			mem_dataout	<=32'd0;
		end else begin
			if (burstcnt!=6'd0)
			begin
					burstcnt	<=burstcnt-6'd1;
					mem_dataout	<={mem_rdaddr[31:5],burstcnt[4:0]};
					mem_datavalid	<=1'b1;
			end else begin
				if (mem_rdreq)
				begin
					burstcnt	<=6'd32;
					mem_dataout	<={mem_rdaddr[31:5],5'b00000};
					mem_datavalid	<=1'b1;
				end else begin
					mem_datavalid	<=1'b0;
				end
			end
		end
	end
endmodule


module main();
	reg	[31:0]	icache_rdaddr;
	reg		icache_rdreq;
	wire	[31:0]	icache_dataout;
	wire		icache_valid;

	wire	[31:0]	mem_rdaddr;
	wire		mem_rdreq;
	wire	[31:0]	mem_dataout;
	wire		mem_datavalid;

	reg		clk;
	reg		reset_n;			

	
	icache	ICACHE0(
		.icache_rdaddr		(icache_rdaddr),
		.icache_rdreq		(icache_rdreq),
		.icache_dataout		(icache_dataout),
		.icache_valid		(icache_valid),
		.mem_rdaddr		(mem_rdaddr),
		.mem_rdreq		(mem_rdreq),
		.mem_dataout		(mem_dataout),
		.mem_datavalid		(mem_datavalid),
		.mem_burstlen		(16'd32),
		.clk			(clk),
		.reset_n		(reset_n)
	);

	tbmem	TBMEM0(
		.mem_rdaddr		(mem_rdaddr),
		.mem_rdreq		(mem_rdreq),
		.mem_dataout		(mem_dataout),
		.mem_datavalid		(mem_datavalid),
		.clk			(clk),
		.reset_n		(reset_n)
	);

	
	always	#5	clk<=!clk;
	
	initial begin
		$dumpfile("tb.vcd");
		$dumpvars(0);
		#0	reset_n<=1'b1;clk<=1'b0;icache_rdreq<=1'b0;
		#1	reset_n<=1'b0;
		#1	reset_n<=1'b1;
		#3	$display("simulation started");
		
		#100	icache_rdaddr<=32'h00000000;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;
		#1000	icache_rdaddr<=32'h00000000;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;
		#10	icache_rdaddr<=32'h00000004;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;
		#10	icache_rdaddr<=32'h00000008;icache_rdreq<=1'b1;
		#10	icache_rdaddr<=32'h0000000c;icache_rdreq<=1'b1;
		#10	icache_rdaddr<=32'h00000010;icache_rdreq<=1'b1;
		#10	icache_rdaddr<=32'h00000018;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;
		#100	icache_rdaddr<=32'h20000000;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;
		#1000	icache_rdaddr<=32'h20000000;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;
		#10	icache_rdaddr<=32'h20000004;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;
		#10	icache_rdaddr<=32'h20000008;icache_rdreq<=1'b1;
		#10	icache_rdaddr<=32'h2000000c;icache_rdreq<=1'b1;
		#10	icache_rdaddr<=32'h20000010;icache_rdreq<=1'b1;
		#10	icache_rdaddr<=32'h20000018;icache_rdreq<=1'b1;
		#10	icache_rdreq<=1'b0;
		#200	$finish();
	end
endmodule
