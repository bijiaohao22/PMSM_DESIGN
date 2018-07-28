//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/23
// Design Name:PMSM_DESIGN
// Module Name: location_loop_control.v
// Target Device:
// Tool versions:
// Description:λ��ģʽ�ջ�����
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module location_loop_control(
                             input    sys_clk,
                             input    reset_n,

                             input    location_loop_control_enable_in,    //  λ�ÿ���ʹ������

                             input    [(`DATA_WIDTH*2+2-1):0]    pmsm_location_set_value_in,    //ת��ģʽ�趨ֵ������ת��λ�ü�ת���ٶ�
                             input    [`DATA_WIDTH+2-1:0]          pmsm_detect_location_value_in,    //  ����λ�ü��ֵ����

                             output  [`DATA_WIDTH-1:0]    pmsm_location_control_speed_set_value_out,    // λ�ÿ���ģʽ��ת���趨ֵ���

                             output  pmsm_location_control_done_out   //λ�ÿ���ģʽ���Ƽ�����ɱ�־
                             );
//===========================================================================
//�ڲ���������
//===========================================================================

//===========================================================================
//�ڲ���������
//===========================================================================
reg   signed[`DATA_WIDTH-1:0]    pmsm_location_control_speed_set_value_r;
reg   pmsm_location_control_done_r;
//===========================================================================
//λ��ģʽת���趨ֵ���
//===========================================================================
always @(posedge sys_clk or  negedge reset_n)
    begin
    if (!reset_n)
        pmsm_location_control_speed_set_value_r <= 'sd0;
    else if (location_loop_control_enable_in)
        begin
        if (((pmsm_location_set_value_in[17:0] - pmsm_detect_location_value_in) <`location_control_error) || ((pmsm_detect_location_value_in - pmsm_location_set_value_in[17:0])<`location_control_error)) //�ﵽ����ָ��
            pmsm_location_control_speed_set_value_r <= 'sd0;
        else
            pmsm_location_control_speed_set_value_r <= pmsm_location_set_value_in[(`DATA_WIDTH * 2 + 2-1) -:16];
end else
    pmsm_location_control_speed_set_value_r <= pmsm_location_control_speed_set_value_r;
end
//===========================================================================
//λ�ÿ��Ƽ�����ɱ�־
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pmsm_location_control_done_r <= 'd0;
    else
        pmsm_location_control_done_r <= location_loop_control_enable_in;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign pmsm_location_control_speed_set_value_out=pmsm_location_control_speed_set_value_r;
assign pmsm_location_control_done_out=pmsm_location_control_done_r;
endmodule
