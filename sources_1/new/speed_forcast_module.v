`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/16
// Design Name:PMSM_DESIGN
// Module Name: speed_forcast_module.v
// Target Device:
// Tool versions:
// Description:Ԥ���ٶ����䣬�����ٶȼ���
// Dependencies:
// Revision:
// Additional Comments:
//���������������ĸ��������ʱ�������ٶ�Ԥ��
//�ٶ�����	                          ����ֵ
//0r/min~0.1r/min	               >14648438
//0.1r/min~10r/min	              146484~14648438
//10~100r/min	                    14648~146484
//100r/min~1000r/min	       1464~14648
//1000r/min~5000r/min	      <1464

//====================================================================================
module speed_forcast_module(
                            input    sys_clk,        //system clock
                            input    reset_n,        //low-active

                            input    incremental_encoder_pluse_in,           //������������Ƶ����

                            output  [7:0]    speed_area_count_value_out,   //�����������ֵ
                            output  speed_area_count_value_valid_out             //�������ֵ��Ч��־λ
                            );
//===========================================================================
//��������
//===========================================================================
reg[25:0]     incremental_pluse_cnt_r;          //�������������壨4������ʱ
reg              incremental_encoder_pluse_r;   //��������������Ĵ�
reg[2:0]     pluse_count_cnt_r;                    //���������������������
reg[7:0]     speed_value_mode_r;                //�ٶ�ģʽ�Ĵ���
reg             speed_value_valid_r;                  //�ٶ�ģʽ�Ĵ�����Ч��־λ

//===========================================================================
//�߼�ʵ��
//===========================================================================
//�������������建��
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        incremental_encoder_pluse_r <= 'd0;
    else
        incremental_encoder_pluse_r <= incremental_encoder_pluse_in;
    end
//���������������������
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pluse_count_cnt_r <= 'd0;
     else if (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in) //������������������
         begin
            if(pluse_count_cnt_r == 'd4)
                pluse_count_cnt_r <= 'd1;  //����������λʱ������ֵΪ1
            else
                pluse_count_cnt_r <= pluse_count_cnt_r + 1'b1;
         end    
    else if(incremental_pluse_cnt_r == 'd67108863)//incremental_pluse_cnt_rΪ32'hd67108863ʱ��Լ����������ʱ��ʾ�ٶȽ���Ϊ0����ʼ��һ���������
        pluse_count_cnt_r <= 'd0;    //��λ0�����ڴ�ʱ��û���������أ�����ӽ��������زſ�ʼ���м�ʱ
    else
        pluse_count_cnt_r <= pluse_count_cnt_r;
    end
//����ʱ�����
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        incremental_pluse_cnt_r <= 'd0;
    else if ((pluse_count_cnt_r == 'd4) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in)) //���Ĵη�������
        incremental_pluse_cnt_r <= 'd0;
    else if(pluse_count_cnt_r=='d0)
        incremental_pluse_cnt_r <= 'd0;
    else
        incremental_pluse_cnt_r <= incremental_pluse_cnt_r + 'b1;
    end
//�ٶ������б�
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_value_mode_r <= 'd1;  //Ĭ��Ϊ�����
    else if ((pluse_count_cnt_r == 'd4) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in)) //���Ĵη�������
        begin
        if (incremental_pluse_cnt_r < 'd1464)        //�ٶȷ�Χ��1000r/min~5000r/min
            speed_value_mode_r <= 'd128;
        else if (incremental_pluse_cnt_r < 'd14648) //�ٶȷ�Χ��100r/min~1000r/min
            speed_value_mode_r <= 'd64;
        else if (incremental_pluse_cnt_r < 'd146484) //�ٶȷ�Χ��10r/min~100r/min
            speed_value_mode_r <= 'd16;
        else if (incremental_pluse_cnt_r < 'd14648438) //�ٶȷ�Χ��0.1r/min~10r/min
            speed_value_mode_r <= 'd4;
        else  //�ٶȷ�Χ��0r/min~0.1r/min
            speed_value_mode_r <= 'd1;
        end else if (incremental_pluse_cnt_r == 'd67108863) //��Լ����������ʾ�ٶ�Ϊ0
        speed_value_mode_r <= 'd1;
    else
        speed_value_mode_r <= speed_value_mode_r;
    end
//ģʽ��Ч��־
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_value_valid_r <= 'd0;
    else if (((pluse_count_cnt_r == 'd4) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in)) || (incremental_pluse_cnt_r =='d67108863)) //�����Ĵ����������ʱ
        speed_value_valid_r <= 'd1;
    else
        speed_value_valid_r <= 'd0;
    end
//===========================================================================
//�����ֵ
//===========================================================================
assign speed_area_count_value_out = speed_value_mode_r;
assign speed_area_count_value_valid_out = speed_value_valid_r;
endmodule
