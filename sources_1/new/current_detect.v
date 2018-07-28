`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: li-Xiaochuang
// Create Date: 2018/3/15
// Design Name:PMSM_DESIGN
// Module Name: current_detect.v
// Target Device:
// Tool versions:
// Description: detect the current of phase a and phase b
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module current_detect(
                      input    sys_clk,                //system clock
                      input    reset_n,                //reset signal,low active

                      input    detect_enable_in , //detect_enable signale
                      input    [`DATA_WIDTH-1:0]  pmsm_imax_in,  //电机额定电流值
                     
                      //channel a port
                      input    channela_sdat_in,     //spi data input
                      input    channela_ocd_in,     //over_current_detect input
                      output  channela_sclk_out,   //spi clk output
                      output  channela_cs_n_out,  //chip select otuput

                      //channel b port
                      input    channelb_sdat_in,     //spi data input
                      input    channelb_ocd_in,     //over_current_detect input
                      output  channelb_sclk_out,   //spi clk output
                      output  channelb_cs_n_out,  //chip select otuput

                      //current detect
                      output signed[`DATA_WIDTH-1:0] phase_a_current_out,
                      output signed[`DATA_WIDTH-1:0] phase_b_current_out,

                      //current_detect_err_message output
                      output [`DATA_WIDTH-1:0] current_detect_status_out,
                      output  channela_detect_err_out, //current detect error triger
                      output  channelb_detect_err_out, //current detect error triger
                      //detect done signal
                      output channela_detect_done_out,    //channel a detect done signal out
                      output channelb_detect_done_out     //channel b detect done signal out
                      );

//===========================================================================
//内部变量声明
//===========================================================================
wire signed [`DATA_WIDTH-1:0]  channel_a_current;
wire channel_a_current_phy_detect_done;

wire signed [`DATA_WIDTH-1:0]  channel_b_current;
wire channel_b_current_phy_detect_done;
//===========================================================================
//A通道电流检测模块声明
//===========================================================================
current_detect_phy phase_a_current_detect(
                                          .sys_clk(sys_clk),                //system clock
                                          .reset_n(reset_n),                //reset signal,low active

                                          .pmsm_imax_in(pmsm_imax_in),
                                          .detect_enable_in(detect_enable_in), //detect_enable signale

                                          .spi_data_in(channela_sdat_in),         //spi data in
                                          .spi_sclk_out(channela_sclk_out),       //spi sclk out
                                          .spi_cs_n_out(channela_cs_n_out),      //chip select out ,low-active

                                          .current_out(channel_a_current),         //current detect out

                                          .state_out(current_detect_status_out[`DATA_WIDTH-1-8:0]),               //status of the sensor out
                                          .detect_err_out(channela_detect_err_out),      //current detect error out

                                          .detect_done_out(channel_a_current_phy_detect_done)   //current detect done out
                                          );
//电流标幺化
current_per_unit_module phase_a_standardization_module(
                                                       . sys_clk(sys_clk),
                                                       . reset_n(reset_n),

                                                       .current_value_valid_in(channel_a_current_phy_detect_done),                                             //电流有效标志
                                                       .current_value_in(channel_a_current),                  //电流检测值

                                                       .pmsm_imax_in(pmsm_imax_in),                    //电机额定电流值

                                                       .current_standardization_out(phase_a_current_out),  //电流标幺化输出值
                                                       .current_porce_done_out(channela_detect_done_out)                                              //电流标幺化完成标志
                                                       );
//===========================================================================
//B通道电流检测模块声明
//===========================================================================
current_detect_phy channel_b_current_detect(
                                            .sys_clk(sys_clk),                //system clock
                                            .reset_n(reset_n),                //reset signal,low active

                                            .pmsm_imax_in(pmsm_imax_in),
                                            .detect_enable_in(detect_enable_in), //detect_enable signale

                                            .spi_data_in(channelb_sdat_in),         //spi data in
                                            .spi_sclk_out(channelb_sclk_out),       //spi sclk out
                                            .spi_cs_n_out(channelb_cs_n_out),      //chip select out ,low-active

                                            .current_out(channel_b_current),         //current detect out

                                            .state_out(current_detect_status_out[`DATA_WIDTH-1:`DATA_WIDTH-8]),               //status of the sensor out
                                            .detect_err_out(channelb_detect_err_out),      //current detect error out

                                            .detect_done_out(channel_b_current_phy_detect_done)   //current detect done out
                                            );
//电流标幺化
current_per_unit_module phase_b_standardization_module(
                                                       . sys_clk(sys_clk),
                                                       . reset_n(reset_n),

                                                       .current_value_valid_in(channel_b_current_phy_detect_done),                                             //电流有效标志
                                                       .current_value_in(channel_b_current),                  //电流检测值

                                                       .pmsm_imax_in(pmsm_imax_in),                    //电机额定电流值

                                                       .current_standardization_out(phase_b_current_out),  //电流标幺化输出值
                                                       .current_porce_done_out(channelb_detect_done_out)                                              //电流标幺化完成标志
                                                       );
endmodule
