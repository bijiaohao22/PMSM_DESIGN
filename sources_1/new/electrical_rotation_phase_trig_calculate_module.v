`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/12
// Design Name:PMSM_DESIGN
// Module Name: electrical_rotation_phase_trig_calculate_module.v
// Target Device:
// Tool versions:
// Description:获取电机转子旋转的电气角度并计算其正余弦值，用于PMSM的SVPWM坐标变换的计算
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module electrical_rotation_phase_trig_calculate_module(
                                                       input    sys_clk,            //系统时钟
                                                       input    reset_n,            //复位信号，低电平有效

                                                       input    electrical_rotation_phase_forecast_enable_in,    //电气旋转角度相位预测使能，用于上电或复位时相位预判

                                                       input    incremental_encoder_decode_in,                 //增量编码器正交编码输入
                                                       input    rotate_direction_in,                                     //旋转方向输入

                                                       //hall signal input
                                                       input        hall_u_in,
                                                       input        hall_v_in,
                                                       input        hall_w_in,

                                                       output  signed  [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_out, //电气旋转角度正弦输出
                                                       output  signed  [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_out, //电气旋转角度余弦输出
                                                       output   electrical_rotation_phase_trig_calculate_valid                       //正余弦计算有效标志输出
                                                       );
//===========================================================================
//内部变量声明
//===========================================================================
wire hall_u_w,hall_v_w,hall_w_w;     //霍尔编码器模块间连线
wire [`DATA_WIDTH-1:0] electrical_rotation_phase_w; //转子电角度
wire electrical_rotation_phase_valid_w; //转子电角度有效标志

//===========================================================================
//霍尔编码器信息预处理
//===========================================================================
hall_decode_module hall_decode(
                               .sys_clk(sys_clk),
                               .reset_n(reset_n),

                               .hall_u_in(hall_u_in),
                               .hall_v_in(hall_v_in),
                               .hall_w_in(hall_w_in),

                               .hall_u_out(hall_u_w),
                               .hall_v_out(hall_v_w),
                               .hall_w_out(hall_w_w)
                               );
//===========================================================================
//转子电角度处理计算
//===========================================================================
electrical_rotation_phase_calculate_module electrical_rotation_phase_calculate(
                                                                               .sys_clk(sys_clk),
                                                                               .reset_n(reset_n),

                                                                               .electrical_rotation_phase_forecast_enable_in(electrical_rotation_phase_forecast_enable_in),            //电气旋转角度相位预测使能，用于上电或复位时相位预判

                                                                               //增量编码器信息输入
                                                                               .heds_9040_decoder_in(incremental_encoder_decode_in),           //增量编码器正交编码输入
                                                                               .rotate_direction_in(rotate_direction_in),                  //旋转方向输入

                                                                               //霍尔传感器输入
                                                                               .hall_u_in(hall_u_w),
                                                                               .hall_v_in(hall_v_w),
                                                                               .hall_w_in(hall_w_w),

                                                                               //电气角度输出
                                                                               .electrical_rotation_phase_out(electrical_rotation_phase_w),
                                                                               .electrical_rotation_phase_valid_out(electrical_rotation_phase_valid_w)
                                                                               );
//===========================================================================
//正余弦计算
//===========================================================================
sin_and_cos_calculate_module  sin_and_cos_calculate(
                                                    .sys_clk(sys_clk),
                                                    .reset_n(reset_n),

                                                    .electrical_rotation_phase_in(electrical_rotation_phase_w),
                                                    .electrical_rotation_phase_valid_in(electrical_rotation_phase_valid_w),

                                                    .electrical_rotation_phase_sin_out(electrical_rotation_phase_sin_out),
                                                    .electrical_rotation_phase_cos_out(electrical_rotation_phase_cos_out),
                                                    .electrical_rotation_phase_trig_valid_out(electrical_rotation_phase_trig_calculate_valid)   //正余弦计算有效标志
                                                    );
endmodule
