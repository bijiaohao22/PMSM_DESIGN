//====================================================================================
// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/5/3
// Design Name:PMSM_DESIGN
// Module Name: pid_cal_unit.v
// Target Device:
// Tool versions:
// Description:  ������PID�㷨ʵ��
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module pid_cal_unit(
                    input    sys_clk,
                    input    reset_n,

                    input    pid_cal_enable_in,       //PID����ʹ���ź�

                    input[`DATA_WIDTH-1:0]    pid_param_p_in,  //����p����
                    input[`DATA_WIDTH-1:0]    pid_param_i_in,   //����i����
                    input[`DATA_WIDTH-1:0]    pid_param_d_in,  //����d����

                    input signed[`DATA_WIDTH-1:0]    set_value_in,        //�趨ֵ����
                    input signed[`DATA_WIDTH-1:0]    detect_value_in,   //���ֵ����

                    output signed [`DATA_WIDTH-1:0] pid_cal_value_out,    //pid���������
                    output pid_cal_done_out                         //������ɱ�־
                    );
//===========================================================================
//�ڲ���������
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_MULT=1<<1;
localparam FSM_ADDER=1<<2;
localparam FSM_RESULT_ADJUST=1<<3;
//===========================================================================
//  �ڲ���������
//===========================================================================
reg[3:0]     fsm_cs,
    fsm_ns;    //  ����״̬����ǰ״̬������һ״̬
reg[1:0]     period_cnt_r;         //ʱ�����ڼ����Ĵ���
                                   //  pid �����Ĵ���
reg[`DATA_WIDTH-1:0]    param_p_r;
reg[`DATA_WIDTH-1:0]    param_i_r;
reg[`DATA_WIDTH-1:0]    param_d_r;
//PID�����ڲ�����
reg signed[`DATA_WIDTH:0]    pid_error_r;             //  ���ֵ����ʽ1Q15�������ɣ�
reg signed[`DATA_WIDTH:0]    pid_last_error_r;
reg signed[`DATA_WIDTH:0]    pid_prev_error_r;
reg signed[`DATA_WIDTH*2+4:0]   pid_det_value_r;  //pid����ֵ�����ݸ�ʽ6Q30��
reg signed[`DATA_WIDTH-1:0]    pid_cal_value_r;      //PID���������ֵ
wire signed[`DATA_WIDTH*2+5:0] pid_cal_value_w; //pid�������м����7Q30
                                                //�˷�������
reg[`DATA_WIDTH-1:0]     multiplicand_r;    //�������Ĵ���,Q15
reg[`DATA_WIDTH+2:0]    multiplier_r;        //�����Ĵ�����3Q15
wire[`DATA_WIDTH*2+2:0] product_w;       //�˻���4Q30

reg pid_cal_done_r;

//===========================================================================
//����״̬��״̬��ת
//===========================================================================
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
                if (pid_cal_enable_in)  //  �յ�����ʹ���źź�ʼ���г˷�����
                    fsm_ns = FSM_MULT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_MULT: begin        //���ĸ�ʱ�����ں���ת�����ۼӲ���
                if (period_cnt_r == 'd3)
                    fsm_ns = FSM_ADDER;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ADDER: begin      //������ʱ�����ں���ת�������ݵ�������
                if (period_cnt_r == 'd2)
                    fsm_ns = FSM_RESULT_ADJUST;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_RESULT_ADJUST:
            fsm_ns = FSM_IDLE;
        default :fsm_ns = FSM_IDLE;
    endcase
    end
//���ڼ�����ֵ
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        period_cnt_r <= 'd0;
    else if (fsm_cs == FSM_MULT || fsm_cs == FSM_ADDER)
        period_cnt_r <= period_cnt_r + 1'b1;
    else
        period_cnt_r <= 'd0;
    end
//===========================================================================
//�����������
//�ڿ���״̬���յ�pid����ʹ�ܲ����������Ӧ��������
//===========================================================================
//pid ��������
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {param_p_r, param_i_r, param_d_r} <= 'd0;
    else if (fsm_cs == FSM_IDLE && pid_cal_enable_in)
        {param_p_r, param_i_r, param_d_r} <= {pid_param_p_in, pid_param_i_in, pid_param_d_in};
    else
    {param_p_r, param_i_r, param_d_r} <= {param_p_r, param_i_r, param_d_r};
    end
//���ֵ��ֵ
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pid_error_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && pid_cal_enable_in)
        pid_error_r <= {set_value_in[`DATA_WIDTH - 1], set_value_in} - {detect_value_in[`DATA_WIDTH - 1], detect_value_in};
    else
        pid_error_r <= pid_error_r;
    end
//===========================================================================
//�˷�������ֵ
//===========================================================================
//��������ֵ
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        multiplicand_r <= 'd0;
    else if (fsm_cs == FSM_MULT)
        begin
        case (period_cnt_r)
            'd0:  multiplicand_r <= param_p_r;    //��������
            'd1:  multiplicand_r <= param_i_r;     //���ּ���
            'd2:  multiplicand_r <= param_d_r;    //΢�ּ���
            default :multiplicand_r <= 'd0;
        endcase
        end else
        multiplicand_r <= 'd0;
    end
//������ֵ 3Q15
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        multiplier_r <= 'd0;
    else if (fsm_cs == FSM_MULT)
        begin
        case (period_cnt_r)
            'd0:multiplier_r <= {{2{pid_error_r[`DATA_WIDTH]}}, pid_error_r} - {{2{pid_last_error_r[`DATA_WIDTH ]}}, pid_last_error_r};
            'd1:multiplier_r <= {{2{pid_error_r[`DATA_WIDTH]}}, pid_error_r};
            'd2:multiplier_r <= ({{2{pid_error_r[`DATA_WIDTH]}}, pid_error_r} - {{2{pid_last_error_r[`DATA_WIDTH ]}}, pid_last_error_r}) - ({{2{pid_last_error_r[`DATA_WIDTH ]}}, pid_last_error_r} - {{2{pid_prev_error_r[`DATA_WIDTH ]}}, pid_prev_error_r});
            default multiplier_r <= 'd0;
        endcase
        end else
        multiplier_r <= 'd0;
    end
//===========================================================================
//�˻������ۼ�
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pid_det_value_r <= 'd0;
    else if (fsm_cs == FSM_ADDER)
        pid_det_value_r <= pid_det_value_r + {{2{product_w[`DATA_WIDTH * 2 + 2]}}, product_w};
    else
        pid_det_value_r <= 'd0;
    end
//===========================================================================
//pid���������
//===========================================================================
assign pid_cal_value_w = {pid_det_value_r[`DATA_WIDTH * 2 + 4], pid_det_value_r} + {{7{pid_cal_value_r[`DATA_WIDTH - 1]}}, pid_cal_value_r,15'd0}; //������ԭʼ����֮��
//������ݽ�ȡ���޷�
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pid_cal_value_r <= 'd0;
    else if (fsm_cs == FSM_RESULT_ADJUST)
        begin
        if (pid_cal_value_w[(`DATA_WIDTH * 2 + 5) -: 8] != 8'd0 && pid_cal_value_w[(`DATA_WIDTH * 2 + 5) -: 8] != 8'hff)    //������ֵ��ֵ
            pid_cal_value_r <= {pid_cal_value_w[`DATA_WIDTH * 2 + 5], {(`DATA_WIDTH - 1){~pid_cal_value_w[`DATA_WIDTH * 2 + 5]}}};
        else
            pid_cal_value_r <= {pid_cal_value_w[`DATA_WIDTH * 2 + 5], pid_cal_value_w[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]};
        end else
        pid_cal_value_r <= pid_cal_value_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pid_cal_done_r <= 'd0;
    else if (fsm_cs == FSM_RESULT_ADJUST)
        pid_cal_done_r <= 'd1;
    else
        pid_cal_done_r <= 'd0;
    end
//===========================================================================
//pid�м�������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {pid_last_error_r, pid_prev_error_r} <= 'd0;
    else if (fsm_cs == FSM_RESULT_ADJUST)
        {pid_last_error_r, pid_prev_error_r} <= {pid_error_r, pid_last_error_r};
    else
    {pid_last_error_r, pid_prev_error_r} <= {pid_last_error_r, pid_prev_error_r};
    end
//===========================================================================
//�˷���IP�˵���
//===========================================================================
pid_cal_mul pid_cal_mul_inst(
                             .CLK(sys_clk),    // input wire CLK
                             .A(multiplicand_r),        // input wire [15 : 0] A
                             .B(multiplier_r),        // input wire [18 : 0] B
                             .SCLR(~reset_n),  // input wire SCLR
                             .P(product_w)        // output wire [34 : 0] P
);
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign  pid_cal_value_out = pid_cal_value_r;
assign pid_cal_done_out = pid_cal_done_r;
endmodule
