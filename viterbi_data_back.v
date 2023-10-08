`define    RAM_WIDTH                        64
`define    RAM_DEPTH                        128
`define    RAM_DEPTH_x2                     256
`define    RAM_DEPTH_x3                     384
`define    RAM_DEPTH_x4                     512
`define    OUT_WIDTH                        128
`define    BACK_DEPTH                       256
`define    RAM_COUNT_WIDTH                  9
`define    COUNT_WIDTH                      9
`define    RAM_ADDR_WIDTH                   7 
`define    BACK_START                       280
`define    BACK_MID                         153
`define    BACK_END                         25
module viterbi_data_back(
    clk,
    rst,
    ram_din,
    ram_din_v,
    tail,
    viterbi_dout,
    viterbi_dout_v,
    last_v,
    last_length
);
/********************************输入输出信号**************************/
input                                                          clk;
input                                                          rst;
input                 [`RAM_WIDTH-1 : 0]                       ram_din;
input                                                          ram_din_v;
input                                                          tail;
output      reg       [`OUT_WIDTH-1 : 0]                       viterbi_dout;
output      reg                                                viterbi_dout_v;
output      reg                                                last_v;
output      reg       [7 : 0]                                  last_length;

/***********************************RAM信号定义*****************************************/
wire                  [`RAM_ADDR_WIDTH-1  : 0]                 ram_addra_1;
wire                  [`RAM_ADDR_WIDTH-1  : 0]                 ram_addra_2;
wire                  [`RAM_ADDR_WIDTH-1  : 0]                 ram_addra_3;
wire                  [`RAM_ADDR_WIDTH-1  : 0]                 ram_addra_4;
 
reg                   [`RAM_ADDR_WIDTH-1  : 0]                 ram_addrb_1;
reg                   [`RAM_ADDR_WIDTH-1  : 0]                 ram_addrb_2;
reg                   [`RAM_ADDR_WIDTH-1  : 0]                 ram_addrb_3;
reg                   [`RAM_ADDR_WIDTH-1  : 0]                 ram_addrb_4;

wire                                                           ram_wea_1; 
wire                                                           ram_wea_2; 
wire                                                           ram_wea_3; 
wire                                                           ram_wea_4; 

wire                                                           ram_enb_1; 
wire                                                           ram_enb_2; 
wire                                                           ram_enb_3; 
wire                                                           ram_enb_4;

wire                  [`RAM_WIDTH-1 : 0]                       ram_dout_1;
wire                  [`RAM_WIDTH-1 : 0]                       ram_dout_2;
wire                  [`RAM_WIDTH-1 : 0]                       ram_dout_3;
wire                  [`RAM_WIDTH-1 : 0]                       ram_dout_4;

/*****************************全局计数器，写数据和回溯都用到***************************/
reg                   [`RAM_COUNT_WIDTH-1 : 0]                 ram_count;

/*************************回溯变量*****************************/
reg                                                            back_ena;

reg                   [`COUNT_WIDTH-1:0]                       back_count_1;
reg                   [`COUNT_WIDTH-1:0]                       back_count_2;
reg                   [`COUNT_WIDTH-1:0]                       back_count_3;
reg                   [`COUNT_WIDTH-1:0]                       back_count_4;

reg                   [`RAM_WIDTH-1:0]                         back_info_1;
reg                   [`RAM_WIDTH-1:0]                         back_info_2;

reg                   [5:0]                                    back_state_1;
reg                   [5:0]                                    back_state_2;

reg                   [`BACK_DEPTH-1:0]                        back_out_1;
reg                   [`BACK_DEPTH-1:0]                        back_out_2;

/*******************************尾处理变量**********************************/
reg                                                            first_turn;
reg                   [`RAM_COUNT_WIDTH-1:0]                   tail_start;
reg                   [`RAM_COUNT_WIDTH-1:0]                   tail_size;
reg                                                            tailB;
reg                   [7:0]                                    tail_delay;
reg                   [`RAM_COUNT_WIDTH-1:0]                   tail_count;
reg                   [`RAM_COUNT_WIDTH-1:0]                   tail_addr;
reg                   [`RAM_COUNT_WIDTH-1:0]                   tail_addrB;
reg                   [`RAM_COUNT_WIDTH-1:0]                   tail_addrC;
reg                   [63:0]                                   tail_info;
reg                   [5:0]                                    tail_state;
reg                   [`BACK_DEPTH-1:0]                        tail_out;


/*******************************全局RAM计数 ram_count, 随使能信号循环计数*********************************/
always@(posedge clk)begin
    if(rst)
        ram_count <= `RAM_COUNT_WIDTH 'd0;
    else if(ram_din_v)
        ram_count <= ram_count + `RAM_COUNT_WIDTH 'd1;
end

/******************************向RAM里面写back_info数据**************************/
assign ram_wea_1 = (ram_count[`RAM_COUNT_WIDTH-1:`RAM_COUNT_WIDTH-2]==2'b00)?ram_din_v:1'd0;
assign ram_wea_2 = (ram_count[`RAM_COUNT_WIDTH-1:`RAM_COUNT_WIDTH-2]==2'b01)?ram_din_v:1'd0;
assign ram_wea_3 = (ram_count[`RAM_COUNT_WIDTH-1:`RAM_COUNT_WIDTH-2]==2'b10)?ram_din_v:1'd0;
assign ram_wea_4 = (ram_count[`RAM_COUNT_WIDTH-1:`RAM_COUNT_WIDTH-2]==2'b11)?ram_din_v:1'd0;

assign ram_addra_1 = ram_count[`RAM_ADDR_WIDTH-1:0];
assign ram_addra_2 = ram_count[`RAM_ADDR_WIDTH-1:0];
assign ram_addra_3 = ram_count[`RAM_ADDR_WIDTH-1:0];
assign ram_addra_4 = ram_count[`RAM_ADDR_WIDTH-1:0];



/*****************************从RAM里面读数据并回溯**********************************/

/*********普通回溯使能********/
always@(posedge clk)begin
    if(rst)
        back_ena <= 1'd0;
    else if(ram_count >= `COUNT_WIDTH 'd`RAM_DEPTH)
        back_ena <= 1'd1;
end

/**************回溯计数器控制**************/



always@(posedge clk)begin
    if(rst)
        back_count_1 <= `COUNT_WIDTH 'd0;
    else if(ram_count==(`COUNT_WIDTH 'd127) && ram_din_v == 1'd1 && tail==1'd0 && back_ena==1'd1)
        back_count_1 <= `COUNT_WIDTH 'd`BACK_START;
    else if(back_count_1 > `COUNT_WIDTH 'd0)
        back_count_1 <= back_count_1 - `COUNT_WIDTH 'd1;
end

always@(posedge clk)begin
    if(rst)
        back_count_2 <= `COUNT_WIDTH 'd0;
    else if(ram_count==(`COUNT_WIDTH 'd`RAM_DEPTH_x2-1) && ram_din_v == 1'd1 && tail==1'd0 && back_ena==1'd1)
        back_count_2 <= `COUNT_WIDTH 'd`BACK_START;
    else if(back_count_2 > `COUNT_WIDTH 'd0)
        back_count_2 <= back_count_2 - `COUNT_WIDTH 'd1;
end

always@(posedge clk)begin
    if(rst)
        back_count_3 <= `COUNT_WIDTH 'd0;
    else if(ram_count==(`COUNT_WIDTH 'd`RAM_DEPTH_x3-1) && ram_din_v == 1'd1 && tail==1'd0 && back_ena==1'd1)
        back_count_3 <= `COUNT_WIDTH 'd`BACK_START;
    else if(back_count_3 > `COUNT_WIDTH 'd0)
        back_count_3 <= back_count_3 - `COUNT_WIDTH 'd1;
end

always@(posedge clk)begin
    if(rst)
        back_count_4 <= `COUNT_WIDTH 'd0;
    else if(ram_count==(`COUNT_WIDTH 'd511) && ram_din_v == 1'd1 && tail==1'd0 && back_ena==1'd1)
        back_count_4 <= `COUNT_WIDTH 'd`BACK_START;
    else if(back_count_4 > `COUNT_WIDTH 'd0)
        back_count_4 <= back_count_4 - `COUNT_WIDTH 'd1;
end

/***************************从RAM中取数据开始回溯*******************************/

/************************RAM读使能************************/
assign ram_enb_1 = (((tail_count >=10 && tail_count <= tail_size +9) & (tail_addrB[8:7]==2'b00))|((back_count_1<=9'd`BACK_START && back_count_1>=9'd`BACK_MID)|(back_count_2<=(9'd`BACK_MID-1) && back_count_2>=9'd`BACK_END)))?1'd1:1'd0;
assign ram_enb_2 = (((tail_count >=10 && tail_count <= tail_size +9) & (tail_addrB[8:7]==2'b01))|((back_count_2<=9'd`BACK_START && back_count_2>=9'd`BACK_MID)|(back_count_3<=(9'd`BACK_MID-1) && back_count_3>=9'd`BACK_END)))?1'd1:1'd0;
assign ram_enb_3 = (((tail_count >=10 && tail_count <= tail_size +9) & (tail_addrB[8:7]==2'b10))|((back_count_3<=9'd`BACK_START && back_count_3>=9'd`BACK_MID)|(back_count_4<=(9'd`BACK_MID-1) && back_count_4>=9'd`BACK_END)))?1'd1:1'd0;
assign ram_enb_4 = (((tail_count >=10 && tail_count <= tail_size +9) & (tail_addrB[8:7]==2'b11))|((back_count_4<=9'd`BACK_START && back_count_4>=9'd`BACK_MID)|(back_count_1<=(9'd`BACK_MID-1) && back_count_1>=9'd`BACK_END)))?1'd1:1'd0;

/**********************RAM读地址***************************/
always@(posedge clk)begin
    if(rst)
        ram_addrb_1 <= `RAM_ADDR_WIDTH 'd127;
    else if((tail_count >=11 && tail_count <= tail_size +10)& (tail_addr[8:7]==2'b00))
        ram_addrb_1 <= tail_addr[6:0];
    else if(back_count_1<=9'd`BACK_START && back_count_1>=9'd`BACK_MID)
        ram_addrb_1 <= ram_addrb_1 - `RAM_ADDR_WIDTH 'd1;
    else if(back_count_2<=(9'd`BACK_MID-1) && back_count_2>=9'd`BACK_END)
        ram_addrb_1 <= ram_addrb_1 - `RAM_ADDR_WIDTH 'd1;
    else
        ram_addrb_1 <= (`RAM_ADDR_WIDTH 'd127);       
end

always@(posedge clk)begin
    if(rst)
        ram_addrb_2 <= (`RAM_ADDR_WIDTH 'd127);
    else if((tail_count >=11 && tail_count <= tail_size +10)& (tail_addr[8:7]==2'b01))
        ram_addrb_2 <= tail_addr[6:0];
    else if(back_count_2<=9'd`BACK_START && back_count_2>=9'd`BACK_MID)
        ram_addrb_2 <= ram_addrb_2 - `RAM_ADDR_WIDTH 'd1;
    else if(back_count_3<=(9'd`BACK_MID-1) && back_count_3>=9'd`BACK_END)
        ram_addrb_2 <= ram_addrb_2 - `RAM_ADDR_WIDTH 'd1;
    else
        ram_addrb_2 <= (`RAM_ADDR_WIDTH 'd127);       
end

always@(posedge clk)begin
    if(rst)
        ram_addrb_3 <= (`RAM_ADDR_WIDTH 'd127);
    else if((tail_count >=11 && tail_count <= tail_size +10)& (tail_addr[8:7]==2'b10))
        ram_addrb_3 <= tail_addr[6:0];
    else if(back_count_3<=9'd`BACK_START && back_count_3>=9'd`BACK_MID)
        ram_addrb_3 <= ram_addrb_3 - `RAM_ADDR_WIDTH 'd1;
    else if(back_count_4<=(9'd`BACK_MID-1) && back_count_4>=9'd`BACK_END)
        ram_addrb_3 <= ram_addrb_3 - `RAM_ADDR_WIDTH 'd1;
    else
        ram_addrb_3 <= (`RAM_ADDR_WIDTH 'd127);       
end

always@(posedge clk)begin
    if(rst)
        ram_addrb_4 <= (`RAM_ADDR_WIDTH 'd127);
    else if((tail_count >=11 && tail_count <= tail_size +10)& (tail_addr[8:7]==2'b11))
        ram_addrb_4 <= tail_addr[6:0];
    else if(back_count_4<=9'd`BACK_START && back_count_4>=9'd`BACK_MID)
        ram_addrb_4 <= ram_addrb_4 - `RAM_ADDR_WIDTH 'd1;
    else if(back_count_1<=(9'd`BACK_MID-1) && back_count_1>=9'd`BACK_END)
        ram_addrb_4 <= ram_addrb_4 - `RAM_ADDR_WIDTH 'd1;
    else
        ram_addrb_4 <= (`RAM_ADDR_WIDTH 'd127);       
end

/*********************获取回溯信息****************************/
//back_count_1和back_count_3共用back_info_1、back_state_1和back_out_1
//back_count_2和back_count_4共用back_info_2、back_state_2和back_out_2

always@(posedge clk)begin
    if(rst)
        back_info_1 <= `RAM_WIDTH 'd0;
    else if(back_count_1<=(9'd`BACK_START-1) && back_count_1>=(9'd`BACK_MID-1))
        back_info_1 <= ram_dout_1;
    else if(back_count_3<=(9'd`BACK_MID-2) && back_count_3>=(9'd`BACK_END-1))
        back_info_1 <= ram_dout_2;
    else if(back_count_3<=(9'd`BACK_START-1) && back_count_3>=(9'd`BACK_MID-1))
        back_info_1 <= ram_dout_3;
    else if(back_count_1<=(9'd`BACK_MID-2) && back_count_1>=(9'd`BACK_END-1))
        back_info_1 <= ram_dout_4;
end

always@(posedge clk)begin
    if(rst)
        back_info_2 <= `RAM_WIDTH 'd0;    
    else if(back_count_2<=(9'd`BACK_MID-2) && back_count_2>=(9'd`BACK_END-1))
        back_info_2 <= ram_dout_1;
    else if(back_count_2<=(9'd`BACK_START-1) && back_count_2>=(9'd`BACK_MID-1))
        back_info_2 <= ram_dout_2;
    else if(back_count_4<=(9'd`BACK_MID-2) && back_count_4>=(9'd`BACK_END-1))
        back_info_2 <= ram_dout_3;
    else if(back_count_4<=(9'd`BACK_START-1) && back_count_4>=(9'd`BACK_MID-1))
        back_info_2 <= ram_dout_4;
end

/*********************获取状态变换************************/
always@(posedge clk)begin
    if(rst)
        back_state_1 <= 6'd0;
    else if(back_count_1<=(9'd`BACK_START-2) && back_count_1>=(9'd`BACK_END-1))
        back_state_1 <= {back_state_1[4:0],back_info_1[back_state_1]};
    else if(back_count_1 == (9'd`BACK_END-2))
        back_state_1 <= 6'd0;
    else if(back_count_3<=(9'd`BACK_START-2) && back_count_3>=(9'd`BACK_END-1))
        back_state_1 <= {back_state_1[4:0],back_info_1[back_state_1]};
    else if(back_count_3 == (9'd`BACK_END-2))
        back_state_1 <= 6'd0;
end

always@(posedge clk)begin
    if(rst)
        back_state_2 <= 6'd0;
    else if(back_count_2<=(9'd`BACK_START-2) && back_count_2>=(9'd`BACK_END-1))
        back_state_2 <= {back_state_2[4:0],back_info_2[back_state_2]};
    else if(back_count_2 == (9'd`BACK_END-2))
        back_state_2 <= 6'd0;
    else if(back_count_4<=(9'd`BACK_START-2) && back_count_4>=(9'd`BACK_END-1))
        back_state_2 <= {back_state_2[4:0],back_info_2[back_state_2]};
    else if(back_count_4 == (9'd`BACK_END-2))
        back_state_2 <= 6'd0;
end

/**************************获取回溯结果****************************/
always@(posedge clk)begin
    if(rst)
        back_out_1 <= `BACK_DEPTH 'd0;
    else if(back_count_1<=(9'd`BACK_START-2) && back_count_1>=(9'd`BACK_END-2))
        back_out_1 <= {back_out_1[`BACK_DEPTH-2:0], back_state_1[5]};
    else if(back_count_3<=(9'd`BACK_START-2) && back_count_3>=(9'd`BACK_END-2))
        back_out_1 <= {back_out_1[`BACK_DEPTH-2:0], back_state_1[5]};
end

always@(posedge clk)begin
    if(rst)
        back_out_2 <= `BACK_DEPTH 'd0;
    else if(back_count_2<=(9'd`BACK_START-2) && back_count_2>=(9'd`BACK_END-2))
        back_out_2 <= {back_out_2[`BACK_DEPTH-2:0], back_state_2[5]};
    else if(back_count_4<=(9'd`BACK_START-2) && back_count_4>=(9'd`BACK_END-2))
        back_out_2 <= {back_out_2[`BACK_DEPTH-2:0], back_state_2[5]};
end




/***********************获取回溯的前 OUT_WIDTH 位作为输出结果****************************/
always@(posedge clk)begin
    if(rst)
        viterbi_dout_v <= 1'd0;
    else if(back_count_1 == (9'd`BACK_END-3) || back_count_3 == (9'd`BACK_END-3))
        viterbi_dout_v <= 1'd1;
    else if(back_count_2 == (9'd`BACK_END-3) || back_count_4 == (9'd`BACK_END-3))
        viterbi_dout_v <= 1'd1;
    else if(tail_count == 9'd7 && tail_size > 9'd128)
        viterbi_dout_v <= 1'd1;
    else if(tail_count == 9'd6 && tail_size >= 9'd1)
        viterbi_dout_v <= 1'd1;
    else
        viterbi_dout_v <= 1'd0;
end

always@(posedge clk)begin
    if(rst)begin
        viterbi_dout <= `OUT_WIDTH 'd0;
        last_length  <= 8'd0;
    end
    else if(back_count_1 == (9'd`BACK_END-3) || back_count_3 == (9'd`BACK_END-3))
        viterbi_dout <= back_out_1[`OUT_WIDTH-1:0];
    else if(back_count_2 == (9'd`BACK_END-3) || back_count_4 == (9'd`BACK_END-3))
        viterbi_dout <= back_out_2[`OUT_WIDTH-1:0];
    else if(tail_count == 9'd7 && tail_size > 9'd128)
        viterbi_dout <= tail_out[127:0];
    else if(tail_count == 9'd6)begin
        if(tail_size > 9'd128)begin
            last_length <= tail_size - 8'd128;
            viterbi_dout <= tail_out[255:128];
        end
        else if(tail_size >= 1'd1)begin
            last_length <= tail_size;
            viterbi_dout <= tail_out[127:0];
        end
    end
    else
        viterbi_dout <= `OUT_WIDTH 'd0;
end

/************************尾处理******************************/

/********判断是否越过了第一个RAM********/
always@(posedge clk)begin
    if(rst)
        first_turn <= 1'd0;
    else if(ram_count == `RAM_ADDR_WIDTH 'd127 && ram_din_v == 1'd1)
        first_turn <= 1'd1;
end

/********************获取回溯的起始地址******************/
always@(posedge clk)begin
    if(rst)
        tail_start <= `RAM_COUNT_WIDTH 'd0;
    else if(ram_din_v & tail)
        tail_start <= ram_count;
end

/********************获取回溯的个数**********************/
always@(posedge clk)begin
    if(rst)
        tail_size <= `RAM_COUNT_WIDTH 'd0;
    else if(ram_din_v & tail)begin
        if(first_turn)
            tail_size <= ram_count[`RAM_ADDR_WIDTH-1:0] + `RAM_DEPTH + 1;
        else
            tail_size <= ram_count[`RAM_ADDR_WIDTH-1:0] + 1;
    end
end

/***************尾处理回溯延迟，防止与之前的回溯过程冲突***************/
always@(posedge clk)begin
    if(rst)
        tailB <= 1'd0;
    else 
        tailB <= tail;
end

always@(posedge clk)begin
    if(rst)
        tail_delay <= 8'd0;
    else if(tailB && tail_size[`RAM_ADDR_WIDTH-1:0] == `RAM_ADDR_WIDTH 'd0)
        tail_delay <= 8'd1;
    else if(tailB && tail_size<=`RAM_DEPTH)
        tail_delay <= 8'd1;
    else if(tailB && tail_size>`RAM_DEPTH)
        tail_delay <= 8'd129 - tail_size[`RAM_ADDR_WIDTH-1:0];
    else if(tail_delay > 8'd0)
        tail_delay <= tail_delay - 8'd1;
    else 
        tail_delay <= 8'd0;
end

/***********************tail_delay 到1时开始回溯*************************/
always@(posedge clk)begin
    if(rst)begin
        tail_addr <= `RAM_COUNT_WIDTH 'd511;
        tail_count <= `RAM_COUNT_WIDTH 'd0;
    end
    else if(tail_delay == 8'd1)begin
        tail_addr <= tail_start;
        tail_count <= tail_size + 10;
    end
    else if(tail_count>=1 && tail_count <= tail_size+10)begin
        tail_addr <= tail_addr -1;
        tail_count <= tail_count -1;
    end
    else begin
        tail_addr <= `RAM_COUNT_WIDTH 'd511;
        tail_count <= `RAM_COUNT_WIDTH 'd0;
    end
end

/**************************获取回溯信息****************************/
always@(posedge clk)begin
    if(rst)
        tail_addrB <= 9'd511;
    else
        tail_addrB <= tail_addr;
end
always@(posedge clk)begin
    if(rst)
        tail_addrC <= 9'd511;
    else
        tail_addrC <= tail_addrB;
end
always@(posedge clk)begin
    if(rst)
        tail_info <= `RAM_DEPTH 'd0;
    else if(tail_count>=9 && tail_count<=tail_size+8)
        case(tail_addrC[8:7])
            2'b00: tail_info <= ram_dout_1;
            2'b01: tail_info <= ram_dout_2;
            2'b10: tail_info <= ram_dout_3;
            2'b11: tail_info <= ram_dout_4;
            default: tail_info <= `RAM_DEPTH 'd0;
        endcase
end

/***********************从tail_info获取回溯结果*************************/
/**********状态变化**********/
always@(posedge clk)begin
    if(rst)
        tail_state <= 6'd0;
    else if(tail_count>=9 && tail_count<=tail_size+7 )
        tail_state <= {tail_state[4:0], tail_info[tail_state]};
    else    
        tail_state <= 6'd0;
end

/*************获取输出**************/
always@(posedge clk)begin
    if(rst)
        tail_out <= `BACK_DEPTH 'd0;
    else if(tail_count>=8 && tail_count<=tail_size+7)
        tail_out <= {tail_out[`BACK_DEPTH-2:0], tail_state[5]};
end

always@(posedge clk)begin
    if(rst)
        last_v <= 1'd0;
    else if(tail_count == 9'd6)
        last_v <= 1'd1;
    else
        last_v <= 1'd0;
end

viterbi_ram_64_128  u_blk_ram_1(
    .addra(ram_addra_1),
    .clka(clk),
    .dina(ram_din),
    .wea(ram_wea_1),
    .addrb(ram_addrb_1),
    .clkb(clk),
    .doutb(ram_dout_1),
    .enb(ram_enb_1)
);
viterbi_ram_64_128  u_blk_ram_2(
    .addra(ram_addra_2),
    .clka(clk),
    .dina(ram_din),
    .wea(ram_wea_2),
    .addrb(ram_addrb_2),
    .clkb(clk),
    .doutb(ram_dout_2),
    .enb(ram_enb_2)
);
viterbi_ram_64_128  u_blk_ram_3(
    .addra(ram_addra_3),
    .clka(clk),
    .dina(ram_din),
    .wea(ram_wea_3),
    .addrb(ram_addrb_3),
    .clkb(clk),
    .doutb(ram_dout_3),
    .enb(ram_enb_3)
);
viterbi_ram_64_128  u_blk_ram_4(
    .addra(ram_addra_4),
    .clka(clk),
    .dina(ram_din),
    .wea(ram_wea_4),
    .addrb(ram_addrb_4),
    .clkb(clk),
    .doutb(ram_dout_4),
    .enb(ram_enb_4)
);

endmodule