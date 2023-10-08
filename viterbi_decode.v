`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2015/09/18 11:32:35
// Design Name: 
// Module Name: viterbi_decode
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

`define LLR_WIDTH    8

module viterbi_decode(
    clk              ,
	rst              ,
	LLR0             ,
	LLR1             ,
	data_in_v        ,
    tail             ,
	decode_out       ,
	decode_out_v     ,
    tail_v           ,
    tail_length      
	             
    );
input         clk            ;
input         rst            ;
input [`LLR_WIDTH-1:0]   LLR0           ;
input [`LLR_WIDTH-1:0]   LLR1           ;
input         data_in_v      ;
input         tail           ;
output[127:0] decode_out     ;
output        decode_out_v   ;
output        tail_v         ;	
output[7:0]   tail_length    ;
wire  [63:0]  ram_data_in    ;
wire          ram_data_in_v  ;	

reg tailA, tailB, tailC;

reg          last_v_delay;
reg          last_rst;
always@(posedge clk)begin
    if(rst)
        last_v_delay <= 1'd0;
    else
        last_v_delay <= tail_v;
end

always@(posedge clk)begin
    if(rst)
	    last_rst<=1'd1;
	else if(last_v_delay)
        last_rst<=1'd1;
    else 
        last_rst<=1'd0;	
end

viterbi_data_forward u_viterbi_data_forward(
    .clk         ( clk            ),
    .rst         ( last_rst       ),
    .LLR0        ( LLR0           ),
    .LLR1        ( LLR1           ),
    .data_in_v   ( data_in_v      ),
    .back_info   ( ram_data_in    ),
    .back_info_v ( ram_data_in_v  )
);
/*
ram_data_get u_ram_data_get(
    .clk         ( clk            ),
    .rst         ( rst            ),
    .LLR0        ( LLR0           ),
    .LLR1        ( LLR1           ),
    .data_in_v   ( data_in_v      ),
    .back_info   ( ram_data_in    ),
    .back_info_v ( ram_data_in_v  )
);
*/


viterbi_data_back u_viterbi_data_back(
    .clk             ( clk             ),
    .rst             ( last_rst        ),
    .ram_din         ( ram_data_in     ),
    .ram_din_v       ( ram_data_in_v   ),
    .tail            ( tailC           ),
    .viterbi_dout    ( decode_out      ),
    .viterbi_dout_v  ( decode_out_v    ),
    .last_v          ( tail_v          ),
    .last_length     ( tail_length     )
    );	

   
always @(posedge clk)begin
    if(rst)begin
        tailA  <= 1'd0;
        tailB  <= 1'd0;
        tailC  <= 1'd0;
    end
    else begin
        tailA <= tail;
        tailB <= tailA;
        tailC <= tailB;
    end
end
endmodule
