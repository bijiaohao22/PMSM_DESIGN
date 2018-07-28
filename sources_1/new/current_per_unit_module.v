//====================================================================================
// Company:
// Engineer: feng
// Create Date: 2018/3/29
// Design Name:PMSM_DESIGN
// Module Name: current_per_unit_module.v
// Target Device:
// Tool versions:
// Description:���ۻ��������ֵ��λ��16λ
// Dependencies:
// Revision:
// Additional Comments:
//����ת����ϵ�����ۻ�����ֵ=��������ֵ*(2^15-1)*10/(160*Imax)   ImaxΪ��������������ֵ
//160=(2^7+2^5);
//(2^15-1)*10=2^18+2^16-2^3-2^1
//====================================================================================
`include "project_param.v"
module current_per_unit_module(
                               input            sys_clk,
                               input            reset_n,

                               input              current_value_valid_in,                                             //������Ч��־
                               input signed   [`DATA_WIDTH-1:0] current_value_in,                  //�������ֵ

                               input              [`DATA_WIDTH-1:0] pmsm_imax_in,                    //��������ֵ

                               output signed [`DATA_WIDTH-1:0] current_standardization_out,  //�������ۻ����ֵ
                               output            current_porce_done_out                                              //�������ۻ���ɱ�־
                               );
//===========================================================================
//�ڲ���������
//===========================================================================
wire   [`DATA_WIDTH+16-1:0]         dividend_wire;                 //������������
wire   [`DATA_WIDTH-1:0]               divisor_wire;                   //����������
wire                                                    m_axis_dout_tvalid;        //�����������Ч�ź�
wire  [`DATA_WIDTH*2+16-1:0]         m_axis_dout_tdata;          //������������
reg                                                     current_porce_done_r;      //���ۻ���ɱ�־
reg signed[`DATA_WIDTH-1:0]       current_standardization_r;  //��������ֵ

//===========================================================================
//������IP������
//===========================================================================
current_per_unit_divider current_standardization_module(
                                                        .aclk(sys_clk),                                      // input wire aclk
                                                        .aresetn(reset_n),                                // input wire aresetn
                                                        .s_axis_divisor_tvalid(1'b1),    // input wire s_axis_divisor_tvalid
                                                        .s_axis_divisor_tready(),    // output wire s_axis_divisor_tready
                                                        .s_axis_divisor_tdata(divisor_wire),      // input wire [15 : 0] s_axis_divisor_tdata
                                                        .s_axis_dividend_tvalid(current_value_valid_in),  // input wire s_axis_dividend_tvalid
                                                        .s_axis_dividend_tready(),  // output wire s_axis_dividend_tready
                                                        .s_axis_dividend_tdata(dividend_wire),    // input wire [31 : 0] s_axis_dividend_tdata
                                                        .m_axis_dout_tvalid(m_axis_dout_tvalid),          // output wire m_axis_dout_tvalid
                                                        .m_axis_dout_tdata(m_axis_dout_tdata)            // output wire [47 : 0] m_axis_dout_tdata
);
//===========================================================================
//����������λ����չ
//===========================================================================
assign   dividend_wire = (current_value_in<<<'d18)+(current_value_in<<<'d16)-(current_value_in<<<'d3)   - current_value_in;
assign   divisor_wire = (pmsm_imax_in <<<7) + (pmsm_imax_in <<<5);
//===========================================================================
//���������ֵ��ȡ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_porce_done_r <= 'd0;
    else
        current_porce_done_r <= m_axis_dout_tvalid;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_standardization_r <= 'sd0;
    else if (m_axis_dout_tvalid)
        current_standardization_r <= {m_axis_dout_tdata[`DATA_WIDTH + 16 - 1], m_axis_dout_tdata[30:16]};
    else
        current_standardization_r <= current_standardization_r;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign   current_standardization_out = current_standardization_r;
assign   current_porce_done_out = current_porce_done_r;
endmodule
