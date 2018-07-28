`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/17
// Design Name:PMSM_DESIGN
// Module Name: incremental_pluse_time_count_module.v
// Target Device:
// Tool versions:
// Description://根据速度预测模式，对相应个数增量编码器脉冲进行计时
// Dependencies:
// Revision:
// Additional Comments:在模式预测输入有效时，锁存速度模式，每完成一次速度匹配进行一次模式更新
//若时间计时超过32'd67108863则默认为速度为0，满足相应脉冲计时候输出计数值，用于速度计算
//====================================================================================
module incremental_pluse_time_count_module(
                                           input         sys_clk,
                                           input         reset_n,

                                           input  [7:0]   speed_area_count_value_in, //速度模式预测区间
                                           input             speed_area_count_valid_in, //速度模式有效标志位

                                           input             incremental_encoder_pluse_in,    //增量编码器脉宽输入

                                           output [25:0] speed_pluse_time_cnt_out,          //脉冲计时输出
                                           output [25:0] speed_pluse_count_dividend_out, //脉冲个数输出*390625
                                           output           speed_cnt_valid_out                    //速度测量计数输出有效标志位
                                           );
//===========================================================================
//内部变量声明
//===========================================================================
reg[7:0]    speed_area_count_mode_r;                                             //速度模式寄存器
reg[7:0]    incremental_encoder_pluse_cnt_r;                                   //增量编码器脉冲计数器
reg[25:0]  incremental_encoder_pluse_time_cnt_r;                          //增量编码器脉冲计时器
reg           incremental_encoder_pluse_r;                                          //增量编码器脉冲输入锁存
reg           speed_cnt_valid_r;                                                           //数据有效标志寄存器
reg[25:0] speed_pluse_time_cnt_r;                                                  //脉冲计时输出寄存器   [29:0]
reg[25:0] speed_pluse_count_dividend_r;                                       //脉冲个数输出寄存器*390625   [25:0]

//===========================================================================
//逻辑设计
//===========================================================================
//增量编码器输入锁存
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        incremental_encoder_pluse_r <= 'd0;
    else
        incremental_encoder_pluse_r <= incremental_encoder_pluse_in;
    end
//速度模式寄存器赋值更新
always @(posedge sys_clk  or negedge reset_n)
    begin
    if (!reset_n)
        speed_area_count_mode_r <= 'd1; //默认速度区间为0r/min~0.1r/min
    else if (((incremental_encoder_pluse_cnt_r == speed_area_count_mode_r) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in))||(incremental_encoder_pluse_time_cnt_r=='d67108863)) //完成一次速度脉冲计数计时或超时
        speed_area_count_mode_r <= speed_area_count_value_in;
    else  //其他情况保持不变
        speed_area_count_mode_r <= speed_area_count_mode_r;
    end
//增量编码器脉冲计数赋值
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
        else if(incremental_encoder_pluse_time_cnt_r=='d67108863) //超时,则准备下一次计数
                incremental_encoder_pluse_cnt_r<='d0;
        else
                incremental_encoder_pluse_cnt_r<=incremental_encoder_pluse_cnt_r;
    end
//增量编码器脉冲计时器
always @(posedge sys_clk or negedge reset_n)
    begin
        if(!reset_n)
            incremental_encoder_pluse_time_cnt_r<='d0;
        else if ((incremental_encoder_pluse_cnt_r == speed_area_count_mode_r) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in))
            incremental_encoder_pluse_time_cnt_r<='d0;
        else if(incremental_encoder_pluse_cnt_r=='d0)    //避免初启动时计数
             incremental_encoder_pluse_time_cnt_r<='d0;
        else
            incremental_encoder_pluse_time_cnt_r <= incremental_encoder_pluse_time_cnt_r+1'b1;
    end
//脉冲计时输出寄存器
    always @(posedge sys_clk or negedge reset_n)
        begin
            if(!reset_n)
                speed_pluse_time_cnt_r<='d67108863;  //由于该寄存器用作除数，因而复位不为0，避免出错
            else if(((incremental_encoder_pluse_cnt_r == speed_area_count_mode_r) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in))||(incremental_encoder_pluse_time_cnt_r=='d67108863))//完成相应脉冲计数或超时
                speed_pluse_time_cnt_r<=incremental_encoder_pluse_time_cnt_r+1'b1;
            else
                speed_pluse_time_cnt_r<=speed_pluse_time_cnt_r;
        end
//脉冲计数寄存器输出
always @(posedge sys_clk or negedge reset_n)
    begin
        if(!reset_n)
            speed_pluse_count_dividend_r<='d390625;    //290625*1;
        else if(((incremental_encoder_pluse_cnt_r == speed_area_count_mode_r) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in))||(incremental_encoder_pluse_time_cnt_r=='d67108863))//完成相应脉冲计数或超时
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
//输出有效标志寄存器输出
always @(posedge sys_clk or negedge reset_n)
    begin
        if(!reset_n)
            speed_cnt_valid_r<='d0;
        else if(((incremental_encoder_pluse_cnt_r == speed_area_count_mode_r) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in))||(incremental_encoder_pluse_time_cnt_r=='d67108863))//完成相应脉冲计数或超时
            speed_cnt_valid_r<='d1;
        else
            speed_cnt_valid_r<='d0;
    end

    //===========================================================================
    //输出赋值
    //===========================================================================
    assign speed_pluse_time_cnt_out=speed_pluse_time_cnt_r;
    assign speed_pluse_count_dividend_out=speed_pluse_count_dividend_r;
    assign speed_cnt_valid_out=speed_cnt_valid_r;
endmodule
