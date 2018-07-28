`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/4
// Design Name:PMSM_DESIGN
// Module Name: speed_loop_control.v
// Target Device:
// Tool versions:
// Description:  速度闭环控制
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module speed_loop_control(
                          input    sys_clk,
                          input    reset_n,
                            
                          input    speed_control_enable_in,   //速度控制使能信号
                          input    [`DATA_WIDTH-1:0]    speed_control_param_p_in,   //速度闭环控制P参数
                          input    [`DATA_WIDTH-1:0]    speed_control_param_i_in,   //速度闭环控制I参数
                          input    [`DATA_WIDTH-1:0]    speed_control_param_d_in,   //速度闭环控制D参数

                          input    [`DATA_WIDTH-1:0]    speed_set_val_in,       //速度设定值
                          input    [`DATA_WIDTH-1:0]          speed_detect_val_in,  //实际速度检测值

                          output[`DATA_WIDTH-1:0]  current_q_set_val_out,    //Q轴电流设定值
                          output    speed_loop_cal_done_out   //  电流闭环计算输出
                          );

//===========================================================================
//
//===========================================================================
pid_cal_unit speed_loop_control_inst(
                                         .sys_clk(sys_clk),
                                         .reset_n(reset_n),

                                         .pid_cal_enable_in(speed_control_enable_in),       //PID计算使能信号,当clark和park转换完成后启动控制模块

                                         .pid_param_p_in(speed_control_param_p_in),  //参数p输入
                                         .pid_param_i_in(speed_control_param_i_in),   //参数i输入
                                         .pid_param_d_in(speed_control_param_d_in),  //参数d输入

                                         .set_value_in(speed_set_val_in),        //设定值输入
                                         .detect_value_in(speed_detect_val_in),   //检测值输入

                                         .pid_cal_value_out(current_q_set_val_out),    //pid计算结果输出
                                         .pid_cal_done_out(speed_loop_cal_done_out)                         //计算完成标志
                                         );
endmodule
