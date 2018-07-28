`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/4/18
// Design Name:PMSM_DESIGN
// Module Name: speed_detection_module.v
// Target Device:
// Tool versions:
// Description:�����������������ı�Ƶ��ı�����Ϣ�Ե��ת��������
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module speed_detection_module(
                              input    sys_clk,
                              input    reset_n,

                              input    incremental_decoder_in,
                              input    rotation_direction_in,

                              input  [`DATA_WIDTH-1:0]  rated_speed_in,       //�ת������

                              output [`DATA_WIDTH-1:0]  standardization_speed_out  //���ۻ��ٶ�ֵ���
                              );
//===========================================================================
//�ڲ���������
//===========================================================================
wire [7:0] speed_area_count_value_w;             //�ٶ�Ԥ�����ģʽ
wire         speed_area_count_value_valid_w;    //�ٶ�Ԥ������Ч��־
wire [25:0]   speed_pluse_time_cnt_w;            //�����ʱ
wire [25:0] speed_pluse_count_dividend_w; //�������*390625
wire             speed_cnt_valid_w;                   // �����ʱ������Ч��־λ

//===========================================================================
//�ٶ�Ԥ��ģ������
//===========================================================================
speed_forcast_module speed_forcast_inst(
                                        .sys_clk(sys_clk),        //system clock
                                        .reset_n(reset_n),        //low-active

                                        . incremental_encoder_pluse_in(incremental_decoder_in),           //������������Ƶ����

                                        .speed_area_count_value_out(speed_area_count_value_w),   //�����������ֵ[7:0]
                                        .speed_area_count_value_valid_out(speed_area_count_value_valid_w)             //�������ֵ��Ч��־λ
                                        );
//===========================================================================
//M/T���ٷ���ʱ����
//===========================================================================
incremental_pluse_time_count_module incremental_pluse_time_count_inst(
                                                                      .sys_clk(sys_clk),
                                                                      .reset_n(reset_n),

                                                                      .speed_area_count_value_in(speed_area_count_value_w), //�ٶ�ģʽԤ������,[7:0]
                                                                      .speed_area_count_valid_in(speed_area_count_value_valid_w), //�ٶ�ģʽ��Ч��־λ

                                                                      .incremental_encoder_pluse_in(incremental_decoder_in),    //������������������

                                                                      .speed_pluse_time_cnt_out(speed_pluse_time_cnt_w),          //�����ʱ���[25:0]
                                                                      .speed_pluse_count_dividend_out(speed_pluse_count_dividend_w), //����������*390625[25:0]
                                                                      .speed_cnt_valid_out(speed_cnt_valid_w)                    //�ٶȲ������������Ч��־λ
                                                                      );
//===========================================================================
//�ٶȼ�������ۻ�
//===========================================================================
speed_calculate_and_standardization_module speed_calculate_and_standardization_inst(
                                                    .sys_clk(sys_clk),
                                                    .reset_n(reset_n),

                                                   .speed_pluse_time_cnt_in(speed_pluse_time_cnt_w),                          //�����ʱ����M2
                                                   .speed_pluse_count_dividend_in(speed_pluse_count_dividend_w),               //�������M1*390625
                                                   .speed_cnt_valid_in(speed_cnt_valid_w),                                  //�����ʱ������Ч��־λ
                                                   .rotation_direction_in(rotation_direction_in),                                //�����ת��������
                                                   .rated_speed_in(rated_speed_in),                                         //�ת������

                                                  .standardization_speed_out(standardization_speed_out)                       //����ٶȱ��ۻ����
                                                  );
endmodule
