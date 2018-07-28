`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/12
// Design Name:PMSM_DESIGN
// Module Name: electrical_rotation_phase_trig_calculate_module.v
// Target Device:
// Tool versions:
// Description:��ȡ���ת����ת�ĵ����ǶȲ�������������ֵ������PMSM��SVPWM����任�ļ���
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module electrical_rotation_phase_trig_calculate_module(
                                                       input    sys_clk,            //ϵͳʱ��
                                                       input    reset_n,            //��λ�źţ��͵�ƽ��Ч

                                                       input    electrical_rotation_phase_forecast_enable_in,    //������ת�Ƕ���λԤ��ʹ�ܣ������ϵ��λʱ��λԤ��

                                                       input    incremental_encoder_decode_in,                 //����������������������
                                                       input    rotate_direction_in,                                     //��ת��������

                                                       //hall signal input
                                                       input        hall_u_in,
                                                       input        hall_v_in,
                                                       input        hall_w_in,

                                                       output  signed  [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_out, //������ת�Ƕ��������
                                                       output  signed  [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_out, //������ת�Ƕ��������
                                                       output   electrical_rotation_phase_trig_calculate_valid                       //�����Ҽ�����Ч��־���
                                                       );
//===========================================================================
//�ڲ���������
//===========================================================================
wire hall_u_w,hall_v_w,hall_w_w;     //����������ģ�������
wire [`DATA_WIDTH-1:0] electrical_rotation_phase_w; //ת�ӵ�Ƕ�
wire electrical_rotation_phase_valid_w; //ת�ӵ�Ƕ���Ч��־

//===========================================================================
//������������ϢԤ����
//===========================================================================
hall_decode_module hall_decode(
                               .sys_clk(sys_clk),
                               .reset_n(reset_n),

                               .hall_u_in(hall_u_in),
                               .hall_v_in(hall_v_in),
                               .hall_w_in(hall_w_in),

                               .hall_u_out(hall_u_w),
                               .hall_v_out(hall_v_w),
                               .hall_w_out(hall_w_w)
                               );
//===========================================================================
//ת�ӵ�Ƕȴ������
//===========================================================================
electrical_rotation_phase_calculate_module electrical_rotation_phase_calculate(
                                                                               .sys_clk(sys_clk),
                                                                               .reset_n(reset_n),

                                                                               .electrical_rotation_phase_forecast_enable_in(electrical_rotation_phase_forecast_enable_in),            //������ת�Ƕ���λԤ��ʹ�ܣ������ϵ��λʱ��λԤ��

                                                                               //������������Ϣ����
                                                                               .heds_9040_decoder_in(incremental_encoder_decode_in),           //����������������������
                                                                               .rotate_direction_in(rotate_direction_in),                  //��ת��������

                                                                               //��������������
                                                                               .hall_u_in(hall_u_w),
                                                                               .hall_v_in(hall_v_w),
                                                                               .hall_w_in(hall_w_w),

                                                                               //�����Ƕ����
                                                                               .electrical_rotation_phase_out(electrical_rotation_phase_w),
                                                                               .electrical_rotation_phase_valid_out(electrical_rotation_phase_valid_w)
                                                                               );
//===========================================================================
//�����Ҽ���
//===========================================================================
sin_and_cos_calculate_module  sin_and_cos_calculate(
                                                    .sys_clk(sys_clk),
                                                    .reset_n(reset_n),

                                                    .electrical_rotation_phase_in(electrical_rotation_phase_w),
                                                    .electrical_rotation_phase_valid_in(electrical_rotation_phase_valid_w),

                                                    .electrical_rotation_phase_sin_out(electrical_rotation_phase_sin_out),
                                                    .electrical_rotation_phase_cos_out(electrical_rotation_phase_cos_out),
                                                    .electrical_rotation_phase_trig_valid_out(electrical_rotation_phase_trig_calculate_valid)   //�����Ҽ�����Ч��־
                                                    );
endmodule
