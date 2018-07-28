`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/16
// Design Name:PMSM_DESIGN
// Module Name: speed_forcast_module.v
// Target Device:
// Tool versions:
// Description:预测速度区间，辅助速度计算
// Dependencies:
// Revision:
// Additional Comments:
//计算增量编码器四个脉冲的延时，作出速度预测
//速度区间	                          计数值
//0r/min~0.1r/min	               >14648438
//0.1r/min~10r/min	              146484~14648438
//10~100r/min	                    14648~146484
//100r/min~1000r/min	       1464~14648
//1000r/min~5000r/min	      <1464

//====================================================================================
module speed_forcast_module(
                            input    sys_clk,        //system clock
                            input    reset_n,        //low-active

                            input    incremental_encoder_pluse_in,           //增量编码器倍频输入

                            output  [7:0]    speed_area_count_value_out,   //脉冲个数计数值
                            output  speed_area_count_value_valid_out             //脉冲计数值有效标志位
                            );
//===========================================================================
//变量声明
//===========================================================================
reg[25:0]     incremental_pluse_cnt_r;          //增量编码器脉冲（4个）计时
reg              incremental_encoder_pluse_r;   //增量编码器脉冲寄存
reg[2:0]     pluse_count_cnt_r;                    //增量编码器脉冲个数计数
reg[7:0]     speed_value_mode_r;                //速度模式寄存器
reg             speed_value_valid_r;                  //速度模式寄存器有效标志位

//===========================================================================
//逻辑实现
//===========================================================================
//增量编码器脉冲缓存
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        incremental_encoder_pluse_r <= 'd0;
    else
        incremental_encoder_pluse_r <= incremental_encoder_pluse_in;
    end
//增量编码器脉冲个数计数
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pluse_count_cnt_r <= 'd0;
     else if (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in) //增量编码器发生跳变
         begin
            if(pluse_count_cnt_r == 'd4)
                pluse_count_cnt_r <= 'd1;  //避免启动或复位时刻误差，赋值为1
            else
                pluse_count_cnt_r <= pluse_count_cnt_r + 1'b1;
         end    
    else if(incremental_pluse_cnt_r == 'd67108863)//incremental_pluse_cnt_r为32'hd67108863时针对极端情况，此时表示速度近乎为0，开始下一次脉冲计数
        pluse_count_cnt_r <= 'd0;    //复位0是由于此时还没到到跳边沿，因而从进入跳边沿才开始进行计时
    else
        pluse_count_cnt_r <= pluse_count_cnt_r;
    end
//脉冲时间计数
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        incremental_pluse_cnt_r <= 'd0;
    else if ((pluse_count_cnt_r == 'd4) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in)) //第四次发生跳变
        incremental_pluse_cnt_r <= 'd0;
    else if(pluse_count_cnt_r=='d0)
        incremental_pluse_cnt_r <= 'd0;
    else
        incremental_pluse_cnt_r <= incremental_pluse_cnt_r + 'b1;
    end
//速度区间判别
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_value_mode_r <= 'd1;  //默认为最低速
    else if ((pluse_count_cnt_r == 'd4) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in)) //第四次发生跳变
        begin
        if (incremental_pluse_cnt_r < 'd1464)        //速度范围：1000r/min~5000r/min
            speed_value_mode_r <= 'd128;
        else if (incremental_pluse_cnt_r < 'd14648) //速度范围：100r/min~1000r/min
            speed_value_mode_r <= 'd64;
        else if (incremental_pluse_cnt_r < 'd146484) //速度范围：10r/min~100r/min
            speed_value_mode_r <= 'd16;
        else if (incremental_pluse_cnt_r < 'd14648438) //速度范围：0.1r/min~10r/min
            speed_value_mode_r <= 'd4;
        else  //速度范围：0r/min~0.1r/min
            speed_value_mode_r <= 'd1;
        end else if (incremental_pluse_cnt_r == 'd67108863) //针对极端情况，表示速度为0
        speed_value_mode_r <= 'd1;
    else
        speed_value_mode_r <= speed_value_mode_r;
    end
//模式有效标志
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_value_valid_r <= 'd0;
    else if (((pluse_count_cnt_r == 'd4) && (incremental_encoder_pluse_r ^ incremental_encoder_pluse_in)) || (incremental_pluse_cnt_r =='d67108863)) //满足四次脉冲计数或超时
        speed_value_valid_r <= 'd1;
    else
        speed_value_valid_r <= 'd0;
    end
//===========================================================================
//输出赋值
//===========================================================================
assign speed_area_count_value_out = speed_value_mode_r;
assign speed_area_count_value_valid_out = speed_value_valid_r;
endmodule
