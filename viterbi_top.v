`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2015/11/03 09:31:21
// Design Name: 
// Module Name: viterbi_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module viterbi_top(
    clk                      ,
    rst                      ,
    isof                     ,
    viterbi_datain           ,
    viterbi_datain_v         ,
    R_viterbi                ,
    viterbi_data_length      ,                             
    viterbi_dataout          ,
    viterbi_dataout_v        ,
    osof                     
    );
input         clk                       ;
input         rst                       ;
input         isof                      ;
input [59:0]  viterbi_datain            ;
input         viterbi_datain_v          ;
input [1:0]   R_viterbi                 ;
input [19:0]  viterbi_data_length       ; 
                                       
output[7:0]   viterbi_dataout           ;
output        viterbi_dataout_v         ;
output        osof                      ;

reg   [19:0]  viterbi_datain_length     ;       //输入的长度计数
reg   [59:0]  viterbi_datain_delay      ;       //输入延迟1拍，实际中存入fifo的输入。
reg           viterbi_datain_v_delay    ;       //根据viterbi_data_length处理之后有效的使能
reg           isof_delay                ;
reg   [1:0]   R_viterbi_delay           ;
reg           viterbi_datain_end        ;                                       
reg   [19:0]  viterbi_datain_count     ;
reg           viterbi_datain_fifo_rd    ;
reg           viterbi_datain_fifo_rd_ff1;
reg           viterbi_datain_fifo_rd_ff2;
reg   [47:0]  viterbi_data_reg          ;
reg           isof_ff,isof_flag         ;
reg           three_fourth_state        ;
reg   [2:0]   viterbi_step_count        ; 

reg   [7:0]   LLR0                      ;
reg   [7:0]   LLR1                      ;
reg           data_in_v                 ;            
reg           tail,vend_ff,tail_flag    ; 
reg   [7:0]   viterbi_dataout           ;
reg           viterbi_dataout_v         ; 
reg   [247:0] decode_out_reg            ;        //储存decode_out以转化为8bit
reg   [7:0]   decode_out_reg_count      ;        //decode_out_reg中有效位的计数

reg   [7:0]   buff_LLR0                 ;        //缓存输入数据，再例化viterbi模块
reg   [7:0]   buff_LLR1                 ;
reg           buff_data_in_v            ;            
reg           buff_tail                 ; 

wire  [63:0]  viterbi_datain_fifo_data ;
wire          viterbi_datain_fifo_empty;

wire          osof                      ;
wire  [127:0]  decode_out                ;
wire          decode_out_v              ;
wire          tail_v                    ;	
wire  [7:0]   tail_length               ; 

parameter   one_second  =2'b00,
            two_third   =2'b01,
            three_fourth=2'b10,
			five_sixth  =2'b11;
/****************************************************************************/
/************************* 处理viterbi_data_length **************************/
/****************************************************************************/
always@(posedge clk)begin
    if(rst)
	    viterbi_datain_length<=20'd0;
	else if(isof & viterbi_datain_v)
        viterbi_datain_length<=20'd6;
	else if(viterbi_datain_length>viterbi_data_length)
        viterbi_datain_length<=viterbi_datain_length; 	
	else if(viterbi_datain_v==1'd1 && viterbi_datain_length!=20'd0)
        viterbi_datain_length<=viterbi_datain_length+20'd6; 	
end

always@(posedge clk)begin
    if(rst)
	    viterbi_datain_v_delay<=1'd0;
	else if(isof & viterbi_datain_v)
        viterbi_datain_v_delay<=1'd1;
	else if(viterbi_datain_length<viterbi_data_length && viterbi_datain_length!=20'd0)
        viterbi_datain_v_delay<=viterbi_datain_v;
    else
        viterbi_datain_v_delay<=1'd0;	
end

always@(posedge clk)begin
    if(rst)
	    viterbi_datain_delay<=60'd0;
	else 
        viterbi_datain_delay<=viterbi_datain;
end	

always@(posedge clk)begin
    if(rst)
	    isof_delay<=1'd0;
	else 
        isof_delay<=isof;
end		

always@(posedge clk)begin
    if(rst)
	    R_viterbi_delay<=2'd0;
	else 
        R_viterbi_delay<=R_viterbi;
end

always@(posedge clk)begin
    if(rst)
	    viterbi_datain_end<=1'd0;
	else if((viterbi_datain_length<viterbi_data_length) && (viterbi_datain_length+20'd6>=viterbi_data_length))
        viterbi_datain_end<=1'd1;
	else 
        viterbi_datain_end<=1'd0;	
end			
/****************************************************************************/
/*********************** viterbi_datain_delay的计数 *************************/
/****************************************************************************/
always@(posedge clk)begin
    if(rst)
	    viterbi_datain_count<=20'd0;
	else if(isof_delay & viterbi_datain_v_delay)
        viterbi_datain_count<=20'd1;
	else if(isof_delay & ~viterbi_datain_v_delay)
        viterbi_datain_count<=20'd0;	
    else if(viterbi_datain_v_delay)
        viterbi_datain_count<=(viterbi_datain_fifo_rd)?viterbi_datain_count:(viterbi_datain_count+20'd1);
	else if(viterbi_datain_fifo_rd)
        viterbi_datain_count<=viterbi_datain_count-20'd1;	
end		
/****************************************************************************/
/****************************** fifo 例化  **********************************/
/****************************************************************************/
viterbi_datain_fifo_64_1024 datain_fifo(
    .clk          ( clk                            ),  // input wire clk
	.rst          ( rst                            ),  // input wire rst
    .din          ( {viterbi_datain_end,R_viterbi_delay,isof_delay,viterbi_datain_delay}),  // input wire [63 : 0] din
    .wr_en        ( viterbi_datain_v_delay               ),  // input wire wr_en
    .rd_en        ( viterbi_datain_fifo_rd         ),  // input wire rd_en
    .dout         ( viterbi_datain_fifo_data       ),  // output wire [63 : 0] dout
    .full         (                                ),  // output wire full
    .empty        (                                ),  // output wire empty
    .almost_empty ( viterbi_datain_fifo_empty      )   // output wire almost_empty
    );			
/****************************************************************************/
/**************************   fifo rd信号的处理  ****************************/
/****************************************************************************/
always@(posedge clk)begin
    if(rst)
	    three_fourth_state<=1'd1;
    else if((viterbi_datain_fifo_rd_ff1==1'd1) &&(viterbi_datain_fifo_data[62:61]==three_fourth))
        three_fourth_state=~three_fourth_state;
end

always@(posedge clk)begin
    if(rst)
	    viterbi_step_count<=3'd0;
    else if(viterbi_step_count>=3'd5)
	    case(viterbi_datain_fifo_data[62:61])
		    one_second:   viterbi_step_count<=3'd0;
		    two_third:    viterbi_step_count<=(viterbi_step_count==3'd6)?3'd0:(viterbi_step_count+3'd1);
		    three_fourth: viterbi_step_count<=((three_fourth_state==1'd0) && (viterbi_step_count==3'd6))?3'd0:(viterbi_step_count+3'd1);
		    five_sixth:   viterbi_step_count<=viterbi_step_count+3'd1;             
		    default:      viterbi_step_count<=3'd0;
		endcase	    
	else 
        viterbi_step_count<=viterbi_step_count+3'd1;
end	

always@(posedge clk)begin
    if(rst)
	    viterbi_datain_fifo_rd<=1'd0;
    else if((viterbi_datain_count>=20'd1) && (viterbi_step_count==3'd0))
	    viterbi_datain_fifo_rd<=1'd1;
	else 
        viterbi_datain_fifo_rd<=1'd0;
end		

always@(posedge clk)begin
    if(rst)begin
	    viterbi_datain_fifo_rd_ff1<=1'd0;
		viterbi_datain_fifo_rd_ff2<=1'd0;
	end 	
    else begin     		
		viterbi_datain_fifo_rd_ff1<=viterbi_datain_fifo_rd;
		viterbi_datain_fifo_rd_ff2<=viterbi_datain_fifo_rd_ff1;
	end	
end		
			
/****************************************************************************/
/********************** 根据 R_viterbi 进行数据补孔输出 *********************/
/****************************************************************************/
always@(posedge clk)begin
    if(rst)
	    viterbi_data_reg<=48'd0;
	else if((viterbi_datain_fifo_rd_ff1==1'd1) && (viterbi_step_count==3'd2))	    
		viterbi_data_reg<={viterbi_datain_fifo_data[59:52],viterbi_datain_fifo_data[49:42],viterbi_datain_fifo_data[39:32],viterbi_datain_fifo_data[29:22],viterbi_datain_fifo_data[19:12],viterbi_datain_fifo_data[9:2]};
    else if((viterbi_datain_fifo_rd_ff1==1'd0) && (viterbi_step_count==3'd2))
	    viterbi_data_reg<=48'd0;
end				

always@(posedge clk)begin
    if(rst) 
	    data_in_v<=1'd0;
	else if(viterbi_step_count==3'd0)
        data_in_v<=1'd0;
    else if((viterbi_datain_fifo_rd_ff2==1'd1) && (viterbi_step_count==3'd3))
        data_in_v<=1'd1;	
end

always@(posedge clk)begin
    if(rst)
	    LLR0<=8'd0;
	else 	    
		case(viterbi_datain_fifo_data[62:61])
		    one_second:   if(viterbi_step_count==3'd3)               //(B2A2B1A1B0A0)6
                                LLR0<=viterbi_data_reg[7:0];
                          else if(viterbi_step_count==3'd4)
                                LLR0<=viterbi_data_reg[23:16];
                          else if(viterbi_step_count==3'd5)
                                LLR0<=viterbi_data_reg[39:32];							              
		    two_third:    if(viterbi_step_count==3'd3)               //(_A3B2A2_A1B0A0)8
                                LLR0<=viterbi_data_reg[7:0];
                          else if(viterbi_step_count==3'd4)
                                LLR0<=viterbi_data_reg[23:16];
                          else if(viterbi_step_count==3'd5)
                                LLR0<=viterbi_data_reg[31:24];
						  else if(viterbi_step_count==3'd6)
                                LLR0<=viterbi_data_reg[47:40];	
		    three_fourth: if(~three_fourth_state)begin               //(B3A3B2__A1B0A0)8
			                if(viterbi_step_count==3'd3)
                                LLR0<=viterbi_data_reg[7:0];
                            else if(viterbi_step_count==3'd4)
                                LLR0<=viterbi_data_reg[23:16];
                            else if(viterbi_step_count==3'd5)
                                LLR0<=8'd0;
						    else if(viterbi_step_count==3'd6)
                                LLR0<=viterbi_data_reg[39:32];
			              end
						  else if(three_fourth_state)begin           //(B4__A3B2A2B1__A0)10
			                if(viterbi_step_count==3'd3)
                                LLR0<=viterbi_data_reg[7:0];
                            else if(viterbi_step_count==3'd4)
                                LLR0<=8'd0;
                            else if(viterbi_step_count==3'd5)
                                LLR0<=viterbi_data_reg[23:16];
						    else if(viterbi_step_count==3'd6)
                                LLR0<=viterbi_data_reg[39:32];
							else if(viterbi_step_count==3'd7)
                                LLR0<=8'd0;	
			              end
		    five_sixth:   if(viterbi_step_count==3'd3)               //(B4__A3B2__A1B0A0)10
                                LLR0<=viterbi_data_reg[7:0];
                            else if(viterbi_step_count==3'd4)
                                LLR0<=viterbi_data_reg[23:16];
                            else if(viterbi_step_count==3'd5)
                                LLR0<=8'd0;
						    else if(viterbi_step_count==3'd6)
                                LLR0<=viterbi_data_reg[39:32];
							else if(viterbi_step_count==3'd7)
                                LLR0<=8'd0;             
		    default:      LLR0<=8'd0;
		endcase	    
end

always@(posedge clk)begin
    if(rst)
	    LLR1<=8'd0;
	else 	    
		case(viterbi_datain_fifo_data[62:61])
		    one_second:   if(viterbi_step_count==3'd3)               //(B2A2B1A1B0A0)6
                                LLR1<=viterbi_data_reg[15:8];
                          else if(viterbi_step_count==3'd4)
                                LLR1<=viterbi_data_reg[31:24];
                          else if(viterbi_step_count==3'd5)
                                LLR1<=viterbi_data_reg[47:40];							              
		    two_third:    if(viterbi_step_count==3'd3)               //(_A3B2A2_A1B0A0)8
                                LLR1<=viterbi_data_reg[15:8];
                          else if(viterbi_step_count==3'd4)
                                LLR1<=8'd0;
                          else if(viterbi_step_count==3'd5)
                                LLR1<=viterbi_data_reg[39:32];
						  else if(viterbi_step_count==3'd6)
                                LLR1<=8'd0;	
		    three_fourth: if(~three_fourth_state)begin               //(B3A3B2__A1B0A0)8
			                if(viterbi_step_count==3'd3)
                                LLR1<=viterbi_data_reg[15:8];
                            else if(viterbi_step_count==3'd4)
                                LLR1<=8'd0;
                            else if(viterbi_step_count==3'd5)
                                LLR1<=viterbi_data_reg[31:24];
						    else if(viterbi_step_count==3'd6)
                                LLR1<=viterbi_data_reg[47:40];
			              end
						  else if(three_fourth_state)begin           //(B4__A3B2A2B1__A0)10
			                if(viterbi_step_count==3'd3)
                                LLR1<=8'd0;
                            else if(viterbi_step_count==3'd4)
                                LLR1<=viterbi_data_reg[15:8];
                            else if(viterbi_step_count==3'd5)
                                LLR1<=viterbi_data_reg[31:24];
						    else if(viterbi_step_count==3'd6)
                                LLR1<=8'd0;
							else if(viterbi_step_count==3'd7)
                                LLR1<=viterbi_data_reg[47:40];	
			              end
		    five_sixth:   if(viterbi_step_count==3'd3)               //(B4__A3B2__A1B0A0)10
                                LLR1<=viterbi_data_reg[15:8];
                            else if(viterbi_step_count==3'd4)
                                LLR1<=8'd0;
                            else if(viterbi_step_count==3'd5)
                                LLR1<=viterbi_data_reg[31:24];
						    else if(viterbi_step_count==3'd6)
                                LLR1<=8'd0;
							else if(viterbi_step_count==3'd7)
                                LLR1<=viterbi_data_reg[47:40];             
		    default:      LLR1<=8'd0;
		endcase	    
end
/****************************************************************************/
/**********************         get tail and isof_flag       *********************/
/****************************************************************************/
always@(posedge clk)begin
    if(rst) 
	    vend_ff<=1'd0;
	else 
        vend_ff<=viterbi_datain_fifo_data[63];	
end

always@(posedge clk)begin
    if(rst) 
	    tail_flag<=1'd0;
	else if(viterbi_datain_fifo_data[63] & ~vend_ff) 
        tail_flag<=1'd1;
    else if(tail)
        tail_flag<=1'd0;	
end

always@(posedge clk)begin
    if(rst) 
	    tail<=1'd0;
	else if(tail)
        tail<=1'd0;	
	else if(tail_flag) 
        case(viterbi_datain_fifo_data[62:61])
		    one_second:   tail<=(viterbi_step_count==3'd5)?1'd1:1'd0;
		    two_third:    tail<=(viterbi_step_count==3'd6)?1'd1:1'd0;
		    three_fourth: if(~three_fourth_state)
			                tail<=(viterbi_step_count==3'd6)?1'd1:1'd0;
						  else if(three_fourth_state)
			                tail<=(viterbi_step_count==3'd7)?1'd1:1'd0;
		    five_sixth:   tail<=(viterbi_step_count==3'd7)?1'd1:1'd0;             
		    default:      tail<=1'd0;
		endcase	 	
end

always@(posedge clk)begin
    if(rst) 
	    isof_ff<=1'd0;
	else 
        isof_ff<=viterbi_datain_fifo_data[60];	
end

always@(posedge clk)begin
    if(rst) 
	    isof_flag<=1'd0;
	else if(viterbi_datain_fifo_data[60] & ~isof_ff) 
        isof_flag<=1'd1;
    else if(osof)
        isof_flag<=1'd0;	
end
/****************************************************************************/
/**********************   viterbi子模块输入数据缓存     *********************/
/****************************************************************************/
always@(posedge clk)begin
    if(rst) 
	    buff_LLR0<=1'd0;
    else
        buff_LLR0<=LLR0;	
end

always@(posedge clk)begin
    if(rst) 
	    buff_LLR1<=1'd0;
    else
        buff_LLR1<=LLR1;	
end

always@(posedge clk)begin
    if(rst) 
	    buff_data_in_v<=1'd0;
    else
        buff_data_in_v<=data_in_v;	
end

always@(posedge clk)begin
    if(rst) 
	    buff_tail<=1'd0;
    else
        buff_tail<=tail;	
end
/****************************************************************************/
/**********************      调用 viterbi 子模块        *********************/
/****************************************************************************/
viterbi_decode viterbi(
    .clk           ( clk               )  ,
	.rst           ( rst               )  ,
	.LLR0          ( buff_LLR0         )  ,
	.LLR1          ( buff_LLR1         )  ,
	.data_in_v     ( buff_data_in_v    )  ,
    .tail          ( buff_tail         )  ,
	.decode_out    ( decode_out        )  ,
	.decode_out_v  ( decode_out_v      )  ,
    .tail_v        ( tail_v            )  ,
    .tail_length   ( tail_length       )  	             
    );
/****************************************************************************/
/**********************       get viterbi_dataout and osof       *********************/
/****************************************************************************/
always@(posedge clk)begin
    if(rst) 
	    decode_out_reg<=248'd0;
	else if(decode_out_v & tail_v)
        decode_out_reg<={decode_out,decode_out_reg[127:8]};	
	else if(decode_out_v)
        decode_out_reg[127:0]<=decode_out;
    else if(decode_out_reg_count>8'd0)
        decode_out_reg<={8'd0,decode_out_reg[247:8]};	
end	

always@(posedge clk)begin
    if(rst) 
	    decode_out_reg_count<=8'd0;
	else if(decode_out_v & tail_v)
        decode_out_reg_count<=8'd120+tail_length[7:0];
	else if(decode_out_v)
        decode_out_reg_count<=8'd128;
    else if(decode_out_reg_count>=8'd8)
        decode_out_reg_count<=decode_out_reg_count-8'd8;
    else if(decode_out_reg_count<8'd8 &&decode_out_reg_count>8'd0)
        decode_out_reg_count<=8'd0;	
end

assign osof= viterbi_dataout_v & isof_flag;

always@(posedge clk)begin
    if(rst) 
	    viterbi_dataout_v<=1'd0;
    else if(decode_out_reg_count>8'd0)
        viterbi_dataout_v<=1'd1;
    else 
        viterbi_dataout_v<=1'd0;	
end	

always@(posedge clk)begin
    if(rst) 
	    viterbi_dataout<=8'd0;
    else if(decode_out_reg_count>8'd0)
        viterbi_dataout<=decode_out_reg[7:0];
    else 
        viterbi_dataout<=8'd0;	
end	

endmodule
