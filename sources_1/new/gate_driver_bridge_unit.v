//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/9
// Design Name:PMSM_DESIGN
// Module Name: gate_driver_bridge_unit.v
// Target Device:
// Tool versions:
// Description:栅极驱动器六个驱动单元的驱动控制，收到错误检测时立即关断所有桥臂
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module gate_driver_bridge_unit(
                               input    sys_clk,
                               input    reset_n,

                               input  gate_driver_nfault_in,                    //栅极驱动器错误检测输入

                               input  gate_a_high_side_in,                     //    a相上桥壁控制
                               input  gate_a_low_side_in,                      //    a相下桥臂控制
                               input  gate_b_high_side_in,                    //    b相上桥臂控制
                               input  gate_b_low_side_in,                     //    b相下桥臂控制
                               input  gate_c_high_side_in,                    //     c相上桥臂控制
                               input  gate_c_low_side_in,                      //     c相下桥臂控制

                               output  gate_a_high_side_out,                     //    a相上桥壁控制
                               output  gate_a_low_side_out,                      //    a相下桥臂控制
                               output  gate_b_high_side_out,                    //    b相上桥臂控制
                               output  gate_b_low_side_out,                     //    b相下桥臂控制
                               output  gate_c_high_side_out,                    //     c相上桥臂控制
                               output  gate_c_low_side_out                      //     c相下桥臂控制
                               );
//===========================================================================
//内部变量声明
//===========================================================================
reg  gate_a_high_side_r;                     //    a相上桥壁控制
reg  gate_a_low_side_r;                      //    a相下桥臂控制
reg  gate_b_high_side_r;                    //    b相上桥臂控制
reg  gate_b_low_side_r;                     //    b相下桥臂控制
reg  gate_c_high_side_r;                    //     c相上桥臂控制
reg  gate_c_low_side_r;                      //     c相下桥臂控制
reg[1:0]    gate_driver_nfault_buffer_r;
//===========================================================================
//栅极驱动器错误检测输入缓存
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_nfault_buffer_r <= 'b11;
    else
        gate_driver_nfault_buffer_r <= {gate_driver_nfault_buffer_r[0], gate_driver_nfault_in};
    end
//===========================================================================
//三相桥臂赋值输出
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        gate_a_high_side_r <= 'b0;
        gate_b_high_side_r <= 'b0;
        gate_c_high_side_r <= 'b0;
        gate_a_low_side_r  <= 'b0;
        gate_b_low_side_r  <= 'b0;
        gate_c_low_side_r  <= 'b0;
        end else if (!gate_driver_nfault_buffer_r[1])
        begin
        gate_a_high_side_r <= 'b0;
        gate_b_high_side_r <= 'b0;
        gate_c_high_side_r <= 'b0;
        gate_a_low_side_r  <= 'b0;
        gate_b_low_side_r  <= 'b0;
        gate_c_low_side_r  <= 'b0;
        end else
        begin
        gate_a_high_side_r <= gate_a_high_side_in;
        gate_b_high_side_r <= gate_b_high_side_in;
        gate_c_high_side_r <= gate_c_high_side_in;
        gate_a_low_side_r  <= gate_a_low_side_in;
        gate_b_low_side_r  <= gate_b_low_side_in;
        gate_c_low_side_r  <= gate_c_low_side_in;
        end
    end
//===========================================================================
//输出端口赋值
//===========================================================================
assign     gate_a_high_side_out = gate_a_high_side_r;
assign     gate_a_low_side_out = gate_a_low_side_r;
assign     gate_b_high_side_out = gate_b_high_side_r;
assign     gate_b_low_side_out = gate_b_low_side_r;
assign     gate_c_high_side_out = gate_c_high_side_r;
assign     gate_c_low_side_out = gate_c_low_side_r;
endmodule

