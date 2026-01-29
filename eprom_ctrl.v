////////////////////////////////////////////////////////
//
//  Module: eprom_ctrl
//  Project: BRIGHTON
//  Description: 
// 
//  Change history: 
//
////////////////////////////////////////////////////////
`timescale 1ns/10ps

module eprom_ctrl #(
	parameter DEPTH = 128,
	parameter DW	= 8,
	parameter AW	= $clog2(DEPTH)
)(
	input	wire			i_clk	,
	input	wire			i_rstn	,
	input	wire			i_read	,
	input	wire			i_mread	,	//margin read
	input	wire			i_bread	,	//block read
	input	wire			i_pgm	,
	input	wire [DW-1:0]	i_din	,
	input	wire [AW-1:0]	i_addr	,
	output	reg  [DW-1:0]	o_dout	,
	output	reg				o_valid	
);

//Internal Signal
reg 				r_xce		;
reg 				r_xread		;
reg 				r_xpgm		;
reg 				r_xtm		;
reg 	[DW-1:0]	r_xdin		;
reg		[AW-1:0]	r_addr		;
reg 	[AW-1:0]	r_xa		;
wire	[DW-1:0]	w_dq		;

reg					r_read_d1	;
reg					r_read_d2	;
reg					r_pgm_d1	;
reg					r_pgm_d2	;
reg		[   3:0]	r_rcnt		;
reg		[  13:0]	r_pcnt		;
reg					r_mread_d1	;
reg					r_mread_d2	;
reg					r_bread_d1	;
reg					r_bread_d2	;
reg					burst_read	;
reg		[DW-1:0]	r_mem [0:DEPTH-1];

DBH_1530BD13SA_EP_128x8_5V_ISO u_eprom (
	.XCE			(r_xce		),
	.XREAD			(r_xread	),
	.XPGM			(r_xpgm		),
	.XTM			(r_xtm		),
	.XA				(r_xa		),	
	.XDIN			(r_xdin		),
	.DQ				(w_dq		)
);

always @(posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_read_d1 <= 1'b0;
		r_read_d2 <= 1'b0;
	end else begin
		r_read_d1 <= i_read;
		r_read_d2 <= r_read_d1;
	end
end
assign cmd_read = r_read_d1 & ~r_read_d2;

always @(posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_mread_d1 <= 1'b0;
		r_mread_d2 <= 1'b0;
	end else begin
		r_mread_d1 <= i_mread;
		r_mread_d2 <= r_mread_d1;
	end
end
assign cmd_mread = r_mread_d1 & ~r_mread_d2;

always @(posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_bread_d1 <= 1'b0;
		r_bread_d2 <= 1'b0;
	end else begin
		r_bread_d1 <= i_bread;
		r_bread_d2 <= r_bread_d1;
	end
end
assign cmd_bread = r_bread_d1 & ~r_bread_d2;

always @(posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		burst_read <= 1'b0;
	end else if (i_bread) begin
		burst_read <= 1'b1;
	end else if (r_addr == DEPTH-1) begin
		burst_read <= 1'b0;
	end
end

always @(posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_pgm_d1 <= 1'b0;
		r_pgm_d2 <= 1'b0;
	end else begin
		r_pgm_d1 <= i_pgm;
		r_pgm_d2 <= r_pgm_d1;
	end
end
assign cmd_pgm = r_pgm_d1 & ~r_pgm_d2;

//--------------------------------------------------
// eprom controller FSM
//--------------------------------------------------
localparam 	Standby		= 10'b00_0000_0001,
			Pgm_setup	= 10'b00_0000_0010,
			Pgm_mode	= 10'b00_0000_0100,
			Pgm_done	= 10'b00_0000_1000,
			Read_setup	= 10'b00_0001_0000,
			Read_mode	= 10'b00_0010_0000,
			Read_done	= 10'b00_0100_0000,
			BRead_setup	= 10'b00_1000_0000,
			BRead_mode	= 10'b01_0000_0000,
			BRead_done	= 10'b10_0000_0000;

reg [09:0] CurSt_eprom_FSM;
reg [09:0] NextSt_eprom_FSM;

// State Decoding for Visual Debugging
wire	tStandby	= CurSt_eprom_FSM[0];
wire	tPgm_setup	= CurSt_eprom_FSM[1];	
wire	tPgm_mode	= CurSt_eprom_FSM[2];
wire	tPgm_done	= CurSt_eprom_FSM[3];
wire	tRead_setup	= CurSt_eprom_FSM[4];
wire	tRead_mode	= CurSt_eprom_FSM[5];
wire	tRead_done	= CurSt_eprom_FSM[6];
wire	tBRead_setup= CurSt_eprom_FSM[7];
wire	tBRead_mode	= CurSt_eprom_FSM[8];
wire	tBRead_done	= CurSt_eprom_FSM[9];

// synopsys translate_off
reg   [(64*8)-1:0]  MAIN_eprom_FSM_STATE;
supply1             vdd;

always @ (*) begin
	case (vdd)
		tStandby		: MAIN_eprom_FSM_STATE = "Standby	";
		tPgm_setup		: MAIN_eprom_FSM_STATE = "Pgm_setup	";
		tPgm_mode		: MAIN_eprom_FSM_STATE = "pgm_mode	";
		tPgm_done		: MAIN_eprom_FSM_STATE = "pgm_done	";
		tRead_setup		: MAIN_eprom_FSM_STATE = "Read_setup";
		tRead_mode		: MAIN_eprom_FSM_STATE = "Read_mode	";
		tRead_done		: MAIN_eprom_FSM_STATE = "Read_done	";
		tBRead_setup	: MAIN_eprom_FSM_STATE = "BRead_setup";
		tBRead_mode		: MAIN_eprom_FSM_STATE = "BRead_mode";
		tBRead_done		: MAIN_eprom_FSM_STATE = "BRead_done";
		default			: MAIN_eprom_FSM_STATE = "UNDEFINDE	";
	endcase
end

// synopsys translate_on

always @ (posedge i_clk or negedge i_rstn) begin
	if (~i_rstn)	CurSt_eprom_FSM <= Standby;
	else			CurSt_eprom_FSM <= #1 NextSt_eprom_FSM;
end

// Internal FSM Regs
reg r_clr_xce	,	r_set_xce	;
reg r_clr_xread	,	r_set_xread	;
reg r_clr_xpgm	,	r_set_xpgm	;
reg r_clr_xtm	,	r_set_xtm	;
reg	r_clr_xdin	,	r_set_xdin	;
reg	r_clr_xa	,	r_set_xa	;
reg	r_clr_dout	,	r_set_dout	;
reg	r_clr_valid	,	r_set_valid	;
reg r_clr_rcnt	,	r_set_rcnt	;
reg r_clr_pcnt	,	r_set_pcnt	;
reg r_clr_addr	,	r_set_addr	;

// FSM Main Body
always @(*) begin
	NextSt_eprom_FSM = Standby;
	r_clr_xce	= 1'b0;	r_set_xce	= 1'b0;
	r_clr_xread	= 1'b0;	r_set_xread	= 1'b0;
	r_clr_xpgm	= 1'b0;	r_set_xpgm	= 1'b0;
	r_clr_xtm	= 1'b0;	r_set_xtm	= 1'b0;
	r_clr_xdin	= 1'b0; r_set_xdin	= 1'b0;
	r_clr_xa	= 1'b0;	r_set_xa	= 1'b0;
	r_clr_dout	= 1'b0;	r_set_dout	= 1'b0;
	r_clr_valid	= 1'b0;	r_set_valid	= 1'b0;
	r_clr_rcnt	= 1'b0;	r_set_rcnt	= 1'b0;
	r_clr_pcnt	= 1'b0;	r_set_pcnt	= 1'b0;
	r_clr_addr	= 1'b0;	r_set_addr	= 1'b0;

	case (CurSt_eprom_FSM)

		Standby: begin
			if (cmd_read) begin
				r_clr_xtm	= 1'b1;
				r_clr_dout	= 1'b1;
				r_clr_valid	= 1'b1;
				r_clr_xpgm	= 1'b1;
				r_set_xce	= 1'b1;
				r_set_xa	= 1'b1;
				NextSt_eprom_FSM = Read_setup;
			end else if (cmd_mread) begin
				r_clr_xpgm	= 1'b1;
				r_clr_dout	= 1'b1;
				r_clr_valid	= 1'b1;
				r_set_xce	= 1'b1;
				r_set_xa	= 1'b1;
				r_set_xtm	= 1'b1;
				NextSt_eprom_FSM = Read_setup;
			end else if (cmd_bread | burst_read) begin
				if (r_addr < DEPTH) begin
					r_clr_xpgm	= 1'b1;
					r_clr_dout	= 1'b1;
					r_clr_valid	= 1'b1;
					r_set_xce	= 1'b1;
					NextSt_eprom_FSM = BRead_setup;
				end else begin	
					r_clr_addr	= 1'b1;
					NextSt_eprom_FSM = Standby;
				end
			end else if (cmd_pgm) begin
				r_clr_xread = 1'b1;
				r_clr_xtm	= 1'b1;
				r_set_xce	= 1'b1;
				r_set_xa	= 1'b1;
				r_set_xdin	= 1'b1;
				NextSt_eprom_FSM = Pgm_setup;				
			end else begin
				r_clr_xce	= 1'b1;
				r_clr_xread = 1'b1;
				r_clr_xpgm	= 1'b1;
				r_clr_xtm	= 1'b1;
				NextSt_eprom_FSM = Standby;				
			end
		end

		Pgm_setup: begin
			if (r_pcnt < 13'd5000) begin
				r_set_pcnt = 1'b1;
				r_set_xpgm = 1'b1;				
				NextSt_eprom_FSM = Pgm_setup;
			end else begin
				r_clr_pcnt = 1'b1;
				r_clr_xpgm = 1'b1;
				NextSt_eprom_FSM = Pgm_mode;
			end
		end

		Pgm_mode: begin
			r_clr_xa = 1'b1;
			r_clr_xdin = 1'b1;
			NextSt_eprom_FSM = Pgm_done;
		end

		Pgm_done: begin
			NextSt_eprom_FSM = Standby;
		end
		
		Read_setup: begin
			r_set_xread = 1'b1;
			NextSt_eprom_FSM = Read_mode;
		end
			
		Read_mode: begin
			if (r_rcnt < 4'd5) begin
				r_set_rcnt	= 1'b1;
				r_set_dout	= 1'b1;
				NextSt_eprom_FSM = Read_mode;
			end else begin
				r_clr_rcnt	= 1'b1;
				r_clr_xread	= 1'b1;
				r_set_valid	= 1'b1;			
				NextSt_eprom_FSM = Read_done;
			end
		end
		
		Read_done: begin
			r_clr_xa	= 1'b1;
			r_clr_xce	= 1'b1;
			NextSt_eprom_FSM = Standby;
		end
		
		BRead_setup: begin
			r_set_xread = 1'b1;
			NextSt_eprom_FSM = BRead_mode;
		end
	
		BRead_mode: begin
			if (r_rcnt < 4'd5) begin
				r_set_rcnt	= 1'b1;
				r_set_dout	= 1'b1;
				NextSt_eprom_FSM = BRead_mode;
			end else begin
				r_clr_rcnt	= 1'b1;
				r_clr_xread	= 1'b1;
				r_set_valid	= 1'b1;			
				NextSt_eprom_FSM = BRead_done;
			end
		end
		
		BRead_done: begin
			r_clr_xce	= 1'b1;
			r_set_addr	= 1'b1;			
  			r_mem[r_addr] <= o_dout;			
			NextSt_eprom_FSM = Standby;	
		end
	endcase
end

//--------------------------------------------------
// Count for Period check
//--------------------------------------------------
always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_rcnt <= 4'b0;
else if (r_clr_rcnt)	r_rcnt <= 4'b0;
else if (r_set_rcnt)	r_rcnt <= r_rcnt + 1'b1;
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_pcnt <= 13'b0;
else if (r_clr_pcnt)	r_pcnt <= 13'b0;
else if (r_set_pcnt)	r_pcnt <= r_pcnt + 1'b1;
end

//--------------------------------------------------
// Setup Burst Read address
//--------------------------------------------------
always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_addr <= 'b0;
else if (r_clr_addr)	r_addr <= 'b0;
else if (r_set_addr)	r_addr <= r_addr + 1'b1;
end

//--------------------------------------------------
// Setup eprom control register
//--------------------------------------------------
always @(posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_xce	<= 1'b0;
else if (r_clr_xce)		r_xce	<= 1'b0;
else if	(r_set_xce)		r_xce	<= 1'b1;
end

always @(posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_xread	<= 1'b0;
else if (r_clr_xread)	r_xread	<= 1'b0;
else if	(r_set_xread)	r_xread	<= 1'b1;
end

always @(posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_xpgm	<= 1'b0;
else if (r_clr_xpgm)	r_xpgm	<= 1'b0;
else if	(r_set_xpgm)	r_xpgm	<= 1'b1;
end

always @(posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_xtm	<= 1'b0;
else if (r_clr_xtm)		r_xtm	<= 1'b0;
else if	(r_set_xtm)		r_xtm	<= 1'b1;
end

always @(posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_xdin	<= 1'b0;
else if (r_clr_xdin)	r_xdin	<= 1'b0;
else if	(r_set_xdin)	r_xdin	<= i_din;
end

always @(posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_xa	<= 1'b0;
else if (r_clr_xa)		r_xa	<= 1'b0;
else if	(r_set_xa)		r_xa	<= i_addr;
else if (r_clr_addr)	r_xa	<= 1'b0;
else if (r_set_addr)	r_xa	<= r_addr;
end

//--------------------------------------------------
// Setup Outputs
//--------------------------------------------------
always @(posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		o_dout	<= 1'b0;
else if (r_clr_dout)	o_dout	<= 1'b0;
else if	(r_set_dout)	o_dout	<= w_dq;
end

always @(posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		o_valid	<= 1'b0;
else if (r_clr_valid)	o_valid	<= 1'b0;
else if (r_set_valid)	o_valid <= 1'b1;
end

endmodule
