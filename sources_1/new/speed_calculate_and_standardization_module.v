`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/17
// Design Name:PMSM_DESIGN
// Module Name: speed_calculate_and_standardization_module.v
// Target Device:
// Tool versions:
// Description: �ٶȼ�������ۻ�����
// Dependencies:
// Revision:
// Additional Comments:
//���ת�ٱ��ۻ�������㹫ʽ���������M1*390625*(2^15-1)*60/�������ʱM2*64*�ת��)
//��ʽ�ɻ���Ϊ��M1*390625*(2^19-2^15-2^4+1)/�������ʱM2*16*�ת��)
//���㷽��:���յ������ʱ������Ч��־λʱ�����ȶԳ������ó˷������г˷������������λ�������ó�
//           �������г�������.
//====================================================================================


module speed_calculate_and_standardization_module(
                                                  input    sys_clk,
                                                  input    reset_n,

                                                  input   [25:0]      speed_pluse_time_cnt_in,                          //�����ʱ���M2
                                                  input   [25:0]      speed_pluse_count_dividend_in,               //�������M1*390625
                                                  input                   speed_cnt_valid_in,                                  //�����ʱ������Ч��־λ
                                                  input                   rotation_direction_in,                                //�����ת��������
                                                  input   [15:0]       rated_speed_in,                                         //�ת������

                                                  output [15:0]       standardization_speed_out                       //����ٶȱ��ۻ����
                                                  );
//===========================================================================
//�ڲ���������
//===========================================================================
reg[45:0]     speed_pluse_count_dividend_r;         //��������Ĵ������뻺��*390625*(2^19-2^15-2^4+1)�Ĵ���
reg[2:0]       speed_cnt_valid_r;                             //��ʱ������Ч�źŻ����������ڳ˷���������ʱ�ӵ���ʱ������ӳ�����
reg   signed[15:0] standardization_speed_r;            // ���ۻ��ٶ�����Ĵ���
wire[41:0]     multipler_result_w;                          //�˷����������
wire[63:0]   m_axis_dout_tdata_w;                     //�������������
wire             m_axi_dout_valid_w;                      //�����������Ч��־λ

//===========================================================================
//��������Ĵ������뻺��*390625*(2^19-2^15-2^4+1)�Ĵ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_pluse_count_dividend_r <= 'd0;
    else if (speed_cnt_valid_in)  //������Чʱ��������̳˷���λ����
        speed_pluse_count_dividend_r <= ((speed_pluse_count_dividend_in << 'd19) - (speed_pluse_count_dividend_in << 'd15)) - ((speed_pluse_count_dividend_in << 'd4) - (speed_pluse_count_dividend_in));
    else
        speed_pluse_count_dividend_r <= speed_pluse_count_dividend_r;
    end
//===========================================================================
//�����ʱ�˷����㣬�˷���IP��������ʱ�ӵ��ӳ�
//===========================================================================
divisor_generate_ip_core divisor_generate(
                                          .CLK(sys_clk),    // input wire CLK
                                          .A(speed_pluse_time_cnt_in),        // input wire [25 : 0] A
                                          .B(rated_speed_in),        // input wire [15 : 0] B
                                          .SCLR(~reset_n),  // input wire SCLR,HIGH-ACTIVE
                                          .P(multipler_result_w)        // output wire [41 : 0] P
);
//===========================================================================
//������Ч�ź��ӳټĴ棬��������ʱ������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_cnt_valid_r <= 'd0;
    else
        speed_cnt_valid_r <= {speed_cnt_valid_r[1:0], speed_cnt_valid_in};
    end
//===========================================================================
//���������ã����ڼ�����ۻ��������16λΪС����
//===========================================================================
speed_standardization_divider speed_standardization(
                                                    .aclk(sys_clk),                                      // input wire aclk
                                                    .aresetn(reset_n),                                // input wire aresetn
                                                    .s_axis_divisor_tvalid(speed_cnt_valid_r[2]),    // input wire s_axis_divisor_tvalid
                                                    .s_axis_divisor_tdata({2'd0, multipler_result_w,4'd0}),      // input wire [47 : 0] s_axis_divisor_tdata
                                                    .s_axis_dividend_tvalid(speed_cnt_valid_r[2]),  // input wire s_axis_dividend_tvalid
                                                    .s_axis_dividend_tdata({ 2'd0,speed_pluse_count_dividend_r}),    // input wire [47 : 0] s_axis_dividend_tdata
                                                    .m_axis_dout_tvalid(m_axi_dout_valid_w),          // output wire m_axis_dout_tvalid
                                                    .m_axis_dout_tdata(m_axis_dout_tdata_w)            // output wire [63 : 0] m_axis_dout_tdata
);
//===========================================================================
//�ٶȱ���ֵ���Ż�
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        standardization_speed_r <= 'sd0;
    else if (m_axi_dout_valid_w)
        begin
        if (rotation_direction_in) //1��ʾ��ת
            standardization_speed_r <= 16'sd0 - m_axis_dout_tdata_w[31:16];
        else
            standardization_speed_r <= m_axis_dout_tdata_w[31:16];
        end else
        standardization_speed_r <= standardization_speed_r;
    end
//===========================================================================
//�����ֵ
//===========================================================================
assign standardization_speed_out = standardization_speed_r;
endmodule
