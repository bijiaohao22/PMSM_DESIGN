//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/23
// Design Name:PMSM_DESIGN
// Module Name: location_control_unit.v
// Target Device:
// Tool versions:
// Description:λ�ÿ���ģ��ʵ��
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module location_control_unit(
                             input    sys_clk,
                             input    reset_n,

                             input    location_loop_control_enable_in,    //  λ�ÿ���ʹ������
                             input    location_detection_enable_in,          //  λ�ü��ʹ������

                             input        vlx_data_in,                         //  ssi�ӿ���������
                             output      vlx_clk_out,                        //  ssi�ӿ�ʱ�����

                             input    [(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value_in,    //ת��ģʽ�趨ֵ������ת��λ�ü�ת���ٶ�

                             output  [`DATA_WIDTH-1:0]    pmsm_location_control_speed_set_value_out,    // λ�ÿ���ģʽ��ת���趨ֵ���
                             output  [`ABSOLUTION_TOTAL_BIT-1:0]   location_detection_value_out,        //λ�ü�����

                             output  pmsm_location_control_done_out   //λ�ÿ���ģʽ���Ƽ�����ɱ�־
                             );
//===========================================================================
//�ڲ���������
//===========================================================================

//===========================================================================
//λ�ü��ģ������
//===========================================================================
absolution_location_encoder absolution_location_encoder_inst(
                                   .sys_clk(sys_clk),
                                   .reset_n(reset_n),

                                   .location_detection_enable_in(location_detection_enable_in),  //  λ�ü��ʹ������

                                   .vlx_data_in(vlx_data_in),                         //  ssi�ӿ���������
                                   .vlx_clk_out(vlx_clk_out),                        //  ssi�ӿ�ʱ�����

                                   .location_detection_value_out(location_detection_value_out)
                                   );
//===========================================================================
//λ�ÿ���ģ������
//===========================================================================
location_loop_control location_loop_control_inst(
                             .sys_clk(sys_clk),
                                   .reset_n(reset_n),

                             .location_loop_control_enable_in(location_loop_control_enable_in),    //  λ�ÿ���ʹ������

                             .pmsm_location_set_value_in(pmsm_location_set_value_in),    //ת��ģʽ�趨ֵ������ת��λ�ü�ת���ٶ�
                             .pmsm_detect_location_value_in(location_detection_value_out),    //  ����λ�ü��ֵ����

                             .pmsm_location_control_speed_set_value_out(pmsm_location_control_speed_set_value_out),    // λ�ÿ���ģʽ��ת���趨ֵ���

                             .pmsm_location_control_done_out(pmsm_location_control_done_out)   //λ�ÿ���ģʽ���Ƽ�����ɱ�־
                             );
endmodule
