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
module	bigmem
#(
	parameter	ADDRBITS=10,
	parameter	DATABITS=32,
	parameter	MEMSIZE=(2**ADDRBITS)
)
(
	input	[ADDRBITS-1:0]	mem_addr,
	output	[DATABITS-1:0]	mem_out,
	output			mem_out_valid,
	input	[DATABITS-1:0]	mem_in,
	input			mem_wrreq,
	input			mem_rdreq,
	input			clk
);
	reg	[DATABITS-1:0]	remember[MEMSIZE-1:0];
	reg	r_mem_out_valid;
	reg	[DATABITS-1:0]	r_mem_out;

	assign	mem_out=r_mem_out;
	assign	mem_out_valid=r_mem_out_valid;
	always	@(posedge clk)
	begin
		if (mem_wrreq) begin
			remember[mem_addr]<=mem_in;
			r_mem_out_valid<=1'b0;
		end else if (mem_rdreq) begin
			r_mem_out<=remember[mem_addr];
			r_mem_out_valid<=1'b1;
		end else begin
			r_mem_out_valid<=1'b1;
		end
	end
endmodule



module	tb_stimuli
#(
	parameter	ADDRBITS=32,
	parameter	DATABITS=32,
	parameter	WORDLENBITS=2
)
(
	output		[ADDRBITS-1:0]	dcache_rdaddr,
	output				dcache_rdreq,
	output		[ADDRBITS-1:0]	dcache_wraddr,
	output				dcache_wrreq,
	output		[DATABITS-1:0]	dcache_in,
	output				dcache_in_wordlen,
	output		[ADDRBITS-1:0]	icache_rdaddr,
	output				icache_rdreq,

	input				reset_n,
	input				clk
);

	reg		[ADDRBITS-1:0]	r_dcache_rdaddr;
	reg				r_dcache_rdreq;
	reg		[ADDRBITS-1:0]	r_dcache_wraddr;
	reg				r_dcache_wrreq;
	reg		[DATABITS-1:0]	r_dcache_in;
	reg				r_dcache_in_wordlen;
	reg		[ADDRBITS-1:0]	r_icache_rdaddr;
	reg				r_icache_rdreq;	
	reg		[24:0]		r_waitcnt;
	reg		[15:0]		r_idx;


	assign	dcache_rdaddr		=r_dcache_rdaddr;
	assign	dcache_rdreq		=r_dcache_rdreq;
	assign	dcache_wraddr		=r_dcache_wraddr;
	assign	dcache_wrreq		=r_dcache_wrreq;
	assign	dcache_in		=r_dcache_in;
	assign	dcache_in_wordlen	=r_dcache_in_wordlen;
	assign	icache_rdaddr		=r_icache_rdaddr;
	assign	icache_rdreq		=r_icache_rdreq;


	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			r_waitcnt		<='d0;
			r_idx			<='d0;
			
			r_dcache_rdaddr		<='h0;
			r_dcache_rdreq		<=1'b0;
			r_dcache_wraddr		<='h0;
			r_dcache_wrreq		<=1'b0;
			r_dcache_in		<='h0;
			r_dcache_in_wordlen	<=2'b10;
			r_icache_rdaddr		<='h0;
			r_icache_rdreq		<=1'b0;
		end else begin
			if (r_waitcnt=='d0)
			begin
				case (r_idx)
					'd0:	begin
							r_waitcnt<='d10;r_idx<=r_idx+'d1;
						end
					// write test. writing 0fff0001...0fff0004 to 80000000..8000000c
					'd1:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h80000000; r_dcache_in<=32'h0fff0001;r_dcache_wrreq<=1'b1; end
					'd2:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h80000004; r_dcache_in<=32'h0fff0002;r_dcache_wrreq<=1'b1; end
					'd3:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h80000008; r_dcache_in<=32'h0fff0003;r_dcache_wrreq<=1'b1; end
					'd4:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h8000000c; r_dcache_in<=32'h0fff0004;r_dcache_wrreq<=1'b1; end
					'd5:	begin r_waitcnt<='d400;r_idx<=r_idx+'d1; r_dcache_wrreq<=1'b0; end

					// read test. expecting 0fff0001...0fff0004
					'd6:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h80000000; r_dcache_rdreq<=1'b1;end
					'd7:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h80000004; r_dcache_rdreq<=1'b1;end
					'd8:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h80000008; r_dcache_rdreq<=1'b1;end
					'd9:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h8000000c; r_dcache_rdreq<=1'b1;end
					'd10:	begin r_waitcnt<='d300000;r_idx<=r_idx+'d1;r_dcache_rdreq<=1'b1;end

					'd11:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_icache_rdaddr<=32'h80000000; r_icache_rdreq<=1'b1;end
					'd12:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_icache_rdaddr<=32'h80000004; r_icache_rdreq<=1'b1;end
					'd13:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_icache_rdaddr<=32'h80000008; r_icache_rdreq<=1'b1;end
					'd14:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_icache_rdaddr<=32'h8000000c; r_icache_rdreq<=1'b1;end
					'd15:	begin r_waitcnt<='d300000;r_idx<=r_idx+'d1;r_icache_rdreq<=1'b0;end


					// flush test 1/2
					'd16:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h00000100; r_dcache_in<=32'h00000100;r_dcache_wrreq<=1'b1; end
					'd17:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h00000180; r_dcache_in<=32'h00000180;r_dcache_wrreq<=1'b1; end
					'd18:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h00000200; r_dcache_in<=32'h00000200;r_dcache_wrreq<=1'b1; end
					'd19:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h00000280; r_dcache_in<=32'h00000280;r_dcache_wrreq<=1'b1; end
					'd20:	begin r_waitcnt<='d200;r_idx<=r_idx+'d1; r_dcache_wrreq<=1'b0; end

					// flush test 2/2
					'd21:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h00000300; r_dcache_in<=32'h00000300;r_dcache_wrreq<=1'b1; end
					'd22:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h00000380; r_dcache_in<=32'h00000380;r_dcache_wrreq<=1'b1; end
					'd23:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h00000400; r_dcache_in<=32'h00000400;r_dcache_wrreq<=1'b1; end
					'd24:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1; r_dcache_wraddr<=32'h00000480; r_dcache_in<=32'h00000480;r_dcache_wrreq<=1'b1; end
					'd25:	begin r_waitcnt<='d400;r_idx<=r_idx+'d1; r_dcache_wrreq<=1'b0; end

					// read test. expecting 00000480...00000100
					'd26:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h00000100; r_dcache_rdreq<=1'b1;end
					'd27:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h00000180; r_dcache_rdreq<=1'b1;end
					'd28:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h00000200; r_dcache_rdreq<=1'b1;end
					'd29:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h00000280; r_dcache_rdreq<=1'b1;end
					'd30:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h00000300; r_dcache_rdreq<=1'b1;end
					'd31:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h00000380; r_dcache_rdreq<=1'b1;end
					'd32:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h00000400; r_dcache_rdreq<=1'b1;end
					'd33:	begin r_waitcnt<='d0;r_idx<=r_idx+'d1;	r_dcache_rdaddr<=32'h00000480; r_dcache_rdreq<=1'b1;end
					'd34:	begin r_waitcnt<='d300000;r_idx<=r_idx+'d1; r_dcache_rdreq<=1'b0;
					
					default:begin
							r_waitcnt<='d0;
						end

				endcase
			end else begin
				r_waitcnt<=r_waitcnt-'d1;
			end
		end
	end
end

module	hexuart
#(
	parameter	CLKFREQ=50000000,
	parameter	BAUDRATE=115200,
	parameter	SAMPLECLK=(CLKFREQ/BAUDRATE)
)
(
	input	[ 7:0]	prefix,
	input	[31:0]	value,
	input		start,
	output		tx,
	output		ready,

	input		reset_n,
	input		clk
);
	reg	r_tx;
	reg	r_ready;

	reg	[3:0]	r_bytecnt;
	reg	[9:0]	r_shift;
	reg	[31:0]	r_value;
	reg	[15:0]	r_samplecnt;

	always	@(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			r_tx		<=1'b1;
			r_ready		<=1'b1;
			r_bytecnt	<='d0;
			r_shift		<='b0000000000;
			r_samplecnt	<='d0;
		end else begin
			if (r_shift==10'b0000000000 & r_samplecnt=='d0)
			begin
				r_tx	<=1'b1;
				case (r_bytecnt)
					'd0:begin
						if (start)
						begin
							r_samplecnt	<=SAMPLECLK;
							r_shift		<={1'b1,prefix,1'b0};	// 1 start bit, data (lsb first), 1 stop bit
							r_bytecnt	<='d1;
							r_ready		<=1'b0;
							r_value		<=value;
						end else begin
							r_ready		<=1'b1;
						end
					end
					'd9:	begin
							r_samplecnt	<=SAMPLECLK;
							r_shift		<={1'b1,8'h0a,1'b0};	
							r_bytecnt	<=r_bytecnt+'d1;
					end
					'd10:	begin
							r_samplecnt	<=SAMPLECLK;
							r_shift		<={1'b1,8'h0d,1'b0};	
							r_bytecnt	<='d0;
					end
					default: begin
						r_samplecnt	<=SAMPLECLK;
						r_bytecnt	<=r_bytecnt+'d1;
						case (r_value[31:28])
							'h0:	begin	r_shift	<={1'b1,8'h30,1'b0};end
							'h1:	begin	r_shift	<={1'b1,8'h31,1'b0};end
							'h2:	begin	r_shift	<={1'b1,8'h32,1'b0};end
							'h3:	begin	r_shift	<={1'b1,8'h33,1'b0};end

							'h4:	begin	r_shift	<={1'b1,8'h34,1'b0};end
							'h5:	begin	r_shift	<={1'b1,8'h35,1'b0};end
							'h6:	begin	r_shift	<={1'b1,8'h36,1'b0};end
							'h7:	begin	r_shift	<={1'b1,8'h37,1'b0};end

							'h8:	begin	r_shift	<={1'b1,8'h38,1'b0};end
							'h9:	begin	r_shift	<={1'b1,8'h39,1'b0};end
							'ha:	begin	r_shift	<={1'b1,8'h41,1'b0};end
							'hb:	begin	r_shift	<={1'b1,8'h42,1'b0};end

							'hc:	begin	r_shift	<={1'b1,8'h43,1'b0};end
							'hd:	begin	r_shift	<={1'b1,8'h44,1'b0};end
							'he:	begin	r_shift	<={1'b1,8'h45,1'b0};end
							'hf:	begin	r_shift	<={1'b1,8'h46,1'b0};end
						endcase
						r_value<={r_value[27:0],4'b0000};
					end
				endcase
			end else begin
				r_tx	<=r_shift[0];
				if (r_samplecnt=='d0)
				begin
					r_shift		<={1'b0,r_shift[9:1]};
					r_samplecnt	<=SAMPLECLK;
				end else begin
					r_samplecnt	<=r_samplecnt-'d1;
				end
			end

		end
	end
endmodule

module toplevel
#(
	parameter	ADDRBITS=32,
	parameter	DATABITS=32,
	parameter	WORDLENBITS=2
)
(
	output	tx,
	input	reset_n,
	input	clk
);
	// data cache connection, read
	wire	[ADDRBITS-1:0]		dcache_rdaddr;		//
	wire				dcache_rdreq;		//
	wire	[DATABITS-1:0]		dcache_out;		//
	wire				dcache_out_valid;	//
	wire				dcache_rd_ready;	//

	// data cache connection; write
	wire	[ADDRBITS-1:0]		dcache_wraddr;		//
	wire				dcache_wrreq;		//
	wire	[DATABITS-1:0]		dcache_in;		//
	wire	[WORDLENBITS-1:0]	dcache_in_wordlen;	//
	wire				dcache_wr_ready;	//
	

	// instruction cache connection; read
	wire	[ADDRBITS-1:0]		icache_rdaddr;		//
	wire				icache_rdreq;		//
	wire	[DATABITS-1:0]		icache_out;		//
	wire				icache_out_valid;	//
	wire				icache_rd_ready;	//



	wire	[ADDRBITS-1:0]		mem_addr;		//
	wire	[DATABITS-1:0]		mem_in;			//
	wire	[DATABITS-1:0]		mem_out;		//
	wire				mem_out_valid;		//
	wire				mem_wrreq;		//
	wire				mem_rdreq;		//
	


	tb_stimuli	TB_STIMULI0
	(
		.dcache_rdaddr		(dcache_rdaddr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_wraddr		(dcache_wraddr),
		.dcache_wrreq		(dcache_wrreq),

		.dcache_in		(dcache_in),
		.dcache_in_wordlen	(dcache_in_wordlen),
		.icache_rdaddr		(icache_rdaddr),
		.icache_rdreq		(icache_rdreq),
		.reset_n		(reset_n),
		.clk			(clk)
	);

	hyrid_cache	HYBRID_CACHE0(
		.dcache_rdaddr		(dcache_rdaddr),
		.dcache_rdreq		(dcache_rdreq),
		.dcache_out		(dcache_out),
		.dcache_out_valid	(dcache_out_valid),
		.dcache_rd_ready	(dcache_rd_ready),

		.dcache_wraddr		(dcache_wraddr),
		.dcache_wrreq		(dcache_wrreq),
		.dcache_in		(dcache_in),
		.dcache_in_wordlen	(dcache_in_wordlen),
		.dcache_wr_ready	(dcache_wr_ready),


		.icache_rdaddr		(icache_rdaddr),
		.icache_rdreq		(icache_rdreq),
		.icache_out		(icache_out),
		.icache_out_valid	(icache_out_valid),
		.icache_rd_ready	(icache_rd_ready),

		.mem_addr		(mem_addr),
		.mem_in			(mem_in),
		.mem_out		(mem_out),
		.mem_out_valid		(mem_out_valid),
		.mem_wrreq		(mem_wrreq),
		.mem_rdreq		(mem_rdreq),

		.reset_n		(reset_n),
		.clk			(clk)	
	);

	bigmem		BIGMEM0(
		.mem_addr			(mem_addr[11:2]),
		.mem_in				(mem_in),
		.mem_out			(mem_out),
		.mem_out_valid			(mem_out_valid),
		.mem_wrreq			(mem_wrreq),
		.mem_rdreq			(mem_rdreq),

		.clk				(clk)
	);

	
endmodule
