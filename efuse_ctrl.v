//
//  Module: efuse_ctrl
//  Project: CHICAGO
//  Description: 
// 
//  Change history: 
//
////////////////////////////////////////////////////////
`timescale 1ns/10ps

module efuse_ctrl (
	input  wire			i_test_en		,
	input  wire			i_clk			,
	input  wire			i_rstn			,
	input  wire			i_cmd_read		,
	input  wire			i_cmd_pgm		,
	input  wire			i_cmd_init		,
	input  wire			i_cmd_pmu		,
	input  wire	[ 7:0]	i_passcode		,
	input  wire	[63:0]	i_wdata			,
	input  wire	[ 3:0]	i_wsel			,
	input  wire	[ 1:0]	i_rd			,
	output reg			o_read_done		,
	output reg	[63:0]	o_output		,
	output reg			o_read_fail		
);

localparam match_key = 8'h38;

// Internal Signal
reg		[63:0]	r_werp		;	// Word line enable for read or programming operation
reg 			r_access	;	// For read or programming access
reg				r_wren		;	// Write enable
reg				r_peb		;	// Programming enable
reg				r_re		;	// Read enable
reg		[ 3:0]	r_wsel		;	// Programming current control
reg		[ 1:0]	r_rd		;	// Read margin check control
reg		[ 3:0]	r_cnt		;	// 11-bit counter for 2000 cycle
reg		[ 6:0]	r_pcnt		;
reg		[ 6:0]	r_addr		;
reg				r_init		;
reg				r_read_d1	;
reg				r_read_d2	;
reg				r_pgm_d1	;
reg				r_pgm_d2	;
reg				r_init_d1	;
reg				r_init_d2	;
reg				r_pmu_d1	;
reg		[ 7:0]	r_pc_d1		;
reg		[ 7:0]	r_pc_d2		;
reg		[63:0]	r_wdata_d1	;
reg		[63:0]	r_wdata_d2	;
reg		[ 3:0]	r_wsel_d1	;
reg		[ 3:0]	r_wsel_d2	;
reg		[ 1:0]	r_rd_d1		;
reg		[ 1:0]	r_rd_d2		;

wire 			access	;
//wire 			ef_out	;
wire			w_output;
wire			read_cmd;
wire			pgm_cmd	;
wire			init_cmd;
wire			pmu_cmd	;

//wire test_pattern	= r_cnt[0];
//wire w_test_out		= test_pattern;
wire w_test_access	= 'd0;

CLK_MUX I_TMUX_ACCESS 		(.A(r_access), .B(w_test_access	), .S(i_test_en), .Y(access	 ));
//CLK_MUX I_TMUX_OUTPUT		(.A(ef_out	), .B(w_test_out	), .S(i_test_en), .Y(w_output));

M18GFLEF64R1C5P0VIM3 u_efuse (
/*input			*/	.RESETB		(i_rstn		),
/*input [63:0]	*/	.WERP		/*(werp		),*/(r_werp		),
/*input			*/	.ACCESS		(access		),/*(r_access	),*/
/*input			*/	.WREN		/*(wren		),*/(r_wren		),
/*input			*/	.PEB		/*(peb		),*/(r_peb		),
/*input			*/	.RE			/*(re		),*/(r_re		),
/*output		*/	.OUTPUT		/*(ef_out	),*/(w_output	),		  
/*input [3:0]	*/	.WSEL		/*(wsel		),*/(r_wsel		),
/*input [1:0]	*/	.RD			/*(rd		) */(r_rd		) 
);

//--------------------------------------------------
// eFuse controller FSM
//--------------------------------------------------
localparam Standby		= 10'b00_0000_0001,
		   Pgm_setup	= 10'b00_0000_0010,
		   Pgm_access	= 10'b00_0000_0100,
		   Pgm_mode		= 10'b00_0000_1000,
		   Pgm_done		= 10'b00_0001_0000,
		   Read_setup	= 10'b00_0010_0000,
		   Read_access	= 10'b00_0100_0000,
		   Read_enable	= 10'b00_1000_0000,
		   Read_disable	= 10'b01_0000_0000,
		   Read_done	= 10'b10_0000_0000;

reg [9:0] CurSt_eFuse_FSM;
reg [9:0] NextSt_eFuse_FSM;

always @ (posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_read_d1 <= 1'b0;
		r_read_d2 <= 1'b0;
	end else begin
		r_read_d1 <= i_cmd_read;
		r_read_d2 <= r_read_d1;
	end
end
assign read_cmd = r_read_d1 & ~r_read_d2;

always @ (posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_pgm_d1 <= 1'b0;
		r_pgm_d2 <= 1'b0;
	end else begin
		r_pgm_d1 <= i_cmd_pgm;
		r_pgm_d2 <= r_pgm_d1;
	end
end
assign pgm_cmd =  r_pgm_d1 & ~r_pgm_d2;

always @ (posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_init_d1 <= 1'b0;
		r_init_d2 <= 1'b0;
	end else begin
		r_init_d1 <= i_cmd_init;
		r_init_d2 <= r_init_d1;
	end
end
assign init_cmd = r_init_d1 & ~r_init_d2;

always @ (posedge i_clk or negedge i_rstn) begin
	if (~i_rstn)	r_pmu_d1 <= 1'b0;
	else 			r_pmu_d1 <= i_cmd_pmu;
end
assign pmu_cmd = i_cmd_pmu & ~r_pmu_d1;

always @ (posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_pc_d1 <= 8'b0;
		r_pc_d2 <= 8'b0;
	end else begin
		r_pc_d1 <= i_passcode;
		r_pc_d2 <= r_pc_d1;
	end
end

always @ (posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_wdata_d1 <= 64'b0;
		r_wdata_d2 <= 64'b0;
	end else begin
		r_wdata_d1 <= i_wdata;
		r_wdata_d2 <= r_wdata_d1;
	end
end

always @ (posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_wsel_d1 <= 4'b0;
		r_wsel_d2 <= 4'b0;
	end else begin
		r_wsel_d1 <= i_wsel;
		r_wsel_d2 <= r_wsel_d1;
	end
end

always @ (posedge i_clk or negedge i_rstn) begin
	if (~i_rstn) begin
		r_rd_d1 <= 2'b0;
		r_rd_d2 <= 2'b0;
	end else begin
		r_rd_d1 <= i_rd;
		r_rd_d2 <= r_rd_d1;
	end
end

always @ (posedge i_clk or negedge i_rstn) begin
	if (~i_rstn)	CurSt_eFuse_FSM <= Standby;
	else			CurSt_eFuse_FSM <= #1 NextSt_eFuse_FSM;
end

// Internal FSM Regs
reg	r_set_w_werp,	r_clr_w_werp;
reg r_set_r_werp,	r_clr_r_werp;
reg r_set_access,	r_clr_access;
reg r_set_re,		r_clr_re;
reg	r_set_rd,		r_clr_rd;
reg r_set_cnt,		r_clr_cnt;
reg r_set_pcnt,		r_clr_pcnt;
reg	r_set_wren,		r_clr_wren;
reg r_set_peb,		r_clr_peb;
reg r_set_addr,		r_clr_addr;
reg r_set_wsel,		r_clr_wsel;
reg r_set_init,		r_clr_init;
reg r_set_output,	r_clr_output;
reg r_set_read_done,r_clr_read_done;

//FSM Main Body
always @ (*) begin
	NextSt_eFuse_FSM = Standby;
	r_set_w_werp = 1'b0;	r_clr_w_werp = 1'b0;
	r_set_r_werp = 1'b0;	r_clr_r_werp = 1'b0;
	r_set_access = 1'b0;	r_clr_access = 1'b0;
	r_set_re = 1'b0;		r_clr_re = 1'b0;
	r_set_rd = 1'b0;		r_clr_rd = 1'b0;
	r_set_cnt = 1'b0;		r_clr_cnt = 1'b0;
	r_set_pcnt = 1'b0;		r_clr_pcnt = 1'b0;
	r_set_wren = 1'b0;		r_clr_wren = 1'b0;
	r_set_peb = 1'b0;		r_clr_peb = 1'b0;
	r_set_addr = 1'b0;		r_clr_addr = 1'b0;
	r_set_wsel = 1'b0;		r_clr_wsel = 1'b0;
	r_set_init = 1'b0;		r_clr_init = 1'b0;
	r_set_output = 1'b0;	r_clr_output = 1'b0;
	r_set_read_done = 1'b0; r_clr_read_done = 1'b0;

	case (CurSt_eFuse_FSM)

		Standby : begin	
			if ((read_cmd & ~o_read_done) || pmu_cmd) begin
				r_set_rd = 1'b1;
				NextSt_eFuse_FSM = Read_setup;
			end
			else if (pgm_cmd & (r_pc_d2 == match_key)) begin
				r_clr_output = 1'b1;
				NextSt_eFuse_FSM = Pgm_setup;
			end
			else if (init_cmd) begin
				r_set_init = 1'b1;
				NextSt_eFuse_FSM = Read_setup;
			end
			else begin
				r_clr_read_done = 1'b1;
				r_clr_r_werp = 1'b1;
				r_clr_pcnt = 1'b1;
				r_clr_peb = 1'b1;
				r_clr_wren = 1'b1;
				NextSt_eFuse_FSM = Standby;
			end
		end

		Pgm_setup : begin
			if (r_wdata_d2[r_pcnt] == 1'b1) begin
				r_set_pcnt = 1'b1;
				r_set_wren = 1'b1;
				r_set_peb = 1'b1;
				r_set_w_werp = 1'b1;
				r_set_wsel = 1'b1;
				NextSt_eFuse_FSM = Pgm_access;
			end
			else begin
				r_set_pcnt = 1'b1;
				NextSt_eFuse_FSM = Pgm_done;
			end
		end
		
		Pgm_access : begin
			r_set_access = 1'b1;
			NextSt_eFuse_FSM = Pgm_mode;
		end

		Pgm_mode : begin
			if (r_cnt < 4'd15) begin
				r_set_cnt = 1'b1;
				NextSt_eFuse_FSM = Pgm_mode;
			end
			else begin
				r_clr_cnt = 1'b1;
				r_clr_access = 1'b1;
				NextSt_eFuse_FSM = Pgm_done;
			end
		end
	
		Pgm_done : begin
			if (r_pcnt < 7'd64) begin
				r_clr_wren = 1'b1;
				r_clr_peb = 1'b1;
				r_clr_w_werp = 1'b1;
				r_clr_wsel = 1'b1;
				NextSt_eFuse_FSM = Pgm_setup;
			end
			else begin
				r_clr_wsel = 1'b1;
				NextSt_eFuse_FSM = Standby;
			end
		end

		Read_setup : begin
			r_set_r_werp = 1'b1;
			NextSt_eFuse_FSM = Read_access;
		end

		Read_access : begin
			r_set_access = 1'b1;
			NextSt_eFuse_FSM = Read_enable;
		end

		Read_enable : begin
			r_set_re = 1'b1;
			NextSt_eFuse_FSM = Read_disable;
		end

		Read_disable : begin
			r_clr_re = 1'b1;
			NextSt_eFuse_FSM = Read_done;
		end

		Read_done : begin
			if (r_addr < 7'd64) begin
				r_clr_access = 1'b1;
				r_set_addr = 1'b1;
				r_set_output = 1'b1;
				NextSt_eFuse_FSM = Read_setup;
			end
			else begin
				r_clr_access = 1'b1;
				r_clr_rd = 1'b1;
				r_clr_addr = 1'b1;
				r_clr_init = 1'b1;
				r_set_read_done = 1'b1;
				NextSt_eFuse_FSM = Standby;
			end
		end
	endcase
end

//--------------------------------------------------
// Count for Period check
//--------------------------------------------------
always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_cnt <= 4'b0;
else if (r_clr_cnt)		r_cnt <= 4'b0;
else if (r_set_cnt)		r_cnt <= r_cnt + 1'b1;
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_pcnt <= 7'b0;
else if (r_clr_pcnt)	r_pcnt <= 7'b0;
else if (r_set_pcnt)	r_pcnt <= r_pcnt + 1'b1;
end

//--------------------------------------------------
// Setup Read address
//--------------------------------------------------
always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)		r_addr <= 7'd0;
else if (r_clr_addr)	r_addr <= 7'd0;
else if (r_set_addr)	r_addr <= r_addr + 1'b1;
end

//--------------------------------------------------
// Setup eFuse control register
//--------------------------------------------------
always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			r_access <= 1'b0;
else if (r_clr_access)		r_access <= 1'b0;
else if (r_set_access)		r_access <= 1'b1;
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			r_re	<= 1'b0;
else if (r_clr_re)			r_re	<= 1'b0;
else if (r_set_re)			r_re	<= 1'b1;
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			r_rd	<= 2'b0;
else if (r_clr_rd)			r_rd	<= 2'b0;
else if (r_set_rd)			r_rd	<= r_rd_d2;
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			r_wren	<= 1'b0;
else if (r_clr_wren)		r_wren	<= 1'b0;
else if (r_set_wren)		r_wren	<= 1'b1;
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			r_peb	<= 1'b1;
else if (r_clr_peb)			r_peb	<= 1'b1;
else if (r_set_peb)			r_peb	<= 1'b0;
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			r_wsel	<= 4'b0;
else if (r_clr_wsel)		r_wsel	<= 4'b0;
else if (r_set_wsel)		r_wsel	<= r_wsel_d2;
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			r_werp 	<= 64'd0;
else if (r_clr_w_werp)		r_werp 	<= 64'd0;
else if (r_clr_r_werp)		r_werp 	<= 64'd0;
else if (r_set_w_werp)		r_werp 	<= 64'b1 << r_pcnt;
else if (r_set_r_werp)		r_werp 	<= 64'b1 << r_addr; 
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			r_init 	<= 1'b0;
else if (r_clr_init)		r_init 	<= 1'b0;
else if (r_set_init)		r_init 	<= 1'b1;
end

//--------------------------------------------------
// Setup Outputs
//--------------------------------------------------
// Setup Requeset Outputs
always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			o_read_done <= 1'b0;
else if (r_clr_read_done)	o_read_done <= 1'b0;
else if (r_set_read_done) 	o_read_done <= 1'b1;
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			o_output <= 64'd0;
else if (r_clr_output)		o_output <= 64'd0;
else if (r_set_output)		o_output[r_addr] <= w_output;
end

always @ (posedge i_clk or negedge i_rstn) begin
	 if (~i_rstn)			o_read_fail <= 1'b0;
else if (r_clr_init)		o_read_fail <= 1'b0;
else if (r_init & (o_output != 0)) o_read_fail <= 1'b1;
end

endmodule
