`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/12
// Design Name:PMSM_DESIGN
// Module Name: hall_decode_module.v
// Target Device:
// Tool versions:
// Description:缓存霍尔传感器输出，用于电气旋转角度的校正
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
module hall_decode_module(
                          input    sys_clk,
                          input    reset_n,

                          input    hall_u_in,
                          input    hall_v_in,
                          input    hall_w_in,

                          output  hall_u_out,
                          output  hall_v_out,
                          output  hall_w_out
                          );
//===========================================================================
//内部变量声明
//===========================================================================
reg[2:0] hall_u_r,hall_v_r, hall_w_r;
//===========================================================================
//霍尔传感器数据缓存，避免亚稳态，由于增量编码器里有缓存加处理三拍延迟，因而此处缓存三拍
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {hall_u_r, hall_v_r, hall_w_r} <= 'd0;
    else
    {hall_u_r, hall_v_r, hall_w_r} <= {hall_u_r[1:0], hall_u_in, hall_v_r[1:0], hall_v_in, hall_w_r[1:0], hall_w_in};
    end
//===========================================================================
//输出变量赋值
//===========================================================================
assign {hall_u_out, hall_v_out, hall_w_out} = {hall_u_r[2], hall_v_r[2], hall_w_r[2]};
endmodule
