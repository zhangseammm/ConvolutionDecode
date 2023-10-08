`define Metric_WIDTH 14
`define LLR_WIDTH    8
module viterbi_data_forward(
    clk,
    rst,
    LLR0,
    LLR1,
    data_in_v,
    back_info,
    back_info_v
);



    input                               clk;
    input                               rst;
    input   [`LLR_WIDTH-1:0]            LLR0;
    input   [`LLR_WIDTH-1:0]            LLR1;
    input                               data_in_v;
    output                              back_info_v;
    output  [63:0]                      back_info;  

	reg  [`Metric_WIDTH-1:0]			BM[3:0];//分支计算结果
    reg                                 add_en;	
	
    wire [`Metric_WIDTH-1:0]            state_new_up[63:0];
    wire [`Metric_WIDTH-1:0]            state_new_down[63:0];
    
    wire                beyound_en0,beyound_en1,beyound_en2,beyound_en3,beyound_en4,beyound_en5,beyound_en6,beyound_en7,beyound_en8,beyound_en9,beyound_en10,beyound_en11,beyound_en12,beyound_en13,beyound_en14,beyound_en15,beyound_en16,beyound_en17,beyound_en18,beyound_en19,beyound_en20,beyound_en21,beyound_en22,beyound_en23,beyound_en24,beyound_en25,beyound_en26,beyound_en27,beyound_en28,beyound_en29,beyound_en30,beyound_en31;
		wire  							IsUniform;
	  assign IsUniform = ((((beyound_en0|beyound_en1)|(beyound_en2|beyound_en3))|((beyound_en4|beyound_en5)|(beyound_en6||beyound_en7)))|(((beyound_en8|beyound_en9)|(beyound_en10|beyound_en11))|((beyound_en12|beyound_en13)|(beyound_en14|beyound_en15))))|((((beyound_en16|beyound_en17)|(beyound_en18|beyound_en19))|((beyound_en20|beyound_en21)|(beyound_en22|beyound_en23)))|(((beyound_en24|beyound_en25)|(beyound_en26|beyound_en27))|((beyound_en28|beyound_en29)|(beyound_en30|beyound_en31))));
	  //-----------------------------END----------------------------------------------------
	always@(posedge clk)
	begin
		if(rst)
		begin
			BM[0] <= `Metric_WIDTH 'd0;
			BM[1] <= `Metric_WIDTH 'd0;
			BM[2] <= `Metric_WIDTH 'd0;
			BM[3] <= `Metric_WIDTH 'd0;
		end
		if(data_in_v)
		begin
			BM[3] <= {{(`Metric_WIDTH-`LLR_WIDTH){LLR0[`LLR_WIDTH-1]}},LLR0[`LLR_WIDTH-1:0]} + {{(`Metric_WIDTH-`LLR_WIDTH){LLR1[`LLR_WIDTH-1]}},LLR1[`LLR_WIDTH-1:0]} ;
			BM[2] <= {{(`Metric_WIDTH-`LLR_WIDTH){LLR1[`LLR_WIDTH-1]}},LLR1[`LLR_WIDTH-1:0]} - {{(`Metric_WIDTH-`LLR_WIDTH){LLR0[`LLR_WIDTH-1]}},LLR0[`LLR_WIDTH-1:0]};
			BM[1] <= {{(`Metric_WIDTH-`LLR_WIDTH){LLR0[`LLR_WIDTH-1]}},LLR0[`LLR_WIDTH-1:0]} - {{(`Metric_WIDTH-`LLR_WIDTH){LLR1[`LLR_WIDTH-1]}},LLR1[`LLR_WIDTH-1:0]};
			BM[0] <= -({{(`Metric_WIDTH-`LLR_WIDTH){LLR1[`LLR_WIDTH-1]}},LLR1[`LLR_WIDTH-1:0]}+{{(`Metric_WIDTH-`LLR_WIDTH){LLR0[`LLR_WIDTH-1]}},LLR0[`LLR_WIDTH-1:0]});			
		end	
	end
	
	always@(posedge clk)begin
	    if(rst)
		    add_en<=1'd0;
		else
            add_en<=data_in_v;
    end			
/****************************************************************************/
/********************************  add_select  ******************************/
/****************************************************************************/	 
viterbi_add_select u_viterbi_add_select_0(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[0]),
    .branchB                      (BM[3]),
    .metricA_up                   (state_new_up[0]),          
    .metricA_down                 (state_new_down[0]),       
    .metricB_up                   (state_new_up[1]),
    .metricB_down                 (state_new_down[1]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[0]),     
    .new_metric_down_a            (state_new_down[0]),
    .new_metric_up_b              (state_new_up[32]),  
    .new_metric_down_b            (state_new_down[32]),
    .metric_out_selectA           (back_info[0]),
    .metric_out_selectB           (back_info[1]),
    .back_infoA                   (back_info[0]),         
    .back_infoB                   (back_info[32]),         
    .out_able                     (back_info_v),
    .beyound_en                   (beyound_en0)
);

viterbi_add_select u_viterbi_add_select_1(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[1]),
    .branchB                      (BM[2]),
    .metricA_up                   (state_new_up[2]),          
    .metricA_down                 (state_new_down[2]),       
    .metricB_up                   (state_new_up[3]),
    .metricB_down                 (state_new_down[3]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[1]),     
    .new_metric_down_a            (state_new_down[1]),
    .new_metric_up_b              (state_new_up[33]),  
    .new_metric_down_b            (state_new_down[33]),
    .metric_out_selectA           (back_info[2]),
    .metric_out_selectB           (back_info[3]),
    .back_infoA                   (back_info[1]),         
    .back_infoB                   (back_info[33]),         
    //.out_able                     (back_info_v),
    .beyound_en                   (beyound_en1)
);

viterbi_add_select u_viterbi_add_select_2(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[0]),
    .branchB                      (BM[3]),
    .metricA_up                   (state_new_up[4]),          
    .metricA_down                 (state_new_down[4]),       
    .metricB_up                   (state_new_up[5]),
    .metricB_down                 (state_new_down[5]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[2]),     
    .new_metric_down_a            (state_new_down[2]),
    .new_metric_up_b              (state_new_up[34]),  
    .new_metric_down_b            (state_new_down[34]),
    .metric_out_selectA           (back_info[4]),
    .metric_out_selectB           (back_info[5]),
    .back_infoA                   (back_info[2]),         
    .back_infoB                   (back_info[34]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en2)
);

viterbi_add_select u_viterbi_add_select_3(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[1]),
    .branchB                      (BM[2]),
    .metricA_up                   (state_new_up[6]),          
    .metricA_down                 (state_new_down[6]),       
    .metricB_up                   (state_new_up[7]),
    .metricB_down                 (state_new_down[7]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[3]),     
    .new_metric_down_a            (state_new_down[3]),
    .new_metric_up_b              (state_new_up[35]),  
    .new_metric_down_b            (state_new_down[35]),
    .metric_out_selectA           (back_info[6]),
    .metric_out_selectB           (back_info[7]),
    .back_infoA                   (back_info[3]),         
    .back_infoB                   (back_info[35]),         
    //.out_able                     (back_info_v),
    .beyound_en                   (beyound_en3)
);

viterbi_add_select u_viterbi_add_select_4(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[3]),
    .branchB                      (BM[0]),
    .metricA_up                   (state_new_up[8]),          
    .metricA_down                 (state_new_down[8]),       
    .metricB_up                   (state_new_up[9]),
    .metricB_down                 (state_new_down[9]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[4]),     
    .new_metric_down_a            (state_new_down[4]),
    .new_metric_up_b              (state_new_up[36]),  
    .new_metric_down_b            (state_new_down[36]),
    .metric_out_selectA           (back_info[8]),
    .metric_out_selectB           (back_info[9]),
    .back_infoA                   (back_info[4]),         
    .back_infoB                   (back_info[36]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en4)
);

viterbi_add_select u_viterbi_add_select_5(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[2]),
    .branchB                      (BM[1]),
    .metricA_up                   (state_new_up[10]),          
    .metricA_down                 (state_new_down[10]),       
    .metricB_up                   (state_new_up[11]),
    .metricB_down                 (state_new_down[11]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[5]),     
    .new_metric_down_a            (state_new_down[5]),
    .new_metric_up_b              (state_new_up[37]),  
    .new_metric_down_b            (state_new_down[37]),
    .metric_out_selectA           (back_info[10]),
    .metric_out_selectB           (back_info[11]),
    .back_infoA                   (back_info[5]),         
    .back_infoB                   (back_info[37]),         
    //.out_able                     (back_info_v),
    .beyound_en                   (beyound_en5)
);


viterbi_add_select u_viterbi_add_select_6(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[3]),
    .branchB                      (BM[0]),
    .metricA_up                   (state_new_up[12]),          
    .metricA_down                 (state_new_down[12]),       
    .metricB_up                   (state_new_up[13]),
    .metricB_down                 (state_new_down[13]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[6]),     
    .new_metric_down_a            (state_new_down[6]),
    .new_metric_up_b              (state_new_up[38]),  
    .new_metric_down_b            (state_new_down[38]),
    .metric_out_selectA           (back_info[12]),
    .metric_out_selectB           (back_info[13]),
    .back_infoA                   (back_info[6]),         
    .back_infoB                   (back_info[38]),         
    //.out_able                     (back_info_v),
    .beyound_en                   (beyound_en6)
);

viterbi_add_select u_viterbi_add_select_7(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[2]),
    .branchB                      (BM[1]),
    .metricA_up                   (state_new_up[14]),          
    .metricA_down                 (state_new_down[14]),       
    .metricB_up                   (state_new_up[15]),
    .metricB_down                 (state_new_down[15]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[7]),     
    .new_metric_down_a            (state_new_down[7]),
    .new_metric_up_b              (state_new_up[39]),  
    .new_metric_down_b            (state_new_down[39]),
    .metric_out_selectA           (back_info[14]),
    .metric_out_selectB           (back_info[15]),
    .back_infoA                   (back_info[7]),         
    .back_infoB                   (back_info[39]),         
    //.out_able                     (back_info_v),
    .beyound_en                   (beyound_en7)
);

viterbi_add_select u_viterbi_add_select_8(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[3]),
    .branchB                      (BM[0]),
    .metricA_up                   (state_new_up[16]),          
    .metricA_down                 (state_new_down[16]),       
    .metricB_up                   (state_new_up[17]),
    .metricB_down                 (state_new_down[17]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[8]),     
    .new_metric_down_a            (state_new_down[8]),
    .new_metric_up_b              (state_new_up[40]),  
    .new_metric_down_b            (state_new_down[40]),
    .metric_out_selectA           (back_info[16]),
    .metric_out_selectB           (back_info[17]),
    .back_infoA                   (back_info[8]),         
    .back_infoB                   (back_info[40]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en8)
);

viterbi_add_select u_viterbi_add_select_9(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[2]),
    .branchB                      (BM[1]),
    .metricA_up                   (state_new_up[18]),          
    .metricA_down                 (state_new_down[18]),       
    .metricB_up                   (state_new_up[19]),
    .metricB_down                 (state_new_down[19]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[9]),     
    .new_metric_down_a            (state_new_down[9]),
    .new_metric_up_b              (state_new_up[41]),  
    .new_metric_down_b            (state_new_down[41]),
    .metric_out_selectA           (back_info[18]),
    .metric_out_selectB           (back_info[19]),
    .back_infoA                   (back_info[9]),         
    .back_infoB                   (back_info[41]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en9)
);

viterbi_add_select u_viterbi_add_select_10(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[3]),
    .branchB                      (BM[0]),
    .metricA_up                   (state_new_up[20]),          
    .metricA_down                 (state_new_down[20]),       
    .metricB_up                   (state_new_up[21]),
    .metricB_down                 (state_new_down[21]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[10]),     
    .new_metric_down_a            (state_new_down[10]),
    .new_metric_up_b              (state_new_up[42]),  
    .new_metric_down_b            (state_new_down[42]),
    .metric_out_selectA           (back_info[20]),
    .metric_out_selectB           (back_info[21]),
    .back_infoA                   (back_info[10]),         
    .back_infoB                   (back_info[42]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en10)
);

viterbi_add_select u_viterbi_add_select_11(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[2]),
    .branchB                      (BM[1]),
    .metricA_up                   (state_new_up[22]),          
    .metricA_down                 (state_new_down[22]),       
    .metricB_up                   (state_new_up[23]),
    .metricB_down                 (state_new_down[23]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[11]),     
    .new_metric_down_a            (state_new_down[11]),
    .new_metric_up_b              (state_new_up[43]),  
    .new_metric_down_b            (state_new_down[43]),
    .metric_out_selectA           (back_info[22]),
    .metric_out_selectB           (back_info[23]),
    .back_infoA                   (back_info[11]),         
    .back_infoB                   (back_info[43]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en11)
);

viterbi_add_select u_viterbi_add_select_12(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[0]),
    .branchB                      (BM[3]),
    .metricA_up                   (state_new_up[24]),          
    .metricA_down                 (state_new_down[24]),       
    .metricB_up                   (state_new_up[25]),
    .metricB_down                 (state_new_down[25]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[12]),     
    .new_metric_down_a            (state_new_down[12]),
    .new_metric_up_b              (state_new_up[44]),  
    .new_metric_down_b            (state_new_down[44]),
    .metric_out_selectA           (back_info[24]),
    .metric_out_selectB           (back_info[25]),
    .back_infoA                   (back_info[12]),         
    .back_infoB                   (back_info[44]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en12)
);

viterbi_add_select u_viterbi_add_select_13(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[1]),
    .branchB                      (BM[2]),
    .metricA_up                   (state_new_up[26]),          
    .metricA_down                 (state_new_down[26]),       
    .metricB_up                   (state_new_up[27]),
    .metricB_down                 (state_new_down[27]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[13]),     
    .new_metric_down_a            (state_new_down[13]),
    .new_metric_up_b              (state_new_up[45]),  
    .new_metric_down_b            (state_new_down[45]),
    .metric_out_selectA           (back_info[26]),
    .metric_out_selectB           (back_info[27]),
    .back_infoA                   (back_info[13]),         
    .back_infoB                   (back_info[45]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en13)
);

viterbi_add_select u_viterbi_add_select_14(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[0]),
    .branchB                      (BM[3]),
    .metricA_up                   (state_new_up[28]),          
    .metricA_down                 (state_new_down[28]),       
    .metricB_up                   (state_new_up[29]),
    .metricB_down                 (state_new_down[29]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[14]),     
    .new_metric_down_a            (state_new_down[14]),
    .new_metric_up_b              (state_new_up[46]),  
    .new_metric_down_b            (state_new_down[46]),
    .metric_out_selectA           (back_info[28]),
    .metric_out_selectB           (back_info[29]),
    .back_infoA                   (back_info[14]),         
    .back_infoB                   (back_info[46]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en14)
);

viterbi_add_select u_viterbi_add_select_15(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[1]),
    .branchB                      (BM[2]),
    .metricA_up                   (state_new_up[30]),          
    .metricA_down                 (state_new_down[30]),       
    .metricB_up                   (state_new_up[31]),
    .metricB_down                 (state_new_down[31]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[15]),     
    .new_metric_down_a            (state_new_down[15]),
    .new_metric_up_b              (state_new_up[47]),  
    .new_metric_down_b            (state_new_down[47]),
    .metric_out_selectA           (back_info[30]),
    .metric_out_selectB           (back_info[31]),
    .back_infoA                   (back_info[15]),         
    .back_infoB                   (back_info[47]),         
 //   .out_able                     (back_info_v),
    .beyound_en                   (beyound_en15)
);

viterbi_add_select u_viterbi_add_select_16(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[2]),
    .branchB                      (BM[1]),
    .metricA_up                   (state_new_up[32]),          
    .metricA_down                 (state_new_down[32]),       
    .metricB_up                   (state_new_up[33]),
    .metricB_down                 (state_new_down[33]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[16]),     
    .new_metric_down_a            (state_new_down[16]),
    .new_metric_up_b              (state_new_up[48]),  
    .new_metric_down_b            (state_new_down[48]),
    .metric_out_selectA           (back_info[32]),
    .metric_out_selectB           (back_info[33]),
    .back_infoA                   (back_info[16]),         
    .back_infoB                   (back_info[48]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en16)
);

viterbi_add_select u_viterbi_add_select_17(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[3]),
    .branchB                      (BM[0]),
    .metricA_up                   (state_new_up[34]),          
    .metricA_down                 (state_new_down[34]),       
    .metricB_up                   (state_new_up[35]),
    .metricB_down                 (state_new_down[35]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[17]),     
    .new_metric_down_a            (state_new_down[17]),
    .new_metric_up_b              (state_new_up[49]),  
    .new_metric_down_b            (state_new_down[49]),
    .metric_out_selectA           (back_info[34]),
    .metric_out_selectB           (back_info[35]),
    .back_infoA                   (back_info[17]),         
    .back_infoB                   (back_info[49]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en17)
);

viterbi_add_select u_viterbi_add_select_18(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[2]),
    .branchB                      (BM[1]),
    .metricA_up                   (state_new_up[36]),          
    .metricA_down                 (state_new_down[36]),       
    .metricB_up                   (state_new_up[37]),
    .metricB_down                 (state_new_down[37]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[18]),     
    .new_metric_down_a            (state_new_down[18]),
    .new_metric_up_b              (state_new_up[50]),  
    .new_metric_down_b            (state_new_down[50]),
    .metric_out_selectA           (back_info[36]),
    .metric_out_selectB           (back_info[37]),
    .back_infoA                   (back_info[18]),         
    .back_infoB                   (back_info[50]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en18)
);

viterbi_add_select u_viterbi_add_select_19(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[3]),
    .branchB                      (BM[0]),
    .metricA_up                   (state_new_up[38]),          
    .metricA_down                 (state_new_down[38]),       
    .metricB_up                   (state_new_up[39]),
    .metricB_down                 (state_new_down[39]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[19]),     
    .new_metric_down_a            (state_new_down[19]),
    .new_metric_up_b              (state_new_up[51]),  
    .new_metric_down_b            (state_new_down[51]),
    .metric_out_selectA           (back_info[38]),
    .metric_out_selectB           (back_info[39]),
    .back_infoA                   (back_info[19]),         
    .back_infoB                   (back_info[51]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en19)
);

viterbi_add_select u_viterbi_add_select_20(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[1]),
    .branchB                      (BM[2]),
    .metricA_up                   (state_new_up[40]),          
    .metricA_down                 (state_new_down[40]),       
    .metricB_up                   (state_new_up[41]),
    .metricB_down                 (state_new_down[41]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[20]),     
    .new_metric_down_a            (state_new_down[20]),
    .new_metric_up_b              (state_new_up[52]),
    .new_metric_down_b            (state_new_down[52]),  
    .metric_out_selectA           (back_info[40]),
    .metric_out_selectB           (back_info[41]),
    .back_infoA                   (back_info[20]),         
    .back_infoB                   (back_info[52]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en20)
);

viterbi_add_select u_viterbi_add_select_21(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[0]),
    .branchB                      (BM[3]),
    .metricA_up                   (state_new_up[42]),          
    .metricA_down                 (state_new_down[42]),       
    .metricB_up                   (state_new_up[43]),
    .metricB_down                 (state_new_down[43]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[21]),     
    .new_metric_down_a            (state_new_down[21]),
    .new_metric_up_b              (state_new_up[53]),  
    .new_metric_down_b            (state_new_down[53]),
    .metric_out_selectA           (back_info[42]),
    .metric_out_selectB           (back_info[43]),
    .back_infoA                   (back_info[21]),         
    .back_infoB                   (back_info[53]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en21)
);

viterbi_add_select u_viterbi_add_select_22(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[1]),
    .branchB                      (BM[2]),
    .metricA_up                   (state_new_up[44]),          
    .metricA_down                 (state_new_down[44]),       
    .metricB_up                   (state_new_up[45]),
    .metricB_down                 (state_new_down[45]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[22]),     
    .new_metric_down_a            (state_new_down[22]),
    .new_metric_up_b              (state_new_up[54]),  
    .new_metric_down_b            (state_new_down[54]),
    .metric_out_selectA           (back_info[44]),
    .metric_out_selectB           (back_info[45]),
    .back_infoA                   (back_info[22]),         
    .back_infoB                   (back_info[54]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en22)
);

viterbi_add_select u_viterbi_add_select_23(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[0]),
    .branchB                      (BM[3]),
    .metricA_up                   (state_new_up[46]),          
    .metricA_down                 (state_new_down[46]),       
    .metricB_up                   (state_new_up[47]),
    .metricB_down                 (state_new_down[47]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[23]),     
    .new_metric_down_a            (state_new_down[23]),
    .new_metric_up_b              (state_new_up[55]),  
    .new_metric_down_b            (state_new_down[55]),
    .metric_out_selectA           (back_info[46]),
    .metric_out_selectB           (back_info[47]),
    .back_infoA                   (back_info[23]),         
    .back_infoB                   (back_info[55]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en23)
);

viterbi_add_select u_viterbi_add_select_24(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[1]),
    .branchB                      (BM[2]),
    .metricA_up                   (state_new_up[48]),          
    .metricA_down                 (state_new_down[48]),       
    .metricB_up                   (state_new_up[49]),
    .metricB_down                 (state_new_down[49]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[24]),     
    .new_metric_down_a            (state_new_down[24]),
    .new_metric_up_b              (state_new_up[56]),  
    .new_metric_down_b            (state_new_down[56]),
    .metric_out_selectA           (back_info[48]),
    .metric_out_selectB           (back_info[49]),
    .back_infoA                   (back_info[24]),         
    .back_infoB                   (back_info[56]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en24)
);

viterbi_add_select u_viterbi_add_select_25(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[0]),
    .branchB                      (BM[3]),
    .metricA_up                   (state_new_up[50]),          
    .metricA_down                 (state_new_down[50]),       
    .metricB_up                   (state_new_up[51]),
    .metricB_down                 (state_new_down[51]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[25]),     
    .new_metric_down_a            (state_new_down[25]),
    .new_metric_up_b              (state_new_up[57]),  
    .new_metric_down_b            (state_new_down[57]),
    .metric_out_selectA           (back_info[50]),
    .metric_out_selectB           (back_info[51]),
    .back_infoA                   (back_info[25]),         
    .back_infoB                   (back_info[57]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en25)
);

viterbi_add_select u_viterbi_add_select_26(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[1]),
    .branchB                      (BM[2]),
    .metricA_up                   (state_new_up[52]),          
    .metricA_down                 (state_new_down[52]),       
    .metricB_up                   (state_new_up[53]),
    .metricB_down                 (state_new_down[53]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[26]),     
    .new_metric_down_a            (state_new_down[26]),
    .new_metric_up_b              (state_new_up[58]),  
    .new_metric_down_b            (state_new_down[58]),
    .metric_out_selectA           (back_info[52]),
    .metric_out_selectB           (back_info[53]),
    .back_infoA                   (back_info[26]),         
    .back_infoB                   (back_info[58]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en26)
);

viterbi_add_select u_viterbi_add_select_27(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[0]),
    .branchB                      (BM[3]),
    .metricA_up                   (state_new_up[54]),          
    .metricA_down                 (state_new_down[54]),       
    .metricB_up                   (state_new_up[55]),
    .metricB_down                 (state_new_down[55]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[27]),     
    .new_metric_down_a            (state_new_down[27]),
    .new_metric_up_b              (state_new_up[59]),  
    .new_metric_down_b            (state_new_down[59]),
    .metric_out_selectA           (back_info[54]),
    .metric_out_selectB           (back_info[55]),
    .back_infoA                   (back_info[27]),         
    .back_infoB                   (back_info[59]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en27)
);

viterbi_add_select u_viterbi_add_select_28(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[2]),
    .branchB                      (BM[1]),
    .metricA_up                   (state_new_up[56]),          
    .metricA_down                 (state_new_down[56]),       
    .metricB_up                   (state_new_up[57]),
    .metricB_down                 (state_new_down[57]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[28]),     
    .new_metric_down_a            (state_new_down[28]),
    .new_metric_up_b              (state_new_up[60]),  
    .new_metric_down_b            (state_new_down[60]),
    .metric_out_selectA           (back_info[56]),
    .metric_out_selectB           (back_info[57]),
    .back_infoA                   (back_info[28]),         
    .back_infoB                   (back_info[60]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en28)
);

viterbi_add_select u_viterbi_add_select_29(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[3]),
    .branchB                      (BM[0]),
    .metricA_up                   (state_new_up[58]),          
    .metricA_down                 (state_new_down[58]),       
    .metricB_up                   (state_new_up[59]),
    .metricB_down                 (state_new_down[59]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[29]),     
    .new_metric_down_a            (state_new_down[29]),
    .new_metric_up_b              (state_new_up[61]),  
    .new_metric_down_b            (state_new_down[61]),
    .metric_out_selectA           (back_info[58]),
    .metric_out_selectB           (back_info[59]),
    .back_infoA                   (back_info[29]),         
    .back_infoB                   (back_info[61]),         
  //  .out_able                     (back_info_v),
    .beyound_en                   (beyound_en29)
);

viterbi_add_select u_viterbi_add_select_30(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[2]),
    .branchB                      (BM[1]),
    .metricA_up                   (state_new_up[60]),          
    .metricA_down                 (state_new_down[60]),       
    .metricB_up                   (state_new_up[61]),
    .metricB_down                 (state_new_down[61]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[30]),     
    .new_metric_down_a            (state_new_down[30]),
    .new_metric_up_b              (state_new_up[62]),  
    .new_metric_down_b            (state_new_down[62]),
    .metric_out_selectA           (back_info[60]),
    .metric_out_selectB           (back_info[61]),
    .back_infoA                   (back_info[30]),         
    .back_infoB                   (back_info[62]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en30)
);

viterbi_add_select u_viterbi_add_select_31(
    .clk                          (clk),
    .rst                          (rst),
    .branchA                      (BM[3]),
    .branchB                      (BM[0]),
    .metricA_up                   (state_new_up[62]),          
    .metricA_down                 (state_new_down[62]),       
    .metricB_up                   (state_new_up[63]),
    .metricB_down                 (state_new_down[63]),
    .in_ena                       (add_en),
    .IsUniform                    (IsUniform),
    .new_metric_up_a              (state_new_up[31]),     
    .new_metric_down_a            (state_new_down[31]),
    .new_metric_up_b              (state_new_up[63]),  
    .new_metric_down_b            (state_new_down[63]),
    .metric_out_selectA           (back_info[62]),
    .metric_out_selectB           (back_info[63]),
    .back_infoA                   (back_info[31]),         
    .back_infoB                   (back_info[63]),         
   // .out_able                     (back_info_v),
    .beyound_en                   (beyound_en31)
);

endmodule