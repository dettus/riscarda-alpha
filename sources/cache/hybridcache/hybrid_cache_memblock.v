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

module hybrid_cache_memblock
#(
	parameter	ADDRBITS=32,
	parameter	DATABITS=32,
	parameter	LSBBITS=7,
	parameter	WORDLENBITS=2,
	parameter	LOGBANKNUM=2,
	parameter	BANKNUM=(2**LOGBANKNUM)
)
(
	input	[LSBBITS-1:0]		line_mem_wraddr,
	input	[LSBBITS-1:0]		line_mem_rdaddr,
	input				line_mem_we,
	input	[DATABITS-1:0]		line_mem_in,
	output	[DATABITS-1:0]		line_mem_out,
	input	[WORDLENBITS-1:0]	line_mem_in_wordlen,
	input				clk
			
);
	reg	[DATABITS-1:0]		int_mem_in;
	wire	[DATABITS-1:0]		int_mem_out;
	reg	[DATABITS-1:0]		r_line_mem_out;
	reg	[BANKNUM-1:0]		r_bank_we;	

	assign	line_mem_out		=r_line_mem_out;	
	always	@(line_mem_in,line_mem_wraddr[1:0])
	begin
		case (line_mem_wraddr[1:0])
			2'b01:		begin	int_mem_in<={line_mem_in[23:0],line_mem_in[31:24]};end
			2'b10:		begin	int_mem_in<={line_mem_in[15:0],line_mem_in[31:16]};end
			2'b11:		begin	int_mem_in<={line_mem_in[ 7:0],line_mem_in[31: 8]};end
			default:	begin	int_mem_in<=line_mem_in;end
		endcase
	end
	always	@(int_mem_out,line_mem_rdaddr[1:0])
	begin
		case (line_mem_rdaddr[1:0])
			2'b01:		begin	r_line_mem_out<={int_mem_out[23:0],int_mem_out[31:24]};end
			2'b10:		begin	r_line_mem_out<={int_mem_out[15:0],int_mem_out[31:16]};end
			2'b11:		begin	r_line_mem_out<={int_mem_out[ 7:0],int_mem_out[31: 8]};end
			default:	begin	r_line_mem_out<=int_mem_out;end
		endcase
	end
	always	@(line_mem_wraddr[1:0],line_mem_in_wordlen)
	begin
		case({line_mem_in_wordlen,line_mem_wraddr[1:0]})
			// byte write
			4'b0000:	begin	r_bank_we<=4'b0001;	end
			4'b0001:	begin	r_bank_we<=4'b0010;	end
			4'b0010:	begin	r_bank_we<=4'b0100;	end
			4'b0011:	begin	r_bank_we<=4'b1000;	end

			// half word write
			4'b0100:	begin	r_bank_we<=4'b0011;	end
			4'b0110:	begin	r_bank_we<=4'b1100;	end

			// word write
			4'b1000:	begin	r_bank_we<=4'b1111;	end

			// otherwise: alignment error
			default:	begin	r_bank_we<=4'b0000;	end	
		endcase
	end


	mydpram	
	#(
		.DATABITS	(DATABITS/BANKNUM),
		.ADDRBITS	(LSBBITS-LOGBANKNUM)
	)
	DPRAM0
	(
		.wraddr		(line_mem_wraddr[LSBBITS-1:LOGBANKNUM]),
		.rdaddr		(line_mem_rdaddr[LSBBITS-1:LOGBANKNUM]),
		.we		(line_mem_we&r_bank_we[0]),
		.in		(int_mem_in[ 7: 0]),
		.q		(int_mem_out[ 7: 0]),
		.clk		(clk)
	);


	mydpram	
	#(
		.DATABITS	(DATABITS/BANKNUM),
		.ADDRBITS	(LSBBITS-LOGBANKNUM)
	)
	DPRAM1
	(
		.wraddr		(line_mem_wraddr[LSBBITS-1:LOGBANKNUM]),
		.rdaddr		(line_mem_rdaddr[LSBBITS-1:LOGBANKNUM]),
		.we		(line_mem_we&r_bank_we[1]),
		.in		(int_mem_in[15: 8]),
		.q		(int_mem_out[15: 8]),
		.clk		(clk)
	);


	mydpram	
	#(
		.DATABITS	(DATABITS/BANKNUM),
		.ADDRBITS	(LSBBITS-LOGBANKNUM)
	)
	DPRAM2
	(
		.wraddr		(line_mem_wraddr[LSBBITS-1:LOGBANKNUM]),
		.rdaddr		(line_mem_rdaddr[LSBBITS-1:LOGBANKNUM]),
		.we		(line_mem_we&r_bank_we[2]),
		.in		(int_mem_in[23:16]),
		.q		(int_mem_out[23:16]),
		.clk		(clk)
	);


	mydpram	
	#(
		.DATABITS	(DATABITS/BANKNUM),
		.ADDRBITS	(LSBBITS-LOGBANKNUM)
	)
	DPRAM3
	(
		.wraddr		(line_mem_wraddr[LSBBITS-1:LOGBANKNUM]),
		.rdaddr		(line_mem_rdaddr[LSBBITS-1:LOGBANKNUM]),
		.we		(line_mem_we&r_bank_we[3]),
		.in		(int_mem_in[31:24]),
		.q		(int_mem_out[31:24]),
		.clk		(clk)
	);


	

endmodule
