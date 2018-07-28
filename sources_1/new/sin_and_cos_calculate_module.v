`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/12
// Design Name:PMSM_DESIGN
// Module Name: sin_and_cos_calculate_module.v
// Target Device:
// Tool versions:
// Description:����ת�ӵ����ǵ������ҽ������������仯
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module sin_and_cos_calculate_module(
                                    input    sys_clk,
                                    input    reset_n,

                                    input  [`DATA_WIDTH-1:0]    electrical_rotation_phase_in,
                                    input                                          electrical_rotation_phase_valid_in,

                                    output signed [`DATA_WIDTH-1:0] electrical_rotation_phase_sin_out,
                                    output signed [`DATA_WIDTH-1:0] electrical_rotation_phase_cos_out,
                                    output                                                 electrical_rotation_phase_trig_valid_out   //�����Ҽ�����Ч��־
                                    );

//===========================================================================
//�ڲ���������
//===========================================================================
reg   electrical_rotation_phase_trig_valid_r;           //�����Ҽ�����Ч��־�Ĵ���
wire electrical_rotation_phase_trig_valid_w;
reg[`DATA_WIDTH-1:0]   electrical_rotation_phase_sin_r;
reg[`DATA_WIDTH-1:0]   electrical_rotation_phase_cos_r;
wire[`DATA_WIDTH-1:0]   electrical_rotation_phase_sin_w;
wire[`DATA_WIDTH-1:0]   electrical_rotation_phase_cos_w;
//===========================================================================
//CORDIC�˵���
//===========================================================================
sin_and_cos_calculate sin_and_cos_calculate_unit(
                                                 .aclk(sys_clk),                                // input wire aclk
                                                 .aresetn(reset_n),                          // input wire aresetn
                                                 .s_axis_phase_tvalid(electrical_rotation_phase_valid_in),  // input wire s_axis_phase_tvalid
                                                 .s_axis_phase_tdata(electrical_rotation_phase_in),    // input wire [15 : 0] s_axis_phase_tdata
                                                 .m_axis_dout_tvalid(electrical_rotation_phase_trig_valid_w),    // output wire m_axis_dout_tvalid
                                                 .m_axis_dout_tdata({electrical_rotation_phase_sin_w,electrical_rotation_phase_cos_w})      // output wire [31 : 0] m_axis_dout_tdata
);

//===========================================================================
//����ת��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        electrical_rotation_phase_sin_r <= 'd0;
    else if (electrical_rotation_phase_sin_w == 16'h4000)
        electrical_rotation_phase_sin_r <= 16'h7fff;
    else
        electrical_rotation_phase_sin_r <= {electrical_rotation_phase_sin_w[15], electrical_rotation_phase_sin_w[13:0], 1'b0};
    end
always@(posedge sys_clk or   negedge reset_n)
    begin
    if (!reset_n)
        electrical_rotation_phase_cos_r <= 'd0;
    else if (electrical_rotation_phase_cos_w == 16'h4000)
        electrical_rotation_phase_cos_r <= 16'h7fff;
    else
        electrical_rotation_phase_cos_r <= {electrical_rotation_phase_cos_w[15], electrical_rotation_phase_cos_w[13:0], 1'b0};
    end
//===========================================================================
//��������Ч�������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        electrical_rotation_phase_trig_valid_r <= 'd0;
    else
        electrical_rotation_phase_trig_valid_r <= electrical_rotation_phase_trig_valid_w;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign electrical_rotation_phase_sin_out = electrical_rotation_phase_sin_r;
assign electrical_rotation_phase_cos_out = electrical_rotation_phase_cos_r;
assign electrical_rotation_phase_trig_valid_out = electrical_rotation_phase_trig_valid_r;
endmodule
