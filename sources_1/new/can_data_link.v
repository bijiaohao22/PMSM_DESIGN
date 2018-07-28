//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/21
// Design Name:PMSM_DESIGN
// Module Name: can_data_link.v
// Target Device:
// Tool versions:
// Description:can总线数据链路层，封装can总线通讯协议应用
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module can_data_link(
                     input    sys_clk,
                     input    can_clk,   //  can物理层时钟
                     input    reset_n,

                     //  can物理层端口
                     input    can_phy_rx,
                     output  can_phy_tx,

                     input   system_initilization_done_in,              //  系统初始化完成输入,高电平有效

                     input    can_init_enable_in,    //   can初始化使能标志
                     output  can_init_done_out,    //    can初始化完成标志

                     input[31:0]  tx_dw1r_in,       //   数据发送字1，
                     input[31:0]  tx_dw2r_in,       //   数据发送字2，
                     input               tx_valid_in,       //   数据发送有效标志位
                     output             tx_ready_out,    //  数据发送准备好标志

                     output[31:0] rx_dw1r_out,    //  接收数据字1
                     output[31:0] rx_dw2r_out,    //  接收数据字2
                     output            rx_valid_out,     //  接收数据有效标志
                     input              rx_ready_in      //  接收准备好标志输入
                     );
//===========================================================================
//内部变量声明
//===========================================================================
wire can_interrupt_w;  //can Ip核中断标志线网
                       //axi总线线网
wire[7:0] axi_awaddr_w;    //  总线写地址输入
wire axi_awvalid_w;    //  总线写地址有效信号
wire axi_awready_w;   //  总线写地址准备，表示准备好接收地址写请求
wire[31:0] axi_wdata_w; //  写数据通道
wire[3:0] axi_wstrb_w;   //   总线写选通，对应数据总线的每8位，有一个写通道
wire axi_wvalid_w;         //   表示所要求的写有效数据和选通有效
wire axi_wready_w;        //   写准备，表示可接受
wire[1:0] axi_bresp_w;  //   写响应，表示写交易的状态。00表示成功，01表示Exclusive access okay，10：表示从机错误，11表示译码错误
wire axi_bvalid_w;         //   写响应有效，该信号表示所要求的有效写响应可用
wire axi_bready_w;        //    响应准备，表示主设备可接受响应信息
wire[7:0] axi_araddr_w; //    总线读地址
wire axi_arvalid_w;      //  读地址有效
wire axi_arready_w;     //  读地址准备。该信号表示从设备准备接受地址和相关的控制信息
wire[31:0] axi_rdata_w;  //  读数据
wire[1:0] axi_rresp_w;  //  读响应
wire axi_rvalid_w;   //读有效，表示所有要求的读数据可用，可以完成读传输
wire axi_rready_w;  //读准备，表示主设备能够接受读数据和响应信息

//  自定义命令接口层
wire[7:0]   cmd_wr_addr_w;
wire[31:0] cmd_wr_data_w;
wire           cmd_wr_enable_w;
wire           cmd_wr_done_w;
wire           cmd_wr_busy_w;

wire[7:0]   cmd_rd_addr_w;
wire[31:0] cmd_rd_data_w;
wire           cmd_rd_enable_w;
wire           cmd_rd_done_w;
wire           cmd_rd_busy_w;

//初始化模块端口
wire [7:0]   can_init_wr_addr_w;
wire [31:0] can_init_wr_data_w;
wire           can_init_wr_enable_w;
wire [7:0]   can_init_rd_addr_w;
wire           can_init_rd_enable_w;
//数据分发模块端口
wire [7:0]   can_trans_wr_addr_w;
wire [31:0] can_trans_wr_data_w;
wire           can_trans_wr_enable_w;
wire [7:0]   can_trans_rd_addr_w;
wire           can_trans_rd_enable_w;
//===========================================================================
//can IP核例化
//===========================================================================
pmsm_can_phy pmsm_can_unit(
                           .can_clk(can_clk),                    // input wire can_clk
                           .can_phy_rx(can_phy_rx),              // input wire can_phy_rx
                           .can_phy_tx(can_phy_tx),              // output wire can_phy_tx

                           .ip2bus_intrevent(can_interrupt_w),  // output wire ip2bus_intrevent

                           .s_axi_aclk(sys_clk),              // input wire s_axi_aclk
                           .s_axi_aresetn(reset_n),        // input wire s_axi_aresetn

                           .s_axi_awaddr(axi_awaddr_w),          // input wire [7 : 0] s_axi_awaddr
                           .s_axi_awvalid(axi_awvalid_w),        // input wire s_axi_awvalid
                           .s_axi_awready(axi_awready_w),        // output wire s_axi_awready

                           .s_axi_wdata(axi_wdata_w),            // input wire [31 : 0] s_axi_wdata
                           .s_axi_wstrb(axi_wstrb_w),            // input wire [3 : 0] s_axi_wstrb
                           .s_axi_wvalid(axi_wvalid_w),          // input wire s_axi_wvalid
                           .s_axi_wready(axi_wready_w),          // output wire s_axi_wready

                           .s_axi_bresp(axi_bresp_w),            // output wire [1 : 0] s_axi_bresp
                           .s_axi_bvalid(axi_bvalid_w),          // output wire s_axi_bvalid
                           .s_axi_bready(axi_bready_w),          // input wire s_axi_bready

                           .s_axi_araddr(axi_araddr_w),          // input wire [7 : 0] s_axi_araddr
                           .s_axi_arvalid(axi_arvalid_w),        // input wire s_axi_arvalid
                           .s_axi_arready(axi_arready_w),        // output wire s_axi_arready

                           .s_axi_rdata(axi_rdata_w),            // output wire [31 : 0] s_axi_rdata
                           .s_axi_rresp(axi_rresp_w),            // output wire [1 : 0] s_axi_rresp

                           .s_axi_rvalid(axi_rvalid_w),          // output wire s_axi_rvalid
                           .s_axi_rready(axi_rready_w)          // input wire s_axi_rready
                           );
//===========================================================================
//接口转换IP核例化
//===========================================================================
cmd_to_axi_lite_unit cmd_to_axi_lite_inst(
                                          .sys_clk(sys_clk),
                                          .reset_n(reset_n),

                                          .wr_addr_in(cmd_wr_addr_w),
                                          .wr_data_in(cmd_wr_data_w),
                                          .wr_enable_in(cmd_wr_enable_w),   //  写指令有效标志
                                          .wr_done_out(cmd_wr_done_w),   //   写操作完成标志
                                          .wr_busy_out(cmd_wr_busy_w),   //    写操作忙标志

                                          .rd_addr_in(cmd_rd_addr_w),    //  读操作地址输入
                                          .rd_enable_in(cmd_rd_enable_w), //   读操作使能标志
                                          .rd_data_out(cmd_rd_data_w),  //  读操作数据输出
                                          .rd_done_out(cmd_rd_done_w),
                                          .rd_busy_out(cmd_rd_busy_w),

                                          .s_axi_awaddr_out(axi_awaddr_w),
                                          .s_axi_awvalid_out(axi_awvalid_w),
                                          .s_axi_awready_in(axi_awready_w),

                                          .s_axi_wdata_out(axi_wdata_w),
                                          .s_axi_wstrb_out(axi_wstrb_w),
                                          .s_axi_wvalid_in(axi_wvalid_w),
                                          .s_axi_wready_in(axi_wready_w),

                                          .s_axi_bresp_in(axi_bresp_w),
                                          .s_axi_bvalid_in(axi_bvalid_w),
                                          .s_axi_bready_out(axi_bready_w),

                                          .s_axi_araddr_out(axi_araddr_w),
                                          .s_axi_arvalid_out(axi_arvalid_w),
                                          .s_axi_arready_in(axi_arready_w),

                                          .s_axi_rdata_in(axi_rdata_w),
                                          .s_axi_rresp_in(axi_rresp_w),

                                          .s_axi_rvalid_in(axi_rvalid_w),
                                          .s_axi_rready_out(axi_rready_w)
                                          );
//===========================================================================
//初始化模块例化
//===========================================================================
can_init_unit can_init_inst(
                            .sys_clk(sys_clk),
                            .reset_n(reset_n),

                            .can_init_enable_in(can_init_enable_in),    //   can初始化使能标志
                            .can_init_done_out(can_init_done_out),    //    can初始化完成标志

                            .wr_addr_out(can_init_wr_addr_w), //can总线写地址
                            .wr_data_out(can_init_wr_data_w), //can总线写数据
                            .wr_enable_out(can_init_wr_enable_w), //can总线写使能
                            .wr_done_in(cmd_wr_done_w),    //can写操作完成输入
                            .wr_busy_in(cmd_wr_busy_w),    //can总线写操作忙标志

                            . rd_addr_out(can_init_rd_addr_w), //can总线读地址
                            . rd_enable_out(can_init_rd_enable_w), //can总线读使能
                            . rd_done_in(cmd_rd_done_w),   //can总线读完成输入
                            .rd_data_in(cmd_rd_data_w)     //can总线读数据输入
                            );
//===========================================================================
//数据分发模块例化
//===========================================================================
can_data_trans_unit can_data_trans_inst(
                                        .sys_clk(sys_clk),
                                        .reset_n(reset_n),

                                        .tx_dw1r_in(tx_dw1r_in),       //   数据发送字1，
                                        .tx_dw2r_in(tx_dw2r_in),       //   数据发送字2，
                                        .tx_valid_in(tx_valid_in),       //   数据发送有效标志位
                                        .tx_ready_out(tx_ready_out),    //  数据发送准备好标志

                                        .rx_dw1r_out(rx_dw1r_out),    //  接收数据字1
                                        .rx_dw2r_out(rx_dw2r_out),    //  接收数据字2
                                        .rx_valid_out(rx_valid_out),     //  接收数据有效标志
                                        .rx_ready_in(rx_ready_in),      //  接收准备好标志输入

                                        .wr_addr_out(can_trans_wr_addr_w),
                                        .wr_data_out(can_trans_wr_data_w),
                                        .wr_enable_out(can_trans_wr_enable_w),
                                        .wr_done_in(cmd_wr_done_w),
                                        .wr_busy_in(cmd_wr_busy_w),

                                        . rd_addr_out(can_trans_rd_addr_w),
                                        . rd_enable_out(can_trans_rd_enable_w),
                                        .rd_data_in(cmd_rd_data_w),
                                        .rd_done_in(cmd_rd_done_w),
                                        .rd_busy_in(cmd_rd_busy_w),

                                        .ip2bus_intrevent_in(can_interrupt_w)
                                        );
//===========================================================================
//数据通道切换
//===========================================================================
assign cmd_wr_addr_w=system_initilization_done_in?can_trans_wr_addr_w:can_init_wr_addr_w;
assign cmd_wr_data_w=system_initilization_done_in?can_trans_wr_data_w:can_init_wr_data_w;
assign cmd_wr_enable_w=system_initilization_done_in?can_trans_wr_enable_w:can_init_wr_enable_w;
assign cmd_rd_addr_w=system_initilization_done_in?can_trans_rd_addr_w:can_init_rd_addr_w;
assign cmd_rd_enable_w=system_initilization_done_in?can_trans_rd_enable_w:can_init_rd_enable_w;
endmodule
