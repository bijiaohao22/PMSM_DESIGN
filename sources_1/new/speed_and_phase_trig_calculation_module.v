`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/18
// Design Name:PMSM_DESIGN
// Module Name: speed_and_phase_trig_calculation_module.v
// Target Device:
// Tool versions:
// Description:���ת�ӵ�Ƕ�������ֵ���㼰ת�ٱ��ۻ�����
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module speed_and_phase_trig_calculation_module(
                                               input sys_clk,
                                               input reset_n,
                                               //   ��������������
                                               input    hall_u_in,
                                               input    hall_v_in,
                                               input    hall_w_in,

                                               //   ��������������
                                               input    incremental_encode_ch_a_in,
                                               input     incremental_encode_ch_b_in,

                                               //   ��Ƕ�Ԥ��ʹ��
                                               input     electrical_rotation_phase_forecast_enable_in,

                                               //�ת������
                                               input     [`DATA_WIDTH-1:0]  rated_speed_in,

                                               //ת�ӵ�Ƕ������Ҽ������
                                               output  signed  [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_out, //������ת�Ƕ��������
                                               output  signed  [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_out, //������ת�Ƕ��������
                                               output   electrical_rotation_phase_trig_calculate_valid_out,                       //�����Ҽ�����Ч��־���

                                               //ת��ת�����
                                               output [`DATA_WIDTH-1:0]  standardization_speed_out
                                               );

//===========================================================================
//�ڲ���������
//===========================================================================
wire rotate_direction_w;       //��ת����
wire incremental_decoder_w;   //�����������ı�Ƶ

//===========================================================================
//������������Ƶ����ת�������
//===========================================================================
incremental_encoder_decoder_module incremental_encoder_decoder_inst(
                                                                    . sys_clk(sys_clk),                //ϵͳʱ��
                                                                    . reset_n(reset_n),                //��λ�źţ��͵�ƽ��Ч
                                                                    
                                                                    . heds_9040_ch_a_in(incremental_encode_ch_a_in),    //����������aͨ������
                                                                    . heds_9040_ch_b_in(incremental_encode_ch_b_in),   //����������bͨ������
                                                                    
                                                                    .heds_9040_decoder_out(incremental_decoder_w),     //�����������������
                                                                    .rotate_direction_out(rotate_direction_w)             //��ת���������0����ת��1����ת
                                                                    );
//===========================================================================
//ת�ӵ�Ƕ������Ҽ���
//===========================================================================
electrical_rotation_phase_trig_calculate_module electrical_rotation_phase_trig_calculate_inst(
                                                       .sys_clk(sys_clk),            //ϵͳʱ��
                                                       .reset_n(reset_n),            //��λ�źţ��͵�ƽ��Ч
                                                       
                                                       .electrical_rotation_phase_forecast_enable_in(electrical_rotation_phase_forecast_enable_in),    //������ת�Ƕ���λԤ��ʹ�ܣ������ϵ��λʱ��λԤ��
                                                       
                                                       .incremental_encoder_decode_in(incremental_decoder_w),                 //����������������������
                                                       .rotate_direction_in(rotate_direction_w),                                     //��ת��������

                                                       //hall signal input
                                                       .hall_u_in(hall_u_in),
                                                       .hall_v_in(hall_v_in),
                                                       .hall_w_in(hall_w_in),

                                                       .electrical_rotation_phase_sin_out(electrical_rotation_phase_sin_out), //������ת�Ƕ��������[`DATA_WIDTH-1:0]
                                                       .electrical_rotation_phase_cos_out(electrical_rotation_phase_cos_out), //������ת�Ƕ��������[`DATA_WIDTH-1:0]
                                                       .electrical_rotation_phase_trig_calculate_valid(electrical_rotation_phase_trig_calculate_valid_out)                       //�����Ҽ�����Ч��־���
                                                       );

//===========================================================================
//  ת���ٶȲ���
//===========================================================================
speed_detection_module speed_detection_inst(
                              .sys_clk(sys_clk),
                              .reset_n(reset_n),
                              
                              .incremental_decoder_in(incremental_decoder_w),
                              .rotation_direction_in(rotate_direction_w),

                              . rated_speed_in(rated_speed_in),       //�ת������
                              
                              . standardization_speed_out(standardization_speed_out)  //���ۻ��ٶ�ֵ���
                              );
endmodule
