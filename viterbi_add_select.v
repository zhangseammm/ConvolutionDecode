`define Metric_WIDTH 14
`define NORMAL       1024

module viterbi_add_select(
    clk,
    rst,
    branchA,
    branchB,
    metricA_up,          //��ģ��������ĸ�����ֵ
    metricA_down,       //
    metricB_up,
    metricB_down,
    in_ena,
    IsUniform,
    new_metric_up_a,     //��ģ��������ĸ�����ֵ����8����ѡ����4����
    new_metric_down_a,
    new_metric_up_b,  
    new_metric_down_b,
    metric_out_selectA, //��8����ѡ��4����ָʾ�ź�
    metric_out_selectB,
    back_infoA,         //������Ϣ���
    back_infoB,         
    out_able,           //������Ϣʹ��
    beyound_en          //��һ��ʹ��
);

input                                            clk;
input                                            rst;
input            [`Metric_WIDTH-1:0]             branchA;
input            [`Metric_WIDTH-1:0]             branchB;
input            [`Metric_WIDTH-1:0]             metricA_up;        
input            [`Metric_WIDTH-1:0]             metricA_down;      
input            [`Metric_WIDTH-1:0]             metricB_up;
input            [`Metric_WIDTH-1:0]             metricB_down;
input                                            in_ena;
input                                            IsUniform;
input                                            metric_out_selectA; //��8����ѡ��4����ѡ���ź�
input                                            metric_out_selectB; //0��ʾ��·��1��ʾ��·

output    wire   [`Metric_WIDTH-1:0]             new_metric_up_a;   
output    wire   [`Metric_WIDTH-1:0]             new_metric_down_a;
output    wire   [`Metric_WIDTH-1:0]             new_metric_up_b;  
output    wire   [`Metric_WIDTH-1:0]             new_metric_down_b;
output    reg                                    back_infoA     ;       
output    reg                                    back_infoB     ;       
output    reg                                    out_able       ;          
output                                           beyound_en     ;       


reg             [`Metric_WIDTH-1:0]              up_metric_up_a;
reg             [`Metric_WIDTH-1:0]              up_metric_down_a;
reg             [`Metric_WIDTH-1:0]              up_metric_up_b;
reg             [`Metric_WIDTH-1:0]              up_metric_down_b;

reg             [`Metric_WIDTH-1:0]              down_metric_up_a;
reg             [`Metric_WIDTH-1:0]              down_metric_down_a;
reg             [`Metric_WIDTH-1:0]              down_metric_up_b;
reg             [`Metric_WIDTH-1:0]              down_metric_down_b;

reg             [`Metric_WIDTH-1:0]              reg_new_metric_up_a   ;   
reg             [`Metric_WIDTH-1:0]              reg_new_metric_down_a ;
reg             [`Metric_WIDTH-1:0]              reg_new_metric_up_b   ;  
reg             [`Metric_WIDTH-1:0]              reg_new_metric_down_b ;

//wire                                             metric_out_selectA; //��8����ѡ��4����ѡ���ź�
//wire                                             metric_out_selectB; //0��ʾ��·��1��ʾ��·

reg             [`Metric_WIDTH-1:0]              metric_newA;
reg             [`Metric_WIDTH-1:0]              metric_newB;
reg                                              select_en;
reg                                              compareA;
reg                                              compareB;

/*************************�Ӳ���***********************/
/*
    ����Ϊ�ĸ�����ֵ
    ���Ϊ8������ֵ
*/

always@(posedge clk)begin
    if(rst)begin
        up_metric_up_a      <=   `Metric_WIDTH 'd0 ;
        up_metric_down_a    <=   `Metric_WIDTH 'd0 ;
        up_metric_up_b      <=   `Metric_WIDTH 'd0 ;
        up_metric_down_b    <=   `Metric_WIDTH 'd0 ;
        down_metric_up_a    <=   `Metric_WIDTH 'd0 ;
        down_metric_down_a  <=   `Metric_WIDTH 'd0 ;
        down_metric_up_b    <=   `Metric_WIDTH 'd0 ;
        down_metric_down_b  <=   `Metric_WIDTH 'd0 ; 
    end
    else if(in_ena)begin
        if(~IsUniform)begin
            up_metric_up_a          <=  metricA_up + branchA;
            up_metric_down_a        <=  metricB_up + branchB;
            up_metric_up_b          <=  metricA_up + branchB;
            up_metric_down_b        <=  metricB_up + branchA;
            
            down_metric_up_a        <=  metricA_down + branchA;
            down_metric_down_a      <=  metricB_down + branchB;
            down_metric_up_b        <=  metricA_down + branchB;
            down_metric_down_b      <=  metricB_down + branchA;
 
        end
        else begin
            up_metric_up_a          <=  metricA_up + branchA   +`Metric_WIDTH'd`NORMAL ;
            up_metric_down_a        <=  metricB_up + branchB   +`Metric_WIDTH'd`NORMAL ;
            up_metric_up_b          <=  metricA_up + branchB   +`Metric_WIDTH'd`NORMAL ;
            up_metric_down_b        <=  metricB_up + branchA   +`Metric_WIDTH'd`NORMAL ;
                                                               
            down_metric_up_a        <=  metricA_down + branchA +`Metric_WIDTH'd`NORMAL ;
            down_metric_down_a      <=  metricB_down + branchB +`Metric_WIDTH'd`NORMAL ;
            down_metric_up_b        <=  metricA_down + branchB +`Metric_WIDTH'd`NORMAL ;
            down_metric_down_b      <=  metricB_down + branchA +`Metric_WIDTH'd`NORMAL ;   
        end
    end
end

/*************************�Ӱ˸�����ֵɸѡ���ĸ����б�ѡ����*******************************/
//assign  metric_out_selectA     =      back_infoA; 
//assign  metric_out_selectB     =      back_infoB;

assign  new_metric_up_a        = select_en ? ((metric_out_selectA == 1'd0) ? up_metric_up_a   : down_metric_up_a  ) :reg_new_metric_up_a  ;   
assign  new_metric_down_a      = select_en ? ((metric_out_selectB == 1'd0) ? up_metric_down_a : down_metric_down_a) :reg_new_metric_down_a;
assign  new_metric_up_b        = select_en ? ((metric_out_selectA == 1'd0) ? up_metric_up_b   : down_metric_up_b  ) :reg_new_metric_up_b  ;
assign  new_metric_down_b      = select_en ? ((metric_out_selectB == 1'd0) ? up_metric_down_b : down_metric_down_b) :reg_new_metric_down_b;

always@(posedge clk)begin
    if(rst)begin
        reg_new_metric_up_a    <= 'd0;
        reg_new_metric_down_a  <= 'd0;
        reg_new_metric_up_b    <= 'd0;
        reg_new_metric_down_b  <= 'd0;
    end
    
    else if(select_en)begin
        if(metric_out_selectA == 1'd0)begin
            reg_new_metric_up_a <= up_metric_up_a;
            reg_new_metric_up_b <= up_metric_up_b;
        end
        else begin
            reg_new_metric_up_a <= down_metric_up_a;
            reg_new_metric_up_b <= down_metric_up_b;
        end
        if(metric_out_selectB == 1'd0)begin
            reg_new_metric_down_a <= up_metric_down_a;
            reg_new_metric_down_b <= up_metric_down_b;
        end
        else begin
            reg_new_metric_down_a <= down_metric_down_a; 
            reg_new_metric_down_b <= down_metric_down_b;
        end
    end    
end

/********************************��ѡ����*********************************/
/*
    ����Ϊ�ĸ�����ֵ
    ���Ϊѡ����
    ͬʱ������Ķ���ֵɸѡ�ṩָʾ�ź�
*/

/**********��ѡʹ���ź�***************/
always@(posedge clk)begin
    if(rst)
        select_en <= 1'd0;
    else
        select_en <= in_ena;
end

/***************���ʹ���ź�**************/
always@(posedge clk)begin
    if(rst)
        out_able <= 1'd0;
    else
        out_able <= select_en;
end
/*
//���µ�metricֵ
always@(posedge clk)begin
    if(rst)
        metric_newA <= `Metric_WIDTH'd0;
	else if(select_en)begin
		if( new_metric_up_a[`Metric_WIDTH-1]^new_metric_down_a[`Metric_WIDTH-1] == 1'd1)begin
			if(new_metric_up_a[`Metric_WIDTH-1] == 1'd1)
				metric_newA <= new_metric_up_a;
			else
				metric_newA <= new_metric_down_a;
		end
		else if(new_metric_up_a < new_metric_down_a)
			metric_newA <= new_metric_up_a;
		else
			metric_newA <= new_metric_down_a;
	end
end

always@(posedge clk)begin
    if(rst)
        metric_newB <= `Metric_WIDTH'd0;
	else if(select_en)begin
		if( new_metric_up_b[`Metric_WIDTH-1]^new_metric_down_b[`Metric_WIDTH-1] == 1'd1)begin
			if(new_metric_up_b[`Metric_WIDTH-1] == 1'd1)
				metric_newB <= new_metric_up_b;
			else
				metric_newB <= new_metric_down_b;
		end
		else if(new_metric_up_b < new_metric_down_b)
			metric_newB <= new_metric_up_b;
		else
			metric_newB <= new_metric_down_b;
	end
end
*/

//���µ�back info��ֵ
always@(posedge clk)begin
    if(rst)
        back_infoA <= 1'd0;
	else if(select_en)begin
		if( new_metric_up_a[`Metric_WIDTH-1]^new_metric_down_a[`Metric_WIDTH-1] == 1'd1)begin
			if(new_metric_up_a[`Metric_WIDTH-1] == 1'd1)
				back_infoA <= 1'd0;
			else
				back_infoA <= 1'd1;
		end
		else if(new_metric_up_a < new_metric_down_a)
			back_infoA <= 1'd0;
		else
			back_infoA <= 1'd1;
	end
end

always@(posedge clk)begin
    if(rst)
        back_infoB <= 1'd0;
	else if(select_en)begin
		if( new_metric_up_b[`Metric_WIDTH-1]^new_metric_down_b[`Metric_WIDTH-1] == 1'd1)begin
			if(new_metric_up_b[`Metric_WIDTH-1] == 1'd1)
				back_infoB <= 1'd0;
			else
				back_infoB <= 1'd1;
		end
		else if(new_metric_up_b < new_metric_down_b)
			back_infoB <= 1'd0;
		else
			back_infoB <= 1'd1;
	end
end


assign  beyound_en= compareA|compareB;
always@(posedge clk)begin
    if(rst)
        compareA <= 1'b0;
    else if(reg_new_metric_up_a[`Metric_WIDTH-1] == 1'b0)
        compareA <= 1'b0;
    else if(reg_new_metric_up_a <= -`Metric_WIDTH 'd`NORMAL)
        compareA <= 1'b1;
    else 
        compareA <= 1'b0;
end

always@(posedge clk)begin
    if(rst)
        compareB <= 1'b0;
    else if(reg_new_metric_up_b[`Metric_WIDTH-1] == 1'b0)
        compareB <= 1'b0;
    else if(reg_new_metric_up_b <= -`Metric_WIDTH 'd`NORMAL)
        compareB <= 1'b1;
    else 
        compareB <= 1'b0;
end



endmodule
