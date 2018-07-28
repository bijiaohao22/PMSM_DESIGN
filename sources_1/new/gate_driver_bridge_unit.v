//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/9
// Design Name:PMSM_DESIGN
// Module Name: gate_driver_bridge_unit.v
// Target Device:
// Tool versions:
// Description:դ������������������Ԫ���������ƣ��յ�������ʱ�����ض������ű�
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module gate_driver_bridge_unit(
                               input    sys_clk,
                               input    reset_n,

                               input  gate_driver_nfault_in,                    //դ������������������

                               input  gate_a_high_side_in,                     //    a�����űڿ���
                               input  gate_a_low_side_in,                      //    a�����űۿ���
                               input  gate_b_high_side_in,                    //    b�����űۿ���
                               input  gate_b_low_side_in,                     //    b�����űۿ���
                               input  gate_c_high_side_in,                    //     c�����űۿ���
                               input  gate_c_low_side_in,                      //     c�����űۿ���

                               output  gate_a_high_side_out,                     //    a�����űڿ���
                               output  gate_a_low_side_out,                      //    a�����űۿ���
                               output  gate_b_high_side_out,                    //    b�����űۿ���
                               output  gate_b_low_side_out,                     //    b�����űۿ���
                               output  gate_c_high_side_out,                    //     c�����űۿ���
                               output  gate_c_low_side_out                      //     c�����űۿ���
                               );
//===========================================================================
//�ڲ���������
//===========================================================================
reg  gate_a_high_side_r;                     //    a�����űڿ���
reg  gate_a_low_side_r;                      //    a�����űۿ���
reg  gate_b_high_side_r;                    //    b�����űۿ���
reg  gate_b_low_side_r;                     //    b�����űۿ���
reg  gate_c_high_side_r;                    //     c�����űۿ���
reg  gate_c_low_side_r;                      //     c�����űۿ���
reg[1:0]    gate_driver_nfault_buffer_r;
//===========================================================================
//դ�����������������뻺��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_nfault_buffer_r <= 'b11;
    else
        gate_driver_nfault_buffer_r <= {gate_driver_nfault_buffer_r[0], gate_driver_nfault_in};
    end
//===========================================================================
//�����ű۸�ֵ���
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        gate_a_high_side_r <= 'b0;
        gate_b_high_side_r <= 'b0;
        gate_c_high_side_r <= 'b0;
        gate_a_low_side_r  <= 'b0;
        gate_b_low_side_r  <= 'b0;
        gate_c_low_side_r  <= 'b0;
        end else if (!gate_driver_nfault_buffer_r[1])
        begin
        gate_a_high_side_r <= 'b0;
        gate_b_high_side_r <= 'b0;
        gate_c_high_side_r <= 'b0;
        gate_a_low_side_r  <= 'b0;
        gate_b_low_side_r  <= 'b0;
        gate_c_low_side_r  <= 'b0;
        end else
        begin
        gate_a_high_side_r <= gate_a_high_side_in;
        gate_b_high_side_r <= gate_b_high_side_in;
        gate_c_high_side_r <= gate_c_high_side_in;
        gate_a_low_side_r  <= gate_a_low_side_in;
        gate_b_low_side_r  <= gate_b_low_side_in;
        gate_c_low_side_r  <= gate_c_low_side_in;
        end
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign     gate_a_high_side_out = gate_a_high_side_r;
assign     gate_a_low_side_out = gate_a_low_side_r;
assign     gate_b_high_side_out = gate_b_high_side_r;
assign     gate_b_low_side_out = gate_b_low_side_r;
assign     gate_c_high_side_out = gate_c_high_side_r;
assign     gate_c_low_side_out = gate_c_low_side_r;
endmodule

