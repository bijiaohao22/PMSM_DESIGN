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

                        input    gate_driver_init_enable_in,  //  դ���������ϵ��λ���ʼ��ʹ������
                        output  gate_driver_init_done_out,  //  դ����������ʼ����ɱ�־

                        input  gate_a_high_side_in,                     //    a�����űڿ���
                        input  gate_a_low_side_in,                      //    a�����űۿ���
                        input  gate_b_high_side_in,                    //    b�����űۿ���
                        input  gate_b_low_side_in,                     //    b�����űۿ���
                        input  gate_c_high_side_in,                    //     c�����űۿ���
                        input  gate_c_low_side_in,                      //     c�����űۿ���

                        output  gate_driver_enable_out,
                        output  gate_driver_nscs_out,
                        output  gate_driver_sclk_out,
                        output  gate_driver_sdi_out,
                        input  gate_driver_sdo_in,
                        input  gate_driver_nfault_in,

                        output  gate_a_high_side_out,                     //    a�����űڿ���
                        output  gate_a_low_side_out,                      //    a�����űۿ���
                        output  gate_b_high_side_out,                    //    b�����űۿ���
                        output  gate_b_low_side_out,                     //    b�����űۿ���
                        output  gate_c_high_side_out,                    //     c�����űۿ���
                        output  gate_c_low_side_out,                     //     c�����űۿ���

                        output[`DATA_WIDTH-1:0]    gate_driver_register_1_out,  //  դ���Ĵ���״̬1�Ĵ������
                        output[`DATA_WIDTH-1:0]    gate_driver_register_2_out,  //  դ���Ĵ���״̬2�Ĵ������
                        output  gate_driver_error_out   //դ���Ĵ������ϱ������
                        );
//===========================================================================
//�ڲ���������
//===========================================================================
wire  [`SPI_FRAME_WIDTH-1:0]    wr_data_w;    //spi����д�˿�
wire wr_data_valid_w; //spiд��Ч��־
wire [`SPI_FRAME_WIDTH-1:0]    rd_data_w;    //spi�����ݶ˿�
wire rd_data_enable_w;   //spi��ʹ�ܶ˿�
wire [`DATA_WIDTH-1:0]    rd_addr_w;   //spi����ַ�˿�
wire spi_proc_done_w; //    spi������ɱ�־
wire spi_proc_busy_w; //    spiæ��־

//===========================================================================
//spi �����Э������
//===========================================================================
spi_phy_unit spi_phy_inst(
                          .sys_clk(sys_clk),
                          .reset_n(reset_n),

                          .wr_data_in(wr_data_w),  //  ����д�˿�
                          .wr_data_valid_in(wr_data_valid_w),                      //  ����д�˿���Ч��־

                          .rd_data_out(rd_data_w),  //   ���ݶ��˿�
                          .rd_data_enable_in(rd_data_enable_w),     //  ���ݶ��˿�ʹ�ܱ�־
                          .rd_addr_in(rd_addr_w),   //  ����ַ����

                          .spi_proc_done_out(spi_proc_done_w),   //    spi������ɱ�־
                          .spi_proc_busy_out(spi_proc_busy_w),   //    spiæ��־

                          . spi_nscs_out(gate_driver_nscs_out),        //spiʹ�ܱ�־���
                          . spi_sclk_out(gate_driver_sclk_out),           //spiʱ�Ӷ˿����
                          . spi_sdo_out(gate_driver_sdi_out),           //   spi��������˿�
                          .  spi_sdi_in(gate_driver_sdo_in)               //   spi��������˿�
                          );
//===========================================================================
//դ����������ʼ����״̬���ģ������
//===========================================================================
gate_driver_init_and_monitor_unit gate_driver_init_and_monitor_inst(
                                                                    .sys_clk(sys_clk),
                                                                    .reset_n(reset_n),

                                                                    .gate_driver_init_enable_in(gate_driver_init_enable_in),  //  դ���������ϵ��λ���ʼ��ʹ������
                                                                    .gate_driver_init_done_out(gate_driver_init_done_out),  //  դ����������ʼ����ɱ�־

                                                                    .gate_driver_nfault_in(gate_driver_nfault_in),           //   դ�����������������룬�͵�ƽ��Ч
                                                                    .gate_driver_enable_out(gate_driver_enable_out),      //   դ��������ʹ��������ߵ�ƽ��Ч

                                                                    .wr_data_out(wr_data_w),    //  spiд����
                                                                    .wr_data_enable_out(wr_data_valid_w),    //  spiдʹ��
                                                                    .rd_addr_out(rd_addr_w), //  spi���Ĵ�����ַ
                                                                    .rd_data_enable_out(rd_data_enable_w), //  spi��ʹ��
                                                                    .rd_data_in(rd_data_w),   //spi������

                                                                    .spi_phy_proc_done_in(spi_proc_done_w),   //  spi����㴦����ɱ�־
                                                                    .spi_phy_proc_busy_in(spi_proc_busy_w),   //  spi�����æ��־

                                                                    .gate_driver_register_1_out(gate_driver_register_1_out),  //  դ���Ĵ���״̬1�Ĵ������
                                                                    .gate_driver_register_2_out(gate_driver_register_2_out),  //  դ���Ĵ���״̬2�Ĵ������
                                                                    .gate_driver_error_out(gate_driver_error_out)   //դ���Ĵ������ϱ������
                                                                    );
//===========================================================================
//դ���������ű�����ģ������
//===========================================================================
gate_driver_bridge_unit gate_driver_bridge_inst(
                                                .sys_clk(sys_clk),
                                                .reset_n(reset_n),

                                                .gate_driver_nfault_in(gate_driver_nfault_in),                    //դ������������������

                                                .gate_a_high_side_in(gate_a_high_side_in),                     //    a�����űڿ���
                                                .gate_a_low_side_in(gate_a_low_side_in),                      //    a�����űۿ���
                                                .gate_b_high_side_in(gate_b_high_side_in),                    //    b�����űۿ���
                                                .gate_b_low_side_in(gate_b_low_side_in),                     //    b�����űۿ���
                                                .gate_c_high_side_in(gate_c_high_side_in),                    //     c�����űۿ���
                                                .gate_c_low_side_in(gate_c_low_side_in),                      //     c�����űۿ���

                                                .gate_a_high_side_out(gate_a_high_side_out),                     //    a�����űڿ���
                                                .gate_a_low_side_out(gate_a_low_side_out),                      //    a�����űۿ���
                                                .gate_b_high_side_out(gate_b_high_side_out),                    //    b�����űۿ���
                                                .gate_b_low_side_out(gate_b_low_side_out),                     //    b�����űۿ���
                                                .gate_c_high_side_out(gate_c_high_side_out),                    //     c�����űۿ���
                                                .gate_c_low_side_out(gate_c_low_side_out)                      //     c�����űۿ���
                                                );
endmodule
