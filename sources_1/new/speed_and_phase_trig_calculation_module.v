`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/18
// Design Name:PMSM_DESIGN
// Module Name: speed_and_phase_trig_calculation_module.v
// Target Device:
// Tool versions:
// Description:电机转子电角度正余弦值计算及转速标幺化计算
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module speed_and_phase_trig_calculation_module(
                                               input sys_clk,
                                               input reset_n,
                                               //   霍尔传感器输入
                                               input    hall_u_in,
                                               input    hall_v_in,
                                               input    hall_w_in,

                                               //   增量编码器输入
                                               input    incremental_encode_ch_a_in,
                                               input     incremental_encode_ch_b_in,

                                               //   电角度预测使能
                                               input     electrical_rotation_phase_forecast_enable_in,

                                               //额定转速输入
                                               input     [`DATA_WIDTH-1:0]  rated_speed_in,

                                               //转子电角度正余弦计算输出
                                               output  signed  [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_out, //电气旋转角度正弦输出
                                               output  signed  [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_out, //电气旋转角度余弦输出
                                               output   electrical_rotation_phase_trig_calculate_valid_out,                       //正余弦计算有效标志输出

                                               //转子转速输出
                                               output [`DATA_WIDTH-1:0]  standardization_speed_out
                                               );

//===========================================================================
//内部变量声明
//===========================================================================
wire rotate_direction_w;       //旋转方向
wire incremental_decoder_w;   //增量编码器四倍频

//===========================================================================
//增量编码器倍频及旋转方向测量
//===========================================================================
incremental_encoder_decoder_module incremental_encoder_decoder_inst(
                                                                    . sys_clk(sys_clk),                //系统时钟
                                                                    . reset_n(reset_n),                //复位信号，低电平有效
                                                                    
                                                                    . heds_9040_ch_a_in(incremental_encode_ch_a_in),    //增量编码器a通道输入
                                                                    . heds_9040_ch_b_in(incremental_encode_ch_b_in),   //增量编码器b通道输入
                                                                    
                                                                    .heds_9040_decoder_out(incremental_decoder_w),     //增量编码器解码输出
                                                                    .rotate_direction_out(rotate_direction_w)             //旋转方向输出，0：正转，1：反转
                                                                    );
//===========================================================================
//转子电角度正余弦计算
//===========================================================================
electrical_rotation_phase_trig_calculate_module electrical_rotation_phase_trig_calculate_inst(
                                                       .sys_clk(sys_clk),            //系统时钟
                                                       .reset_n(reset_n),            //复位信号，低电平有效
                                                       
                                                       .electrical_rotation_phase_forecast_enable_in(electrical_rotation_phase_forecast_enable_in),    //电气旋转角度相位预测使能，用于上电或复位时相位预判
                                                       
                                                       .incremental_encoder_decode_in(incremental_decoder_w),                 //增量编码器正交编码输入
                                                       .rotate_direction_in(rotate_direction_w),                                     //旋转方向输入

                                                       //hall signal input
                                                       .hall_u_in(hall_u_in),
                                                       .hall_v_in(hall_v_in),
                                                       .hall_w_in(hall_w_in),

                                                       .electrical_rotation_phase_sin_out(electrical_rotation_phase_sin_out), //电气旋转角度正弦输出[`DATA_WIDTH-1:0]
                                                       .electrical_rotation_phase_cos_out(electrical_rotation_phase_cos_out), //电气旋转角度余弦输出[`DATA_WIDTH-1:0]
                                                       .electrical_rotation_phase_trig_calculate_valid(electrical_rotation_phase_trig_calculate_valid_out)                       //正余弦计算有效标志输出
                                                       );

//===========================================================================
//  转子速度测量
//===========================================================================
speed_detection_module speed_detection_inst(
                              .sys_clk(sys_clk),
                              .reset_n(reset_n),
                              
                              .incremental_decoder_in(incremental_decoder_w),
                              .rotation_direction_in(rotate_direction_w),

                              . rated_speed_in(rated_speed_in),       //额定转速输入
                              
                              . standardization_speed_out(standardization_speed_out)  //标幺化速度值输出
                              );
endmodule
