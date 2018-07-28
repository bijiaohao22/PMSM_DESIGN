`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/25
// Design Name:PMSM_DESIGN
// Module Name: clark_and_park_transaction.v
// Target Device:
// Tool versions:
// Description: �յ�ʹ���źź����Clark��Park�任����ȡIq��Id
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module clark_and_park_transaction(
                                  input    sys_clk,    //system clock
                                  input    reset_n,    //active-low,reset signal

                                  input    transaction_enable_in,  //ת��ʹ���ź�

                                  input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_in,   //  �����Ƕ�����ֵ
                                  input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_in,  //  �����Ƕ�����ֵ

                                  input    signed [`DATA_WIDTH-1:0]    phase_a_current_in,                      //  a��������ֵ
                                  input    signed [`DATA_WIDTH-1:0]    phase_b_current_in,                      //  b��������ֵ

                                  output    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_out,   //  �����Ƕ�����ֵ��������ڷ�Park�任
                                  output    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_out,  //  �����Ƕ�����ֵ���

                                  output  signed [`DATA_WIDTH-1:0]    current_q_out,                              //  Iq�������
                                  output  signed [`DATA_WIDTH-1:0]    current_d_out,                              //  Id�������
                                  output                                          transaction_valid_out                               //ת�������Ч�ź�
                                  );
//===========================================================================
//�ڲ���������
//===========================================================================
localparam FSM_IDLE=1<<0;                    //  ��ʼ״̬
localparam FSM_PARK_MULT=1<<1;    //   PARK�任�˷�����
localparam FSM_PARK_SUM=1<<2;      //    PARK�任��Ͳ���
localparam FSM_CAL_DONE = 1 << 3;      //    CLARK��PARKת�����״̬

//===========================================================================
//�ڲ���������
//===========================================================================
reg signed[`DATA_WIDTH-1:0]      current_alpha_r;        //  Ialpha����ֵ
reg signed[`DATA_WIDTH*2-1:0]  current_beta_r;      //  Ibeta����ֵ     ����ǣ�浽�˷�λ����չ
reg signed[`DATA_WIDTH*2-1:0]   multiplicand_r;    //  �������Ĵ���
reg signed[`DATA_WIDTH-1:0]       multipler_r;          //�����Ĵ���
reg signed[`DATA_WIDTH-1:0]       electrical_rotation_phase_sin_r;    //��Ƕ����ҼĴ���
reg signed[`DATA_WIDTH-1:0]       electrical_rotation_phase_cos_r;   //��Ƕ����ҼĴ���
reg signed[`DATA_WIDTH*3-1:0]       product_cache_r;                         //�˷����������Ĵ���
wire signed[`DATA_WIDTH*3-1:0]       product_w;                                //�˷����������
wire [`DATA_WIDTH*3:0]    product_sum_w;                                        //�˷�����������ͻ���
reg[4:0]   fsm_cs,
    fsm_ns;                                    //״̬���Ĵ���������һ״̬
reg           transaction_valid_r;                              //ת����ɱ�־�Ĵ���
reg[1:0]   delay_time_cnt;                                   //�˷����ӳټ���
reg  signed[`DATA_WIDTH-1:0]    current_q_r;            //  Iq��������Ĵ���
reg  signed[`DATA_WIDTH-1:0]    current_d_r;        //  Id��������Ĵ���

//===========================================================================
//�߼�����ʵ��
//===========================================================================
//״̬��״̬ת��
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        fsm_cs <= FSM_IDLE;
    else
        fsm_cs <= fsm_ns;
    end
always @(*)
    begin
    case (fsm_cs)
        FSM_IDLE: begin
                if (transaction_enable_in)  //�յ�ת��ʹ���ź�
                    fsm_ns = FSM_PARK_MULT;   //����PARK��Ͳ���
                else
                    fsm_ns = fsm_cs;
            end
        FSM_PARK_MULT: begin
                if (delay_time_cnt == 'd3)       //����Ҫ�����Ĵγ˷����㣬���ӳ��ĸ�ʱ������
                    fsm_ns = FSM_PARK_SUM;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_PARK_SUM: begin
                if (delay_time_cnt == 'd3)       //����Ҫ�����Ĵγ˷����㣬���ӳ��ĸ�ʱ������
                    fsm_ns = FSM_CAL_DONE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_CAL_DONE:
            fsm_ns = FSM_IDLE;
        default : fsm_ns = FSM_IDLE;
    endcase
    end

//clark�任�Ĵ�����ֵ
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_alpha_r <= 'd0;
    else if (transaction_enable_in)
        current_alpha_r <= phase_a_current_in;
    else
        current_alpha_r <= current_alpha_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_beta_r <= 'd0;
    else if (transaction_enable_in)   //�յ�ת��ʹ��ʱ����clark�任
        current_beta_r <= (((phase_a_current_in << 'd14) + (phase_a_current_in << 'd11)) + ((phase_a_current_in << 9) - (phase_a_current_in << 5))) + (((phase_a_current_in << 2) + (phase_a_current_in << 1)) + ((phase_b_current_in << 15) + (phase_b_current_in << 12))) + (((phase_b_current_in << 10) - (phase_b_current_in << 6)) + ((phase_b_current_in << 3) + (phase_b_current_in << 2)));
    else
        current_beta_r <= current_beta_r;
    end
//������ֵ����
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {electrical_rotation_phase_sin_r, electrical_rotation_phase_cos_r} <= 'd0;
    else if (transaction_enable_in)
        {electrical_rotation_phase_sin_r, electrical_rotation_phase_cos_r} <= {electrical_rotation_phase_sin_in, electrical_rotation_phase_cos_in};
    else
    {electrical_rotation_phase_sin_r, electrical_rotation_phase_cos_r} <= {electrical_rotation_phase_sin_r, electrical_rotation_phase_cos_r};
    end
//�˷����ӳټĴ�����������߳˷��ֲ�����
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        delay_time_cnt <= 'd0;
    else if (fsm_cs == FSM_PARK_MULT || fsm_cs == FSM_PARK_SUM)
        delay_time_cnt <= delay_time_cnt + 'b1;
    else
        delay_time_cnt <= 'd0;
    end
//�������������ֵ
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {multiplicand_r, multipler_r} <= 'd0;
    else if (fsm_cs == FSM_PARK_MULT)
        begin
        case (delay_time_cnt)
            'd0:{multiplicand_r, multipler_r} <= {current_alpha_r[`DATA_WIDTH - 1],current_alpha_r,{(`DATA_WIDTH-1){1'b0}}, electrical_rotation_phase_cos_r};   //����cos(theta)*Ialpha
                'd1:{multiplicand_r, multipler_r} <= {current_beta_r, electrical_rotation_phase_sin_r};         //����Ibeta*sin(theta)
                'd2:{multiplicand_r, multipler_r} <= {current_alpha_r[`DATA_WIDTH - 1],current_alpha_r,{(`DATA_WIDTH-1){1'b0}}, (16'sd0 - electrical_rotation_phase_sin_r)}; //����-sin(alpha)*Ialpha
                'd3:{multiplicand_r, multipler_r} <= {current_beta_r, electrical_rotation_phase_cos_r};
                default :{multiplicand_r, multipler_r} <= 'd0;
                endcase
        end else
            {multiplicand_r, multipler_r} <= 'd0;
        end

        //�˷���������渳ֵ
        always @(posedge sys_clk or  negedge reset_n) begin
        if (!reset_n)
            product_cache_r <= 'd0;
        else if (fsm_cs == FSM_PARK_SUM)
            product_cache_r <= product_w;
        else
            product_cache_r <= 'd0;
    end
        //�˷�����������ͻ���
        assign product_sum_w = {product_cache_r[`DATA_WIDTH*3-1],product_cache_r }+{product_w[`DATA_WIDTH*3-1], product_w};
        //Id��ֵ
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            current_d_r <= 'd0;
        else if ((fsm_cs == FSM_PARK_SUM) && (delay_time_cnt == 'd1))
            begin
                if (product_sum_w[(`DATA_WIDTH*3)-:4]==4'd0||product_sum_w[(`DATA_WIDTH*3)-:4]==4'hf)
                current_d_r <= {product_sum_w[`DATA_WIDTH*3],product_sum_w[(`DATA_WIDTH*3-4)-:15]};
            else
                current_d_r <=product_sum_w[`DATA_WIDTH*3]?16'h7fff:16'h8000;
            end else
            current_d_r <= current_d_r;
    end

        //Iq��ֵ
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            current_q_r <= 'd0;
        else  if ((fsm_cs == FSM_PARK_SUM) && (delay_time_cnt == 'd3))
            begin
            if (product_sum_w[(`DATA_WIDTH*3)-:4]==4'd0||product_sum_w[(`DATA_WIDTH*3)-:4]==4'hf)
                current_q_r <= {product_sum_w[`DATA_WIDTH*3],product_sum_w[(`DATA_WIDTH*3-4)-:15]};
            else
                current_q_r <=product_sum_w[`DATA_WIDTH*3]?16'h7fff:16'h8000;;
            end else
            current_q_r <= current_q_r;
    end
        //�����Ч��־
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            transaction_valid_r <= 'd0;
        else if (fsm_cs == FSM_CAL_DONE)
            transaction_valid_r <= 1'b1;
        else
            transaction_valid_r <= 1'b0;
    end

        //===========================================================================
        //�˷����˵���
        //===========================================================================
        park_multiplier_module park_multipler(
                                                  .CLK(sys_clk),    // input wire CLK
                                                  .A(multiplicand_r),        // input wire [31 : 0] A
                                                  .B(multipler_r),        // input wire [15 : 0] B
                                                  .SCLR(~reset_n),  // input wire SCLR
                                                  .P(product_w)        // output wire [15 : 0] P
    );
        //===========================================================================
        //����˿ڸ�ֵ
        //===========================================================================
        assign current_q_out = current_q_r;
        assign current_d_out = current_d_r;
        assign transaction_valid_out = transaction_valid_r;
        assign electrical_rotation_phase_sin_out=electrical_rotation_phase_sin_r;
        assign electrical_rotation_phase_cos_out = electrical_rotation_phase_cos_r;
endmodule
