`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/4
// Design Name:PMSM_DESIGN
// Module Name: speed_loop_control.v
// Target Device:
// Tool versions:
// Description:  �ٶȱջ�����
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module speed_loop_control(
                          input    sys_clk,
                          input    reset_n,
                            
                          input    speed_control_enable_in,   //�ٶȿ���ʹ���ź�
                          input    [`DATA_WIDTH-1:0]    speed_control_param_p_in,   //�ٶȱջ�����P����
                          input    [`DATA_WIDTH-1:0]    speed_control_param_i_in,   //�ٶȱջ�����I����
                          input    [`DATA_WIDTH-1:0]    speed_control_param_d_in,   //�ٶȱջ�����D����

                          input    [`DATA_WIDTH-1:0]    speed_set_val_in,       //�ٶ��趨ֵ
                          input    [`DATA_WIDTH-1:0]          speed_detect_val_in,  //ʵ���ٶȼ��ֵ

                          output[`DATA_WIDTH-1:0]  current_q_set_val_out,    //Q������趨ֵ
                          output    speed_loop_cal_done_out   //  �����ջ��������
                          );

//===========================================================================
//
//===========================================================================
pid_cal_unit speed_loop_control_inst(
                                         .sys_clk(sys_clk),
                                         .reset_n(reset_n),

                                         .pid_cal_enable_in(speed_control_enable_in),       //PID����ʹ���ź�,��clark��parkת����ɺ���������ģ��

                                         .pid_param_p_in(speed_control_param_p_in),  //����p����
                                         .pid_param_i_in(speed_control_param_i_in),   //����i����
                                         .pid_param_d_in(speed_control_param_d_in),  //����d����

                                         .set_value_in(speed_set_val_in),        //�趨ֵ����
                                         .detect_value_in(speed_detect_val_in),   //���ֵ����

                                         .pid_cal_value_out(current_q_set_val_out),    //pid���������
                                         .pid_cal_done_out(speed_loop_cal_done_out)                         //������ɱ�־
                                         );
endmodule
