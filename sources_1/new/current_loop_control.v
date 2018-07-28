`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer:
// Create Date: 2018/5/4
// Design Name:
// Module Name: current_loop_control.v
// Target Device:
// Tool versions:
// Description:电流闭环控制电路
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module current_loop_control(
                            input    sys_clk,
                            input    reset_n,

                            input    current_loop_control_enable_in,      //控制使能输入，high-active

                            input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_in,   //  电气角度正弦值输入
                            input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_in,  //  电气角度余弦值输入

                            input    signed [`DATA_WIDTH-1:0]    phase_a_current_in,                      //  a相电流检测值
                            input    signed [`DATA_WIDTH-1:0]    phase_b_current_in,                      //  b相电流检测值

                            input [`DATA_WIDTH-1:0]    current_d_param_p_in,         //d轴电流环P参数
                            input [`DATA_WIDTH-1:0]    current_d_param_i_in,          //d轴电流环I参数
                            input [`DATA_WIDTH-1:0]    current_d_param_d_in,         //d轴电流环D参数

                            input [`DATA_WIDTH-1:0]    current_d_set_val_in,            //d轴电流设定值

                            input [`DATA_WIDTH-1:0]    current_q_param_p_in,         //q轴电流环P参数
                            input [`DATA_WIDTH-1:0]    current_q_param_i_in,          //q轴电流环I参数
                            input [`DATA_WIDTH-1:0]    current_q_param_d_in,         //q轴电流环D参数

                            input [`DATA_WIDTH-1:0]    current_q_set_val_in,            //q轴电流设定值

                            output  signed [`DATA_WIDTH-1:0] voltage_alpha_out, //U_alpha电压输出
                            output  signed [`DATA_WIDTH-1:0] voltage_beta_out,   //U_beta电压输出
                            output  current_loop_control_done_out     //电压输出有效标志
                            );
//===========================================================================
//  内部变量声明
//===========================================================================
wire clark_and_park_transaction_done_w;           //clark和park转换完成标志
wire [`DATA_WIDTH-1:0] current_q_w;            //q轴电流
wire[`DATA_WIDTH-1:0]  current_d_w;            //d轴电流输出
wire[`DATA_WIDTH-1:0]  anti_park_sin_w;     //用于反PARK变换的正弦值
wire[`DATA_WIDTH-1:0]  anti_park_cos_w;    //用于反PARK变换的余弦值

wire[`DATA_WIDTH-1:0]  vlotage_d_w;          //d轴电压
wire current_d_control_cal_done_w;                  //d轴电流控制完成标志
wire[`DATA_WIDTH-1:0]  vlotage_q_w;          //q轴电压
wire current_q_control_cal_done_w;                  //q轴电流控制完成标志

//===========================================================================
//CLARK变换与PARK变换IP核例化
//===========================================================================
clark_and_park_transaction clark_and_park_transaction_inst(
                                                           .sys_clk(sys_clk),    //system clock
                                                           .reset_n(reset_n),    //active-low,reset signal

                                                           .transaction_enable_in(current_loop_control_enable_in),  //转换使能信号

                                                           .electrical_rotation_phase_sin_in(electrical_rotation_phase_sin_in),   //  电气角度正弦值
                                                           .electrical_rotation_phase_cos_in(electrical_rotation_phase_cos_in),  //  电气角度余弦值

                                                           .phase_a_current_in(phase_a_current_in),                      //  a相电流检测值
                                                           .phase_b_current_in(phase_b_current_in),                      //  b相电流检测值

                                                           .electrical_rotation_phase_sin_out(anti_park_sin_w),   //  电气角度正弦值输出，用于反Park变换
                                                           .electrical_rotation_phase_cos_out(anti_park_cos_w),  //  电气角度余弦值输出

                                                           .current_q_out(current_q_w),                              //  Iq电流输出
                                                           .current_d_out(current_d_w),                              //  Id电流输出
                                                           .transaction_valid_out(clark_and_park_transaction_done_w)                               //转换输出有效信号
                                                           );
//===========================================================================
//D轴电流控制模块IP核例化
//===========================================================================
pid_cal_unit current_d_loop_control_inst(
                                         .sys_clk(sys_clk),
                                         .reset_n(reset_n),

                                         .pid_cal_enable_in(clark_and_park_transaction_done_w),       //PID计算使能信号,当clark和park转换完成后启动控制模块

                                         .pid_param_p_in(current_d_param_p_in),  //参数p输入
                                         .pid_param_i_in(current_d_param_i_in),   //参数i输入
                                         .pid_param_d_in(current_d_param_d_in),  //参数d输入

                                         .set_value_in(current_d_set_val_in),        //设定值输入
                                         .detect_value_in(current_d_w),   //检测值输入

                                         .pid_cal_value_out(vlotage_d_w),    //pid计算结果输出
                                         .pid_cal_done_out(current_d_control_cal_done_w)                         //计算完成标志
                                         );
//===========================================================================
//Q轴电流控制模块IP核例化
//===========================================================================
pid_cal_unit current_q_loop_control_inst(
                                         .sys_clk(sys_clk),
                                         .reset_n(reset_n),

                                         .pid_cal_enable_in(clark_and_park_transaction_done_w),       //PID计算使能信号,当clark和park转换完成后启动控制模块

                                         .pid_param_p_in(current_q_param_p_in),  //参数p输入
                                         .pid_param_i_in(current_q_param_i_in),   //参数i输入
                                         .pid_param_d_in(current_q_param_d_in),  //参数d输入

                                         .set_value_in(current_q_set_val_in),        //设定值输入
                                         .detect_value_in(current_q_w),   //检测值输入

                                         .pid_cal_value_out(vlotage_q_w),    //pid计算结果输出
                                         .pid_cal_done_out(current_q_control_cal_done_w)                         //计算完成标志
                                         );
//===========================================================================
//反PARK变换
//===========================================================================
anti_park_unit anti_park_inst(
                              .sys_clk(sys_clk),
                              .reset_n(reset_n),

                              .anti_park_cal_enable_in(current_d_control_cal_done_w&&current_q_control_cal_done_w),       //反Park变换使能输入

                              .voltage_d_in(vlotage_d_w),   //Ud电压输入
                              .voltage_q_in(vlotage_q_w),   //Uq电压输入
                              .electrical_rotation_phase_sin_in(anti_park_sin_w),   //  电气角度正弦值
                              .electrical_rotation_phase_cos_in(anti_park_cos_w),  //  电气角度余弦值

                              .voltage_alpha_out(voltage_alpha_out), //U_alpha电压输出
                              .voltage_beta_out(voltage_beta_out),   //U_beta电压输出
                              .anti_park_cal_valid_out(current_loop_control_done_out)     //电压输出有效标志
                              );
endmodule
