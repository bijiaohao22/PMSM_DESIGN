//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/21
// Design Name:PMSM_DESIGN
// Module Name: can_data_link.v
// Target Device:
// Tool versions:
// Description:can����������·�㣬��װcan����ͨѶЭ��Ӧ��
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module can_data_link(
                     input    sys_clk,
                     input    can_clk,   //  can�����ʱ��
                     input    reset_n,

                     //  can�����˿�
                     input    can_phy_rx,
                     output  can_phy_tx,

                     input   system_initilization_done_in,              //  ϵͳ��ʼ���������,�ߵ�ƽ��Ч

                     input    can_init_enable_in,    //   can��ʼ��ʹ�ܱ�־
                     output  can_init_done_out,    //    can��ʼ����ɱ�־

                     input[31:0]  tx_dw1r_in,       //   ���ݷ�����1��
                     input[31:0]  tx_dw2r_in,       //   ���ݷ�����2��
                     input               tx_valid_in,       //   ���ݷ�����Ч��־λ
                     output             tx_ready_out,    //  ���ݷ���׼���ñ�־

                     output[31:0] rx_dw1r_out,    //  ����������1
                     output[31:0] rx_dw2r_out,    //  ����������2
                     output            rx_valid_out,     //  ����������Ч��־
                     input              rx_ready_in      //  ����׼���ñ�־����
                     );
//===========================================================================
//�ڲ���������
//===========================================================================
wire can_interrupt_w;  //can Ip���жϱ�־����
                       //axi��������
wire[7:0] axi_awaddr_w;    //  ����д��ַ����
wire axi_awvalid_w;    //  ����д��ַ��Ч�ź�
wire axi_awready_w;   //  ����д��ַ׼������ʾ׼���ý��յ�ַд����
wire[31:0] axi_wdata_w; //  д����ͨ��
wire[3:0] axi_wstrb_w;   //   ����дѡͨ����Ӧ�������ߵ�ÿ8λ����һ��дͨ��
wire axi_wvalid_w;         //   ��ʾ��Ҫ���д��Ч���ݺ�ѡͨ��Ч
wire axi_wready_w;        //   д׼������ʾ�ɽ���
wire[1:0] axi_bresp_w;  //   д��Ӧ����ʾд���׵�״̬��00��ʾ�ɹ���01��ʾExclusive access okay��10����ʾ�ӻ�����11��ʾ�������
wire axi_bvalid_w;         //   д��Ӧ��Ч�����źű�ʾ��Ҫ�����Чд��Ӧ����
wire axi_bready_w;        //    ��Ӧ׼������ʾ���豸�ɽ�����Ӧ��Ϣ
wire[7:0] axi_araddr_w; //    ���߶���ַ
wire axi_arvalid_w;      //  ����ַ��Ч
wire axi_arready_w;     //  ����ַ׼�������źű�ʾ���豸׼�����ܵ�ַ����صĿ�����Ϣ
wire[31:0] axi_rdata_w;  //  ������
wire[1:0] axi_rresp_w;  //  ����Ӧ
wire axi_rvalid_w;   //����Ч����ʾ����Ҫ��Ķ����ݿ��ã�������ɶ�����
wire axi_rready_w;  //��׼������ʾ���豸�ܹ����ܶ����ݺ���Ӧ��Ϣ

//  �Զ�������ӿڲ�
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

//��ʼ��ģ��˿�
wire [7:0]   can_init_wr_addr_w;
wire [31:0] can_init_wr_data_w;
wire           can_init_wr_enable_w;
wire [7:0]   can_init_rd_addr_w;
wire           can_init_rd_enable_w;
//���ݷַ�ģ��˿�
wire [7:0]   can_trans_wr_addr_w;
wire [31:0] can_trans_wr_data_w;
wire           can_trans_wr_enable_w;
wire [7:0]   can_trans_rd_addr_w;
wire           can_trans_rd_enable_w;
//===========================================================================
//can IP������
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
//�ӿ�ת��IP������
//===========================================================================
cmd_to_axi_lite_unit cmd_to_axi_lite_inst(
                                          .sys_clk(sys_clk),
                                          .reset_n(reset_n),

                                          .wr_addr_in(cmd_wr_addr_w),
                                          .wr_data_in(cmd_wr_data_w),
                                          .wr_enable_in(cmd_wr_enable_w),   //  дָ����Ч��־
                                          .wr_done_out(cmd_wr_done_w),   //   д������ɱ�־
                                          .wr_busy_out(cmd_wr_busy_w),   //    д����æ��־

                                          .rd_addr_in(cmd_rd_addr_w),    //  ��������ַ����
                                          .rd_enable_in(cmd_rd_enable_w), //   ������ʹ�ܱ�־
                                          .rd_data_out(cmd_rd_data_w),  //  �������������
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
//��ʼ��ģ������
//===========================================================================
can_init_unit can_init_inst(
                            .sys_clk(sys_clk),
                            .reset_n(reset_n),

                            .can_init_enable_in(can_init_enable_in),    //   can��ʼ��ʹ�ܱ�־
                            .can_init_done_out(can_init_done_out),    //    can��ʼ����ɱ�־

                            .wr_addr_out(can_init_wr_addr_w), //can����д��ַ
                            .wr_data_out(can_init_wr_data_w), //can����д����
                            .wr_enable_out(can_init_wr_enable_w), //can����дʹ��
                            .wr_done_in(cmd_wr_done_w),    //canд�����������
                            .wr_busy_in(cmd_wr_busy_w),    //can����д����æ��־

                            . rd_addr_out(can_init_rd_addr_w), //can���߶���ַ
                            . rd_enable_out(can_init_rd_enable_w), //can���߶�ʹ��
                            . rd_done_in(cmd_rd_done_w),   //can���߶��������
                            .rd_data_in(cmd_rd_data_w)     //can���߶���������
                            );
//===========================================================================
//���ݷַ�ģ������
//===========================================================================
can_data_trans_unit can_data_trans_inst(
                                        .sys_clk(sys_clk),
                                        .reset_n(reset_n),

                                        .tx_dw1r_in(tx_dw1r_in),       //   ���ݷ�����1��
                                        .tx_dw2r_in(tx_dw2r_in),       //   ���ݷ�����2��
                                        .tx_valid_in(tx_valid_in),       //   ���ݷ�����Ч��־λ
                                        .tx_ready_out(tx_ready_out),    //  ���ݷ���׼���ñ�־

                                        .rx_dw1r_out(rx_dw1r_out),    //  ����������1
                                        .rx_dw2r_out(rx_dw2r_out),    //  ����������2
                                        .rx_valid_out(rx_valid_out),     //  ����������Ч��־
                                        .rx_ready_in(rx_ready_in),      //  ����׼���ñ�־����

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
//����ͨ���л�
//===========================================================================
assign cmd_wr_addr_w=system_initilization_done_in?can_trans_wr_addr_w:can_init_wr_addr_w;
assign cmd_wr_data_w=system_initilization_done_in?can_trans_wr_data_w:can_init_wr_data_w;
assign cmd_wr_enable_w=system_initilization_done_in?can_trans_wr_enable_w:can_init_wr_enable_w;
assign cmd_rd_addr_w=system_initilization_done_in?can_trans_rd_addr_w:can_init_rd_addr_w;
assign cmd_rd_enable_w=system_initilization_done_in?can_trans_rd_enable_w:can_init_rd_enable_w;
endmodule
