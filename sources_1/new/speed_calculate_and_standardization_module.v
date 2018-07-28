`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/17
// Design Name:PMSM_DESIGN
// Module Name: speed_calculate_and_standardization_module.v
// Target Device:
// Tool versions:
// Description: 速度计算与标幺化计算
// Dependencies:
// Revision:
// Additional Comments:
//电机转速标幺化输出计算公式：脉冲计数M1*390625*(2^15-1)*60/（脉冲计时M2*64*额定转速)
//上式可化简为：M1*390625*(2^19-2^15-2^4+1)/（脉冲计时M2*16*额定转速)
//计算方法:当收到脉冲计时计数有效标志位时，首先对除数调用乘法器进行乘法计算后左移四位，随后调用除
//           法器进行除法运算.
//====================================================================================


module speed_calculate_and_standardization_module(
                                                  input    sys_clk,
                                                  input    reset_n,

                                                  input   [25:0]      speed_pluse_time_cnt_in,                          //脉冲计时输出M2
                                                  input   [25:0]      speed_pluse_count_dividend_in,               //脉冲计数M1*390625
                                                  input                   speed_cnt_valid_in,                                  //脉冲计时计数有效标志位
                                                  input                   rotation_direction_in,                                //电机旋转方向输入
                                                  input   [15:0]       rated_speed_in,                                         //额定转速输入

                                                  output [15:0]       standardization_speed_out                       //电机速度标幺化输出
                                                  );
//===========================================================================
//内部变量声明
//===========================================================================
reg[45:0]     speed_pluse_count_dividend_r;         //脉冲个数寄存器输入缓存*390625*(2^19-2^15-2^4+1)寄存器
reg[2:0]       speed_cnt_valid_r;                             //计时计数有效信号缓存器，由于乘法器有三个时钟的延时，因而延迟三拍
reg   signed[15:0] standardization_speed_r;            // 标幺化速度输出寄存器
wire[41:0]     multipler_result_w;                          //乘法器输出缓存
wire[63:0]   m_axis_dout_tdata_w;                     //除法器输出缓存
wire             m_axi_dout_valid_w;                      //除法器输出有效标志位

//===========================================================================
//脉冲个数寄存器输入缓存*390625*(2^19-2^15-2^4+1)寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_pluse_count_dividend_r <= 'd0;
    else if (speed_cnt_valid_in)  //输入有效时对输入进程乘法移位锁存
        speed_pluse_count_dividend_r <= ((speed_pluse_count_dividend_in << 'd19) - (speed_pluse_count_dividend_in << 'd15)) - ((speed_pluse_count_dividend_in << 'd4) - (speed_pluse_count_dividend_in));
    else
        speed_pluse_count_dividend_r <= speed_pluse_count_dividend_r;
    end
//===========================================================================
//脉冲计时乘法计算，乘法器IP和有三个时钟的延迟
//===========================================================================
divisor_generate_ip_core divisor_generate(
                                          .CLK(sys_clk),    // input wire CLK
                                          .A(speed_pluse_time_cnt_in),        // input wire [25 : 0] A
                                          .B(rated_speed_in),        // input wire [15 : 0] B
                                          .SCLR(~reset_n),  // input wire SCLR,HIGH-ACTIVE
                                          .P(multipler_result_w)        // output wire [41 : 0] P
);
//===========================================================================
//输入有效信号延迟寄存，缓存三个时钟周期
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_cnt_valid_r <= 'd0;
    else
        speed_cnt_valid_r <= {speed_cnt_valid_r[1:0], speed_cnt_valid_in};
    end
//===========================================================================
//除法器调用，用于计算标幺化（输出低16位为小数）
//===========================================================================
speed_standardization_divider speed_standardization(
                                                    .aclk(sys_clk),                                      // input wire aclk
                                                    .aresetn(reset_n),                                // input wire aresetn
                                                    .s_axis_divisor_tvalid(speed_cnt_valid_r[2]),    // input wire s_axis_divisor_tvalid
                                                    .s_axis_divisor_tdata({2'd0, multipler_result_w,4'd0}),      // input wire [47 : 0] s_axis_divisor_tdata
                                                    .s_axis_dividend_tvalid(speed_cnt_valid_r[2]),  // input wire s_axis_dividend_tvalid
                                                    .s_axis_dividend_tdata({ 2'd0,speed_pluse_count_dividend_r}),    // input wire [47 : 0] s_axis_dividend_tdata
                                                    .m_axis_dout_tvalid(m_axi_dout_valid_w),          // output wire m_axis_dout_tvalid
                                                    .m_axis_dout_tdata(m_axis_dout_tdata_w)            // output wire [63 : 0] m_axis_dout_tdata
);
//===========================================================================
//速度标幺值符号化
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        standardization_speed_r <= 'sd0;
    else if (m_axi_dout_valid_w)
        begin
        if (rotation_direction_in) //1表示反转
            standardization_speed_r <= 16'sd0 - m_axis_dout_tdata_w[31:16];
        else
            standardization_speed_r <= m_axis_dout_tdata_w[31:16];
        end else
        standardization_speed_r <= standardization_speed_r;
    end
//===========================================================================
//输出赋值
//===========================================================================
assign standardization_speed_out = standardization_speed_r;
endmodule
