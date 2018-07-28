`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer:
// Create Date: 2018/5/4
// Design Name:
// Module Name: current_loop_control.v
// Target Device:
// Tool versions:
// Description:�����ջ����Ƶ�·
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module current_loop_control(
                            input    sys_clk,
                            input    reset_n,

                            input    current_loop_control_enable_in,      //����ʹ�����룬high-active

                            input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_in,   //  �����Ƕ�����ֵ����
                            input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_in,  //  �����Ƕ�����ֵ����

                            input    signed [`DATA_WIDTH-1:0]    phase_a_current_in,                      //  a��������ֵ
                            input    signed [`DATA_WIDTH-1:0]    phase_b_current_in,                      //  b��������ֵ

                            input [`DATA_WIDTH-1:0]    current_d_param_p_in,         //d�������P����
                            input [`DATA_WIDTH-1:0]    current_d_param_i_in,          //d�������I����
                            input [`DATA_WIDTH-1:0]    current_d_param_d_in,         //d�������D����

                            input [`DATA_WIDTH-1:0]    current_d_set_val_in,            //d������趨ֵ

                            input [`DATA_WIDTH-1:0]    current_q_param_p_in,         //q�������P����
                            input [`DATA_WIDTH-1:0]    current_q_param_i_in,          //q�������I����
                            input [`DATA_WIDTH-1:0]    current_q_param_d_in,         //q�������D����

                            input [`DATA_WIDTH-1:0]    current_q_set_val_in,            //q������趨ֵ

                            output  signed [`DATA_WIDTH-1:0] voltage_alpha_out, //U_alpha��ѹ���
                            output  signed [`DATA_WIDTH-1:0] voltage_beta_out,   //U_beta��ѹ���
                            output  current_loop_control_done_out     //��ѹ�����Ч��־
                            );
//===========================================================================
//  �ڲ���������
//===========================================================================
wire clark_and_park_transaction_done_w;           //clark��parkת����ɱ�־
wire [`DATA_WIDTH-1:0] current_q_w;            //q�����
wire[`DATA_WIDTH-1:0]  current_d_w;            //d��������
wire[`DATA_WIDTH-1:0]  anti_park_sin_w;     //���ڷ�PARK�任������ֵ
wire[`DATA_WIDTH-1:0]  anti_park_cos_w;    //���ڷ�PARK�任������ֵ

wire[`DATA_WIDTH-1:0]  vlotage_d_w;          //d���ѹ
wire current_d_control_cal_done_w;                  //d�����������ɱ�־
wire[`DATA_WIDTH-1:0]  vlotage_q_w;          //q���ѹ
wire current_q_control_cal_done_w;                  //q�����������ɱ�־

//===========================================================================
//CLARK�任��PARK�任IP������
//===========================================================================
clark_and_park_transaction clark_and_park_transaction_inst(
                                                           .sys_clk(sys_clk),    //system clock
                                                           .reset_n(reset_n),    //active-low,reset signal

                                                           .transaction_enable_in(current_loop_control_enable_in),  //ת��ʹ���ź�

                                                           .electrical_rotation_phase_sin_in(electrical_rotation_phase_sin_in),   //  �����Ƕ�����ֵ
                                                           .electrical_rotation_phase_cos_in(electrical_rotation_phase_cos_in),  //  �����Ƕ�����ֵ

                                                           .phase_a_current_in(phase_a_current_in),                      //  a��������ֵ
                                                           .phase_b_current_in(phase_b_current_in),                      //  b��������ֵ

                                                           .electrical_rotation_phase_sin_out(anti_park_sin_w),   //  �����Ƕ�����ֵ��������ڷ�Park�任
                                                           .electrical_rotation_phase_cos_out(anti_park_cos_w),  //  �����Ƕ�����ֵ���

                                                           .current_q_out(current_q_w),                              //  Iq�������
                                                           .current_d_out(current_d_w),                              //  Id�������
                                                           .transaction_valid_out(clark_and_park_transaction_done_w)                               //ת�������Ч�ź�
                                                           );
//===========================================================================
//D���������ģ��IP������
//===========================================================================
pid_cal_unit current_d_loop_control_inst(
                                         .sys_clk(sys_clk),
                                         .reset_n(reset_n),

                                         .pid_cal_enable_in(clark_and_park_transaction_done_w),       //PID����ʹ���ź�,��clark��parkת����ɺ���������ģ��

                                         .pid_param_p_in(current_d_param_p_in),  //����p����
                                         .pid_param_i_in(current_d_param_i_in),   //����i����
                                         .pid_param_d_in(current_d_param_d_in),  //����d����

                                         .set_value_in(current_d_set_val_in),        //�趨ֵ����
                                         .detect_value_in(current_d_w),   //���ֵ����

                                         .pid_cal_value_out(vlotage_d_w),    //pid���������
                                         .pid_cal_done_out(current_d_control_cal_done_w)                         //������ɱ�־
                                         );
//===========================================================================
//Q���������ģ��IP������
//===========================================================================
pid_cal_unit current_q_loop_control_inst(
                                         .sys_clk(sys_clk),
                                         .reset_n(reset_n),

                                         .pid_cal_enable_in(clark_and_park_transaction_done_w),       //PID����ʹ���ź�,��clark��parkת����ɺ���������ģ��

                                         .pid_param_p_in(current_q_param_p_in),  //����p����
                                         .pid_param_i_in(current_q_param_i_in),   //����i����
                                         .pid_param_d_in(current_q_param_d_in),  //����d����

                                         .set_value_in(current_q_set_val_in),        //�趨ֵ����
                                         .detect_value_in(current_q_w),   //���ֵ����

                                         .pid_cal_value_out(vlotage_q_w),    //pid���������
                                         .pid_cal_done_out(current_q_control_cal_done_w)                         //������ɱ�־
                                         );
//===========================================================================
//��PARK�任
//===========================================================================
anti_park_unit anti_park_inst(
                              .sys_clk(sys_clk),
                              .reset_n(reset_n),

                              .anti_park_cal_enable_in(current_d_control_cal_done_w&&current_q_control_cal_done_w),       //��Park�任ʹ������

                              .voltage_d_in(vlotage_d_w),   //Ud��ѹ����
                              .voltage_q_in(vlotage_q_w),   //Uq��ѹ����
                              .electrical_rotation_phase_sin_in(anti_park_sin_w),   //  �����Ƕ�����ֵ
                              .electrical_rotation_phase_cos_in(anti_park_cos_w),  //  �����Ƕ�����ֵ

                              .voltage_alpha_out(voltage_alpha_out), //U_alpha��ѹ���
                              .voltage_beta_out(voltage_beta_out),   //U_beta��ѹ���
                              .anti_park_cal_valid_out(current_loop_control_done_out)     //��ѹ�����Ч��־
                              );
endmodule
