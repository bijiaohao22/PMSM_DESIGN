//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/9
// Design Name:PMSM_DESIGN
// Module Name: gate_driver_unit.v
// Target Device:
// Tool versions:
// Description:
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module gate_driver_unit(
                        input    sys_clk,
                        input    reset_n,

                        input    gate_driver_init_enable_in,  //  栅极驱动器上电或复位后初始化使能输入
                        output  gate_driver_init_done_out,  //  栅极驱动器初始化完成标志

                        input  gate_a_high_side_in,                     //    a相上桥壁控制
                        input  gate_a_low_side_in,                      //    a相下桥臂控制
                        input  gate_b_high_side_in,                    //    b相上桥臂控制
                        input  gate_b_low_side_in,                     //    b相下桥臂控制
                        input  gate_c_high_side_in,                    //     c相上桥臂控制
                        input  gate_c_low_side_in,                      //     c相下桥臂控制

                        output  gate_driver_enable_out,
                        output  gate_driver_nscs_out,
                        output  gate_driver_sclk_out,
                        output  gate_driver_sdi_out,
                        input  gate_driver_sdo_in,
                        input  gate_driver_nfault_in,

                        output  gate_a_high_side_out,                     //    a相上桥壁控制
                        output  gate_a_low_side_out,                      //    a相下桥臂控制
                        output  gate_b_high_side_out,                    //    b相上桥臂控制
                        output  gate_b_low_side_out,                     //    b相下桥臂控制
                        output  gate_c_high_side_out,                    //     c相上桥臂控制
                        output  gate_c_low_side_out,                     //     c相下桥臂控制

                        output[`DATA_WIDTH-1:0]    gate_driver_register_1_out,  //  栅极寄存器状态1寄存器输出
                        output[`DATA_WIDTH-1:0]    gate_driver_register_2_out,  //  栅极寄存器状态2寄存器输出
                        output  gate_driver_error_out   //栅极寄存器故障报警输出
                        );
//===========================================================================
//内部变量声明
//===========================================================================
wire  [`SPI_FRAME_WIDTH-1:0]    wr_data_w;    //spi数据写端口
wire wr_data_valid_w; //spi写有效标志
wire [`SPI_FRAME_WIDTH-1:0]    rd_data_w;    //spi读数据端口
wire rd_data_enable_w;   //spi读使能端口
wire [`DATA_WIDTH-1:0]    rd_addr_w;   //spi读地址端口
wire spi_proc_done_w; //    spi操作完成标志
wire spi_proc_busy_w; //    spi忙标志

//===========================================================================
//spi 物理层协议例化
//===========================================================================
spi_phy_unit spi_phy_inst(
                          .sys_clk(sys_clk),
                          .reset_n(reset_n),

                          .wr_data_in(wr_data_w),  //  数据写端口
                          .wr_data_valid_in(wr_data_valid_w),                      //  数据写端口有效标志

                          .rd_data_out(rd_data_w),  //   数据读端口
                          .rd_data_enable_in(rd_data_enable_w),     //  数据读端口使能标志
                          .rd_addr_in(rd_addr_w),   //  读地址输入

                          .spi_proc_done_out(spi_proc_done_w),   //    spi操作完成标志
                          .spi_proc_busy_out(spi_proc_busy_w),   //    spi忙标志

                          . spi_nscs_out(gate_driver_nscs_out),        //spi使能标志输出
                          . spi_sclk_out(gate_driver_sclk_out),           //spi时钟端口输出
                          . spi_sdo_out(gate_driver_sdi_out),           //   spi数据输出端口
                          .  spi_sdi_in(gate_driver_sdo_in)               //   spi数据输入端口
                          );
//===========================================================================
//栅极驱动器初始化及状态监控模块例化
//===========================================================================
gate_driver_init_and_monitor_unit gate_driver_init_and_monitor_inst(
                                                                    .sys_clk(sys_clk),
                                                                    .reset_n(reset_n),

                                                                    .gate_driver_init_enable_in(gate_driver_init_enable_in),  //  栅极驱动器上电或复位后初始化使能输入
                                                                    .gate_driver_init_done_out(gate_driver_init_done_out),  //  栅极驱动器初始化完成标志

                                                                    .gate_driver_nfault_in(gate_driver_nfault_in),           //   栅极驱动器错误检测输入，低电平有效
                                                                    .gate_driver_enable_out(gate_driver_enable_out),      //   栅极驱动器使能输出，高电平有效

                                                                    .wr_data_out(wr_data_w),    //  spi写数据
                                                                    .wr_data_enable_out(wr_data_valid_w),    //  spi写使能
                                                                    .rd_addr_out(rd_addr_w), //  spi读寄存器地址
                                                                    .rd_data_enable_out(rd_data_enable_w), //  spi读使能
                                                                    .rd_data_in(rd_data_w),   //spi读数据

                                                                    .spi_phy_proc_done_in(spi_proc_done_w),   //  spi物理层处理完成标志
                                                                    .spi_phy_proc_busy_in(spi_proc_busy_w),   //  spi物理层忙标志

                                                                    .gate_driver_register_1_out(gate_driver_register_1_out),  //  栅极寄存器状态1寄存器输出
                                                                    .gate_driver_register_2_out(gate_driver_register_2_out),  //  栅极寄存器状态2寄存器输出
                                                                    .gate_driver_error_out(gate_driver_error_out)   //栅极寄存器故障报警输出
                                                                    );
//===========================================================================
//栅极驱动器桥臂驱动模块例化
//===========================================================================
gate_driver_bridge_unit gate_driver_bridge_inst(
                                                .sys_clk(sys_clk),
                                                .reset_n(reset_n),

                                                .gate_driver_nfault_in(gate_driver_nfault_in),                    //栅极驱动器错误检测输入

                                                .gate_a_high_side_in(gate_a_high_side_in),                     //    a相上桥壁控制
                                                .gate_a_low_side_in(gate_a_low_side_in),                      //    a相下桥臂控制
                                                .gate_b_high_side_in(gate_b_high_side_in),                    //    b相上桥臂控制
                                                .gate_b_low_side_in(gate_b_low_side_in),                     //    b相下桥臂控制
                                                .gate_c_high_side_in(gate_c_high_side_in),                    //     c相上桥臂控制
                                                .gate_c_low_side_in(gate_c_low_side_in),                      //     c相下桥臂控制

                                                .gate_a_high_side_out(gate_a_high_side_out),                     //    a相上桥壁控制
                                                .gate_a_low_side_out(gate_a_low_side_out),                      //    a相下桥臂控制
                                                .gate_b_high_side_out(gate_b_high_side_out),                    //    b相上桥臂控制
                                                .gate_b_low_side_out(gate_b_low_side_out),                     //    b相下桥臂控制
                                                .gate_c_high_side_out(gate_c_high_side_out),                    //     c相上桥臂控制
                                                .gate_c_low_side_out(gate_c_low_side_out)                      //     c相下桥臂控制
                                                );
endmodule
