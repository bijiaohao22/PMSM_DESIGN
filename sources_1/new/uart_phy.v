//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/6/4
// Design Name:PMSM_DESIGN
// Module Name: uart_phy.v
// Target Device:
// Tool versions:
// Description:uart物理层协议
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module uart_phy#(
                 parameter band_rate = 230400
                 ) (
                    input   sys_clk,
                    input   reset_n,

                    input [31:0] wr_data1_in,
                    input [31:0] wr_data2_in,
                    input            wr_data_valid_in,
                    output          wr_data_ready_out,

                    output[31:0]  rx_data1_out,
                    output[31:0]   rx_data2_out,
                    output              rx_valid_out,
                    input                rx_ready_in,

                    input    uart_rx_in,
                    output  uart_tx_out
                    );
//===========================================================================
//发送模块例化
//===========================================================================
uart_tx_phy #(
              .band_rate(band_rate)
              ) uart_tx_phy_inst(
                                 .sys_clk(sys_clk),
                                 .reset_n(reset_n),

                                 .wr_data1_in(wr_data1_in),
                                 .wr_data2_in(wr_data2_in),
                                 . wr_data_valid_in(wr_data_valid_in),
                                 . wr_data_ready_out(wr_data_ready_out),

                                 .uart_tx_out(uart_tx_out)
                                 );
//===========================================================================
//接收模块例化
//===========================================================================
uart_rx_phy #(
              .band_rate(band_rate)
              ) uart_rx_phy_inst (
                                  .sys_clk(sys_clk),
                                  .reset_n(reset_n),

                                  .uart_rx_in(uart_rx_in),

                                  .rx_data1_out(rx_data1_out),
                                  .rx_data2_out(rx_data2_out),
                                  .rx_valid_out(rx_valid_out),
                                  .rx_ready_in(rx_ready_in)
                                  );
endmodule
