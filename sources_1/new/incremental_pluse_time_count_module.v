`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/17
// Design Name:PMSM_DESIGN
// Module Name: incremental_pluse_time_count_module.v
// Target Device:
// Tool versions:
// Description://�����ٶ�Ԥ��ģʽ������Ӧ��������������������м�ʱ
// Dependencies:
// Revision:
// Additional Comments:��ģʽԤ��������Чʱ�������ٶ�ģʽ��ÿ���һ���ٶ�ƥ�����һ��ģʽ����
//��ʱ���ʱ����32'd67108863��Ĭ��Ϊ�ٶ�Ϊ0��������Ӧ�����ʱ���������ֵ�������ٶȼ���
//====================================================================================
module incremental_pluse_time_count_module(
                                           input         sys_clk,
                                           input         reset_n,

                                           input  [7:0]   speed_area_count_value_in, //�ٶ�ģʽԤ������
                                           input             speed_area_count_valid_in, //�ٶ�ģʽ��Ч��־λ

                                           input             incremental_encoder_pluse_in,    //������������������

                                           output [25:0] speed_pluse_time_cnt_out,          //�����ʱ���
                                           output [25:0] speed_pluse_count_dividend_out, //����������*390625
                                           output           speed_cnt_valid_out                    //�ٶȲ������������Ч��־λ
                                           );
//===========================================================================
//�ڲ���������
//===========================================================================
reg[7:0]    speed_area_count_mode_r;                                             //�ٶ�ģʽ�Ĵ���
reg[7:0]    incremental_encoder_pluse_cnt_r;                                   //�������������������
reg[25:0]  incremental_encoder_pluse_time_cnt_r;                          //���������������ʱ��
reg           incremental_encoder_pluse_r;                                          //����������������������
reg           speed_cnt_valid_r;                                                           //������Ч��־�Ĵ���
reg[25:0] speed_pluse_time_cnt_r;                                                  //�����ʱ����Ĵ���   [29:0]
reg[25:0] speed_pluse_count_dividend_r;                                       //�����������Ĵ���*390625   [25:0]

//===========================================================================
//�߼����
//===========================================================================
//������������������
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        incremental_encoder_pluse_r <= 'd0;
    else
        incremental_encoder_pluse_r <= incremental_encoder_pluse_in;
    end
//�ٶ�ģʽ�Ĵ�����ֵ����
always @(posedge sys_clk  or negedge reset_n)
    begin
    if (!reset_n)
        speed_area_count_mode_r <= 'd1; //Ĭ���ٶ�����Ϊ0r/min~0.1r/min
    else if (((incremental_encoder_pluse_cnt_r == speed_area_count_mode_r) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in))||(incremental_encoder_pluse_time_cnt_r=='d67108863)) //���һ���ٶ����������ʱ��ʱ
        speed_area_count_mode_r <= speed_area_count_value_in;
    else  //����������ֲ���
        speed_area_count_mode_r <= speed_area_count_mode_r;
    end
//�������������������ֵ
always @(posedge sys_clk or negedge reset_n)
    begin
        if(!reset_n)
            incremental_encoder_pluse_cnt_r<='d0;
        else if(incremental_encoder_pluse_r ^ incremental_encoder_pluse_in)
            begin
                if (incremental_encoder_pluse_cnt_r==speed_area_count_mode_r)
                    incremental_encoder_pluse_cnt_r<='d1;
                else
                    incremental_encoder_pluse_cnt_r <= incremental_encoder_pluse_cnt_r+1'b1;
            end
        else if(incremental_encoder_pluse_time_cnt_r=='d67108863) //��ʱ,��׼����һ�μ���
                incremental_encoder_pluse_cnt_r<='d0;
        else
                incremental_encoder_pluse_cnt_r<=incremental_encoder_pluse_cnt_r;
    end
//���������������ʱ��
always @(posedge sys_clk or negedge reset_n)
    begin
        if(!reset_n)
            incremental_encoder_pluse_time_cnt_r<='d0;
        else if ((incremental_encoder_pluse_cnt_r == speed_area_count_mode_r) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in))
            incremental_encoder_pluse_time_cnt_r<='d0;
        else if(incremental_encoder_pluse_cnt_r=='d0)    //���������ʱ����
             incremental_encoder_pluse_time_cnt_r<='d0;
        else
            incremental_encoder_pluse_time_cnt_r <= incremental_encoder_pluse_time_cnt_r+1'b1;
    end
//�����ʱ����Ĵ���
    always @(posedge sys_clk or negedge reset_n)
        begin
            if(!reset_n)
                speed_pluse_time_cnt_r<='d67108863;  //���ڸüĴ������������������λ��Ϊ0���������
            else if(((incremental_encoder_pluse_cnt_r == speed_area_count_mode_r) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in))||(incremental_encoder_pluse_time_cnt_r=='d67108863))//�����Ӧ���������ʱ
                speed_pluse_time_cnt_r<=incremental_encoder_pluse_time_cnt_r+1'b1;
            else
                speed_pluse_time_cnt_r<=speed_pluse_time_cnt_r;
        end
//��������Ĵ������
always @(posedge sys_clk or negedge reset_n)
    begin
        if(!reset_n)
            speed_pluse_count_dividend_r<='d390625;    //290625*1;
        else if(((incremental_encoder_pluse_cnt_r == speed_area_count_mode_r) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in))||(incremental_encoder_pluse_time_cnt_r=='d67108863))//�����Ӧ���������ʱ
            case(speed_area_count_mode_r)
                'd1:  speed_pluse_count_dividend_r<='d390625*1;
                'd4:  speed_pluse_count_dividend_r<='d390625<<2;
                'd16:  speed_pluse_count_dividend_r<='d390625<<4;
                'd64:  speed_pluse_count_dividend_r<='d390625<<6;
                'd128:speed_pluse_count_dividend_r<='d390625<<7;
                default :speed_pluse_count_dividend_r<='d390625;
            endcase
        else
            speed_pluse_count_dividend_r<=speed_pluse_count_dividend_r;
    end
//�����Ч��־�Ĵ������
always @(posedge sys_clk or negedge reset_n)
    begin
        if(!reset_n)
            speed_cnt_valid_r<='d0;
        else if(((incremental_encoder_pluse_cnt_r == speed_area_count_mode_r) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in))||(incremental_encoder_pluse_time_cnt_r=='d67108863))//�����Ӧ���������ʱ
            speed_cnt_valid_r<='d1;
        else
            speed_cnt_valid_r<='d0;
    end

    //===========================================================================
    //�����ֵ
    //===========================================================================
    assign speed_pluse_time_cnt_out=speed_pluse_time_cnt_r;
    assign speed_pluse_count_dividend_out=speed_pluse_count_dividend_r;
    assign speed_cnt_valid_out=speed_cnt_valid_r;
endmodule
