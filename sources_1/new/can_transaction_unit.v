`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2018/05/22 22:24:18
// Design Name:
// Module Name: can_transaction_unit
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`include "project_param.v"
module can_transaction_unit(
                            input    sys_clk,
                            input    reset_n,

                            //  can物理层端口
                            input    can_phy_rx,
                            output  can_phy_tx,
                            input    can_clk,

                            input   system_initilization_done_in,              //  系统初始化完成输入,高电平有效

                            input    can_init_enable_in,    //   can初始化使能标志
                            output  can_init_done_out,    //    can初始化完成标志

                            output[`DATA_WIDTH-1:0]  current_rated_value_out,  //  额定电流值输出
                            output[`DATA_WIDTH-1:0]  speed_rated_value_out,  //  额定转速值输出

                            output [`DATA_WIDTH-1:0]    current_d_param_p_out,  //    电流环d轴控制参数p输出
                            output [`DATA_WIDTH-1:0]    current_d_param_i_out,   //    电流环d轴控制参数i输出
                            output [`DATA_WIDTH-1:0]    current_d_param_d_out,  //    电流环d轴控制参数d输出

                            output [`DATA_WIDTH-1:0]    current_q_param_p_out,         //q轴电流环P参数
                            output [`DATA_WIDTH-1:0]    current_q_param_i_out,          //q轴电流环I参数
                            output [`DATA_WIDTH-1:0]    current_q_param_d_out,         //q轴电流环D参数

                            output  [`DATA_WIDTH-1:0]    speed_control_param_p_out,   //速度闭环控制P参数
                            output  [`DATA_WIDTH-1:0]    speed_control_param_i_out,   //速度闭环控制I参数
                            output  [`DATA_WIDTH-1:0]    speed_control_param_d_out,   //速度闭环控制D参数

                            output  [`DATA_WIDTH-1:0]    location_control_param_p_out,   //位置闭环控制P参数
                            output  [`DATA_WIDTH-1:0]    location_control_param_i_out,   //位置闭环控制I参数
                            output  [`DATA_WIDTH-1:0]    location_control_param_d_out,   //位置闭环控制D参数

                            output[(`DATA_WIDTH/2)-1:0] band_breaks_mode_out,  //抱闸工作模式输出

                            output[(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode_out,   //电机启停指令输出

                            output [(`DATA_WIDTH/4)-1:0] pmsm_work_mode_out,     //电机工作模式指令输出

                            output[`DATA_WIDTH-1:0]   pmsm_speed_set_value_out,   //  电机转速设定值输出
                            output[(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value_out,    //电机位置设定值输出

                            input   [`DATA_WIDTH-1:0]    gate_driver_register_1_in,  //  栅极寄存器状态1寄存器输入
                            input   [`DATA_WIDTH-1:0]    gate_driver_register_2_in,  //  栅极寄存器状态2寄存器输入
                            input                                          gate_driver_error_in,          //栅极寄存器故障报警输入

                            input  [`DATA_WIDTH-1:0] current_detect_status_in,
                            input   channela_detect_err_in,    //current detect error triger
                            input   channelb_detect_err_in,   //current detect error triger
                            input signed[`DATA_WIDTH-1:0] phase_a_current_in,     //  a相电流检测值
                            input signed[`DATA_WIDTH-1:0] phase_b_current_in,    //  b相电流检测值
                            input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_in,   //  电气角度正弦值输入
                            input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_in,  //  电气角度余弦值输入
                            input current_loop_control_enable_in,     //电流环控制使能输入，用于触发电流电气角度值上传

                            input signed   [`DATA_WIDTH-1:0]      U_alpha_in,       //    Ualpha电压输入
                            input signed   [`DATA_WIDTH-1:0]      U_beta_in,         //    Ubeta电压输入
                            input  current_loop_control_done_in,     //电压输出有效标志输入

                            input [`DATA_WIDTH-1:0]   Tcma_in,    //  a 相时间切换点输出
                            input [`DATA_WIDTH-1:0]   Tcmb_in,    //   b相时间切换点输出
                            input [`DATA_WIDTH-1:0]   Tcmc_in,    //   c相时间切换点输出
                            input svpwm_cal_done_in,  //svpwm计算完成输入，用于三相时间切换点数据上传

                            input    [`DATA_WIDTH-1:0]       speed_detect_val_in,      //实际速度检测值
                            input    [`DATA_WIDTH-1:0]  current_q_set_val_in,    //Q轴电流设定值
                            input    speed_loop_cal_done_in,     //  速度闭环完成标志

                            input    [(`DATA_WIDTH*2+2)-1:0]pmsm_location_detect_value_in,   //位置检测输入
                            input    [`DATA_WIDTH-1:0]    speed_set_value_in,  //  位置模式速度设定值输入
                            input    pmsm_location_cal_done_in,   //位置闭环控制完成标志

                            input    [`DATA_WIDTH-1:0]    ds_18b20_temp_in,  //  环境温度输入
                            input    ds_18b20_update_done_in  //环境温度更新指令
                            );
//===========================================================================
//内部变量声明
//===========================================================================
wire  [31:0]  tx_dw1r,tx_dw2r;
wire  tx_valid,tx_ready;
wire  [31:0] rx_dw1r,rx_dw2r;
wire  rx_valid,rx_ready;
//===========================================================================
//CAN总线应用层通讯例化
//===========================================================================
can_bus_app_unit can_bus_app_inst(
                                  .sys_clk(sys_clk),
                                  .reset_n(reset_n),

                                  .tx_dw1r_out(tx_dw1r),    //  数据发送字1
                                  .tx_dw2r_out(tx_dw2r),    //  数据发送字2
                                  . tx_valid_out(tx_valid),   //  发送有效标志
                                  . tx_ready_in(tx_ready),     //  发送准备好输入

                                  .rx_dw1r_in(rx_dw1r),     //  数据接收字1
                                  .rx_dw2r_in(rx_dw2r),     //  数据接收字2
                                  .rx_valid_in(rx_valid),      //  数据接收有效标志输入
                                  .rx_ready_out(rx_ready),   //  数据接收准备好输出

                                  .current_rated_value_out(current_rated_value_out),  //  额定电流值输出
                                  .speed_rated_value_out(speed_rated_value_out),  //  额定转速值输出

                                  .current_d_param_p_out(current_d_param_p_out),  //    电流环d轴控制参数p输出
                                  .current_d_param_i_out(current_d_param_i_out),   //    电流环d轴控制参数i输出
                                  .current_d_param_d_out(current_d_param_d_out),  //    电流环d轴控制参数d输出

                                  .current_q_param_p_out(current_q_param_p_out),         //q轴电流环P参数
                                  .current_q_param_i_out(current_q_param_i_out),          //q轴电流环I参数
                                  .current_q_param_d_out(current_q_param_d_out),         //q轴电流环D参数

                                  .speed_control_param_p_out(speed_control_param_p_out),   //速度闭环控制P参数
                                  .speed_control_param_i_out(speed_control_param_i_out),   //速度闭环控制I参数
                                  .speed_control_param_d_out(speed_control_param_d_out),   //速度闭环控制D参数

                                  .location_control_param_p_out(location_control_param_p_out),   //位置闭环控制P参数
                                  .location_control_param_i_out(location_control_param_i_out),   //位置闭环控制I参数
                                  .location_control_param_d_out(location_control_param_d_out),   //位置闭环控制D参数

                                  .band_breaks_mode_out(band_breaks_mode_out),  //抱闸工作模式输出

                                  .pmsm_start_stop_mode_out(pmsm_start_stop_mode_out),   //电机启停指令输出

                                  .pmsm_work_mode_out(pmsm_work_mode_out),     //电机工作模式指令输出

                                  .pmsm_speed_set_value_out(pmsm_speed_set_value_out),   //  电机转速设定值输出
                                  .pmsm_location_set_value_out(pmsm_location_set_value_out),    //电机位置设定值输出

                                  .gate_driver_register_1_in(gate_driver_register_1_in),  //  栅极寄存器状态1寄存器输入
                                  .gate_driver_register_2_in(gate_driver_register_2_in),  //  栅极寄存器状态2寄存器输入
                                  .gate_driver_error_in(gate_driver_error_in),          //栅极寄存器故障报警输入

                                  .current_detect_status_in(current_detect_status_in),
                                  .channela_detect_err_in(channela_detect_err_in),    //current detect error triger
                                  .channelb_detect_err_in(channelb_detect_err_in),   //current detect error triger
                                  .phase_a_current_in(phase_a_current_in),     //  a相电流检测值
                                  .phase_b_current_in(phase_b_current_in),    //  b相电流检测值
                                  .electrical_rotation_phase_sin_in(electrical_rotation_phase_sin_in),   //  电气角度正弦值输入
                                  .electrical_rotation_phase_cos_in(electrical_rotation_phase_cos_in),  //  电气角度余弦值输入
                                  .current_loop_control_enable_in(current_loop_control_enable_in),     //电流环控制使能输入，用于触发电流电气角度值上传

                                  . U_alpha_in(U_alpha_in),       //    Ualpha电压输入
                                  . U_beta_in(U_beta_in),         //    Ubeta电压输入
                                  .current_loop_control_done_in(current_loop_control_done_in),     //电压输出有效标志输入

                                  .Tcma_in(Tcma_in),    //  a 相时间切换点输出
                                  .Tcmb_in(Tcmb_in),    //   b相时间切换点输出
                                  .Tcmc_in(Tcmc_in),    //   c相时间切换点输出
                                  .svpwm_cal_done_in(svpwm_cal_done_in),  //svpwm计算完成输入，用于三相时间切换点数据上传

                                  .speed_detect_val_in(speed_detect_val_in),      //实际速度检测值
                                  .current_q_set_val_in(current_q_set_val_in),    //Q轴电流设定值
                                  .speed_loop_cal_done_in(speed_loop_cal_done_in),     //  速度闭环完成标志

                                  .pmsm_location_detect_value_in(pmsm_location_detect_value_in),   //位置检测输入
                                  .speed_set_value_in(speed_set_value_in),  //  位置模式速度设定值输入
                                  .pmsm_location_cal_done_in(pmsm_location_cal_done_in),   //位置闭环控制完成标志

                                  .ds_18b20_temp_in(ds_18b20_temp_in),  //  环境温度输入
                                  .ds_18b20_update_done_in(ds_18b20_update_done_in)  //环境温度更新指令
                                  );
//===========================================================================
//uart模块例化
//===========================================================================
uart_phy uart_phy_inst(
             .sys_clk(sys_clk),
             .reset_n(reset_n),

             .wr_data1_in(tx_dw1r),
             .wr_data2_in(tx_dw2r),
             . wr_data_valid_in(tx_valid),
             . wr_data_ready_out(tx_ready),

             .rx_data1_out(rx_dw1r),
             .rx_data2_out(rx_dw2r),
             .rx_valid_out(rx_valid),
             .rx_ready_in(rx_ready),

             .uart_rx_in(can_phy_rx),
             .uart_tx_out(can_phy_tx)
             );
assign can_init_done_out='b1;
//===========================================================================
//can总线数据链路层例化
//===========================================================================
//can_data_link can_data_link_inst(
//                                 .sys_clk(sys_clk),
//                                 .can_clk(can_clk),   //  can物理层时钟
//                                 .reset_n(reset_n),
//
//                                 //  can物理层端口
//                                 .can_phy_rx(can_phy_rx),
//                                 .can_phy_tx(can_phy_tx),
//
//                                 .system_initilization_done_in(system_initilization_done_in),              //  系统初始化完成输入,高电平有效
//
//                                 .can_init_enable_in(can_init_enable_in),    //   can初始化使能标志
//                                 .can_init_done_out(can_init_done_out),    //    can初始化完成标志
//
//                                 .tx_dw1r_in(tx_dw1r),       //   数据发送字1，
//                                 .tx_dw2r_in(tx_dw2r),       //   数据发送字2，
//                                 .tx_valid_in(tx_valid),       //   数据发送有效标志位
//                                 .tx_ready_out(tx_ready),    //  数据发送准备好标志
//
//                                 .rx_dw1r_out(rx_dw1r),    //  接收数据字1
//                                 .rx_dw2r_out(rx_dw2r),    //  接收数据字2
//                                 .rx_valid_out(rx_valid),     //  接收数据有效标志
//                                 .rx_ready_in(rx_ready)      //  接收准备好标志输入
//                                 );
endmodule
