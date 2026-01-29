`timescale 1ns/1ps
module tb_top();
`define mem0_data tb_top.u_chicago_chip.u_chicago_dig.u_dis_mem_0.u_sp_320x8_wrap.I_MEM.mem
`define mem1_data tb_top.u_chicago_chip.u_chicago_dig.u_dis_mem_1.u_sp_320x8_wrap.I_MEM.mem

reg		test_mode;

`ifdef TEST_I2C
//parameter	I2C_ST_INTERVAL	= 300000;
parameter	I2C_ST_INTERVAL	= 300;

`ifdef	I2C_LONG_INTV
parameter	I2C_INTERVAL_SYS= 5000000;
`else
parameter	I2C_INTERVAL_SYS= 300000;
`endif

parameter	i2c_memfile		= "ana1703.bin";
parameter	i2c_memfile_sram= "ana1703.sram.bin";
parameter	I2C_SCL_tick_t	= (500/0.5); //500KHz
//parameter	I2C_SCL_tick_t	= 500000;
integer		I2C_SCL_tick = I2C_SCL_tick_t;
parameter	i2c_block_bsize	= 2048;
parameter	i2c_block_wsize	= 2048/4;
parameter	i2c_page_bsize	= 256;
parameter	i2c_page_wsize	= 256/4;
//parameter	i2c_fw_page_num	= (FW_BIN_SIZE/i2c_page_bsize)+1;	//CHK

//---------------------------------------------------
integer i2c_i, i2c_ii, i2c_fd, i2c_j, i2c_jj, i2c_loop; 
reg         i2c_done1, i2c_done2;
reg  [15:0] i2c_kk, i2c_xx, i2c_yy;
reg  [ 6:0] i2c_slaveID; 
reg  [31:0] i2c_addr, i2c_data;
reg  [63:0] i2c_spp_data;
reg  [15:0] i2c_page_count;
reg  [15:0] i2c_sec_start, i2c_sec_end;
reg [7:0] i2c_read_data;
reg [31:0] read_data;
wire		O_SDA;
wire        SCL;
wire        SDA;
wire        SCL_in = SCL; 
wire        SDA_in = SDA; 
//wire        SDA_in = O_SDA; 
reg         SCL_out; 
reg         SDA_out; 
reg         RSTB;


pullup(SCL);
pullup(SDA);
assign      SCL = (test_mode) ? 1'bz : (SCL_out) ? 1'bZ : 1'b0; 
assign      SDA = (test_mode) ? 1'bz : (SDA_out) ? 1'bZ : 1'b0; 
//---------------------------------------------------


task I2C_READ_ACK_normal;
begin
	for(i2c_i=0; i2c_i<8; i2c_i=i2c_i+1) begin
		#(I2C_SCL_tick/2); SCL_out <= 1;
		while(SCL_in== 0) #10;
		#(I2C_SCL_tick/2); i2c_read_data[7-i2c_i] <= SDA_in;
		#(I2C_SCL_tick/2); SCL_out <= 0;
		#(I2C_SCL_tick/2);
	end
	SDA_out <= 0;
	#(I2C_SCL_tick/2); SCL_out <= 1;
	while(SCL_in== 0) #10;
	#I2C_SCL_tick;     SCL_out <= 0; 
	//#(I2C_SCL_tick/2); SDA_out <= 1;
	//#(I2C_SCL_tick*2);
	#(I2C_SCL_tick/2); #I2C_SCL_tick; SDA_out <= 1;
	#(I2C_SCL_tick*1);
end
endtask

task I2C_READ_NACK_normal;
begin
	for(i2c_i=0; i2c_i<8; i2c_i=i2c_i+1) begin
		#(I2C_SCL_tick/2); SCL_out <= 1;
		while(SCL_in== 0) #10;
		#(I2C_SCL_tick/2); i2c_read_data[7-i2c_i] <= SDA_in;
		#(I2C_SCL_tick/2); SCL_out <= 0;
		#(I2C_SCL_tick/2);
	end
	SDA_out <= 1;
	#(I2C_SCL_tick/2); SCL_out <= 1;
	while(SCL_in== 0) #10;
	#I2C_SCL_tick;     SCL_out <= 0; 
	#(I2C_SCL_tick/2); SDA_out <= 1;
	#(I2C_SCL_tick*2);
end
endtask


reg [31:0] i2c_top_count;
task I2C_WRITE( input [7:0] reg0);
begin
	for(i2c_i=0; i2c_i<8; i2c_i=i2c_i+1) begin
		#(I2C_SCL_tick/2); SDA_out <= reg0[7-i2c_i];
		#(I2C_SCL_tick/2); SCL_out <= 1;
//		while(SCL_in == 0) #10;

		i2c_top_count = 300000;
		while ((i2c_top_count > 0) && (SCL_in == 0)) begin i2c_top_count = i2c_top_count-10; #10; end
		if (i2c_top_count == 0) begin
			$display("I2C_MASTER :      SCL HOLD FAIL....", $realtime); 
			$stop;
		end

		#(I2C_SCL_tick  ); SCL_out <= 0;
	end

	#(I2C_SCL_tick/2); SDA_out <= 0; 
	#(I2C_SCL_tick/2); SCL_out <= 1; 
	while(SCL_in== 0) #10;
	#(I2C_SCL_tick/2); if(SDA_in == 1) $display($time, " ns,    I2C_MASTER :      ERROR => NACK OCCURS....", $realtime); 
	#(I2C_SCL_tick/2); SCL_out <= 0; 
	#(I2C_SCL_tick*2);
end
endtask 

task I2C_WRITE00( input [7:0] reg0);
begin
	for(i2c_i=0; i2c_i<8; i2c_i=i2c_i+1) begin
		#(I2C_SCL_tick/2); SDA_out <= reg0[7-i2c_i];
		#(I2C_SCL_tick/2); SCL_out <= 1;
//		while(SCL_in == 0) #10;

		i2c_top_count = 300000;
		while ((i2c_top_count > 0) && (SCL_in == 0)) begin i2c_top_count = i2c_top_count-10; #10; end
		if (i2c_top_count == 0) begin
			$display("I2C_MASTER :      SCL HOLD FAIL....", $realtime); 
			$stop;
		end

		#(I2C_SCL_tick  ); SCL_out <= 0;
	end

	#(I2C_SCL_tick/2); SDA_out <= 1; 
	#(I2C_SCL_tick/2); SCL_out <= 1; 
//	while(SCL_in== 0) #10;
	#(I2C_SCL_tick/2); //if(SDA_in == 1) $display($time, " ns,    I2C_MASTER :      ERROR => NACK OCCURS....", $realtime); 
	#(I2C_SCL_tick/2); SCL_out <= 0; 
	#(I2C_SCL_tick*2);
end
endtask 


task I2C_RESTART;
begin 
	SDA_out <= 1; 
	#(I2C_SCL_tick/2); SCL_out <= 1; 
	while(SCL_in== 0) #10; 
	#(I2C_SCL_tick/2); SDA_out <= 0; 
	#(I2C_SCL_tick/2); SCL_out <= 0; 
end 
endtask

task I2C_START;
begin
	SCL_out <= 1; 
	SDA_out <= 1; 
	#(I2C_SCL_tick/2); SDA_out <= 0; 
	#(I2C_SCL_tick/2); SCL_out <= 0; 
end 
endtask

task I2C_MASTER_WCMD1(input [7:0] CMD, input [7:0] val); begin 
	I2C_START; I2C_WRITE({i2c_slaveID, 1'b0}); 
	I2C_WRITE(CMD);
	I2C_WRITE(val);
	I2C_STOP;
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_MASTER_WCMD2(input [7:0] CMD, input [7:0] val1, input [7:0] val2); begin 
//	$display($time, " ns, I2C_MASTER : Wakeup Command !!!");
	I2C_START; I2C_WRITE({i2c_slaveID, 1'b0}); 
	I2C_WRITE(CMD);
	I2C_WRITE(val1);
	I2C_WRITE(val2);
	I2C_STOP;
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_MASTER_WCMD200(input [7:0] CMD, input [7:0] val1, input [7:0] val2); begin 
//	$display($time, " ns, I2C_MASTER : Wakeup Command !!!");
	I2C_START; 
	I2C_WRITE({i2c_slaveID, 1'b0}); 
	I2C_WRITE(CMD);
	I2C_WRITE(val1);
	I2C_WRITE00(val2);
	I2C_STOP00;
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_MASTER_WCMD3(input [7:0] CMD, input [7:0] val1, input [7:0] val2, input [7:0] val3); begin 
//	$display($time, " ns, I2C_MASTER : Wakeup Command !!!");
	I2C_START; I2C_WRITE({i2c_slaveID, 1'b0}); 
	I2C_WRITE(CMD);
	I2C_WRITE(val1);
	I2C_WRITE(val2);
	I2C_WRITE(val3);
	I2C_STOP;
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_MASTER_WCMD4(input [7:0] CMD, input [7:0] val1, input [7:0] val2, input [7:0] val3, input [7:0] val4); begin 
//	$display($time, " ns, I2C_MASTER : Wakeup Command !!!");
	I2C_START; I2C_WRITE({i2c_slaveID, 1'b0}); 
	I2C_WRITE(CMD);
	I2C_WRITE(val1);
	I2C_WRITE(val2);
	I2C_WRITE(val3);
	I2C_WRITE(val4);
	I2C_STOP;
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_MASTER_RD0(input [7:0] regidx); begin 
//	$display($time, " ns, I2C_MASTER : Wakeup Command !!!");
	I2C_START; I2C_WRITE({i2c_slaveID, 1'b0}); 
	I2C_WRITE(regidx);
	I2C_RESTART; I2C_WRITE({i2c_slaveID, 1'b1}); 
	I2C_READ_ACK_normal;	read_data[15:8] = i2c_read_data;
	I2C_READ_NACK_normal;	read_data[7:0] = i2c_read_data;
	$display($time, " ns, I2C_MASTER : Read\t(A:0x%02x,D:0x%02x,P:0x%02x)", regidx, read_data[15:8], read_data[7:0]);
	I2C_STOP;
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_MASTER_NOPRT_RD0(input [7:0] regidx); begin 
//	$display($time, " ns, I2C_MASTER : Wakeup Command !!!");
	I2C_START; I2C_WRITE({i2c_slaveID, 1'b0}); 
	I2C_WRITE(regidx);
	I2C_RESTART; I2C_WRITE({i2c_slaveID, 1'b1}); 
	I2C_READ_NACK_normal;	read_data[7:0] = i2c_read_data;
	$display($time, " ns, I2C_MASTER : Read\t(A:0x%02x,D:0x%02x)", regidx, read_data[7:0]);
	I2C_STOP;
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_MASTER_NOPRT_RD2(input [7:0] regidx); begin 
//	$display($time, " ns, I2C_MASTER : Wakeup Command !!!");
	I2C_START; I2C_WRITE({i2c_slaveID, 1'b0}); 
	I2C_WRITE(regidx);
	I2C_RESTART; I2C_WRITE({i2c_slaveID, 1'b1}); 
	I2C_READ_ACK_normal;	read_data[15:8] = i2c_read_data;
	I2C_READ_NACK_normal;	read_data[7:0] = i2c_read_data;
	$display($time, " ns, I2C_MASTER : Read\t(A:0x%02x,D:0x%04x)", regidx, read_data[15:0]);
	I2C_STOP;
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_MASTER_NOPRT_RD4(input [7:0] regidx); begin 
//	$display($time, " ns, I2C_MASTER : Wakeup Command !!!");
	I2C_START; I2C_WRITE({i2c_slaveID, 1'b0}); 
	I2C_WRITE(regidx);
	I2C_RESTART; I2C_WRITE({i2c_slaveID, 1'b1}); 
	I2C_READ_ACK_normal;	read_data[31:24] = i2c_read_data;
	I2C_READ_ACK_normal;	read_data[23:16] = i2c_read_data;
	I2C_READ_ACK_normal;	read_data[15:08] = i2c_read_data;
	I2C_READ_NACK_normal;	read_data[07:00] = i2c_read_data;
	$display($time, " ns, I2C_MASTER : Read\t(A:0x%02x,D:0x%08x)", regidx, read_data[31:0]);
	I2C_STOP;
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_MASTER_RD1(input [7:0] regidx); begin 
//	$display($time, " ns, I2C_MASTER : Wakeup Command !!!");
	I2C_START; I2C_WRITE({i2c_slaveID, 1'b0}); 
	I2C_WRITE(regidx);
	I2C_RESTART; I2C_WRITE({i2c_slaveID, 1'b1}); 
	I2C_READ_ACK_normal;	read_data[23:16] = i2c_read_data;
	I2C_READ_ACK_normal;	read_data[15:8] = i2c_read_data;
	I2C_READ_NACK_normal;	read_data[7:0] = i2c_read_data;
	$display($time, " ns, I2C_MASTER : Read\t(A:0x%02x,D:0x%04x,P:0x%02x)", regidx, read_data[23:8], read_data[7:0]);
	I2C_STOP;
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_MASTER_READ5(output [7:0] val1, output [7:0] val2, output [7:0] val3, output [7:0] val4, output [7:0] parity); begin 
//	$display($time, " ns, I2C_MASTER : Wakeup Command !!!");
	I2C_START; I2C_WRITE({i2c_slaveID, 1'b1}); 
	I2C_READ_ACK_normal; val1   = i2c_read_data;
	I2C_READ_ACK_normal; val2   = i2c_read_data;
	I2C_READ_ACK_normal; val3   = i2c_read_data;
	I2C_READ_ACK_normal; val4   = i2c_read_data;
	I2C_READ_NACK_normal; parity = i2c_read_data;
	I2C_STOP;
	$display($time, " ns, I2C_MASTER : Key Read\t(KS:0x%02x,0x%02x,0x%02x,0x%02x,P:0x%02x)", val1,val2,val3,val4, parity);
	#(I2C_ST_INTERVAL);
end
endtask

task I2C_STOP;
begin
	SDA_out <= 0;
	#(I2C_SCL_tick/2); SCL_out <= 1; 
	while(SCL_in == 0)
	#10; 
	#(I2C_SCL_tick/2); SDA_out <= 1; 
	#(I2C_SCL_tick/2);
end 
endtask

task I2C_STOP00;
begin
	SDA_out <= 0;
	#(I2C_SCL_tick/2); SCL_out <= 1; 
//	while(SCL_in == 0)
	#10; 
	#(I2C_SCL_tick/2); SDA_out <= 1; 
	#(I2C_SCL_tick/2);
end 
endtask

task I2C_MASTER_WR_DON(input on_off); begin 
	I2C_MASTER_WCMD1({4'h1, 3'd0, on_off}, {4'h1, 3'd0, on_off});
	$display($time, " ns, I2C_MASTER :DON Write\t(A:0x1,D:0x%1x)",on_off );
end
endtask

task I2C_MASTER_WR_DISPMOD(input [2:0] disp_mode); begin 
	I2C_MASTER_WCMD1({4'h2, 1'd0, disp_mode}, {4'h2, 1'd0, disp_mode});
	$display($time, " ns, I2C_MASTER :DISPMOD Write\t(A:0x2,D:0x%1x)",disp_mode);
end
endtask

task I2C_MASTER_WR_DIMMOD(input [2:0] dim_mode); begin 
	I2C_MASTER_WCMD1({4'h3, 1'd0, dim_mode}, {4'h3, 1'd0, dim_mode});
	$display($time, " ns, I2C_MASTER :DIMMOD Write\t(A:0x3,D:0x%1x)",dim_mode);
end
endtask

task I2C_MASTER_WR_ADDRSET(input [2:0] addr_set, input [1:14] seg_data); begin 
	I2C_MASTER_WCMD3({4'h5, 1'd0, addr_set}, seg_data[1:8], {seg_data[9:14], 2'd0},
	                 {4'h5, 1'd0, addr_set}^ seg_data[1:8]^ {seg_data[9:14], 2'd0});
	$display($time, " ns, I2C_MASTER :ADDRSET Write\t(A:0x5%01x,0x%04x)",addr_set,seg_data);
end
endtask

task I2C_MASTER_WR(input [7:0] addr, input [7:0] data); begin 
	I2C_MASTER_WCMD2(addr,  data[7:0],
	                 addr^  data[7:0]);
	$display($time, " ns, I2C_MASTER :1byte Write\t(A:0x%02x,0x%02x)",addr,data);
end
endtask

task I2C_MASTER_WR00(input [7:0] addr, input [7:0] data); begin 
	I2C_MASTER_WCMD200(addr,  data[7:0],
	                 addr^  data[7:0]);
	$display($time, " ns, I2C_MASTER :1byte Write\t(A:0x%02x,0x%02x)",addr,data);
end
endtask
wire w_don		;     

//------------------------------------------------
// Instantiate the I2C slave module

reg [7:0] ival1, ival2, ival3, ival4, parity;
`else  //not TEST_I2C

	wire SCL;
	wire SDA;

`endif
reg	[7:0]	lv0_wreg[3:0];
reg [63:0] ef_data;

reg	[4:0]	RC_OSC_BIAS_TRIM	;
reg	[1:0]	RC_OSC_CAP_TRIM 	;
reg	[4:0]	DRV_IBIAS_TRIM  	;
reg	[5:0]	I               	;
reg	     	RES             	;
reg	[4:0]	BGR_OUT_FE_TRIM 	;
reg	[4:0]	BGR_OUT_TRIM    	;
reg	[4:0]	VPTAT_OUT_TRIM  	;
reg	[4:0]	TSP_125_TRIM    	;
reg	[4:0]	TSP_150_TRIM    	;
reg	[2:0]	LOD_REF_TRIM    	;
reg	[2:0]	LSD_REF_TRIM    	;
reg	     	GRID_MODE       	;
reg	[3:0]	I_MAX             	;
reg 		DCHG_EN         	;
reg	     	CHG_EN          	;
reg	[1:0]	SEG_MODE        	;
reg	     	PGM_FLAG    	  	;
reg	[3:0]	CRC             	;

reg [7:0]	grid_num;
wire [3:0]	sg_hi;
wire [7:00]	dout;

wire	GRID1	;
wire	GRID2	;
wire	GRID3	;
wire	GRID4	;
wire	GRID5	;
wire	GRID6	;
wire	GRID7	;
wire	GRID8	;
wire	GRID9	;
wire	GRID10	;
wire	SEG1	;
wire	SEG2	;
wire	SEG3	;
wire	SEG4	;
wire	SEG5	;
wire	SEG6	;
wire	SEG7	;
wire	SEG8	;
wire	SEG9	;
wire	SEG10	;
wire	SEG11	;
wire	SEG12	;
wire	SEG13	;
wire	SEG14	;
wire	SEG15	;
wire	SEG16	;
wire	SEG17	;
wire	SEG18	;
wire	SEG19	;
wire	SEG20	;
wire	SEG21	;
wire	SEG22	;
wire	SEG23	;
wire	SEG24	;
wire	SEG25	;
wire	SEG26	;
wire	SEG27	;
wire	SEG28	;
wire	SEG29	;
wire	SEG30	;
wire	SEG31	;
wire	SEG32	;
//wire	CS1		;
//wire	CS0		;
reg 	CS1		;
reg 	CS0		;
wire	REXT	;



CHICAGO_CHIP u_chicago_chip (
	/*output	wire	*/	.P_GRID1	(GRID1		),
	/*output	wire	*/	.P_GRID2	(GRID2		),
	/*output	wire	*/	.P_GRID3	(GRID3		),
	/*output	wire	*/	.P_GRID4	(GRID4		),
	/*output	wire	*/	.P_GRID5	(GRID5		),
	/*output	wire	*/	.P_GRID6	(GRID6		),
	/*output	wire	*/	.P_GRID7	(GRID7		),
	/*output	wire	*/	.P_GRID8	(GRID8		),
	/*output	wire	*/	.P_GRID9	(GRID9		),
	/*output	wire	*/	.P_GRID10	(GRID10		),
	/*output	wire	*/	.P_SEG1		(SEG1		),
	/*output	wire	*/	.P_SEG2		(SEG2		),
	/*output	wire	*/	.P_SEG3		(SEG3		),
	/*output	wire	*/	.P_SEG4		(SEG4		),
	/*output	wire	*/	.P_SEG5		(SEG5		),
	/*output	wire	*/	.P_SEG6		(SEG6		),
	/*output	wire	*/	.P_SEG7		(SEG7		),
	/*output	wire	*/	.P_SEG8		(SEG8		),
	/*output	wire	*/	.P_SEG9		(SEG9		),
	/*output	wire	*/	.P_SEG10	(SEG10		),
	/*output	wire	*/	.P_SEG11	(SEG11		),
	/*output	wire	*/	.P_SEG12	(SEG12		),
	/*output	wire	*/	.P_SEG13	(SEG13		),
	/*output	wire	*/	.P_SEG14	(SEG14		),
	/*output	wire	*/	.P_SEG15	(SEG15		),
	/*output	wire	*/	.P_SEG16	(SEG16		),
	/*output	wire	*/	.P_SEG17	(SEG17		),
	/*output	wire	*/	.P_SEG18	(SEG18		),
	/*output	wire	*/	.P_SEG19	(SEG19		),
	/*output	wire	*/	.P_SEG20	(SEG20		),
	/*output	wire	*/	.P_SEG21	(SEG21		),
	/*output	wire	*/	.P_SEG22	(SEG22		),
	/*output	wire	*/	.P_SEG23	(SEG23		),
	/*output	wire	*/	.P_SEG24	(SEG24		),
	/*output	wire	*/	.P_SEG25	(SEG25		),
	/*output	wire	*/	.P_SEG26	(SEG26		),
	/*output	wire	*/	.P_SEG27	(SEG27		),
	/*output	wire	*/	.P_SEG28	(SEG28		),
	/*output	wire	*/	.P_SEG29	(SEG29		),
	/*output	wire	*/	.P_SEG30	(SEG30		),
	/*output	wire	*/	.P_SEG31	(SEG31		),
	/*output	wire	*/	.P_SEG32	(SEG32		),
	/*input		wire	*/	.P_CS1		(CS1		),
	/*input		wire	*/	.P_CS0		(CS0		),
	/*input		wire	*/	.P_REXT		(REXT		),
	/*inout		wire	*/	.P_SCL		(SCL		),
	/*inout		wire	*/	.P_SDA		(SDA		)
);

`ifndef HOST_OSC_MODEL

reg CLK; //host clock
initial begin
	forever begin
		CLK = 1'b0;
		`ifndef HOST_OSC_HPERIOD
			#250;
		`else
			#`HOST_OSC_HPERIOD;
		`endif
		CLK = 1'b1;
		`ifndef HOST_OSC_HPERIOD
			#250;
		`else
			#`HOST_OSC_HPERIOD;
		`endif
	end
end

`else
wire CLK;
OSC_MODEL #(
	`ifndef HOST_OSC_HPERIOD
		.osc_half_period	(250)
	`else
		.osc_half_period	(`HOST_OSC_HPERIOD)
	`endif
) u_host_osc_model (
	.OSC_EN		(1'b1		),
	.OSC_CLK	(CLK)
);
`endif

`include "defines.inc"
`include "spi_slave_test.inc"
`ifdef	DFT_TEST
assign SCL = (test_mode) ? 1'bz : sck;
`else
assign SCL = sck;
`endif

//-------------------------
// trans. line : will be revised
//-------------------------
reg trans_line;
always @(*) begin
	trans_line = (!r_host_oeb) ? mosi : 1'bz; 
end
assign SDA  = trans_line;
assign miso = SDA; 
//-------------------------
initial begin
	CS0 = 1'b0;
	CS1 = 1'b0;
end

integer ii;
integer jj;
integer kk;
integer mm;

wire[3:0] crcIn = 4'hE;
wire[3:0] crcOut;

crc tb_crc(
/*input [3:0]  */.crcIn	(crcIn	),
/*input [59:0] */.data	(ef_data[59:0]),
/*output [3:0] */.crcOut(crcOut	) 
);

reg [3:0] r_g_n;

initial begin 
	for (mm=0; mm<320; mm=mm+1) begin
		`mem0_data[mm] = 0;
		`mem1_data[mm] = 0;
	end
	//#10;$readmemh("sram.hex",`mem0_data,0,255); 

end
initial begin

 	ef_data = 64'd0;
	RC_OSC_BIAS_TRIM	=	5'h00;
	RC_OSC_CAP_TRIM 	=	2'h0;
	DRV_IBIAS_TRIM  	=	5'h00;
	I               	=	6'h00;
	RES             	=	1'h0;
	BGR_OUT_FE_TRIM 	=	5'h00;
	BGR_OUT_TRIM    	=	5'h00;
	VPTAT_OUT_TRIM  	=	5'h00;
	TSP_125_TRIM    	=	5'h04;
	TSP_150_TRIM    	=	5'h04;
	LOD_REF_TRIM    	=	3'h4;
	LSD_REF_TRIM    	=	3'h4;
	GRID_MODE       	=	1'h1;
	I_MAX             	=	4'hf;
	DCHG_EN         	=	1'h1;
	CHG_EN          	=	1'h1;
	SEG_MODE        	=	2'h3;
	PGM_FLAG    	  	=	1'h0;
	ss  = 1;
	sck = 1;
	mosi = 1;
	r_host_oeb = 0;
	#120000;
`ifdef SPI_TEST
	#5000000;
	#5000000;
//	cmd_write(8'h4);
//	cmd_write(8'h4);
//	cmd_write(8'hE);
//	cmd_write(8'h4);
//	$finish;

//	spi_bwdata[0] = 8'h55;
//	spi_bwdata[1] = 8'h55;
//	spi_bwdata[2] = 8'h55;
//	spi_bwdata[3] = 8'h55;
//	reg_write_burst(16'h410, 16'd4);
//
//	spi_bwdata[0] = 8'hAA;
//	spi_bwdata[1] = 8'hAA;
//	spi_bwdata[2] = 8'hAA;
//	spi_bwdata[3] = 8'hAA;
//	cmd_write(8'hc2);
//	cksum = 0;
//	for (ii=0; ii<4; ii=ii+1) begin
//		spi_bwrite(0, spi_bwdata[ii]);
//		cksum = cksum + spi_bwdata[ii];
//	end
//	spi_bwrite(0, cksum);
//
//	reg_read_burst(16'h410, 16'd8);	//fuse readdata
//	$finish;

//	reg_write_1byte(16'h4F2, 8'h07);
//	reg_write_1byte(16'h4F2, 8'h07);
//	$finish;

	$display($stime, " ns #### LV0REG Default Read ###");
	reg_read_burst(16'h400, 16'd4);

	$display($stime, " ns #### ANAREG Default Read ###");
	reg_read_burst(16'h404, 16'd12);

	$display($stime, " ns #### EFUSEREG Default Read ###");
	reg_read_burst(16'h410, 16'd19);

	$display($stime, " ns #### REGREAD Default Read ###");
	reg_read_burst(16'h423, 16'd1);

	$display($stime, " ns #### DISP SFTM Default Read ###");
	reg_read_burst(16'h4F0, 16'd1);

	$display($stime, " ns #### TESTREG Default Read ###");
	reg_read_burst(16'h4F2, 16'd1);

	$display($stime, " ns #### DIVID Default Read ###");
	reg_read_burst(16'h4FC, 16'd1);

	$display($stime, " ns #### LV3_WREG0 Default Read ###");
	reg_read_burst(16'h4FD, 16'd1);

	$display($stime, " ns #### READ_FLAG Default Read ###");
	reg_read_burst(16'h4FE, 16'd02);
	$display($stime, " ns #### Default Read DONE ###");
	$display($stime, " ns #### LIMIT_TEST ###");
	#100000;
	reg_write_1byte(16'h400, 8'h3F); 
	reg_write_1byte(16'h40f, 8'h07); 
	#100000;
	reg_write_1byte(16'h400, 8'h30); 
	#100000;
	reg_write_1byte(16'h400, 8'h20); 
	#100000;
	reg_write_1byte(16'h400, 8'h1f); 
	#100000;
	reg_write_1byte(16'h400, 8'h1e); 
	#100000;
	reg_write_1byte(16'h400, 8'h17); 

	#100000;
	creg_write(8'hff, 8'h4, 8'h8, 8'hc4);

	#100000;
	reg_write_1byte(16'h4FE, 8'h01);
	#100000;
	reg_read_burst(16'h400, 16'h4);
	//reg_read_burst(16'h400, 16'h1);

	$display($stime, " ns #### 5BURST WRITE TEST ###");
	spi_bwdata[0] = 8'h05;
	spi_bwdata[1] = 8'h05;
	spi_bwdata[2] = 8'h05;
	spi_bwdata[3] = 8'h05;
	spi_bwdata[4] = 8'h05;
	spi_bwdata[5] = 8'h05;
	spi_bwdata[6] = 8'h05;
	spi_bwdata[7] = 8'h05;
	spi_bwdata[8] = 8'h05;
	spi_bwdata[9] = 8'h05;
	reg_write_burst_abn(16'h410, 16'd5);
	#100000;
	$display($stime, " ns #### 5BURST READ TEST ###");
	reg_read_burst(16'h410, 16'h10);
	#100000;
//	cmd_write(8'h0E); // sleep
//	
//	#100000;
//	disp_write_idat(9'd64, 8'h5A);
//	#100000;
//	reg_read_burst(16'h4FC, 16'h1);

	#100000;
	$finish;

`elsif DFT_TEST 
	test_mode = 0;
	#5_000_000;

	$display($stime, " ns #### Analog TEST ###");
	reg_write_1byte(`ADD_TESTREG, (1<<2)+(0<<1)+(1<<0));	#1_000_000;
	test_mode = 1;
	force tb_top.r_host_oeb = 1'b1;
	#1_000_000;
	force tb_top.u_chicago_chip.P_SCL	= tb_top.sck;
	force tb_top.u_chicago_chip.P_REXT 	= tb_top.mosi;
	reg_write_1byte(`ADD_ANA_WREG7, 8'h5A);	#1_000_000;
	reg_write_1byte(`ADD_ANA_WREG7, 8'hA5);	#1_000_000;
	#1_000_000;
	release tb_top.u_chicago_chip.P_SCL;
	release tb_top.u_chicago_chip.P_REXT;
	release tb_top.r_host_oeb;
	test_mode = 0;

	force tb_top.u_chicago_chip.u_chicago_ana.I_ANA_RESETB = 1'b0;	#1_000;
	release tb_top.u_chicago_chip.u_chicago_ana.I_ANA_RESETB;
	#5_000_000;
	$display($stime, " ns #### SRAM BIST TEST ###");
	reg_write_1byte(`ADD_TESTREG, (1<<2)+(1<<1)+(0<<0));	#1_000_000;
	test_mode = 1;
	force tb_top.u_chicago_chip.P_CS1 = 1'b0;	//BIST_RSTN
	force tb_top.u_chicago_chip.P_CS0 = tb_top.u_chicago_chip.u_chicago_ana.I_CK8M;	
	#100_000;
	force tb_top.u_chicago_chip.P_CS1 = 1'b1;	//BIST_RSTN
	force tb_top.r_host_oeb = 1'b1;
	#1_600_000;
	force tb_top.u_chicago_chip.u_chicago_dig.u_io_mux.I_BIST_FAIL = 2'b11;
	#5_000;

	force tb_top.u_chicago_chip.u_chicago_ana.I_ANA_RESETB = 1'b0;	#1_000;
	release tb_top.u_chicago_chip.u_chicago_ana.I_ANA_RESETB;
	release tb_top.r_host_oeb;
	release tb_top.u_chicago_chip.P_CS1;
	release tb_top.u_chicago_chip.P_CS0;
	test_mode = 0;
	#5_000_000;
	$display($stime, " ns #### SCAN TEST ###");
	reg_write_1byte(`ADD_TESTREG, (1<<2)+(1<<1)+(1<<0));	#1_000_000;
	test_mode = 1;
	#5_000;
	$finish;
	
`elsif RAM_RW 
	#5000000;

	//changing spi read @fall-edge
	`ifdef HOST_SPI_READ_FEDGE
		reg_write_1byte(16'h4fd, 8'd5);
		//reg_write_1byte(16'h4fd, 8'hd);
	`endif

	//checking register interface
	reg_write_1byte(16'h410, 8'h01);
	reg_write_1byte(16'h411, 8'h02);
	reg_write_1byte(16'h412, 8'h03);
	reg_write_1byte(16'h413, 8'h04);

	spi_bwdata[0] = 8'h05;
	spi_bwdata[1] = 8'h06;
	spi_bwdata[2] = 8'h07;
	spi_bwdata[3] = 8'h08;
	reg_write_burst(16'h414, 16'd4);
	reg_read_burst(16'h410, 16'd8);
	cksum = 0;
	for (ii=0; ii<8; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if ((ii+1) !== spi_brdata[ii]) begin
			$display("reg. read fail: 0x%03h address, 0x%02h wrote but 0x%02h read",
					  (11'h410+ii), ii+1, spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[8]) begin
		$display("reg. read check sum fail");
		$finish;
	end
	$display("reg write and read test successfully done (0x410-0x417)");

	for (ii=0; ii<320; ii=ii+1) begin
		reg_write_1byte(ii, ii);
	end

	reg_read_burst(16'h0, 16'd320);
	cksum = 0;
	for (ii=0; ii<320; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if ((ii & 8'hFF) !== spi_brdata[ii]) begin
			$display("SRAM0 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
			          ii, (ii & 8'hFF), spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[320]) begin
		$display("SRAM0 read check sum fail");
		$finish;
	end
	
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h0, 8'hc4);   //G_N = 9, OSC = 1
	
	disp_write_idat(9'd320, 8'hFF);
	reg_read_burst(16'h0, 16'd320);
	cksum = 0;
	for (ii=0; ii<320; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if (8'hFF !== spi_brdata[ii]) begin
			$display("SRAM0 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
			          ii, 8'hFF, spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[320]) begin
		$display("SRAM0 read check sum fail");
		$finish;
	end

	`ifdef RAM_RW_PATTERN
	disp_write_idat(9'd320, 8'h00);
	reg_read_burst(16'h0, 16'd320);
	cksum = 0;
	for (ii=0; ii<320; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if (8'h00 !== spi_brdata[ii]) begin
			$display("SRAM0 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
			          ii, 8'h00, spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[320]) begin
		$display("SRAM0 read check sum fail");
		$finish;
	end

	disp_write_idat(9'd320, 8'hA5);
	reg_read_burst(16'h0, 16'd320);
	cksum = 0;
	for (ii=0; ii<320; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if (8'hA5 !== spi_brdata[ii]) begin
			$display("SRAM0 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
			          ii, 8'hA5, spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[320]) begin
		$display("SRAM0 read check sum fail");
		$finish;
	end

	disp_write_idat(9'd320, 8'h5A);
	reg_read_burst(16'h0, 16'd320);
	cksum = 0;
	for (ii=0; ii<320; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if (8'h5A !== spi_brdata[ii]) begin
			$display("SRAM0 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
			          ii, 8'h5A, spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[320]) begin
		$display("SRAM0 read check sum fail");
		$finish;
	end
	`endif

	$display("RAM0 DATA RW successfully completed");
	
	for (ii=512; ii<512+320; ii=ii+1) begin
		reg_write_1byte(ii, ii);
	end

	reg_read_burst(16'h200, 16'd320);
	cksum = 0;
	for (ii=512; ii<512+320; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if ((ii & 8'hFF) !== spi_brdata[ii-512]) begin
			$display("SRAM1 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
			          ii, (ii & 8'hFF), spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[512+320]) begin
		$display("SRAM1 read check sum fail");
		$finish;
	end

	`ifdef RAM_RW_PATTERN
	for (ii=512; ii<512+320; ii=ii+1) begin
		reg_write_1byte(ii, 8'hFF);
	end

	reg_read_burst(16'h200, 16'd320);
	cksum = 0;
	for (ii=512; ii<512+320; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if (8'hFF !== spi_brdata[ii-512]) begin
			$display("SRAM1 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
			          ii, 8'hFF, spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[512+320]) begin
		$display("SRAM1 read check sum fail");
		$finish;
	end

	for (ii=512; ii<512+320; ii=ii+1) begin
		reg_write_1byte(ii, 8'h00);
	end

	reg_read_burst(16'h200, 16'd320);
	cksum = 0;
	for (ii=512; ii<512+320; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if (8'h00 !== spi_brdata[ii-512]) begin
			$display("SRAM1 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
			          ii, 8'h00, spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[512+320]) begin
		$display("SRAM1 read check sum fail");
		$finish;
	end

	for (ii=512; ii<512+320; ii=ii+1) begin
		reg_write_1byte(ii, 8'hA5);
	end

	reg_read_burst(16'h200, 16'd320);
	cksum = 0;
	for (ii=512; ii<512+320; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if (8'hA5 !== spi_brdata[ii-512]) begin
			$display("SRAM1 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
			          ii, 8'hA5, spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[512+320]) begin
		$display("SRAM1 read check sum fail");
		$finish;
	end

	for (ii=512; ii<512+320; ii=ii+1) begin
		reg_write_1byte(ii, 8'h5A);
	end

	reg_read_burst(16'h200, 16'd320);
	cksum = 0;
	for (ii=512; ii<512+320; ii=ii+1) begin
		cksum = cksum + spi_brdata[ii];
		if (8'h5A !== spi_brdata[ii-512]) begin
			$display("SRAM1 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
			          ii, 8'h5A, spi_brdata[ii]);
			$finish;
		end
	end
	if (cksum !== spi_brdata[512+320]) begin
		$display("SRAM1 read check sum fail");
		$finish;
	end
	`endif

	$display("RAM1 DATA RW successfully completed");
	#1000;
	$finish;

`elsif MANUAL_DISP_UPDATE 
	#10000000;
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b11;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h3C, 8'h0, 8'hc4);   //G_N = 9
	disp_write_idat(9'd288, 8'hFF);
	$display("\t\t############\t DISP DATA SRAM WRITE \t############");
	cmd_write(8'h04); // manual disp. update
	$display("\t\t############\t Manual DISP update \t############");
	creg_write(8'h3f, 8'h3C, 8'h0, 8'h04);   //G_N = 9// SLEEP==0
	creg_write(8'h3f, 8'h3C, 8'h8, 8'h04);   //display on
	#5000000;
	disp_write_idat(9'd288, 8'h55);
	$display("\t\t############\t DISP DATA SRAM WRITE \t############");
	cmd_write(8'h04); // manual disp. update
	$display("\t\t############\t Manual DISP update \t############");
	#5000000;
	creg_write(8'h3f, 8'h3C, 8'h0, 8'h04);   //G_N = 9// SLEEP==0//display off
	$display("\t\t############\t DON == 0 \t############");
	#5000000;
	creg_write(8'h3f, 8'h3C, 8'h8, 8'h04);   //display on
	$display("\t\t############\t DON == 1 \t############");
	#5000000;
	creg_write(8'h3f, 8'h3C, 8'h0, 8'h04);   //G_N = 9// SLEEP==0//display off
	$display("\t\t############\t DON == 0 \t############");
	#5000000;
	disp_write_idat(9'd288, 8'hAA);
	$display("\t\t############\t DISP DATA SRAM WRITE \t############");
	cmd_write(8'h04); // manual disp. update
	$display("\t\t############\t Manual DISP update \t############");
	#5000000;
	creg_write(8'h3f, 8'h3C, 8'h8, 8'h04);   //display on
	$display("\t\t############\t DON == 1 \t############");
	#5000000;
///////////////////////////////////////////////////////////////////////////////////////////
	creg_write(8'h3f, 8'h3d, 8'h0, 8'hc4);   //G_N = 9
	$display("\t\t############\t AUTO update \t############");
	disp_write_idat(9'd288, 8'hF2);
	$display("\t\t############\t DISP DATA SRAM WRITE \t############");
//	cmd_write(8'h04); // manual disp. update
//	$display("\t\t############\t Manual DISP update \t############");
	creg_write(8'h3f, 8'h3d, 8'h0, 8'h04);   //G_N = 9// SLEEP==0
	creg_write(8'h3f, 8'h3d, 8'h8, 8'h04);   //display on
	#5000000;
	disp_write_idat(9'd288, 8'h52);
	$display("\t\t############\t DISP DATA SRAM WRITE \t############");
//	cmd_write(8'h04); // manual disp. update
//	$display("\t\t############\t Manual DISP update \t############");
	#5000000;
	creg_write(8'h3f, 8'h3d, 8'h0, 8'h04);   //G_N = 9// SLEEP==0//display off
	$display("\t\t############\t DON == 0 \t############");
	#5000000;
	creg_write(8'h3f, 8'h3d, 8'h8, 8'h04);   //display on
	$display("\t\t############\t DON == 1 \t############");
	#5000000;
	creg_write(8'h3f, 8'h3d, 8'h0, 8'h04);   //G_N = 9// SLEEP==0//display off
	$display("\t\t############\t DON == 0 \t############");
	#5000000;
	disp_write_idat(9'd288, 8'hA2);
	$display("\t\t############\t DISP DATA SRAM WRITE \t############");
//	cmd_write(8'h04); // manual disp. update
//	$display("\t\t############\t Manual DISP update \t############");
	#5000000;
	creg_write(8'h3f, 8'h3d, 8'h8, 8'h04);   //display on
	$display("\t\t############\t DON == 1 \t############");


//	reg_read_burst(16'h0, 16'd288);
	#5000000;
	$finish;

`elsif EFUSE_TEST		
	#4000000;
	#4000000;
	reg_write_1byte(16'h410, 8'h55);
	reg_write_1byte(16'h411, 8'h55);
	reg_write_1byte(16'h412, 8'h55);
	reg_write_1byte(16'h413, 8'h55);
	reg_write_1byte(16'h414, 8'h55);
	reg_write_1byte(16'h415, 8'h55);
	reg_write_1byte(16'h416, 8'h55);
	reg_write_1byte(16'h417, 8'h55);

	reg_write_1byte(16'h422, {/*EF_PASSCODE*/8'h38} );
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd1,/*EF_CMD_READ*/1'd0});
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd0,/*EF_CMD_READ*/1'd0});
	reg_write_1byte(16'h422, {/*EF_PASSCODE*/8'h00} );
	#4000000;
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd0,/*EF_CMD_READ*/1'd1});
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd0,/*EF_CMD_READ*/1'd0});
	#700_000;
	reg_read_burst(16'h418, 16'd8);	//fuse readdata
	
	reg_write_1byte(16'h410, 8'hAA);
	reg_write_1byte(16'h411, 8'hAA);
	reg_write_1byte(16'h412, 8'hAA);
	reg_write_1byte(16'h413, 8'hAA);
	reg_write_1byte(16'h414, 8'hAA);
	reg_write_1byte(16'h415, 8'hAA);
	reg_write_1byte(16'h416, 8'hAA);
	reg_write_1byte(16'h417, 8'hAA);
	
	reg_write_1byte(16'h422, {/*EF_PASSCODE*/8'h38} );
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd1,/*EF_CMD_READ*/1'd0});
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd0,/*EF_CMD_READ*/1'd0});
	reg_write_1byte(16'h422, {/*EF_PASSCODE*/8'h00} );
	#4000000;
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd0,/*EF_CMD_READ*/1'd1});
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd0,/*EF_CMD_READ*/1'd0});
	#700_000;
	reg_read_burst(16'h418, 16'd8);	//fuse readdata
	#4000000;
	
	reg_write_1byte(16'h410, 8'h00);
	reg_write_1byte(16'h411, 8'h00);
	reg_write_1byte(16'h412, 8'h00);
	reg_write_1byte(16'h413, 8'h00);
	reg_write_1byte(16'h414, 8'h00);
	reg_write_1byte(16'h415, 8'h00);
	reg_write_1byte(16'h416, 8'h00);
	reg_write_1byte(16'h417, 8'h00);
	
	reg_write_1byte(16'h422, {/*EF_PASSCODE*/8'h38} );
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd1,/*EF_CMD_READ*/1'd0});
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd0,/*EF_CMD_READ*/1'd0});
	reg_write_1byte(16'h422, {/*EF_PASSCODE*/8'h00} );
	#4000000;
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd0,/*EF_CMD_READ*/1'd1});
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd0,/*EF_CMD_READ*/1'd0});
	#700_000;
	reg_read_burst(16'h418, 16'd8);	//fuse readdata
	#4000000;

	$finish;
	
	`elsif PMU_TEST
	#4000000;
	#4000000;
	RC_OSC_BIAS_TRIM	=	5'h13;
	RC_OSC_CAP_TRIM 	=	2'h2;
	DRV_IBIAS_TRIM  	=	5'h11;
	I               	=	6'h20;
	RES             	=	1'h1;
	BGR_OUT_FE_TRIM 	=	5'h07;
	BGR_OUT_TRIM    	=	5'h18;
	VPTAT_OUT_TRIM  	=	5'h11;
	TSP_125_TRIM    	=	5'h12;
	TSP_150_TRIM    	=	5'h1f;
	LOD_REF_TRIM    	=	3'h6;
	LSD_REF_TRIM    	=	3'h3;
	GRID_MODE       	=	1'h0;
	I_MAX             	=	4'h8;
	DCHG_EN         	=	1'h0;
	CHG_EN          	=	1'h1;
	SEG_MODE        	=	2'h2;
	PGM_FLAG    	  	=	1'h1;
	#1; 
	ef_data[59:0] = {
	PGM_FLAG			,
	SEG_MODE			,
	CHG_EN				,
	DCHG_EN         	,
	I_MAX             	,
	GRID_MODE       	,
	LSD_REF_TRIM    	,
	LOD_REF_TRIM    	,
	TSP_150_TRIM    	,
	TSP_125_TRIM    	,
	VPTAT_OUT_TRIM  	,
	BGR_OUT_TRIM    	,
	BGR_OUT_FE_TRIM 	,
	RES             	,
	I               	,
	DRV_IBIAS_TRIM  	,
	RC_OSC_CAP_TRIM 	,
	RC_OSC_BIAS_TRIM	};
	#1;
	ef_data[63:60] 	=	crcOut;
	#1;
	reg_write_1byte(16'h410, ef_data[7:0]);
	reg_write_1byte(16'h411, ef_data[15:08]);
	reg_write_1byte(16'h412, ef_data[23:16]);
	reg_write_1byte(16'h413, ef_data[31:24]);
	reg_write_1byte(16'h414, ef_data[39:32]);
	reg_write_1byte(16'h415, ef_data[47:40]);
	reg_write_1byte(16'h416, ef_data[55:48]);
	reg_write_1byte(16'h417, ef_data[63:56]);

	reg_write_1byte(16'h422, {/*EF_PASSCODE*/8'h38} );
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd1,/*EF_CMD_READ*/1'd0});#2000_000;

	force tb_top.u_chicago_chip.u_chicago_dig.I_ANA_RESETB = 1'b0;
	#100000;
	release tb_top.u_chicago_chip.u_chicago_dig.I_ANA_RESETB;

	#6000000;
	#6000000;

	reg_write_1byte(16'h422, {/*EF_PASSCODE*/8'h38} );
	reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd1,/*EF_CMD_READ*/1'd0});#1000_000;
	reg_read_burst(16'h418, 16'd8);	//fuse readdata
	cmd_write(8'hD);//WAKEUP CMD
	$display("\t\t############\t WAKEUP_CMD\t############");
	#1000000;

`ifndef POST_SIM
	if(I_MAX           	==tb_top.u_chicago_chip.u_chicago_dig.u_RegBlk.i_max   	)$display($stime,"ns:\tI_MAX          pass");else $display($stime,"ns:\tI_MAX            fail");
`endif                                                                                                                                                   
	if(SEG_MODE			==tb_top.u_chicago_chip.u_chicago_dig.u_RegBlk.O_SEG_MODE)$display($stime,"ns:\tSEG_MODE	   pass");else $display($stime,"ns:\tSEG_MODE	     fail");
	if(CHG_EN			==tb_top.u_chicago_chip.u_chicago_dig.O_CHG_EN			)$display($stime,"ns:\tCHG_EN		   pass");else $display($stime,"ns:\tCHG_EN		     fail");
	if(DCHG_EN         	==tb_top.u_chicago_chip.u_chicago_dig.O_DCHG_EN        	)$display($stime,"ns:\tDCHG_EN         pass");else $display($stime,"ns:\tDCHG_EN         fail");
	if(GRID_MODE       	==tb_top.u_chicago_chip.u_chicago_dig.O_GRID_MODE      	)$display($stime,"ns:\tGRID_MODE       pass");else $display($stime,"ns:\tGRID_MODE       fail");
	if(LSD_REF_TRIM    	==tb_top.u_chicago_chip.u_chicago_dig.O_LSD_REF_TRIM   	)$display($stime,"ns:\tLSD_REF_TRIM    pass");else $display($stime,"ns:\tLSD_REF_TRIM    fail");
	if(LOD_REF_TRIM    	==tb_top.u_chicago_chip.u_chicago_dig.O_LOD_REF_TRIM   	)$display($stime,"ns:\tLOD_REF_TRIM    pass");else $display($stime,"ns:\tLOD_REF_TRIM    fail");
	if(TSP_150_TRIM    	==tb_top.u_chicago_chip.u_chicago_dig.O_TSP_150_TRIM   	)$display($stime,"ns:\tTSP_150_TRIM    pass");else $display($stime,"ns:\tTSP_150_TRIM    fail");
	if(TSP_125_TRIM    	==tb_top.u_chicago_chip.u_chicago_dig.O_TSP_125_TRIM   	)$display($stime,"ns:\tTSP_125_TRIM    pass");else $display($stime,"ns:\tTSP_125_TRIM    fail");
	if(VPTAT_OUT_TRIM  	==tb_top.u_chicago_chip.u_chicago_dig.O_VPTAT_OUT_TRIM 	)$display($stime,"ns:\tVPTAT_OUT_TRIM  pass");else $display($stime,"ns:\tVPTAT_OUT_TRIM  fail");
	if(BGR_OUT_TRIM    	==tb_top.u_chicago_chip.u_chicago_dig.O_BGR_OUT_TRIM   	)$display($stime,"ns:\tBGR_OUT_TRIM    pass");else $display($stime,"ns:\tBGR_OUT_TRIM    fail");
	if(BGR_OUT_FE_TRIM 	==tb_top.u_chicago_chip.u_chicago_dig.O_BGR_OUT_FE_TRIM	)$display($stime,"ns:\tBGR_OUT_FE_TRIM pass");else $display($stime,"ns:\tBGR_OUT_FE_TRIM fail");
	if(RES             	==tb_top.u_chicago_chip.u_chicago_dig.O_RES            	)$display($stime,"ns:\tRES             pass");else $display($stime,"ns:\tRES             fail");
	if(I               	==tb_top.u_chicago_chip.u_chicago_dig.O_I              	)$display($stime,"ns:\tI               pass");else $display($stime,"ns:\tI               fail");
	if(DRV_IBIAS_TRIM  	==tb_top.u_chicago_chip.u_chicago_dig.O_DRV_IBIAS_TRIM 	)$display($stime,"ns:\tDRV_IBIAS_TRIM  pass");else $display($stime,"ns:\tDRV_IBIAS_TRIM  fail");
	if(RC_OSC_CAP_TRIM 	==tb_top.u_chicago_chip.u_chicago_dig.O_RC_OSC_CAP_TRIM )$display($stime,"ns:\tRC_OSC_CAP_TRIM pass");else $display($stime,"ns:\tRC_OSC_CAP_TRIM fail");
	if(RC_OSC_BIAS_TRIM ==tb_top.u_chicago_chip.u_chicago_dig.O_RC_OSC_BIAS_TRIM)$display($stime,"ns:\tRC_OSC_BIAS_TRIM pass");else $display($stime,"ns:\t RC_OSC_BIAS_TRIM fail");

	#4000000;
	#4000000;

	cmd_write(8'hce);
	$display("\t\t############\t RESET_CMD\t############");
	#6000000;
	#6000000;
	cmd_write(8'hD);//WAKEUP CMD
	$display("\t\t############\t WAKEUP_CMD\t############");
	#1000000;
`ifndef POST_SIM
	if(I_MAX           	==tb_top.u_chicago_chip.u_chicago_dig.u_RegBlk.i_max   	)$display($stime,"ns:\tI_MAX          pass");else $display($stime,"ns:\tI_MAX            fail");
`endif                                                                                                                                                   
	if(SEG_MODE			==tb_top.u_chicago_chip.u_chicago_dig.u_RegBlk.O_SEG_MODE)$display($stime,"ns:\tSEG_MODE	   pass");else $display($stime,"ns:\tSEG_MODE	     fail");
	if(CHG_EN			==tb_top.u_chicago_chip.u_chicago_dig.O_CHG_EN			)$display($stime,"ns:\tCHG_EN		   pass");else $display($stime,"ns:\tCHG_EN		     fail");
	if(DCHG_EN         	==tb_top.u_chicago_chip.u_chicago_dig.O_DCHG_EN        	)$display($stime,"ns:\tDCHG_EN         pass");else $display($stime,"ns:\tDCHG_EN         fail");
	if(GRID_MODE       	==tb_top.u_chicago_chip.u_chicago_dig.O_GRID_MODE      	)$display($stime,"ns:\tGRID_MODE       pass");else $display($stime,"ns:\tGRID_MODE       fail");
	if(LSD_REF_TRIM    	==tb_top.u_chicago_chip.u_chicago_dig.O_LSD_REF_TRIM   	)$display($stime,"ns:\tLSD_REF_TRIM    pass");else $display($stime,"ns:\tLSD_REF_TRIM    fail");
	if(LOD_REF_TRIM    	==tb_top.u_chicago_chip.u_chicago_dig.O_LOD_REF_TRIM   	)$display($stime,"ns:\tLOD_REF_TRIM    pass");else $display($stime,"ns:\tLOD_REF_TRIM    fail");
	if(TSP_150_TRIM    	==tb_top.u_chicago_chip.u_chicago_dig.O_TSP_150_TRIM   	)$display($stime,"ns:\tTSP_150_TRIM    pass");else $display($stime,"ns:\tTSP_150_TRIM    fail");
	if(TSP_125_TRIM    	==tb_top.u_chicago_chip.u_chicago_dig.O_TSP_125_TRIM   	)$display($stime,"ns:\tTSP_125_TRIM    pass");else $display($stime,"ns:\tTSP_125_TRIM    fail");
	if(VPTAT_OUT_TRIM  	==tb_top.u_chicago_chip.u_chicago_dig.O_VPTAT_OUT_TRIM 	)$display($stime,"ns:\tVPTAT_OUT_TRIM  pass");else $display($stime,"ns:\tVPTAT_OUT_TRIM  fail");
	if(BGR_OUT_TRIM    	==tb_top.u_chicago_chip.u_chicago_dig.O_BGR_OUT_TRIM   	)$display($stime,"ns:\tBGR_OUT_TRIM    pass");else $display($stime,"ns:\tBGR_OUT_TRIM    fail");
	if(BGR_OUT_FE_TRIM 	==tb_top.u_chicago_chip.u_chicago_dig.O_BGR_OUT_FE_TRIM	)$display($stime,"ns:\tBGR_OUT_FE_TRIM pass");else $display($stime,"ns:\tBGR_OUT_FE_TRIM fail");
	if(RES             	==tb_top.u_chicago_chip.u_chicago_dig.O_RES            	)$display($stime,"ns:\tRES             pass");else $display($stime,"ns:\tRES             fail");
	if(I               	==tb_top.u_chicago_chip.u_chicago_dig.O_I              	)$display($stime,"ns:\tI               pass");else $display($stime,"ns:\tI               fail");
	if(DRV_IBIAS_TRIM  	==tb_top.u_chicago_chip.u_chicago_dig.O_DRV_IBIAS_TRIM 	)$display($stime,"ns:\tDRV_IBIAS_TRIM  pass");else $display($stime,"ns:\tDRV_IBIAS_TRIM  fail");
	if(RC_OSC_CAP_TRIM 	==tb_top.u_chicago_chip.u_chicago_dig.O_RC_OSC_CAP_TRIM )$display($stime,"ns:\tRC_OSC_CAP_TRIM pass");else $display($stime,"ns:\tRC_OSC_CAP_TRIM fail");
	if(RC_OSC_BIAS_TRIM ==tb_top.u_chicago_chip.u_chicago_dig.O_RC_OSC_BIAS_TRIM)$display($stime,"ns:\tRC_OSC_BIAS_TRIM pass");else $display($stime,"ns:\t RC_OSC_BIAS_TRIM fail");

	#6000000;
	cmd_write(8'hce);
	$display("\t\t############\t RESET_CMD\t############");
		force tb_top.u_chicago_chip.u_chicago_dig.u_pmu.I_EF_DATA[63] = 1;
		force tb_top.u_chicago_chip.u_chicago_dig.u_pmu.I_EF_DATA[62] = 1;
		force tb_top.u_chicago_chip.u_chicago_dig.u_pmu.I_EF_DATA[61] = 1;
		force tb_top.u_chicago_chip.u_chicago_dig.u_pmu.I_EF_DATA[60] = 1;
	#6500000;
	//release tb_top.u_chicago_chip.u_chicago_dig.u_pmu.I_EF_DATA[63];
	//release tb_top.u_chicago_chip.u_chicago_dig.u_pmu.I_EF_DATA[62];
	//release tb_top.u_chicago_chip.u_chicago_dig.u_pmu.I_EF_DATA[61];
	//release tb_top.u_chicago_chip.u_chicago_dig.u_pmu.I_EF_DATA[60];
	#6000000;
	reg_read_burst(16'h423, 16'd1);	
	#6000000;


	$finish;

`elsif READ_FLAG_TEST 
	#5000000;

	//changing IF_MODE[2]
	//reg_write_1byte(16'h4fd, 8'd9);

	//changing spi read @fall-edge
	`ifdef HOST_SPI_READ_FEDGE
		reg_write_1byte(16'h4fd, 8'd5);
		//reg_write_1byte(16'h4fd, 8'hd);
	`endif

	//lv0_read;
	creg_write(8'hff, 8'h4, 8'h8, 8'hc4);

	//command packet error
	spi_wdata = 8'h0e;
	spi_bwrite(0, 8'h5A);
	spi_bwrite(0, 8'hFF);
	spi_bwrite(0, spi_wdata[7:0]);
	spi_wdata = 8'h5A + 8'hFF + spi_wdata[7:0] + 1;
	spi_bwrite(0, spi_wdata[7:0]);

	lv0_read;
	if (spi_brdata[0] != 8'b1100_0100 || 
	    spi_brdata[1] != 8'b0010_0000) begin
		$display("Error: wrong read flag: cmd error must be read");
		$finish;
	end

	//reg. packet error
	cmd_write(8'h1);

	spi_bwrite(0, 8'hff);
	spi_bwrite(0, 8'h4);
	spi_bwrite(0, 8'h8);
	spi_bwrite(0, 8'hc4);
	spi_wdata = 8'hff + 8'h4 + 8'h8 + 8'hc4 + 1;
	spi_bwrite(0, spi_wdata[7:0]);

	lv0_read;
	if (spi_brdata[0] != 8'b1100_0100 || 
	    spi_brdata[1] != 8'b0010_0011) begin
		$display("Error: wrong read flag: reg error/lerror must be read");
		$finish;
	end

	creg_write(8'hff, 8'h4, 8'h8, 8'hc4);
	lv0_read;
	if (spi_brdata[0] != 8'b1100_0100 || 
	    spi_brdata[1] != 8'b0010_0010) begin
		$display("Error: wrong read flag: reg error must be read");
		$finish;
	end

	//disp. packet error
	cmd_write(8'h2);

	spi_wdata = 8'd0;
	repeat(64) begin
		spi_bwrite(0, 8'h5a);
		spi_wdata = spi_wdata + 8'h5a;
	end
	spi_wdata = spi_wdata + 1;
	spi_bwrite(0, spi_wdata[7:0]);

	lv0_read;

	if (spi_brdata[0] != 8'b1100_0100 || 
	    spi_brdata[1] != 8'b0010_1110) begin
		$display("Error: wrong read flag: disp error/lerror must be read");
		$finish;
	end

	disp_write_idat(9'd64, 8'hA5);
	lv0_read;

	if (spi_brdata[0] != 8'b1100_0100 || 
	    spi_brdata[1] != 8'b0010_1010) begin
		$display("Error: wrong read flag: disp error must be read");
		$finish;
	end

	//disable read flag bit
	creg_write(8'h3f, 8'h4, 8'h8, 8'h44);
	lv0_read;
	if (spi_brdata[0] != 8'hff || 
	    spi_brdata[1] != 8'hff ) begin
		$display("Error: wrong read flag: pull-up value must be read");
		$finish;
	end

	#100000;

	$finish;
`elsif CMD_TEST 
	#5000000;

//	for (ii=0; ii<320; ii=ii+1)
//		spi_bwdata[ii] = ii+1;
//	reg_write_burst_abn(16'h0, 320);
//	reg_read_burst(16'h0, 320);
//	$display("!!");
//	reg_write_burst_abn(16'h200, 320);
//	reg_read_burst(16'h200, 320);
//	reg_write_burst_abn(16'h400, 320);
//	reg_write_burst_abn(16'h400, 4);
//	$finish;

	//changing cs0, cs1
	//CS0 = 1;
	//CS1 = 0;

	//wrong cs0, cs1 
	spi_wdata = 8'h1;
	spi_bwrite(0, 8'h5A);
	spi_bwrite(0, 8'hFF);
	spi_bwrite(0, {spi_wdata[7:6], 1'b1, 1'b1, spi_wdata[3:0]});
	spi_bwrite(0, 8'h8A);

	//unknown command
	cmd_write(8'h3);
	cmd_write(8'hc);

	//known lv0 commands check the relevant signal generation 
	//cmd_write(8'h7);
	cmd_write(8'h4);
	cmd_write(8'h4);
	cmd_write(8'h8);
	cmd_write(8'hB);
	cmd_write(8'hD);
	cmd_write(8'hE);

	//lock lv3 and lv3 commands
	reg_write_1byte(16'h4fd, 8'h0); 
	cmd_write(8'hce);
	reg_write_1byte(16'h0, 8'h1); 
	reg_read_burst(16'h0, 16'd1);	

	//known lv0 commands
	cmd_write(8'h8);
	cmd_write(8'hB);
	cmd_write(8'hD);
	cmd_write(8'hE);

	//unlock lv3 and lv3 commands
	reg_write_1byte(16'h4fd, 8'h1); 
	reg_read_burst(16'h0, 16'd1);	
	reg_write_1byte(16'h0, 8'h1); 
	reg_read_burst(16'h0, 16'd1);	
	$finish;
`elsif SLEEP_TEST 
	#10_000_000;
	creg_write(8'h3f, 8'h3C, 8'h40, 8'hc4);   //G_N = 9
	cmd_write(8'hE);//SLEEP CMD
	$display("\t\t############\t SLEEP_CMD\t############");
	#1_000_000;
	cmd_write(8'hD);//WAKEUP CMD
	$display("\t\t############\t WAKEUP_CMD\t############");
	#100_000;
	creg_write(8'h3f, 8'h3C, 8'h40, 8'h04);   //G_N = 9
	disp_write_idat(9'd288, 8'hFF);
	cmd_write(8'h04); // manual disp. update
	creg_write(8'h3f, 8'h3C, 8'h40, 8'h04);   //G_N = 9// SLEEP==0
	creg_write(8'h3f, 8'h3C, 8'h48, 8'h04);   //display on
	$display("\t\t############\t DON == 1 \t############");
	#1_000_000;
	$display("\t0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); 
	#3_000_000;

	reg_write_1byte(16'h403, 8'h40);//SLEEP MODE EN 
	$display("\t\t############\t SLEEP_MODE ==1\t############");
	#100_000;
	cmd_write(8'hE);//SLEEP CMD
	$display("\t\t############\t SLEEP_CMD\t############");
	#2_000_000;
	disp_write_idat(9'd288, 8'hAA);
	$display("\t\t############\t DISP DATA SRAM WRITE \t############");
	cmd_write(8'h04); // manual disp. update
	$display("\t\t############\t Manual DISP update \t############");
	#2_000_000;
	#100_000;
	cmd_write(8'hD);//WAKEUP CMD
	$display("\t\t############\t WAKEUP_CMD\t############");
	#1_000_000;
	$display("\t 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); 
	#5_000_000;
	cmd_write(8'hE);//SLEEP CMD
	$display("\t\t############\t SLEEP_CMD\t############");
	#5_000_000;
	cmd_write(8'hD);//WAKEUP CMD
	$display("\t\t############\t WAKEUP_CMD\t############");
	#1_000_000;
	$display("\t0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); 
	#5_000_000;
	cmd_write(8'hE);//SLEEP CMD
	$display("\t\t############\t SLEEP_CMD\t############");
	#5_000_000;
	creg_write(8'h3f, 8'h3D, 8'h48, 8'hc4);   //G_N = 9 UP=1
	$display("\t\t############\t Auto DISP update \t############");
	disp_write_idat(9'd288, 8'h22);
	#1_000_000;
	cmd_write(8'hD);$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
	
	#1_000_000;
	$display("\t0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); 

	cmd_write(8'hce);	$display("\t\t############\t RESET_CMD\t############");
	#10_000_000;
	creg_write(8'h3f, 8'h00, 8'h40, 8'hc4);   //G_N = 9 UP=1
	cmd_write(8'hE);$display("\t\t############\t SLEEP_CMD\t############");//SLEEP CMD
	#1_000_000;
	cmd_write(8'hce);	$display("\t\t############\t RESET_CMD\t############");
	//cmd_write(8'hD);$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
	#10_000_000;
	#1_000_000;
	spi_brdata[0]	=0;
	spi_brdata[0][2]   = 1'b0;	//10-GRID
	spi_brdata[0][1:0] = 2'b11; //32-SEG
	$display("10-GRID, 32-SEG MODE ..");
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h00, 8'h40, 8'hc4);   //G_N = 9 UP=1
	cmd_write(8'hE);$display("\t\t############\t SLEEP_CMD\t############");//SLEEP CMD
	#5_000_000;
	cmd_write(8'hD);$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
	creg_write(8'h3f, 8'h00, 8'h40, 8'hc4);   //G_N = 9 UP=1
	#1_000_000;
	for (kk=0; kk<11; kk=kk+1) begin
		r_g_n = kk;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h48, 8'hc4);   
		disp_write_idat(32*(1+kk), 8'hF0+(kk+1));
		cmd_write(8'h04); // manual disp. update
		#3_000_000;
		$display("\t0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); 
	
		#2_000_000;
	end
		cmd_write(8'hE);$display("\t\t############\t SLEEP_CMD\t############");//SLEEP CMD
		#5_000_000;
		cmd_write(8'hD);$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
	#1_000_000;
	spi_brdata[0]	=0;
	spi_brdata[0][2]   = 1'b1;	//9-GRID
	spi_brdata[0][1:0] = 2'b11; //32-SEG
	$display("9-GRID, 32-SEG MODE ..");
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h00, 8'h40, 8'hc4);   //G_N = 9 UP=1
	cmd_write(8'hE);$display("\t\t############\t SLEEP_CMD\t############");//SLEEP CMD
	#5_000_000;
	cmd_write(8'hD);$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
	creg_write(8'h3f, 8'h00, 8'h40, 8'hc4);   //G_N = 9 UP=1
	#1_000_000;
	for (kk=0; kk<11; kk=kk+1) begin
		r_g_n = kk;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h48, 8'hc4);   
		disp_write_idat(32*(1+kk), 8'hF0+(kk+1));
		cmd_write(8'h04); // manual disp. update
		#3_000_000;
		$display("\t0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); 

		#2_000_000;
	end

		#1_000_000;
		reg_write_1byte(16'h4FD, 8'h20); 
		cmd_write(8'h08); // 
	#5_000_000;
	$finish;
`elsif PROTECTION_TEST 
	$display("PROTECTION_TEST ");
	#6_000_000;
	spi_brdata[0]   = 8'd0;
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b11;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h0, 8'hc4);   //G_N = 8
	disp_write_idat(9*32, 8'hFF);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h8, 8'hc4);   //DON = 1
	#1_000_000;
	reg_write_1byte(16'h404, 8'hF3); //PEN_MODE = 1 DRV_EN =1 LOD_EN=1 LSD_EN=1TSP_EN=1 BGR_EN=1OSC_EN=1 
	#1_000_000;
	reg_write_1byte(16'h404, 8'hFE); //PEN_MODE = 1 DRV_EN =1 LOD_EN=1 LSD_EN=1TSP_EN=1 BGR_EN=1OSC_EN=1 
	#1_000_000;
	reg_write_1byte(16'h404, 8'h00); //PEN_MODE = 1 DRV_EN =1 LOD_EN=1 LSD_EN=1TSP_EN=1 BGR_EN=1OSC_EN=1 
	
	
	#10_000_000;
	$finish;
`elsif GRID_SEG_IF_TEST
	#5000000;
	//9-Grid/32-Seg	
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b11;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h0, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h8, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h0, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,32);
	
	//9-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b11;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h10, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h18, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h10, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,32);
	//------------------------------------------------------
	
	//9-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b11;
	reg_write_1byte(16'h408, spi_brdata[0]);
	//reg_write_1byte(16'h402, 8'hff);
	creg_write(8'h3f, 8'h20, 8'h20, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h28, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h20, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,32);

	//9-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b11;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h30, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h38, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h30, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,32);
	
	//10-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h0, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h8, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h0, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,32);

	//10-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h10, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h18, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h10, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,32);
	
	//10-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h20, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h28, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h20, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,32);

	//10-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h30, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h38, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h30, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,32);

	//9-Grid/24-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b10;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h0, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 24);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h8, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h0, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,24);
	
	//9-Grid/24-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b10;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h10, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 24);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h18, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h10, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,24);

	//9-Grid/24-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b10;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h20, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 24);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h28, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h20, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,24);

	//9-Grid/24-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b10;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h30, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 24);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h38, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h30, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,24);

	//10-Grid/24-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b0;
	spi_brdata[0][1:0] = 2'b10;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h0, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 24);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h8, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h0, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,24);
	
	//10-Grid/24-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b0;
	spi_brdata[0][1:0] = 2'b10;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h10, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 24);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h18, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h10, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,24);

	//10-Grid/24-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b0;
	spi_brdata[0][1:0] = 2'b10;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h20, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 24);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h28, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h20, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,24);

	//10-Grid/24-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b0;
	spi_brdata[0][1:0] = 2'b10;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h30, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 24);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h38, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h30, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,24);

	//9-Grid/16-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b01;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h0, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 16);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h8, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h0, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,16);

	//9-Grid/16-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b01;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h10, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 16);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h18, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h10, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,16);

	//9-Grid/16-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b01;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h20, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 16);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h28, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h20, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,16);

	//9-Grid/16-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b01;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h20, 8'h30, 8'hc4);   //G_N = 8
	test_seg_grid_if(9, 16);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h38, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h20, 8'h30, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,16);

	//10-Grid/16-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b0;
	spi_brdata[0][1:0] = 2'b01;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h0, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 16);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h8, 8'hc4);   //DON = 1
	#10000000;
	creg_write(8'h3f, 8'h24, 8'h8, 8'hc4);   //DON = 0
	#10000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,16);

	//10-Grid/16-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b0;
	spi_brdata[0][1:0] = 2'b01;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h10, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 16);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h18, 8'hc4);   //DON = 1
	#10000000;
	creg_write(8'h3f, 8'h24, 8'h18, 8'hc4);   //DON = 0
	#10000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,16);

	//10-Grid/16-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b0;
	spi_brdata[0][1:0] = 2'b01;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h20, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 16);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h28, 8'hc4);   //DON = 1
	#10000000;
	creg_write(8'h3f, 8'h24, 8'h28, 8'hc4);   //DON = 0
	#10000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,16);

	//10-Grid/16-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b0;
	spi_brdata[0][1:0] = 2'b01;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h30, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 16);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h38, 8'hc4);   //DON = 1
	#10000000;
	creg_write(8'h3f, 8'h24, 8'h38, 8'hc4);   //DON = 0
	#10000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,16);

	$finish;

`elsif PEN_MODE 
	#10_000_000;
	reg_write_1byte(16'h404, 8'h82); //PEN_MODE = 1// OSC_EN=1 
	#2000000;
	reg_write_1byte(16'h404, 8'h86); //PEN_MODE = 1// BGR_EN=1 OSC_EN=1 
	#2000000;
	reg_write_1byte(16'h404, 8'h8E); //PEN_MODE = 1// TSP_EN=1 BGR_EN=1 OSC_EN=1
	#2000000;
	reg_write_1byte(16'h404, 8'h02); //PEN_MODE = 0// OSC_EN=1 
	
	#2000000;
	reg_write_1byte(16'h404, 8'h82); //PEN_MODE = 0// OSC_EN=1 
	reg_write_1byte(16'h40E, 8'h1); //OSD_START
	#10000;
	reg_write_1byte(16'h404, 8'hA2); //PEN_MODE = 0// LSD_EN=1 OSC_EN=1 
	#10000;
	reg_write_1byte(16'h404, 8'hB2); //PEN_MODE = 0// LOD_EN=1 OSC_EN=1 
	#2000000;

	creg_write(8'h3f, 8'h3C, 8'h0, 8'hc4);   //G_N = 9
	disp_write_idat(9'd288, 8'h88);
	$display("\t\t############\t DISP DATA SRAM WRITE \t############");
	cmd_write(8'h04); // manual disp. update
	$display("\t\t############\t Manual DISP update \t############");
	#2000000;
	creg_write(8'h3f, 8'h3C, 8'h8, 8'h04);   //display on
	#2000000;
	creg_write(8'h3f, 8'h3C, 8'h0, 8'h04);   //display off
	#2000000;
	reg_write_1byte(16'h404, 8'hc2); //PEN_MODE = 1 DRV_EN =1 OSC_EN=1 
	creg_write(8'h3f, 8'h3C, 8'h8, 8'h04);   //display on
	#2000000;
	creg_write(8'h3f, 8'h3C, 8'h0, 8'h04);   //display off
	#2000000;
	reg_write_1byte(16'h404, 8'h82); //PEN_MODE = 1 OSC_EN=1 
	creg_write(8'h3f, 8'h3C, 8'h8, 8'h04);   //display on
	reg_write_1byte(16'h404, 8'hc2); //PEN_MODE = 1 DRV_EN =1 OSC_EN=1 
	#1_000_000;
	reg_read_burst(16'h4fe, 16'd2);	
	#1_000_000;
	creg_write(8'h3f, 8'ha4, 8'h0, 8'hc4);   //G_N = 9, OSC = 1
	sck_insert(32'd50000);
	reg_write_1byte(16'h40D,8'h04 );
	sck_insert(32'd50000);
	#1_000_000;
	$finish;

`elsif ERR_CASE0
	#5000000;
	//9-Grid/32-Seg
	creg_write(8'h3f, 8'h20, 8'h0, 8'hc4);   //G_N = 8
	//disp_write_idat_fail(9*32, 8'hFF);
	//reg_read_burst(16'h0, 9*32);
	test_seg_grid_if(9, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h20, 8'h8, 8'hc4);   //DON = 1
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",9,32);
	
	//10-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h0, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h8, 8'hc4);   //DON = 1
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,32);
	$finish;

`elsif OSC_1_TEST
	#5000000;

	//10-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'ha4, 8'h0, 8'hc4);   //G_N = 9, OSC = 1
	test_seg_grid_if(10, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'ha4, 8'h8, 8'hc4);   //DON = 1

	//delays inserted through the following task
	sck_insert(32'd50000);

	$finish;

`elsif GS_DTEST
	#5000000;

	//9-GRID, 32-SEG mode
	for (kk=0; kk<9; kk=kk+1) begin
		r_g_n = kk;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		test_seg_grid_if(kk+1, 32);
		cmd_write(8'h4);
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h8, 8'hc4);   
		#5000000;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		#5000000;
	end
	$display("9-GRID, 32-SEG MODE PASSED..");

	//10-Grid, 32-SEG mode
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	for (kk=0; kk<10; kk=kk+1) begin
		r_g_n = kk;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		test_seg_grid_if(kk+1, 32);
		cmd_write(8'h4);
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h8, 8'hc4);   
		#5000000;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		#5000000;
	end
	$display("10-GRID, 32-SEG MODE PASSED..");

	//9-Grid/24-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b10;
	reg_write_1byte(16'h408, spi_brdata[0]);
	for (kk=0; kk<9; kk=kk+1) begin
		r_g_n = kk;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		test_seg_grid_if(kk+1, 24);
		cmd_write(8'h4);
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h8, 8'hc4);   
		#5000000;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		#5000000;
	end
	$display("9-GRID, 24-SEG MODE PASSED..");

	//10-Grid/24-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b0;
	spi_brdata[0][1:0] = 2'b10;
	reg_write_1byte(16'h408, spi_brdata[0]);
	for (kk=0; kk<10; kk=kk+1) begin
		r_g_n = kk;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		test_seg_grid_if(kk+1, 24);
		cmd_write(8'h4);
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h8, 8'hc4);   
		#5000000;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		#5000000;
	end
	$display("10-GRID, 24-SEG MODE PASSED..");

	//9-Grid/16-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b1;
	spi_brdata[0][1:0] = 2'b01;
	reg_write_1byte(16'h408, spi_brdata[0]);
	for (kk=0; kk<9; kk=kk+1) begin
		r_g_n = kk;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		test_seg_grid_if(kk+1, 16);
		cmd_write(8'h4);
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h8, 8'hc4);   
		#5000000;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		#5000000;
	end
	$display("9-GRID, 16-SEG MODE PASSED..");

	//10-Grid/16-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2]   = 1'b0;
	spi_brdata[0][1:0] = 2'b01;
	reg_write_1byte(16'h408, spi_brdata[0]);
	for (kk=0; kk<10; kk=kk+1) begin
		r_g_n = kk;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		test_seg_grid_if(kk+1, 16);
		cmd_write(8'h4);
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h8, 8'hc4);   
		#5000000;
		creg_write(8'h3f, {2'd0, r_g_n[3:0], 2'd0}, 8'h0, 8'hc4);   
		#5000000;
	end
	$display("10-GRID, 16-SEG MODE PASSED..");
	$finish;
`elsif DT_TEST
	#10000000;
	//10-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h00, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h08, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h00, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,32);
	//10-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h00, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h09, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h00, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,32);
	//10-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h00, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h0a, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h00, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,32);
	//10-Grid/32-Seg
	reg_read_burst(16'h408, 16'd1);
	spi_brdata[0][2] = 1'b0;
	reg_write_1byte(16'h408, spi_brdata[0]);
	creg_write(8'h3f, 8'h24, 8'h00, 8'hc4);   //G_N = 9
	test_seg_grid_if(10, 32);
	cmd_write(8'h4);
	creg_write(8'h3f, 8'h24, 8'h0b, 8'hc4);   //DON = 1
	#5000000;
	creg_write(8'h3f, 8'h24, 8'h00, 8'hc4);   //DON = 0
	#5000000;
	$display("%2d-GRID, %2d-SEG test successfully completed..",10,32);
	$finish;
`elsif DISP_TM 
	#6_000_000	
	reg_write_1byte(16'h40D, 8'h01);
	#1_000_000	
	reg_write_1byte(16'h40D, 8'h00);
	#1_000_000	
	reg_write_1byte(16'h40D, 8'h02);
	#1_000_000	
	reg_write_1byte(16'h40D, 8'h00);

	reg_write_1byte(16'h401, 8'h24);
	reg_write_1byte(16'h408, 8'h03);
	reg_write_1byte(16'h4F0, 8'h01);
	#5040000;
	reg_write_1byte(16'h4F0, 8'h02);
	#5040000;
	reg_write_1byte(16'h4F0, 8'h03);
	#5040000;
	reg_write_1byte(16'h4F0, 8'h04);
	#5040000;
	reg_write_1byte(16'h4F0, 8'h05);
	#5040000;
	reg_write_1byte(16'h4F0, 8'h06);
	#5040000;
	reg_write_1byte(16'h4F0, 8'h07);
	#5040000;
	reg_write_1byte(16'h4F0, 8'h00);
	#1000000;
	cmd_write(8'hce);	$display("\t\t############\t RESET_CMD\t############");
	#10_000_000;	

	spi_brdata[0]= 8'b0;
	spi_brdata[0][2]   = 1'b0;	//10-GRID
	spi_brdata[0][1:0] = 2'b11; //32-SEG
	$display("10-GRID, 32-SEG MODE ..");
	reg_write_1byte(16'h408, spi_brdata[0]);
	lv0_wreg[0]	={2'b00,6'h3f};	// I; 
	lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
	lv0_wreg[2]	={1'b0,1'b0,2'b00, 1'b0 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT}; DON ==0 
	lv0_wreg[3]	={1'b1,1'b1,4'b0000,1'b0,1'b0};		// {RD_EN,SLEEP/4'b0000,TP2,1'b0}; 
	creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
	disp_write_idat((10*32), 8'hff);	
	$display("\t\t############\t DISP DATA SRAM WRITE \t############");
	cmd_write(8'h04); // manual disp. update
	$display("\t\t############\t Manual DISP update \t############");
	lv0_wreg[2]	={1'b0,1'b0,2'b00, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =1 
	creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
	#5_000_000	
	lv0_wreg[2]	={1'b0,1'b0,2'b01, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =1 
	creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
	#5_000_000	
	lv0_wreg[2]	={1'b0,1'b0,2'b10, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =1 
	creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
	#5_000_000	
	lv0_wreg[2]	={1'b0,1'b0,2'b11, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =1 
	creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 

	#6_000_000	
	$finish;
`elsif COSIM_TEST 
	#2_000_000;
	`ifdef COSIM5
	#7_000_000;
		cmd_write(8'hD);	$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
		spi_brdata[0][2]   = 1'b0;	//10-GRID
		spi_brdata[0][1:0] = 2'b11; //32-SEG
		reg_write_1byte(16'h408, spi_brdata[0]);
		#1000000;
		reg_write_1byte(16'h404, 8'h80); //PEN_MODE = 1
		#1000000;
		reg_write_1byte(16'h404, 8'h82); //PEN_MODE = 1 OSC_EN=1 
		#1000000;
		reg_write_1byte(16'h404, 8'h86); //PEN_MODE = 1 BGR_EN=1 OSC_EN=1 
		#1000000;
		reg_write_1byte(16'h404, 8'h8E); //PEN_MODE = 1 TSP_EN=1 BGR_EN=1 OSC_EN=1
		#1000000;
		reg_write_1byte(16'h404, 8'h9E); //PEN_MODE = 1 LSD_EN=1 TSP_EN=1 BGR_EN=1OSC_EN=1 
		#1000000;
		reg_write_1byte(16'h404, 8'hBE); //PEN_MODE = 1 LOD_EN=1 LSD_EN=1TSP_EN=1 BGR_EN=1OSC_EN=1 
		#1000000;
		reg_write_1byte(16'h404, 8'hFE); //PEN_MODE = 1 DRV_EN =1 LOD_EN=1 LSD_EN=1TSP_EN=1 BGR_EN=1OSC_EN=1 
		#1000000;
		reg_write_1byte(16'h40C, 8'h02); // ANA_TEST_SEL
		reg_write_1byte(16'h40D, 8'h08); // ANA_TEST_EN 
		#1000000;
		reg_write_1byte(16'h40C, 8'h01); // ANA_TEST_SEL
		#1000000;
		reg_write_1byte(16'h40C, 8'h02); // ANA_TEST_SEL
		#1000000;
		reg_write_1byte(16'h40C, 8'h04); // ANA_TEST_SEL
		#1000000;
		reg_write_1byte(16'h40C, 8'h08); // ANA_TEST_SEL
		#1000000;
		reg_write_1byte(16'h40C, 8'h10); // ANA_TEST_SEL
		#1000000;
		reg_write_1byte(16'h40C, 8'h20); // ANA_TEST_SEL
		#1000000;
		reg_write_1byte(16'h40C, 8'h40); // ANA_TEST_SEL
		#1000000;
		reg_write_1byte(16'h40C, 8'h80); // ANA_TEST_SEL
		#1000000;
		reg_write_1byte(16'h40D, 8'h0B); // ANA_TEST_EN//girdtest/segtest 

		#1_000_000;
	`elsif COSIM7 
		#2_000_000;
		$display($stime, " ns #### SCAN TEST ###");
		reg_write_1byte(16'h4F2, 8'h07);	#1_000_000;
		test_mode = 1;
		#500_000;
	`elsif COSIM8 
		#7_000_000;
		$display($stime, " ns #### LOD LSD TEST ###");
		cmd_write(8'hD);	$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
		spi_brdata[0]= 8'b0;
		//spi_brdata[0][2]   = 1'b1;	//9-GRID
		spi_brdata[0][2]   = 1'b0;	//10-GRID
		spi_brdata[0][1:0] = 2'b11; //32-SEG
		//spi_brdata[0][1:0] = 2'b10; //24-SEG
		//spi_brdata[0][1:0] = 2'b01; //16-SEG
		reg_write_1byte(16'h408, spi_brdata[0]);
		reg_write_1byte(16'h400, 8'hff); //O_I=max
		reg_write_1byte(16'h40E, 8'h1); //OSD_START
		#1_000_000;
		`ifndef VCDDUMP 
		$display("\t\t############\t UPDATE REMAP READ \t############");
		reg_read_burst(16'h423, 16'd1);	
		$display("\t\t############\t LOSD DATE READ \t############");
		reg_read_burst(16'h0, 10*32); //read full data
		`endif
		#1_000_000;

	`else
		#1_000_000;
	//	spi_brdata[0]= 8'b0;
		`ifdef FUSING
			`ifdef COSIM9
				RC_OSC_BIAS_TRIM	=	5'h00;
				RC_OSC_CAP_TRIM 	=	2'h0;
				DRV_IBIAS_TRIM  	=	5'h10;
				I               	=	6'h3f;
				RES             	=	1'h1;
				BGR_OUT_FE_TRIM 	=	5'h00;
				BGR_OUT_TRIM    	=	5'h10;
				VPTAT_OUT_TRIM  	=	5'h00;
				TSP_125_TRIM    	=	5'h10;
				TSP_150_TRIM    	=	5'h10;
				LOD_REF_TRIM    	=	3'h4;
				LSD_REF_TRIM    	=	3'h4;
				GRID_MODE       	=	1'h0;
				I_MAX             	=	4'hf;
				DCHG_EN         	=	1'h1;
				CHG_EN          	=	1'h1;
				SEG_MODE        	=	2'h3;
				PGM_FLAG    	  	=	1'h1;
			`elsif COSIMSS
				RC_OSC_BIAS_TRIM	=	5'h14;
				RC_OSC_CAP_TRIM 	=	2'h0;
				DRV_IBIAS_TRIM  	=	5'h12;
				I               	=	6'h3f;
				RES             	=	1'h1;
				BGR_OUT_FE_TRIM 	=	5'h00;
				BGR_OUT_TRIM    	=	5'h10;
				VPTAT_OUT_TRIM  	=	5'h1f;
				TSP_125_TRIM    	=	5'h12;
				TSP_150_TRIM    	=	5'h12;
				LOD_REF_TRIM    	=	3'h4;
				LSD_REF_TRIM    	=	3'h4;
				GRID_MODE       	=	1'h0;
				I_MAX             	=	4'hf;
				DCHG_EN         	=	1'h1;
				CHG_EN          	=	1'h1;
				SEG_MODE        	=	2'h3;
				PGM_FLAG    	  	=	1'h1;
			`elsif COSIMFF
				RC_OSC_BIAS_TRIM	=	5'h09;
				RC_OSC_CAP_TRIM 	=	2'h0;
				DRV_IBIAS_TRIM  	=	5'h0E;
				I               	=	6'h3f;
				RES             	=	1'h1;
				BGR_OUT_FE_TRIM 	=	5'h00;
				BGR_OUT_TRIM    	=	5'h10;
				VPTAT_OUT_TRIM  	=	5'h01;
				TSP_125_TRIM    	=	5'h0e;
				TSP_150_TRIM    	=	5'h0e;
				LOD_REF_TRIM    	=	3'h4;
				LSD_REF_TRIM    	=	3'h4;
				GRID_MODE       	=	1'h0;
				I_MAX             	=	4'hf;
				DCHG_EN         	=	1'h1;
				CHG_EN          	=	1'h1;
				SEG_MODE        	=	2'h3;
				PGM_FLAG    	  	=	1'h1;
			`endif
			#1; 
			ef_data[59:0] = {
			PGM_FLAG			,
			SEG_MODE			,
			CHG_EN				,
			DCHG_EN         	,
			I_MAX             	,
			GRID_MODE       	,
			LSD_REF_TRIM    	,
			LOD_REF_TRIM    	,
			TSP_150_TRIM    	,
			TSP_125_TRIM    	,
			VPTAT_OUT_TRIM  	,
			BGR_OUT_TRIM    	,
			BGR_OUT_FE_TRIM 	,
			RES             	,
			I               	,
			DRV_IBIAS_TRIM  	,
			RC_OSC_CAP_TRIM 	,
			RC_OSC_BIAS_TRIM	};
			#1;
			ef_data[63:60] 	=	crcOut;
			#1;
			reg_write_1byte(16'h410, ef_data[7:0]);
			reg_write_1byte(16'h411, ef_data[15:08]);
			reg_write_1byte(16'h412, ef_data[23:16]);
			reg_write_1byte(16'h413, ef_data[31:24]);
			reg_write_1byte(16'h414, ef_data[39:32]);
			reg_write_1byte(16'h415, ef_data[47:40]);
			reg_write_1byte(16'h416, ef_data[55:48]);
			reg_write_1byte(16'h417, ef_data[63:56]);
		
			reg_write_1byte(16'h422, {/*EF_PASSCODE*/8'h38} );
			reg_write_1byte(16'h420, {6'b000000,/*EF_CMD_PGM*/1'd1,/*EF_CMD_READ*/1'd0});#2000_000;
			cmd_write(8'hce);
			$display("\t\t############\t RESET_CMD\t############");
			#6000000;
			#6000000;
		`endif
		reg_read_burst(16'h408, 16'd1);
		`ifdef COSIM1
			spi_brdata[0][2]   = 1'b1;	//9-GRID
			spi_brdata[0][1:0] = 2'b11; //32-SEG
			$display("9-GRID, 32-SEG MODE ..");
		`elsif COSIM2
			spi_brdata[0][2]   = 1'b1;	//9-GRID
			spi_brdata[0][1:0] = 2'b10; //24-SEG
			$display("9-GRID, 24-SEG MODE ..");
		`elsif COSIM3
			spi_brdata[0][2]   = 1'b1;	//9-GRID
			spi_brdata[0][1:0] = 2'b01; //16-SEG
			$display("9-GRID, 16-SEG MODE ..");
		`elsif COSIM4
//			cmd_write(8'hD);	$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
			spi_brdata[0][2]   = 1'b0;	//10-GRID
			spi_brdata[0][1:0] = 2'b11; //32-SEG
			$display("10-GRID, 32-SEG MODE ..");
		`elsif COSIM9
//			cmd_write(8'hD);	$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
			spi_brdata[0][2]   = 1'b0;	//10-GRID
			spi_brdata[0][1:0] = 2'b11; //32-SEG
			$display("10-GRID, 32-SEG MODE & LIMIT..");
		`elsif COSIM10
//			cmd_write(8'hD);	$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
			spi_brdata[0][2]   = 1'b0;	//10-GRID
			spi_brdata[0][1:0] = 2'b11; //32-SEG
			$display("10-GRID, 32-SEG MODE & LIMIT..");
		`elsif COSIM11
//			cmd_write(8'hD);	$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
			spi_brdata[0][2]   = 1'b0;	//10-GRID
			spi_brdata[0][1:0] = 2'b10; //24-SEG
			$display("10-GRID, 24-SEG MODE & LIMIT..");
		`elsif COSIM12
//			cmd_write(8'hD);	$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
			spi_brdata[0][2]   = 1'b0;	//10-GRID
			spi_brdata[0][1:0] = 2'b01; //16-SEG
			$display("10-GRID, 16-SEG MODE & LIMIT..");
		`elsif COSIMSS
//			cmd_write(8'hD);	$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
			spi_brdata[0][2]   = 1'b0;	//10-GRID
			spi_brdata[0][1:0] = 2'b11; //32-SEG
			$display("10-GRID, 32-SEG MODE & LIMIT..");
		`elsif COSIMFF
//			cmd_write(8'hD);	$display("\t\t############\t WAKEUP_CMD\t############");//WAKEUP CMD
			spi_brdata[0][2]   = 1'b0;	//10-GRID
			spi_brdata[0][1:0] = 2'b11; //32-SEG
			$display("10-GRID, 32-SEG MODE & LIMIT..");
		`endif
		reg_write_1byte(16'h408, spi_brdata[0]);
		lv0_wreg[0]	={2'b00,6'h3f};	// I; 
		`ifdef COSIM4
		lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
		`elsif COSIM9
		lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
		`elsif COSIM10
		lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
		`elsif COSIM11
		lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
		`elsif COSIM12
		lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
		`elsif COSIM5
		lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
		`elsif COSIM8
		lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
		`elsif COSIMSS
		lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
		`elsif COSIMFF
		lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
		`else
		lv0_wreg[1]	={1'b0,1'b0,4'b1000,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
		`endif

		`ifdef COSIMSS
		lv0_wreg[2]	={1'b0,1'b1,2'b00, 1'b0 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT}; DON ==0 
		`elsif COSIMFF
		lv0_wreg[2]	={1'b0,1'b1,2'b00, 1'b0 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT}; DON ==0 
		`elsif COSIM9
		lv0_wreg[2]	={1'b0,1'b1,2'b00, 1'b0 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT}; DON ==0 
		`else
		lv0_wreg[2]	={1'b0,1'b0,2'b00, 1'b0 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT}; DON ==0 
		`endif

		lv0_wreg[3]	={1'b1,1'b1,4'b0000,1'b0,1'b0};		// {RD_EN,SLEEP/4'b0000,TP2,1'b0}; 
		creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
		`ifdef COSIM1
			//disp_write_idat((9*32), 8'h80);	
			cmd_write(8'h2);
			cksum = 8'd0;
			for (ii=0; ii<9; ii=ii+1) begin
				for (jj=0; jj<32; jj=jj+1) begin
					spi_bwrite(0, (50 +(5*jj)));
					cksum = cksum + (50 +(5*jj));
				end
			end
			spi_bwrite(0, cksum);
		`elsif COSIM2
			//disp_write_idat((9*24), 8'h80);	
			cmd_write(8'h2);
			cksum = 8'd0;
			for (ii=0; ii<9; ii=ii+1) begin
				for (jj=0; jj<24; jj=jj+1) begin
					spi_bwrite(0, (128 +(5*jj)));
					cksum = cksum + (128 +(5*jj));
				end
			end
			spi_bwrite(0, cksum);
		`elsif COSIM3
			//disp_write_idat((9*16), 8'h80);	
			cmd_write(8'h2);
			cksum = 8'd0;
			for (ii=0; ii<9; ii=ii+1) begin
				for (jj=0; jj<16; jj=jj+1) begin
					spi_bwrite(0, (128 +(8*jj)));
					cksum = cksum + (128 +(8*jj));
				end
			end
			spi_bwrite(0, cksum);
		`elsif COSIM4
			//disp_write_idat((10*32), 8'h80);	
			cmd_write(8'h2);
			cksum = 8'd0;
			for (ii=0; ii<10; ii=ii+1) begin
				for (jj=0; jj<32; jj=jj+1) begin
					spi_bwrite(0, (50 +(5*jj)));
					cksum = cksum + (50 +(5*jj));
				end
			end
			spi_bwrite(0, cksum);
		`elsif COSIM9
			disp_write_idat((10*32), 8'hFF);	
		`elsif COSIM10
			//disp_write_idat((10*32), 8'hFF);	
			cmd_write(8'h2);
			cksum = 8'd0;
			for (ii=0; ii<10; ii=ii+1) begin
				for (jj=0; jj<32; jj=jj+1) begin
					spi_bwrite(0, (50 +(5*jj)));
					cksum = cksum + (50 +(5*jj));
				end
			end
			spi_bwrite(0, cksum);
		`elsif COSIM11
			//disp_write_idat((10*24), 8'hFF);	
			cmd_write(8'h2);
			cksum = 8'd0;
			for (ii=0; ii<10; ii=ii+1) begin
				for (jj=0; jj<24; jj=jj+1) begin
					spi_bwrite(0, (128 +(5*jj)));
					cksum = cksum + (128 +(5*jj));
				end
			end
			spi_bwrite(0, cksum);
		`elsif COSIM12
			disp_write_idat((10*16), 8'hFF);	
		`elsif COSIMSS
			disp_write_idat((10*32), 8'hFF);	
		`elsif COSIMFF
			disp_write_idat((10*32), 8'hFF);	
		`endif
		$display("\t\t############\t DISP DATA SRAM WRITE \t############");
		cmd_write(8'h04); // manual disp. update
		$display("\t\t############\t Manual DISP update \t############");

		`ifdef COSIMSS
		lv0_wreg[2]	={1'b0,1'b1,2'b00, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=0 DON =1 
		`elsif COSIMFF
		lv0_wreg[2]	={1'b0,1'b1,2'b00, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=0 DON =1 
		`elsif COSIM9
		lv0_wreg[2]	={1'b0,1'b1,2'b00, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=0 DON =1 
		`else
		lv0_wreg[2]	={1'b0,1'b0,2'b00, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=0 DON =1 
		`endif
		creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
		$display("\t\t############\t DO = 1 \t############");
//		`ifdef COSIM10
//			#400_000;
//			reg_write_1byte(16'h40f,8'h04);
//		`elsif COSIM11
//			#400_000;
//			reg_write_1byte(16'h40f,8'h07);
//		`endif
		#4_000_000;

		`ifdef COSIMSS
		lv0_wreg[2]	={1'b0,1'b1,2'b11, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =1 
		`elsif COSIMFF
		lv0_wreg[2]	={1'b0,1'b1,2'b11, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =1 
		`elsif COSIM9
		lv0_wreg[2]	={1'b0,1'b1,2'b11, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =1 
		`else
		lv0_wreg[2]	={1'b0,1'b0,2'b11, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =1 
		`endif
		creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
		`ifdef COSIM10
			#400_000;
			reg_write_1byte(16'h40f,8'h08);
		`elsif COSIM11
			#400_000;
			reg_write_1byte(16'h40f,8'h0C);
		`endif
		#3_000_000;

		`ifdef COSIMSS
		lv0_wreg[2]	={1'b0,1'b1,2'b11, 1'b0 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =0 
		`elsif COSIMFF
		lv0_wreg[2]	={1'b0,1'b1,2'b11, 1'b0 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =0 
		`elsif COSIM9
		lv0_wreg[2]	={1'b0,1'b1,2'b11, 1'b0 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =0 
		`else
		lv0_wreg[2]	={1'b0,1'b0,2'b11, 1'b0 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =0 
		`endif
		creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
		#200_000;
		cmd_write(8'hE);//SLEEP CMD
		$display("\t\t############\t SLEEP_CMD\t############");
		#2_000_000;
	`endif
	`ifdef VCDDUMP 
	$dumpoff;
	$display($stime, " ns : analog pin vcd dump finished");
	`endif
	$finish;
`elsif TOP_TEST 
	#10_000_000;
	spi_brdata[0]= 8'b0;
	spi_brdata[0][2]   = 1'b1;	//9-GRID
	spi_brdata[0][1:0] = 2'b11; //32-SEG
	$display("9-GRID, 32-SEG MODE ..");
	reg_write_1byte(16'h408, spi_brdata[0]);
	lv0_wreg[0]	={2'b00,6'h3f};	// I; 
	lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
	lv0_wreg[2]	={1'b0,1'b0,2'b00, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT}; DON ==1 
	lv0_wreg[3]	={1'b1,1'b1,4'b0000,1'b0,1'b0};		// {RD_EN,SLEEP/4'b0000,TP2,1'b0}; 
	creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
	cmd_write(8'h2);
	cksum = 8'd0;
	for (ii=0; ii<9; ii=ii+1) begin
		for (jj=0; jj<32; jj=jj+1) begin
			spi_bwrite(0, (50 +(5*jj)));
			cksum = cksum + (50 +(5*jj));
		end
	end
	spi_bwrite(0, cksum);
	$display("\t############\t DISP DATA SRAM WRITE \t############");
	cmd_write(8'h04); // manual disp. update
	$display("\t############\t Manual DISP update \t############");
	#4_000_000;
	lv0_wreg[2]	={1'b0,1'b0,2'b11, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT};FR=3 DON =1 
	creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
	#3_000_000;
	cmd_write(8'hE);//SLEEP CMD
	$display("\t############\t SLEEP_CMD\t############");
	#2_000_000;
	cmd_write(8'hD);//WAKEUP CMD
	$display("\t############\t WAKEUP_CMD\t############");
	#5_000_000
	$finish;
`elsif PWR_TEST 
	#5_000_000;
	cmd_write(8'hD);	
	$display($stime, "\t############\t WAKEUP_CMD\t############");
	spi_brdata[0]= 8'b0;
	spi_brdata[0][2]   = 1'b0;	//9-GRID
	spi_brdata[0][1:0] = 2'b11; //32-SEG
	$display("\t\t10-GRID, 32-SEG MODE ..");
	reg_write_1byte(16'h408, spi_brdata[0]);
	lv0_wreg[0]	={2'b00,6'h3f};	// I; 
	lv0_wreg[1]	={1'b0,1'b0,4'b1001,1'b0,1'b0};		// {OSC,1'b0,G_N,TEST,UP}; 
	lv0_wreg[2]	={1'b0,1'b0,2'b00, 1'b1 ,1'b0,2'b0};	// {TP1,RES,FR,DON,GS,DT}; DON ==1 
	lv0_wreg[3]	={1'b1,1'b1,4'b0000,1'b0,1'b0};		// {RD_EN,SLEEP/4'b0000,TP2,1'b0}; 
	creg_write(lv0_wreg[0],lv0_wreg[1],lv0_wreg[2],lv0_wreg[3]);   //G_N = 8 
	disp_write_idat((10*32), 8'hFF);	
	//cmd_write(8'h2);
	//cksum = 8'd0;
	//for (ii=0; ii<9; ii=ii+1) begin
	//	for (jj=0; jj<32; jj=jj+1) begin
	//		spi_bwrite(0, (50 +(5*jj)));
	//		cksum = cksum + (50 +(5*jj));
	//	end
	//end
	//spi_bwrite(0, cksum);
	$display($stime, "\t############\t DISP DATA SRAM WRITE \t############");
	cmd_write(8'h04); // manual disp. update
	$display($stime, "\t############\t Manual DISP update \t############");
	#10_000_000;
	cmd_write(8'hE);//SLEEP CMD
	$display($stime, "\t############\t SLEEP_CMD\t############");
	#5_000_000;
	cmd_write(8'hD);//WAKEUP CMD
	$display($stime, "\t############\t WAKEUP_CMD\t############");
	#5_000_000
	$finish;

`endif

end

`ifdef COSIM_TEST 
initial begin
	wait(tb_top.u_chicago_chip.u_chicago_dig.u_pmu.c_state[4:0]==5'h1f);
	$display($stime, "efuse CRC  data 0x%1h",tb_top.u_chicago_chip.u_chicago_dig.u_pmu.I_EF_DATA[63:60]);
	$display($stime, "CRC output data 0x%1h",tb_top.u_chicago_chip.u_chicago_dig.u_pmu.w_crcout[3:0]);
end	
`endif

`ifdef VCDDUMP 
initial begin
	#1;
	$display($stime, " ns : analog pin vcd dump start");
	`ifdef COSIM1
		$dumpfile("./chicago_chip_0516_no1.vcd");
	`elsif COSIM2
		$dumpfile("./chicago_chip_0516_no2.vcd");
	`elsif COSIM3
		$dumpfile("./chicago_chip_0516_no3.vcd");
	`elsif COSIM4
		$dumpfile("./chicago_chip_0529_no4.vcd");
	`elsif COSIM5
		$dumpfile("./chicago_chip_0517_no5.vcd");
	`elsif COSIM7
		$dumpfile("./chicago_chip_0516_no7_1.vcd");
	`elsif COSIM8
		$dumpfile("./chicago_chip_0518_no8_1.vcd");
	`elsif COSIM9
		$dumpfile("./chicago_chip_0527_no9.vcd");
	`elsif COSIM10
		$dumpfile("./chicago_chip_0523_no10.vcd");
	`elsif COSIM11
		$dumpfile("./chicago_chip_0523_no11.vcd");
	`elsif COSIM12
		$dumpfile("./chicago_chip_0522_no12.vcd");
	`elsif COSIMSS
		$dumpfile("./chicago_chip_0527_no9SS.vcd");
	`elsif COSIMFF
		$dumpfile("./chicago_chip_0527_no9FF.vcd");
	`endif
	$dumpvars(1,tb_top.u_chicago_chip.P_SCL 				);
	$dumpvars(1,tb_top.u_chicago_chip.P_SDA 				);
end
`endif
`ifdef COSIM8
initial begin
	#5000_000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
		
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'hffffffff;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'hffffffff;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'hffffffff;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'hffffffff;
		
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h55555555;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'haaaaaaaa;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'haaaaaaaa;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
		
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h55555555;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h55555555;
		
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'hAAAAAAAA;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'hAAAAAAAA;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
		
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'hFFAAAAFF;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'hFFAAAAFF;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'hFFFFFFFF;
		
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h11111111;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
		
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h11111111;
		
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000001;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h80000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000001;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h80000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000001;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h80000000;
		
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h80000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000001;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h80000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000001;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h80000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000001;
		
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h22222222;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h00000000;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h22222222;
	@(posedge tb_top.u_chicago_chip.u_chicago_dig.O_LOSD_DET_EN[1]); #1;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LOD[32:1] = 32'h22222222;
		force tb_top.u_chicago_chip.u_chicago_dig.I_LSD[32:1] = 32'h00000000;

	
end
`endif



`ifndef POST_SIM
	wire w_clk = tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.I_CLK;
	wire w_rstb = tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.I_RSTB;
	wire w_dt_st = tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.start_dt;
	wire w_grid_st = tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.start_grid;
	wire w_st_grid_t01 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_grid_t01;
	wire w_st_dead_t01 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_dead_t01;
	wire w_st_grid_t02 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_grid_t02;
	wire w_st_dead_t02 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_dead_t02;
	wire w_st_grid_t03 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_grid_t03;
	wire w_st_dead_t03 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_dead_t03;
	wire w_st_grid_t04 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_grid_t04;
	wire w_st_dead_t04 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_dead_t04;
	wire w_st_grid_t05 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_grid_t05;
	wire w_st_dead_t05 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_dead_t05;
	wire w_st_grid_t06 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_grid_t06;
	wire w_st_dead_t06 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_dead_t06;
	wire w_st_grid_t07 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_grid_t07;
	wire w_st_dead_t07 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_dead_t07;
	wire w_st_grid_t08 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_grid_t08;
	wire w_st_dead_t08 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_dead_t08;
	wire w_st_grid_t09 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_grid_t09;
	wire w_st_dead_t09 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_dead_t09;
	wire w_st_grid_t10 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_grid_t10;
	wire w_st_dead_t10 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_st_dead_t10;

	wire w_ne_grid_t01 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_grid_t01;
	wire w_ne_dead_t01 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_dead_t01;
	wire w_ne_grid_t02 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_grid_t02;
	wire w_ne_dead_t02 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_dead_t02;
	wire w_ne_grid_t03 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_grid_t03;
	wire w_ne_dead_t03 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_dead_t03;
	wire w_ne_grid_t04 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_grid_t04;
	wire w_ne_dead_t04 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_dead_t04;
	wire w_ne_grid_t05 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_grid_t05;
	wire w_ne_dead_t05 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_dead_t05;
	wire w_ne_grid_t06 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_grid_t06;
	wire w_ne_dead_t06 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_dead_t06;
	wire w_ne_grid_t07 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_grid_t07;
	wire w_ne_dead_t07 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_dead_t07;
	wire w_ne_grid_t08 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_grid_t08;
	wire w_ne_dead_t08 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_dead_t08;
	wire w_ne_grid_t09 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_grid_t09;
	wire w_ne_dead_t09 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_dead_t09;
	wire w_ne_grid_t10 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_grid_t10;
	wire w_ne_dead_t10 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.w_ne_dead_t10;
	wire [3:0] w_gn    	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.r_gn[3:0];
	wire [1:0] w_dt    	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.r_dt[1:0];
	wire [1:0] w_fr    	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.r_fr[1:0];
	wire [1:0] w_segmode= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.r_seg_mode[1:0];
	wire w_up_remap	   = tb_top.u_chicago_chip.u_chicago_dig.u_addr_dec.I_UP_REMAP;
	wire [10:1] GRID_DCHG = tb_top.u_chicago_chip.u_chicago_dig.O_GRID_DCHG[10:1];
	wire [32:1] SEG_CHG = tb_top.u_chicago_chip.u_chicago_dig.O_SEG_CHG[32:1];
`else
	wire w_clk			= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.I_CLK;
	wire w_rstb			= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.I_RSTB;
	wire [4:0] w_cu_state = tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.CU_STATE[4:0]; 
	wire [4:0] w_ne_state ; 
	assign w_ne_state[0] =tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.cu_state_reg_0_0.D; 
	assign w_ne_state[1] =tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.cu_state_reg_1_0.D; 
	assign w_ne_state[2] =tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.cu_state_reg_2_0.D; 
	assign w_ne_state[3] =tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.cu_state_reg_3_0.D;   
	assign w_ne_state[4] =tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.cu_state_reg_4_0.D;   
	wire w_st_grid_t01	= w_cu_state ==5'h03  ;
	wire w_st_dead_t01	= w_cu_state ==5'h04 ;
	wire w_st_grid_t02	= w_cu_state ==5'h05 ;
	wire w_st_dead_t02	= w_cu_state ==5'h06 ;
	wire w_st_grid_t03	= w_cu_state ==5'h07 ;
	wire w_st_dead_t03	= w_cu_state ==5'h08 ;
	wire w_st_grid_t04	= w_cu_state ==5'h09 ;
	wire w_st_dead_t04	= w_cu_state ==5'h0a ;
	wire w_st_grid_t05	= w_cu_state ==5'h0b ;
	wire w_st_dead_t05	= w_cu_state ==5'h0c ;
	wire w_st_grid_t06	= w_cu_state ==5'h0d ;
	wire w_st_dead_t06	= w_cu_state ==5'h0e ;
	wire w_st_grid_t07	= w_cu_state ==5'h0f ;
	wire w_st_dead_t07	= w_cu_state ==5'h10 ;
	wire w_st_grid_t08	= w_cu_state ==5'h11 ;
	wire w_st_dead_t08	= w_cu_state ==5'h12 ;
	wire w_st_grid_t09	= w_cu_state ==5'h13 ;
	wire w_st_dead_t09	= w_cu_state ==5'h14 ;
	wire w_st_grid_t10	= w_cu_state ==5'h15 ;
	wire w_st_dead_t10	= w_cu_state ==5'h16 ;

	wire w_ne_grid_t01	= w_ne_state ==5'h03 ; 
	wire w_ne_dead_t01	= w_ne_state ==5'h04 ; 
	wire w_ne_grid_t02	= w_ne_state ==5'h05 ; 
	wire w_ne_dead_t02	= w_ne_state ==5'h06 ; 
	wire w_ne_grid_t03	= w_ne_state ==5'h07 ; 
	wire w_ne_dead_t03	= w_ne_state ==5'h08 ; 
	wire w_ne_grid_t04	= w_ne_state ==5'h09 ; 
	wire w_ne_dead_t04	= w_ne_state ==5'h0a ; 
	wire w_ne_grid_t05	= w_ne_state ==5'h0b ; 
	wire w_ne_dead_t05	= w_ne_state ==5'h0c ; 
	wire w_ne_grid_t06	= w_ne_state ==5'h0d ; 
	wire w_ne_dead_t06	= w_ne_state ==5'h0e ; 
	wire w_ne_grid_t07	= w_ne_state ==5'h0f ; 
	wire w_ne_dead_t07	= w_ne_state ==5'h10 ; 
	wire w_ne_grid_t08	= w_ne_state ==5'h11 ; 
	wire w_ne_dead_t08	= w_ne_state ==5'h12 ; 
	wire w_ne_grid_t09	= w_ne_state ==5'h13 ; 
	wire w_ne_dead_t09	= w_ne_state ==5'h14 ; 
	wire w_ne_grid_t10	= w_ne_state ==5'h15 ; 
	wire w_ne_dead_t10	= w_ne_state ==5'h16 ; 
	wire w_dt_st		= w_st_dead_t01 || w_st_dead_t02 || w_st_dead_t03 || w_st_dead_t04 || w_st_dead_t05 || 
				   		  w_st_dead_t06 || w_st_dead_t07 || w_st_dead_t08 || w_st_dead_t09 || w_st_dead_t10 ;
	wire [3:0] w_gn  	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.R_GN[3:0];
	wire [1:0] w_dt  	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.R_DT[1:0];
	wire [1:0] w_fr  	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.R_FR[1:0];
	wire [1:0] w_segmode= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.R_SEG_MODE[1:0];
	wire w_up_remap	 	= tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.O_UPREMAP;
	wire [10:1] GRID_DCHG = tb_top.u_chicago_chip.u_chicago_dig.O_GRID_DCHG[10:1];
	wire [32:1] SEG_CHG = tb_top.u_chicago_chip.u_chicago_dig.O_SEG_CHG[32:1];
`endif

wire [1:10] w_st_dead_t_array;
assign w_st_dead_t_array[1]  = w_st_dead_t01;
assign w_st_dead_t_array[2]  = w_st_dead_t02;
assign w_st_dead_t_array[3]  = w_st_dead_t03;
assign w_st_dead_t_array[4]  = w_st_dead_t04;
assign w_st_dead_t_array[5]  = w_st_dead_t05;
assign w_st_dead_t_array[6]  = w_st_dead_t06;
assign w_st_dead_t_array[7]  = w_st_dead_t07;
assign w_st_dead_t_array[8]  = w_st_dead_t08;
assign w_st_dead_t_array[9]  = w_st_dead_t09;
assign w_st_dead_t_array[10] = w_st_dead_t10;

reg [1:10]r_st_dead_t_array_d1;
reg [1:10]r_st_dead_t_array_d2;
always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		r_st_dead_t_array_d1	<= 0;
		r_st_dead_t_array_d2	<= 0;
	end
	else begin
		r_st_dead_t_array_d1	<= w_st_dead_t_array;
		r_st_dead_t_array_d2	<= r_st_dead_t_array_d1;
	end
end


reg [12:0] cnt[31:00];
reg [12:0] seg[31:00];
integer i,j,k,l,m,n;

reg r_dt_st_d1;
reg r_dt_st_d2;
always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		r_dt_st_d1	<= 0;
		r_dt_st_d2	<= 0;
	end
	else begin
		r_dt_st_d1	<= w_dt_st;
		r_dt_st_d2	<= r_dt_st_d1;
	end
end

wire counter_ack =((w_st_grid_t01 && w_ne_dead_t01)|| 
			(w_st_grid_t02 && w_ne_dead_t02)|| 
			(w_st_grid_t03 && w_ne_dead_t03)|| 
			(w_st_grid_t04 && w_ne_dead_t04)|| 
			(w_st_grid_t05 && w_ne_dead_t05)|| 
			(w_st_grid_t06 && w_ne_dead_t06)|| 
			(w_st_grid_t07 && w_ne_dead_t07)|| 
			(w_st_grid_t08 && w_ne_dead_t08)|| 
			(w_st_grid_t09 && w_ne_dead_t09)|| 
			(w_st_grid_t10 && w_ne_dead_t10));

reg r_counter_ack; 
reg r_counter_ack_d2; 
always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		r_counter_ack 	<=0;
		r_counter_ack_d2 	<=0;; 
	end
	else begin
		r_counter_ack <=counter_ack ;
		r_counter_ack_d2 	<=r_counter_ack ; 
	end
end

reg [12:0] cnt_grid[9:0];
reg [12:0] cnt_dchg[9:0];
reg [12:0] grid[9:0];
reg [12:0] grid_dchg[9:0];

always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		for(k=0;k<10;k=k+1) begin
			cnt_grid[k[4:0]] 	<= 13'd0;
		end	
	end
	else begin
		if(r_counter_ack_d2 	==1) begin 
			for(k=0;k<10;k=k+1) begin
				cnt_grid[k[4:0]] 	<= 13'd0;
			end	
		end
		else begin
			if(GRID1 ) cnt_grid[00] <= cnt_grid[00] +1; else cnt_grid[00] <= cnt_grid[00]; 
			if(GRID2 ) cnt_grid[01] <= cnt_grid[01] +1; else cnt_grid[01] <= cnt_grid[01]; 
			if(GRID3 ) cnt_grid[02] <= cnt_grid[02] +1; else cnt_grid[02] <= cnt_grid[02]; 
			if(GRID4 ) cnt_grid[03] <= cnt_grid[03] +1; else cnt_grid[03] <= cnt_grid[03]; 
			if(GRID5 ) cnt_grid[04] <= cnt_grid[04] +1; else cnt_grid[04] <= cnt_grid[04]; 
			if(GRID6 ) cnt_grid[05] <= cnt_grid[05] +1; else cnt_grid[05] <= cnt_grid[05]; 
			if(GRID7 ) cnt_grid[06] <= cnt_grid[06] +1; else cnt_grid[06] <= cnt_grid[06]; 
			if(GRID8 ) cnt_grid[07] <= cnt_grid[07] +1; else cnt_grid[07] <= cnt_grid[07]; 
			if(GRID9 ) cnt_grid[08] <= cnt_grid[08] +1; else cnt_grid[08] <= cnt_grid[08]; 
			if(GRID10) cnt_grid[09] <= cnt_grid[09] +1; else cnt_grid[09] <= cnt_grid[09]; 
		end
	end
end

always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		for(k=0;k<10;k=k+1) begin
			cnt_dchg[k[4:0]] 	<= 13'd0;
		end	
	end
	else begin
		if(r_counter_ack_d2 	==1) begin 
			for(k=0;k<10;k=k+1) begin
				cnt_dchg[k[4:0]] 	<= 13'd0;
			end	
		end
		else begin
			if(GRID_DCHG[1 ]) cnt_dchg[00] <= cnt_dchg[00] +1; else cnt_dchg[00] <= cnt_dchg[00]; 
			if(GRID_DCHG[2 ]) cnt_dchg[01] <= cnt_dchg[01] +1; else cnt_dchg[01] <= cnt_dchg[01]; 
			if(GRID_DCHG[3 ]) cnt_dchg[02] <= cnt_dchg[02] +1; else cnt_dchg[02] <= cnt_dchg[02]; 
			if(GRID_DCHG[4 ]) cnt_dchg[03] <= cnt_dchg[03] +1; else cnt_dchg[03] <= cnt_dchg[03]; 
			if(GRID_DCHG[5 ]) cnt_dchg[04] <= cnt_dchg[04] +1; else cnt_dchg[04] <= cnt_dchg[04]; 
			if(GRID_DCHG[6 ]) cnt_dchg[05] <= cnt_dchg[05] +1; else cnt_dchg[05] <= cnt_dchg[05]; 
			if(GRID_DCHG[7 ]) cnt_dchg[06] <= cnt_dchg[06] +1; else cnt_dchg[06] <= cnt_dchg[06]; 
			if(GRID_DCHG[8 ]) cnt_dchg[07] <= cnt_dchg[07] +1; else cnt_dchg[07] <= cnt_dchg[07]; 
			if(GRID_DCHG[9 ]) cnt_dchg[08] <= cnt_dchg[08] +1; else cnt_dchg[08] <= cnt_dchg[08]; 
			if(GRID_DCHG[10]) cnt_dchg[09] <= cnt_dchg[09] +1; else cnt_dchg[09] <= cnt_dchg[09]; 
		end
	end
end

always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		for(i=0;i<32;i=i+1) begin
			cnt[i[4:0]] 	<= 13'd0;
		end	
	end
	else begin
		if(r_counter_ack_d2 	==1) begin 
			for(i=0;i<32;i=i+1) begin
				cnt[i[4:0]] 	<= 13'd0;
			end	
		end
		else begin
			if(w_segmode ==2'b11)begin
				if(SEG1 ) cnt[00] <=cnt[00] +1; else cnt[00] <= cnt[00]; 
				if(SEG2 ) cnt[01] <=cnt[01] +1; else cnt[01] <= cnt[01]; 
				if(SEG3 ) cnt[02] <=cnt[02] +1; else cnt[02] <= cnt[02]; 
				if(SEG4 ) cnt[03] <=cnt[03] +1; else cnt[03] <= cnt[03]; 
				if(SEG5 ) cnt[04] <=cnt[04] +1; else cnt[04] <= cnt[04]; 
				if(SEG6 ) cnt[05] <=cnt[05] +1; else cnt[05] <= cnt[05]; 
				if(SEG7 ) cnt[06] <=cnt[06] +1; else cnt[06] <= cnt[06]; 
				if(SEG8 ) cnt[07] <=cnt[07] +1; else cnt[07] <= cnt[07]; 
				if(SEG9 ) cnt[08] <=cnt[08] +1; else cnt[08] <= cnt[08]; 
				if(SEG10) cnt[09] <=cnt[09] +1; else cnt[09] <= cnt[09]; 
				if(SEG11) cnt[10] <=cnt[10] +1; else cnt[10] <= cnt[10]; 
				if(SEG12) cnt[11] <=cnt[11] +1; else cnt[11] <= cnt[11]; 
				if(SEG13) cnt[12] <=cnt[12] +1; else cnt[12] <= cnt[12]; 
				if(SEG14) cnt[13] <=cnt[13] +1; else cnt[13] <= cnt[13]; 
				if(SEG15) cnt[14] <=cnt[14] +1; else cnt[14] <= cnt[14]; 
				if(SEG16) cnt[15] <=cnt[15] +1; else cnt[15] <= cnt[15]; 
				if(SEG17) cnt[16] <=cnt[16] +1; else cnt[16] <= cnt[16]; 
				if(SEG18) cnt[17] <=cnt[17] +1; else cnt[17] <= cnt[17]; 
				if(SEG19) cnt[18] <=cnt[18] +1; else cnt[18] <= cnt[18]; 
				if(SEG20) cnt[19] <=cnt[19] +1; else cnt[19] <= cnt[19]; 
				if(SEG21) cnt[20] <=cnt[20] +1; else cnt[20] <= cnt[20]; 
				if(SEG22) cnt[21] <=cnt[21] +1; else cnt[21] <= cnt[21]; 
				if(SEG23) cnt[22] <=cnt[22] +1; else cnt[22] <= cnt[22]; 
				if(SEG24) cnt[23] <=cnt[23] +1; else cnt[23] <= cnt[23]; 
				if(SEG25) cnt[24] <=cnt[24] +1; else cnt[24] <= cnt[24]; 
				if(SEG26) cnt[25] <=cnt[25] +1; else cnt[25] <= cnt[25]; 
				if(SEG27) cnt[26] <=cnt[26] +1; else cnt[26] <= cnt[26]; 
				if(SEG28) cnt[27] <=cnt[27] +1; else cnt[27] <= cnt[27]; 
				if(SEG29) cnt[28] <=cnt[28] +1; else cnt[28] <= cnt[28]; 
				if(SEG30) cnt[29] <=cnt[29] +1; else cnt[29] <= cnt[29]; 
				if(SEG31) cnt[30] <=cnt[30] +1; else cnt[30] <= cnt[30]; 
				if(SEG32) cnt[31] <=cnt[31] +1; else cnt[31] <= cnt[31];
			end
			else if(w_segmode ==2'b10)begin
				if(SEG1 ) cnt[00] <=cnt[00] +1; else cnt[00] <= cnt[00]; 
				if(SEG2 ) cnt[01] <=cnt[01] +1; else cnt[01] <= cnt[01]; 
				if(SEG3 ) cnt[02] <=cnt[02] +1; else cnt[02] <= cnt[02]; 
				if(SEG4 ) cnt[03] <=cnt[03] +1; else cnt[03] <= cnt[03]; 
				if(SEG5 ) cnt[04] <=cnt[04] +1; else cnt[04] <= cnt[04]; 
				if(SEG6 ) cnt[05] <=cnt[05] +1; else cnt[05] <= cnt[05]; 
				if(SEG7 ) cnt[06] <=cnt[06] +1; else cnt[06] <= cnt[06]; 
				if(SEG8 ) cnt[07] <=cnt[07] +1; else cnt[07] <= cnt[07]; 
				if(SEG10) cnt[08] <=cnt[08] +1; else cnt[08] <= cnt[08]; 
				if(SEG12) cnt[09] <=cnt[09] +1; else cnt[09] <= cnt[09]; 
				if(SEG14) cnt[10] <=cnt[10] +1; else cnt[10] <= cnt[10]; 
				if(SEG16) cnt[11] <=cnt[11] +1; else cnt[11] <= cnt[11]; 
				if(SEG18) cnt[12] <=cnt[12] +1; else cnt[12] <= cnt[12]; 
				if(SEG20) cnt[13] <=cnt[13] +1; else cnt[13] <= cnt[13]; 
				if(SEG22) cnt[14] <=cnt[14] +1; else cnt[14] <= cnt[14]; 
				if(SEG24) cnt[15] <=cnt[15] +1; else cnt[15] <= cnt[15]; 
				if(SEG25) cnt[16] <=cnt[16] +1; else cnt[16] <= cnt[16]; 
				if(SEG26) cnt[17] <=cnt[17] +1; else cnt[17] <= cnt[17]; 
				if(SEG27) cnt[18] <=cnt[18] +1; else cnt[18] <= cnt[18]; 
				if(SEG28) cnt[19] <=cnt[19] +1; else cnt[19] <= cnt[19]; 
				if(SEG29) cnt[20] <=cnt[20] +1; else cnt[20] <= cnt[20]; 
				if(SEG30) cnt[21] <=cnt[21] +1; else cnt[21] <= cnt[21]; 
				if(SEG31) cnt[22] <=cnt[22] +1; else cnt[22] <= cnt[22]; 
				if(SEG32) cnt[23] <=cnt[23] +1; else cnt[23] <= cnt[23];
				if(SEG9 ) cnt[24] <=cnt[24] +1; else cnt[24] <= cnt[24]; 
				if(SEG11) cnt[25] <=cnt[25] +1; else cnt[25] <= cnt[25]; 
				if(SEG13) cnt[26] <=cnt[26] +1; else cnt[26] <= cnt[26]; 
				if(SEG15) cnt[27] <=cnt[27] +1; else cnt[27] <= cnt[27]; 
				if(SEG17) cnt[28] <=cnt[28] +1; else cnt[28] <= cnt[28]; 
				if(SEG19) cnt[29] <=cnt[29] +1; else cnt[29] <= cnt[29]; 
				if(SEG21) cnt[30] <=cnt[30] +1; else cnt[30] <= cnt[30]; 
				if(SEG23) cnt[31] <=cnt[31] +1; else cnt[31] <= cnt[31]; 
			end
			else if(w_segmode ==2'b01)begin
				if(SEG2 ) cnt[00] <=cnt[00] +1; else cnt[00] <= cnt[00]; 
				if(SEG4 ) cnt[01] <=cnt[01] +1; else cnt[01] <= cnt[01]; 
				if(SEG6 ) cnt[02] <=cnt[02] +1; else cnt[02] <= cnt[02]; 
				if(SEG8 ) cnt[03] <=cnt[03] +1; else cnt[03] <= cnt[03]; 
				if(SEG10) cnt[04] <=cnt[04] +1; else cnt[04] <= cnt[04]; 
				if(SEG12) cnt[05] <=cnt[05] +1; else cnt[05] <= cnt[05]; 
				if(SEG14) cnt[06] <=cnt[06] +1; else cnt[06] <= cnt[06]; 
				if(SEG16) cnt[07] <=cnt[07] +1; else cnt[07] <= cnt[07]; 
				if(SEG18) cnt[08] <=cnt[08] +1; else cnt[08] <= cnt[08]; 
				if(SEG20) cnt[09] <=cnt[09] +1; else cnt[09] <= cnt[09]; 
				if(SEG22) cnt[10] <=cnt[10] +1; else cnt[10] <= cnt[10]; 
				if(SEG24) cnt[11] <=cnt[11] +1; else cnt[11] <= cnt[11]; 
				if(SEG26) cnt[12] <=cnt[12] +1; else cnt[12] <= cnt[12]; 
				if(SEG28) cnt[13] <=cnt[13] +1; else cnt[13] <= cnt[13]; 
				if(SEG30) cnt[14] <=cnt[14] +1; else cnt[14] <= cnt[14]; 
				if(SEG32) cnt[15] <=cnt[15] +1; else cnt[15] <= cnt[15];
				if(SEG1 ) cnt[16] <=cnt[16] +1; else cnt[16] <= cnt[16]; 
				if(SEG3 ) cnt[17] <=cnt[17] +1; else cnt[17] <= cnt[17]; 
				if(SEG5 ) cnt[18] <=cnt[18] +1; else cnt[18] <= cnt[18]; 
				if(SEG7 ) cnt[19] <=cnt[19] +1; else cnt[19] <= cnt[19]; 
				if(SEG9 ) cnt[20] <=cnt[20] +1; else cnt[20] <= cnt[20]; 
				if(SEG11) cnt[21] <=cnt[21] +1; else cnt[21] <= cnt[21]; 
				if(SEG13) cnt[22] <=cnt[22] +1; else cnt[22] <= cnt[22]; 
				if(SEG15) cnt[23] <=cnt[23] +1; else cnt[23] <= cnt[23]; 
				if(SEG17) cnt[24] <=cnt[24] +1; else cnt[24] <= cnt[24]; 
				if(SEG19) cnt[25] <=cnt[25] +1; else cnt[25] <= cnt[25]; 
				if(SEG21) cnt[26] <=cnt[26] +1; else cnt[26] <= cnt[26]; 
				if(SEG23) cnt[27] <=cnt[27] +1; else cnt[27] <= cnt[27]; 
				if(SEG25) cnt[28] <=cnt[28] +1; else cnt[28] <= cnt[28]; 
				if(SEG27) cnt[29] <=cnt[29] +1; else cnt[29] <= cnt[29]; 
				if(SEG29) cnt[30] <=cnt[30] +1; else cnt[30] <= cnt[30]; 
				if(SEG31) cnt[31] <=cnt[31] +1; else cnt[31] <= cnt[31]; 
			end
			else if(w_segmode ==2'b00)begin
				if(SEG1 ) cnt[00] <=cnt[00] +1; else cnt[00] <= cnt[00]; 
				if(SEG2 ) cnt[01] <=cnt[01] +1; else cnt[01] <= cnt[01]; 
				if(SEG3 ) cnt[02] <=cnt[02] +1; else cnt[02] <= cnt[02]; 
				if(SEG4 ) cnt[03] <=cnt[03] +1; else cnt[03] <= cnt[03]; 
				if(SEG5 ) cnt[04] <=cnt[04] +1; else cnt[04] <= cnt[04]; 
				if(SEG6 ) cnt[05] <=cnt[05] +1; else cnt[05] <= cnt[05]; 
				if(SEG7 ) cnt[06] <=cnt[06] +1; else cnt[06] <= cnt[06]; 
				if(SEG8 ) cnt[07] <=cnt[07] +1; else cnt[07] <= cnt[07]; 
				if(SEG9 ) cnt[08] <=cnt[08] +1; else cnt[08] <= cnt[08]; 
				if(SEG10) cnt[09] <=cnt[09] +1; else cnt[09] <= cnt[09]; 
				if(SEG11) cnt[10] <=cnt[10] +1; else cnt[10] <= cnt[10]; 
				if(SEG12) cnt[11] <=cnt[11] +1; else cnt[11] <= cnt[11]; 
				if(SEG13) cnt[12] <=cnt[12] +1; else cnt[12] <= cnt[12]; 
				if(SEG14) cnt[13] <=cnt[13] +1; else cnt[13] <= cnt[13]; 
				if(SEG15) cnt[14] <=cnt[14] +1; else cnt[14] <= cnt[14]; 
				if(SEG16) cnt[15] <=cnt[15] +1; else cnt[15] <= cnt[15]; 
				if(SEG17) cnt[16] <=cnt[16] +1; else cnt[16] <= cnt[16]; 
				if(SEG18) cnt[17] <=cnt[17] +1; else cnt[17] <= cnt[17]; 
				if(SEG19) cnt[18] <=cnt[18] +1; else cnt[18] <= cnt[18]; 
				if(SEG20) cnt[19] <=cnt[19] +1; else cnt[19] <= cnt[19]; 
				if(SEG21) cnt[20] <=cnt[20] +1; else cnt[20] <= cnt[20]; 
				if(SEG22) cnt[21] <=cnt[21] +1; else cnt[21] <= cnt[21]; 
				if(SEG23) cnt[22] <=cnt[22] +1; else cnt[22] <= cnt[22]; 
				if(SEG24) cnt[23] <=cnt[23] +1; else cnt[23] <= cnt[23]; 
				if(SEG25) cnt[24] <=cnt[24] +1; else cnt[24] <= cnt[24]; 
				if(SEG26) cnt[25] <=cnt[25] +1; else cnt[25] <= cnt[25]; 
				if(SEG27) cnt[26] <=cnt[26] +1; else cnt[26] <= cnt[26]; 
				if(SEG28) cnt[27] <=cnt[27] +1; else cnt[27] <= cnt[27]; 
				if(SEG29) cnt[28] <=cnt[28] +1; else cnt[28] <= cnt[28]; 
				if(SEG30) cnt[29] <=cnt[29] +1; else cnt[29] <= cnt[29]; 
				if(SEG31) cnt[30] <=cnt[30] +1; else cnt[30] <= cnt[30]; 
				if(SEG32) cnt[31] <=cnt[31] +1; else cnt[31] <= cnt[31];
			end
		end               
	end               
end
reg [12:0] cnt_chg[31:00];
reg [12:0] seg_chg[31:00];
always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		for(i=0;i<32;i=i+1) begin
			cnt_chg[i[4:0]] 	<= 13'd0;
		end	
	end
	else begin
		if(r_counter_ack_d2 	==1) begin 
			for(i=0;i<32;i=i+1) begin
				cnt_chg[i[4:0]] 	<= 13'd0;
			end	
		end
		else begin
			if(w_segmode ==2'b11)begin
				if(SEG_CHG[1 ]) cnt_chg[00] <=cnt_chg[00] +1; else cnt_chg[00] <= cnt_chg[00]; 
				if(SEG_CHG[2 ]) cnt_chg[01] <=cnt_chg[01] +1; else cnt_chg[01] <= cnt_chg[01]; 
				if(SEG_CHG[3 ]) cnt_chg[02] <=cnt_chg[02] +1; else cnt_chg[02] <= cnt_chg[02]; 
				if(SEG_CHG[4 ]) cnt_chg[03] <=cnt_chg[03] +1; else cnt_chg[03] <= cnt_chg[03]; 
				if(SEG_CHG[5 ]) cnt_chg[04] <=cnt_chg[04] +1; else cnt_chg[04] <= cnt_chg[04]; 
				if(SEG_CHG[6 ]) cnt_chg[05] <=cnt_chg[05] +1; else cnt_chg[05] <= cnt_chg[05]; 
				if(SEG_CHG[7 ]) cnt_chg[06] <=cnt_chg[06] +1; else cnt_chg[06] <= cnt_chg[06]; 
				if(SEG_CHG[8 ]) cnt_chg[07] <=cnt_chg[07] +1; else cnt_chg[07] <= cnt_chg[07]; 
				if(SEG_CHG[9 ]) cnt_chg[08] <=cnt_chg[08] +1; else cnt_chg[08] <= cnt_chg[08]; 
				if(SEG_CHG[10]) cnt_chg[09] <=cnt_chg[09] +1; else cnt_chg[09] <= cnt_chg[09]; 
				if(SEG_CHG[11]) cnt_chg[10] <=cnt_chg[10] +1; else cnt_chg[10] <= cnt_chg[10]; 
				if(SEG_CHG[12]) cnt_chg[11] <=cnt_chg[11] +1; else cnt_chg[11] <= cnt_chg[11]; 
				if(SEG_CHG[13]) cnt_chg[12] <=cnt_chg[12] +1; else cnt_chg[12] <= cnt_chg[12]; 
				if(SEG_CHG[14]) cnt_chg[13] <=cnt_chg[13] +1; else cnt_chg[13] <= cnt_chg[13]; 
				if(SEG_CHG[15]) cnt_chg[14] <=cnt_chg[14] +1; else cnt_chg[14] <= cnt_chg[14]; 
				if(SEG_CHG[16]) cnt_chg[15] <=cnt_chg[15] +1; else cnt_chg[15] <= cnt_chg[15]; 
				if(SEG_CHG[17]) cnt_chg[16] <=cnt_chg[16] +1; else cnt_chg[16] <= cnt_chg[16]; 
				if(SEG_CHG[18]) cnt_chg[17] <=cnt_chg[17] +1; else cnt_chg[17] <= cnt_chg[17]; 
				if(SEG_CHG[19]) cnt_chg[18] <=cnt_chg[18] +1; else cnt_chg[18] <= cnt_chg[18]; 
				if(SEG_CHG[20]) cnt_chg[19] <=cnt_chg[19] +1; else cnt_chg[19] <= cnt_chg[19]; 
				if(SEG_CHG[21]) cnt_chg[20] <=cnt_chg[20] +1; else cnt_chg[20] <= cnt_chg[20]; 
				if(SEG_CHG[22]) cnt_chg[21] <=cnt_chg[21] +1; else cnt_chg[21] <= cnt_chg[21]; 
				if(SEG_CHG[23]) cnt_chg[22] <=cnt_chg[22] +1; else cnt_chg[22] <= cnt_chg[22]; 
				if(SEG_CHG[24]) cnt_chg[23] <=cnt_chg[23] +1; else cnt_chg[23] <= cnt_chg[23]; 
				if(SEG_CHG[25]) cnt_chg[24] <=cnt_chg[24] +1; else cnt_chg[24] <= cnt_chg[24]; 
				if(SEG_CHG[26]) cnt_chg[25] <=cnt_chg[25] +1; else cnt_chg[25] <= cnt_chg[25]; 
				if(SEG_CHG[27]) cnt_chg[26] <=cnt_chg[26] +1; else cnt_chg[26] <= cnt_chg[26]; 
				if(SEG_CHG[28]) cnt_chg[27] <=cnt_chg[27] +1; else cnt_chg[27] <= cnt_chg[27]; 
				if(SEG_CHG[29]) cnt_chg[28] <=cnt_chg[28] +1; else cnt_chg[28] <= cnt_chg[28]; 
				if(SEG_CHG[30]) cnt_chg[29] <=cnt_chg[29] +1; else cnt_chg[29] <= cnt_chg[29]; 
				if(SEG_CHG[31]) cnt_chg[30] <=cnt_chg[30] +1; else cnt_chg[30] <= cnt_chg[30]; 
				if(SEG_CHG[32]) cnt_chg[31] <=cnt_chg[31] +1; else cnt_chg[31] <= cnt_chg[31];
			end
			else if(w_segmode ==2'b10)begin
				if(SEG_CHG[1 ]) cnt_chg[00] <=cnt_chg[00] +1; else cnt_chg[00] <= cnt_chg[00]; 
				if(SEG_CHG[2 ]) cnt_chg[01] <=cnt_chg[01] +1; else cnt_chg[01] <= cnt_chg[01]; 
				if(SEG_CHG[3 ]) cnt_chg[02] <=cnt_chg[02] +1; else cnt_chg[02] <= cnt_chg[02]; 
				if(SEG_CHG[4 ]) cnt_chg[03] <=cnt_chg[03] +1; else cnt_chg[03] <= cnt_chg[03]; 
				if(SEG_CHG[5 ]) cnt_chg[04] <=cnt_chg[04] +1; else cnt_chg[04] <= cnt_chg[04]; 
				if(SEG_CHG[6 ]) cnt_chg[05] <=cnt_chg[05] +1; else cnt_chg[05] <= cnt_chg[05]; 
				if(SEG_CHG[7 ]) cnt_chg[06] <=cnt_chg[06] +1; else cnt_chg[06] <= cnt_chg[06]; 
				if(SEG_CHG[8 ]) cnt_chg[07] <=cnt_chg[07] +1; else cnt_chg[07] <= cnt_chg[07]; 
				if(SEG_CHG[10]) cnt_chg[08] <=cnt_chg[08] +1; else cnt_chg[08] <= cnt_chg[08]; 
				if(SEG_CHG[12]) cnt_chg[09] <=cnt_chg[09] +1; else cnt_chg[09] <= cnt_chg[09]; 
				if(SEG_CHG[14]) cnt_chg[10] <=cnt_chg[10] +1; else cnt_chg[10] <= cnt_chg[10]; 
				if(SEG_CHG[16]) cnt_chg[11] <=cnt_chg[11] +1; else cnt_chg[11] <= cnt_chg[11]; 
				if(SEG_CHG[18]) cnt_chg[12] <=cnt_chg[12] +1; else cnt_chg[12] <= cnt_chg[12]; 
				if(SEG_CHG[20]) cnt_chg[13] <=cnt_chg[13] +1; else cnt_chg[13] <= cnt_chg[13]; 
				if(SEG_CHG[22]) cnt_chg[14] <=cnt_chg[14] +1; else cnt_chg[14] <= cnt_chg[14]; 
				if(SEG_CHG[24]) cnt_chg[15] <=cnt_chg[15] +1; else cnt_chg[15] <= cnt_chg[15]; 
				if(SEG_CHG[25]) cnt_chg[16] <=cnt_chg[16] +1; else cnt_chg[16] <= cnt_chg[16]; 
				if(SEG_CHG[26]) cnt_chg[17] <=cnt_chg[17] +1; else cnt_chg[17] <= cnt_chg[17]; 
				if(SEG_CHG[27]) cnt_chg[18] <=cnt_chg[18] +1; else cnt_chg[18] <= cnt_chg[18]; 
				if(SEG_CHG[28]) cnt_chg[19] <=cnt_chg[19] +1; else cnt_chg[19] <= cnt_chg[19]; 
				if(SEG_CHG[29]) cnt_chg[20] <=cnt_chg[20] +1; else cnt_chg[20] <= cnt_chg[20]; 
				if(SEG_CHG[30]) cnt_chg[21] <=cnt_chg[21] +1; else cnt_chg[21] <= cnt_chg[21]; 
				if(SEG_CHG[31]) cnt_chg[22] <=cnt_chg[22] +1; else cnt_chg[22] <= cnt_chg[22]; 
				if(SEG_CHG[32]) cnt_chg[23] <=cnt_chg[23] +1; else cnt_chg[23] <= cnt_chg[23];
				if(SEG_CHG[9 ]) cnt_chg[24] <=cnt_chg[24] +1; else cnt_chg[24] <= cnt_chg[24]; 
				if(SEG_CHG[11]) cnt_chg[25] <=cnt_chg[25] +1; else cnt_chg[25] <= cnt_chg[25]; 
				if(SEG_CHG[13]) cnt_chg[26] <=cnt_chg[26] +1; else cnt_chg[26] <= cnt_chg[26]; 
				if(SEG_CHG[15]) cnt_chg[27] <=cnt_chg[27] +1; else cnt_chg[27] <= cnt_chg[27]; 
				if(SEG_CHG[17]) cnt_chg[28] <=cnt_chg[28] +1; else cnt_chg[28] <= cnt_chg[28]; 
				if(SEG_CHG[19]) cnt_chg[29] <=cnt_chg[29] +1; else cnt_chg[29] <= cnt_chg[29]; 
				if(SEG_CHG[21]) cnt_chg[30] <=cnt_chg[30] +1; else cnt_chg[30] <= cnt_chg[30]; 
				if(SEG_CHG[23]) cnt_chg[31] <=cnt_chg[31] +1; else cnt_chg[31] <= cnt_chg[31]; 
			end
			else if(w_segmode ==2'b01)begin
				if(SEG_CHG[2 ]) cnt_chg[00] <=cnt_chg[00] +1; else cnt_chg[00] <= cnt_chg[00]; 
				if(SEG_CHG[4 ]) cnt_chg[01] <=cnt_chg[01] +1; else cnt_chg[01] <= cnt_chg[01]; 
				if(SEG_CHG[6 ]) cnt_chg[02] <=cnt_chg[02] +1; else cnt_chg[02] <= cnt_chg[02]; 
				if(SEG_CHG[8 ]) cnt_chg[03] <=cnt_chg[03] +1; else cnt_chg[03] <= cnt_chg[03]; 
				if(SEG_CHG[10]) cnt_chg[04] <=cnt_chg[04] +1; else cnt_chg[04] <= cnt_chg[04]; 
				if(SEG_CHG[12]) cnt_chg[05] <=cnt_chg[05] +1; else cnt_chg[05] <= cnt_chg[05]; 
				if(SEG_CHG[14]) cnt_chg[06] <=cnt_chg[06] +1; else cnt_chg[06] <= cnt_chg[06]; 
				if(SEG_CHG[16]) cnt_chg[07] <=cnt_chg[07] +1; else cnt_chg[07] <= cnt_chg[07]; 
				if(SEG_CHG[18]) cnt_chg[08] <=cnt_chg[08] +1; else cnt_chg[08] <= cnt_chg[08]; 
				if(SEG_CHG[20]) cnt_chg[09] <=cnt_chg[09] +1; else cnt_chg[09] <= cnt_chg[09]; 
				if(SEG_CHG[22]) cnt_chg[10] <=cnt_chg[10] +1; else cnt_chg[10] <= cnt_chg[10]; 
				if(SEG_CHG[24]) cnt_chg[11] <=cnt_chg[11] +1; else cnt_chg[11] <= cnt_chg[11]; 
				if(SEG_CHG[26]) cnt_chg[12] <=cnt_chg[12] +1; else cnt_chg[12] <= cnt_chg[12]; 
				if(SEG_CHG[28]) cnt_chg[13] <=cnt_chg[13] +1; else cnt_chg[13] <= cnt_chg[13]; 
				if(SEG_CHG[30]) cnt_chg[14] <=cnt_chg[14] +1; else cnt_chg[14] <= cnt_chg[14]; 
				if(SEG_CHG[32]) cnt_chg[15] <=cnt_chg[15] +1; else cnt_chg[15] <= cnt_chg[15];
				if(SEG_CHG[1 ]) cnt_chg[16] <=cnt_chg[16] +1; else cnt_chg[16] <= cnt_chg[16]; 
				if(SEG_CHG[3 ]) cnt_chg[17] <=cnt_chg[17] +1; else cnt_chg[17] <= cnt_chg[17]; 
				if(SEG_CHG[5 ]) cnt_chg[18] <=cnt_chg[18] +1; else cnt_chg[18] <= cnt_chg[18]; 
				if(SEG_CHG[7 ]) cnt_chg[19] <=cnt_chg[19] +1; else cnt_chg[19] <= cnt_chg[19]; 
				if(SEG_CHG[9 ]) cnt_chg[20] <=cnt_chg[20] +1; else cnt_chg[20] <= cnt_chg[20]; 
				if(SEG_CHG[11]) cnt_chg[21] <=cnt_chg[21] +1; else cnt_chg[21] <= cnt_chg[21]; 
				if(SEG_CHG[13]) cnt_chg[22] <=cnt_chg[22] +1; else cnt_chg[22] <= cnt_chg[22]; 
				if(SEG_CHG[15]) cnt_chg[23] <=cnt_chg[23] +1; else cnt_chg[23] <= cnt_chg[23]; 
				if(SEG_CHG[17]) cnt_chg[24] <=cnt_chg[24] +1; else cnt_chg[24] <= cnt_chg[24]; 
				if(SEG_CHG[19]) cnt_chg[25] <=cnt_chg[25] +1; else cnt_chg[25] <= cnt_chg[25]; 
				if(SEG_CHG[21]) cnt_chg[26] <=cnt_chg[26] +1; else cnt_chg[26] <= cnt_chg[26]; 
				if(SEG_CHG[23]) cnt_chg[27] <=cnt_chg[27] +1; else cnt_chg[27] <= cnt_chg[27]; 
				if(SEG_CHG[25]) cnt_chg[28] <=cnt_chg[28] +1; else cnt_chg[28] <= cnt_chg[28]; 
				if(SEG_CHG[27]) cnt_chg[29] <=cnt_chg[29] +1; else cnt_chg[29] <= cnt_chg[29]; 
				if(SEG_CHG[29]) cnt_chg[30] <=cnt_chg[30] +1; else cnt_chg[30] <= cnt_chg[30]; 
				if(SEG_CHG[31]) cnt_chg[31] <=cnt_chg[31] +1; else cnt_chg[31] <= cnt_chg[31]; 
			end
			else if(w_segmode ==2'b00)begin
				if(SEG_CHG[1 ]) cnt_chg[00] <=cnt_chg[00] +1; else cnt_chg[00] <= cnt_chg[00]; 
				if(SEG_CHG[2 ]) cnt_chg[01] <=cnt_chg[01] +1; else cnt_chg[01] <= cnt_chg[01]; 
				if(SEG_CHG[3 ]) cnt_chg[02] <=cnt_chg[02] +1; else cnt_chg[02] <= cnt_chg[02]; 
				if(SEG_CHG[4 ]) cnt_chg[03] <=cnt_chg[03] +1; else cnt_chg[03] <= cnt_chg[03]; 
				if(SEG_CHG[5 ]) cnt_chg[04] <=cnt_chg[04] +1; else cnt_chg[04] <= cnt_chg[04]; 
				if(SEG_CHG[6 ]) cnt_chg[05] <=cnt_chg[05] +1; else cnt_chg[05] <= cnt_chg[05]; 
				if(SEG_CHG[7 ]) cnt_chg[06] <=cnt_chg[06] +1; else cnt_chg[06] <= cnt_chg[06]; 
				if(SEG_CHG[8 ]) cnt_chg[07] <=cnt_chg[07] +1; else cnt_chg[07] <= cnt_chg[07]; 
				if(SEG_CHG[9 ]) cnt_chg[08] <=cnt_chg[08] +1; else cnt_chg[08] <= cnt_chg[08]; 
				if(SEG_CHG[10]) cnt_chg[09] <=cnt_chg[09] +1; else cnt_chg[09] <= cnt_chg[09]; 
				if(SEG_CHG[11]) cnt_chg[10] <=cnt_chg[10] +1; else cnt_chg[10] <= cnt_chg[10]; 
				if(SEG_CHG[12]) cnt_chg[11] <=cnt_chg[11] +1; else cnt_chg[11] <= cnt_chg[11]; 
				if(SEG_CHG[13]) cnt_chg[12] <=cnt_chg[12] +1; else cnt_chg[12] <= cnt_chg[12]; 
				if(SEG_CHG[14]) cnt_chg[13] <=cnt_chg[13] +1; else cnt_chg[13] <= cnt_chg[13]; 
				if(SEG_CHG[15]) cnt_chg[14] <=cnt_chg[14] +1; else cnt_chg[14] <= cnt_chg[14]; 
				if(SEG_CHG[16]) cnt_chg[15] <=cnt_chg[15] +1; else cnt_chg[15] <= cnt_chg[15]; 
				if(SEG_CHG[17]) cnt_chg[16] <=cnt_chg[16] +1; else cnt_chg[16] <= cnt_chg[16]; 
				if(SEG_CHG[18]) cnt_chg[17] <=cnt_chg[17] +1; else cnt_chg[17] <= cnt_chg[17]; 
				if(SEG_CHG[19]) cnt_chg[18] <=cnt_chg[18] +1; else cnt_chg[18] <= cnt_chg[18]; 
				if(SEG_CHG[20]) cnt_chg[19] <=cnt_chg[19] +1; else cnt_chg[19] <= cnt_chg[19]; 
				if(SEG_CHG[21]) cnt_chg[20] <=cnt_chg[20] +1; else cnt_chg[20] <= cnt_chg[20]; 
				if(SEG_CHG[22]) cnt_chg[21] <=cnt_chg[21] +1; else cnt_chg[21] <= cnt_chg[21]; 
				if(SEG_CHG[23]) cnt_chg[22] <=cnt_chg[22] +1; else cnt_chg[22] <= cnt_chg[22]; 
				if(SEG_CHG[24]) cnt_chg[23] <=cnt_chg[23] +1; else cnt_chg[23] <= cnt_chg[23]; 
				if(SEG_CHG[25]) cnt_chg[24] <=cnt_chg[24] +1; else cnt_chg[24] <= cnt_chg[24]; 
				if(SEG_CHG[26]) cnt_chg[25] <=cnt_chg[25] +1; else cnt_chg[25] <= cnt_chg[25]; 
				if(SEG_CHG[27]) cnt_chg[26] <=cnt_chg[26] +1; else cnt_chg[26] <= cnt_chg[26]; 
				if(SEG_CHG[28]) cnt_chg[27] <=cnt_chg[27] +1; else cnt_chg[27] <= cnt_chg[27]; 
				if(SEG_CHG[29]) cnt_chg[28] <=cnt_chg[28] +1; else cnt_chg[28] <= cnt_chg[28]; 
				if(SEG_CHG[30]) cnt_chg[29] <=cnt_chg[29] +1; else cnt_chg[29] <= cnt_chg[29]; 
				if(SEG_CHG[31]) cnt_chg[30] <=cnt_chg[30] +1; else cnt_chg[30] <= cnt_chg[30]; 
				if(SEG_CHG[32]) cnt_chg[31] <=cnt_chg[31] +1; else cnt_chg[31] <= cnt_chg[31];
			end
		end               
	end               
end
always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		for(j=0;j<32;j=j+1) begin
			seg[j[4:0]] 	<= 13'd0;
		end	
	end
	else begin
		if(	r_counter_ack)begin 
			if(w_fr== 0)begin
				for(j=0;j<32;j=j+1) begin
					seg[j[4:0]] 	<= cnt[j[4:0]]/8;
				end
			end
			else if(w_fr== 1)begin
				for(j=0;j<32;j=j+1) begin
					seg[j[4:0]] 	<= cnt[j[4:0]]/4;
				end
			end
			else if(w_fr== 2)begin
				for(j=0;j<32;j=j+1) begin
					seg[j[4:0]] 	<= cnt[j[4:0]]/2;
				end
			end
			else if(w_fr== 3)begin
				for(j=0;j<32;j=j+1) begin
					seg[j[4:0]] 	<= cnt[j[4:0]]/1;
				end
			end
		end
	end
end

always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		for(j=0;j<32;j=j+1) begin
			seg_chg[j[4:0]] 	<= 13'd0;
		end	
	end
	else begin
		if(	r_counter_ack_d2)begin 
			if(w_fr== 0)begin
				for(j=0;j<32;j=j+1) begin
					seg_chg[j[4:0]] 	<= cnt_chg[j[4:0]]/8 ;
				end
			end
			else if(w_fr== 1)begin
				for(j=0;j<32;j=j+1) begin
					seg_chg[j[4:0]] 	<= cnt_chg[j[4:0]]/4 ;
				end
			end
			else if(w_fr== 2)begin
				for(j=0;j<32;j=j+1) begin
					seg_chg[j[4:0]] 	<= cnt_chg[j[4:0]]/2 ;
				end
			end
			else if(w_fr== 3)begin
				for(j=0;j<32;j=j+1) begin
					seg_chg[j[4:0]] 	<= cnt_chg[j[4:0]]/1 ;
				end
			end
		end
	end
end

always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		for(l=0;l<10;l=l+1) begin
			grid[l[4:0]] 	<= 13'd0;
		end	
	end
	else begin
		if(	r_counter_ack)begin 
			if(w_fr== 0)begin
				for(l=0;l<10;l=l+1) begin
					grid[l[4:0]] 	<= cnt_grid[l[4:0]]/8;
				end
			end
			else if(w_fr== 1)begin
				for(l=0;l<10;l=l+1) begin
					grid[l[4:0]] 	<= cnt_grid[l[4:0]]/4;
				end
			end
			else if(w_fr== 2)begin
				for(l=0;l<10;l=l+1) begin
					grid[l[4:0]] 	<= cnt_grid[l[4:0]]/2;
				end
			end
			else if(w_fr== 3)begin
				for(l=0;l<10;l=l+1) begin
					grid[l[4:0]] 	<= cnt_grid[l[4:0]]/1;
				end
			end
		end
	end
end

always @ (posedge w_clk or negedge w_rstb) begin
	if(!w_rstb) begin
		for(n=0;n<10;n=n+1) begin
			grid_dchg[n[4:0]] 	<= 13'd0;
		end	
	end
	else begin
		if(	r_counter_ack_d2)begin 
			if(w_fr== 0)begin
				for(n=0;n<10;n=n+1) begin
					grid_dchg[n[4:0]] 	<= cnt_dchg[n[4:0]]/8 ;
				end
			end
			else if(w_fr== 1)begin
				for(n=0;n<10;n=n+1) begin
					grid_dchg[n[4:0]] 	<= cnt_dchg[n[4:0]]/4 ;
				end
			end
			else if(w_fr== 2)begin
				for(n=0;n<10;n=n+1) begin
					grid_dchg[n[4:0]] 	<= cnt_dchg[n[4:0]]/2 ;
				end
			end
			else if(w_fr== 3)begin
				for(n=0;n<10;n=n+1) begin
					grid_dchg[n[4:0]] 	<= cnt_dchg[n[4:0]]/1 ;
				end
			end
		end
	end
end

reg [7:0] mem[0:319]; 
always @(*)begin
	if(w_up_remap)begin
		for(m=0;m<320;m=m+1) begin
			mem[m]<=tb_top.u_chicago_chip.u_chicago_dig.u_dis_mem_0.u_sp_320x8_wrap.I_MEM.mem[m];
		end
	end
	else begin
		for(m=0;m<320;m=m+1) begin
			mem[m]<=tb_top.u_chicago_chip.u_chicago_dig.u_dis_mem_1.u_sp_320x8_wrap.I_MEM.mem[m];
		end
	end
end

`ifdef ASSERT_SEG_COMP
always @ (posedge w_clk) begin
	for(ii=1; ii<=10; ii=ii+1) begin
		if(r_st_dead_t_array_d2[ii])begin //w_st_dead_t_array[ii]&& ~r_counter_ack)begin 
			if(w_segmode ==2'b11)begin
				for(jj=0; jj<32; jj=jj+1) begin
					if (seg[jj] !== mem[(ii-1)*32+jj]) begin
						$display($stime,"ns: GRID%2d Error: %2d-th seg. count 0x%2h is not matched to dimming data 0x%2h", ii, jj, seg[jj], mem[(ii-1)*32+jj]);
						$finish;
					end
					if (((seg[jj]+2) != seg_chg[jj]) && (seg[jj] !=0) && (seg_chg[jj]!=0)) begin
						$display($stime,"ns: GRID%2d Error: %2d-th seg. count 0x%2h is not matched to seg_chg count 0x%2h", ii, jj, seg[jj], seg_chg[jj]);
						$finish;
					end
				end
			end
			else if(w_segmode ==2'b10)begin
				for(jj=0; jj<24; jj=jj+1) begin
					if (seg[jj] !== mem[(ii-1)*32+jj]) begin
						$display($stime,"ns: GRID%2d Error: %2d-th seg. count 0x%2h is not matched to dimming data 0x%2h", ii, jj, seg[jj], mem[(ii-1)*32+jj]);
						$finish;
					end
					if (((seg[jj]+2) != seg_chg[jj]) && (seg[jj] !=0) && (seg_chg[jj]!=0)) begin
						$display($stime,"ns: GRID%2d Error: %2d-th seg. count 0x%2h is not matched to seg_chg count 0x%2h", ii, jj, seg[jj], seg_chg[jj]);
						$finish;
					end
				end
			end
			else if(w_segmode ==2'b01)begin
				for(jj=0; jj<16; jj=jj+1) begin
					if (seg[jj] !== mem[(ii-1)*32+jj]) begin
						$display($stime,"ns: GRID%2d Error: %2d-th seg. count 0x%2h is not matched to dimming data 0x%2h", ii, jj, seg[jj], mem[(ii-1)*32+jj]);
						$finish;
					end
					if (((seg[jj]+2) != seg_chg[jj]) && (seg[jj] !=0) && (seg_chg[jj]!=0)) begin
						$display($stime,"ns: GRID%2d Error: %2d-th seg. count 0x%2h is not matched to seg_chg count 0x%2h", ii, jj, seg[jj], seg_chg[jj]);
						$finish;
					end
				end
			end
			else if(w_segmode ==2'b00)begin
				for(jj=0; jj<32; jj=jj+1) begin
					if (seg[jj] !== mem[(ii-1)*32+jj]) begin
						$display($stime,"ns: GRID%2d Error: %2d-th seg. count 0x%2h is not matched to dimming data 0x%2h", ii, jj, seg[jj], mem[(ii-1)*32+jj]);
						$finish;
					end
					if (((seg[jj]+2) != seg_chg[jj]) && (seg[jj] !=0) && (seg_chg[jj]!=0)) begin
						$display($stime,"ns: GRID%2d Error: %2d-th seg. count 0x%2h is not matched to seg_chg count 0x%3h", ii, jj, seg[jj], seg_chg[jj]);
						$finish;
					end
				end
			end
		end
	end
end

always @ (posedge w_clk) begin
	for(ii=1; ii<=10; ii=ii+1) begin
		if(r_st_dead_t_array_d2[ii])begin //w_st_dead_t_array[ii]&& ~r_counter_ack)begin 
			if(grid[ii-1] !='hff) begin 
				$display($stime,"ns: GRID%2d Error count 0x%2h:",ii, grid[ii-1]);
				$finish;
			end
			else begin
				if(grid[1]+grid[2]+grid[3]+grid[4]+grid[5]+grid[6]+grid[7]+grid[8]+grid[9]+grid[0] !='hff)begin
					$display($stime,"ns:Error: GRIDs other than GRID%2d must not be ON.",ii);
				end
			end

			if(grid_dchg[ii-1] !='h101)begin 
				$display($stime,"ns: GRID_DCHG%2d Error count 0x%3h:",ii, grid_dchg[ii-1]);
				$finish;
			end 
		end
	end
end

`endif

`ifdef MANUAL_DISP_UPDATE 
//always @ (*)begin
always @ (posedge w_clk) begin
	if(w_st_dead_t01 && ~w_ne_dead_t01)begin
	$display("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");
	$display("//////\t\tGN= %d\tFR=%d\t//////////////////////////////////////",w_gn,w_fr);
	$display("\t\tS01  S02  S03  S04  S05  S06  S07  S08  S09  S10  S11  S12  S13  S14  S15  S16  S17  S18  S19  S20  S21  S22  S23  S24  S25  S26  S27  S28  S29  S30  S31  S32  ");
	$display("\tGRID01: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t02 && ~w_ne_dead_t02)begin
	$display("\tGRID02: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t03 && ~w_ne_dead_t03)begin 
	$display("\tGRID03: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t04 && ~w_ne_dead_t04)begin 
	$display("\tGRID04: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t05 && ~w_ne_dead_t05)begin 
	$display("\tGRID05: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t06 && ~w_ne_dead_t06)begin 
	$display("\tGRID06: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t07 && ~w_ne_dead_t07)begin 
	$display("\tGRID07: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t08 && ~w_ne_dead_t08)begin 
	$display("\tGRID08: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t09 && ~w_ne_dead_t09)begin 
	$display("\tGRID09: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t10 && ~w_ne_dead_t10)begin 
	$display("\tGRID10: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); 
end
end

`elsif DISP_SEG_CNT
//always @ (*)begin
always @ (posedge w_clk) begin
	if(w_st_dead_t01 && ~w_ne_dead_t01)begin
	$display("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");
	$display("//////\t\tGN= %d\tFR=%d\t//////////////////////////////////////",w_gn,w_fr);
	$display("\t\tS01  S02  S03  S04  S05  S06  S07  S08  S09  S10  S11  S12  S13  S14  S15  S16  S17  S18  S19  S20  S21  S22  S23  S24  S25  S26  S27  S28  S29  S30  S31  S32  ");
	$display("\tGRID01: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t02 && ~w_ne_dead_t02)begin
	$display("\tGRID02: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t03 && ~w_ne_dead_t03)begin 
	$display("\tGRID03: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t04 && ~w_ne_dead_t04)begin 
	$display("\tGRID04: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t05 && ~w_ne_dead_t05)begin 
	$display("\tGRID05: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t06 && ~w_ne_dead_t06)begin 
	$display("\tGRID06: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t07 && ~w_ne_dead_t07)begin 
	$display("\tGRID07: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t08 && ~w_ne_dead_t08)begin 
	$display("\tGRID08: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t09 && ~w_ne_dead_t09)begin 
	$display("\tGRID09: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
	if(w_st_dead_t10 && ~w_ne_dead_t10)begin 
	$display("\tGRID10: 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h 0x%02h ",seg[00],seg[01],seg[02],seg[03],seg[04],seg[05],seg[06],seg[07],seg[08],seg[09],seg[10],seg[11],seg[12],seg[13],seg[14],seg[15],seg[16],seg[17],seg[18],seg[19],seg[20],seg[21],seg[22],seg[23],seg[24],seg[25],seg[26],seg[27],seg[28],seg[29],seg[30],seg[31]); end
end

`endif

															  
task test_seg_grid_if;
input  [3:0] num_grid;
input  [5:0] num_seg;
begin
	$display("[%d-GRID, %d-SEG IF TEST]", num_grid, num_seg);

	for (ii=0; ii<num_grid; ii=ii+1) begin
		for (jj=0; jj<num_seg; jj=jj+1) begin
			disp_data[ii*num_seg+jj] = ii*num_seg+jj;
		end
	end
	disp_write(num_grid*num_seg);
	//disp_write_idat(num_grid*num_seg, 8'hFf);

	//if (tb_top.u_chicago_chip.u_chicago_dig.u_dimming_ctrl.O_UPREMAP)
	//	reg_read_burst(16'h0, 10*32); //read full data
	//else
	//	reg_read_burst(16'h0, 10*32); //read full data
	reg_read_burst(16'h0, 10*32); //read full data

	for (ii=0; ii<10; ii=ii+1) begin
		for (jj=0; jj<32; jj=jj+1) begin
			if (ii < num_grid && jj < num_seg)  begin
				if (((ii*num_seg+jj) & 8'hFF) !== spi_brdata[ii*32+jj]) begin
					$display("SRAM0 wrong data read : 0x%03h address, 0x%02h wrote but 0x%02h read", 
				    	      ii*num_seg+jj, ((ii*num_seg+jj) & 8'hFF), spi_brdata[ii*32+jj]);
					$finish;
				end
			end
		end
	end
	$display("%2d-GRID, %2d-SEG IF mem. write successfully completed..", num_grid, num_seg);
end
endtask															  


endmodule                            
    
    
    
