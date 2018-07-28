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

                        input    opercation_cmd_in,     //  ��������
                        input [7:0]      read_addr_in,       //  ����ַ����
                        input    rd_cmd_valid_in,           //   ������������Ч����
                        output  rd_cmd_ready_out,         //   ������׼���ñ�־

                        output [31:0]    read_data1_out,  //   ���ݶ��ֶ�1
                        output [31:0]   read_data2_out,   //   ���ݶ��ֶ�2���
                        output              rd_data_valid_out, //  ��������Ч��־

                        input [7:0]    wr_addr_in,         //  д������ַ����
                        input            wr_valid_out,      //  д������Ч��־
                        input [31:0] wr_sidh_in,          //  д������ʾ������
                        input [7:0]   wr_dlc_in,            //  д��������������
                        input [31:0] wr_data1_in,        //  д��������1����
                        input [31:0] wr_data2_in,        //  д��������2����
                        output          wr_ready_out,      //   д����׼�������

                        //mcp_2515_spi
                        output          spi_sck_out,         //  spiʱ�����
                        output          spi_sdo_out,         //  spi�����������
                        input            spi_sdi_in,           //  spi�ӻ�����
                        output          spi_cs_n_out       //   spiƬѡʹ�ܣ��͵�ƽ��Ч
                        );
//===========================================================================
//�ڲ���������
//===========================================================================

endmodule
