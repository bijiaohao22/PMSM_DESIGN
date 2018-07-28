`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/4/18
// Design Name:PMSM_DESIGN
// Module Name: speed_detection_module.v
// Target Device:
// Tool versions:
// Description:根据增量编码器经四倍频后的编码信息对电机转速做测量
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module speed_detection_module(
                              input    sys_clk,
                              input    reset_n,

                              input    incremental_decoder_in,
                              input    rotation_direction_in,

                              input  [`DATA_WIDTH-1:0]  rated_speed_in,       //额定转速输入

                              output [`DATA_WIDTH-1:0]  standardization_speed_out  //标幺化速度值输出
                              );
//===========================================================================
//内部变量声明
//===========================================================================
wire [7:0] speed_area_count_value_w;             //速度预测计数模式
wire         speed_area_count_value_valid_w;    //速度预测结果有效标志
wire [25:0]   speed_pluse_time_cnt_w;            //脉冲计时
wire [25:0] speed_pluse_count_dividend_w; //脉冲计数*390625
wire             speed_cnt_valid_w;                   // 脉冲计时计数有效标志位

//===========================================================================
//速度预测模块例化
//===========================================================================
speed_forcast_module speed_forcast_inst(
                                        .sys_clk(sys_clk),        //system clock
                                        .reset_n(reset_n),        //low-active

                                        . incremental_encoder_pluse_in(incremental_decoder_in),           //增量编码器倍频输入

                                        .speed_area_count_value_out(speed_area_count_value_w),   //脉冲个数计数值[7:0]
                                        .speed_area_count_value_valid_out(speed_area_count_value_valid_w)             //脉冲计数值有效标志位
                                        );
//===========================================================================
//M/T测速法计时计数
//===========================================================================
incremental_pluse_time_count_module incremental_pluse_time_count_inst(
                                                                      .sys_clk(sys_clk),
                                                                      .reset_n(reset_n),

                                                                      .speed_area_count_value_in(speed_area_count_value_w), //速度模式预测区间,[7:0]
                                                                      .speed_area_count_valid_in(speed_area_count_value_valid_w), //速度模式有效标志位

                                                                      .incremental_encoder_pluse_in(incremental_decoder_in),    //增量编码器脉宽输入

                                                                      .speed_pluse_time_cnt_out(speed_pluse_time_cnt_w),          //脉冲计时输出[25:0]
                                                                      .speed_pluse_count_dividend_out(speed_pluse_count_dividend_w), //脉冲个数输出*390625[25:0]
                                                                      .speed_cnt_valid_out(speed_cnt_valid_w)                    //速度测量计数输出有效标志位
                                                                      );
//===========================================================================
//速度计算与标幺化
//===========================================================================
speed_calculate_and_standardization_module speed_calculate_and_standardization_inst(
                                                    .sys_clk(sys_clk),
                                                    .reset_n(reset_n),

                                                   .speed_pluse_time_cnt_in(speed_pluse_time_cnt_w),                          //脉冲计时输入M2
                                                   .speed_pluse_count_dividend_in(speed_pluse_count_dividend_w),               //脉冲计数M1*390625
                                                   .speed_cnt_valid_in(speed_cnt_valid_w),                                  //脉冲计时计数有效标志位
                                                   .rotation_direction_in(rotation_direction_in),                                //电机旋转方向输入
                                                   .rated_speed_in(rated_speed_in),                                         //额定转速输入

                                                  .standardization_speed_out(standardization_speed_out)                       //电机速度标幺化输出
                                                  );
endmodule
