//====================================================================================
// Company:
// Engineer:
// Create Date: 2018/5/29
// Design Name:
// Module Name: mcp_2515_spi_phy.v
// Target Device:
// Tool versions:
// Description:
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module mcp_2515_spi_phy(
                        input    sys_clk,
                        input    reset_n,

                        input    opercation_cmd_in,     //  操作命令
                        input [7:0]      read_addr_in,       //  读地址输入
                        input    rd_cmd_valid_in,           //   读操作命令有效输入
                        output  rd_cmd_ready_out,         //   读操作准备好标志

                        output [31:0]    read_data1_out,  //   数据读字段1
                        output [31:0]   read_data2_out,   //   数据读字段2输出
                        output              rd_data_valid_out, //  读数据有效标志

                        input [7:0]    wr_addr_in,         //  写操作地址输入
                        input            wr_valid_out,      //  写操作有效标志
                        input [31:0] wr_sidh_in,          //  写操作表示符输入
                        input [7:0]   wr_dlc_in,            //  写操作长度码输入
                        input [31:0] wr_data1_in,        //  写操作数据1输入
                        input [31:0] wr_data2_in,        //  写操作数据2输入
                        output          wr_ready_out,      //   写操作准备好输出

                        //mcp_2515_spi
                        output          spi_sck_out,         //  spi时钟输出
                        output          spi_sdo_out,         //  spi主机数据输出
                        input            spi_sdi_in,           //  spi从机输入
                        output          spi_cs_n_out       //   spi片选使能，低电平有效
                        );
//===========================================================================
//内部变量声明
//===========================================================================

endmodule
