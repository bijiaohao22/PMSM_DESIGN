//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/2
// Design Name:PMSM_DESIGN
// Module Name: svpwm_gen_module.v
// Target Device:
// Tool versions:
// Description:根据SVPWM产生的Tcma，Tcmb，Tcmc控制相应三相桥壁的通断，产生PWM波形
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module svpwm_gen_module(
                        input    sys_clk,
                        input    reset_n,

                        input    system_initilization_done_in,              //  系统初始换完成标志
                        input    emergency_stop_in,                            //   紧急停机指令，用于电流或栅极驱动器发生异常时停止运行，高点平有效

                        input    [`DATA_WIDTH-1:0]    Tcma_in,      //  a 相时间切换点
                        input    [`DATA_WIDTH-1:0]    Tcmb_in,     //   b相时间切换点
                        input    [`DATA_WIDTH-1:0]    Tcmc_in,     //   c相时间切换点

                        output  phase_a_high_side_out,                     //    a相上桥壁控制
                        output  phase_a_low_side_out,                      //    a相下桥臂控制
                        output  phase_b_high_side_out,                    //    b相上桥臂控制
                        output  phase_b_low_side_out,                     //    b相下桥臂控制
                        output  phase_c_high_side_out,                    //     c相上桥臂控制
                        output  phase_c_low_side_out                      //     c相下桥臂控制
                        );

//===========================================================================
//内部变量声明
//===========================================================================
reg[`DATA_WIDTH-1:0]    time_cnt_r;      //PWM时间计数器
reg[`DATA_WIDTH-1:0]    pwm_cnt_r;     //PWM三角波计数器
reg[`DATA_WIDTH-1:0]   Tcma_r,
    Tcmb_r,
    Tcmc_r;  //三相时间切换点寄存器
reg  phase_a_high_side_r;  //a相上桥壁控制寄存器
reg  phase_b_high_side_r;  //b相上桥壁控制寄存器
reg  phase_c_high_side_r;  //c相上桥壁控制寄存器
reg  phase_a_low_side_r;  //a相下桥壁控制寄存器
reg  phase_b_low_side_r;  //b相下桥壁控制寄存器
reg  phase_c_low_side_r;  //c相下桥壁控制寄存器

//===========================================================================
//PWM三角波发生器
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_cnt_r <= 'd0;
    else if (!system_initilization_done_in)
        time_cnt_r <= 'd0;
    else
        time_cnt_r <= time_cnt_r + `DELTA_INC_VAL;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pwm_cnt_r <= 'd0;
    else if (time_cnt_r[`DATA_WIDTH - 1])    //若高位为1，则进行反转
        pwm_cnt_r <= ~time_cnt_r;
    else
        pwm_cnt_r <= time_cnt_r;
    end
//===========================================================================
//三相时间切换点寄存器赋值
//在锯齿波波底处赋值，避免在PWM周期中因时间切换点的变化对波形的影响
//===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
            if (!reset_n)
                {Tcma_r, Tcmb_r, Tcmc_r}<='d0;
            else if (time_cnt_r=='d0)
                {Tcma_r, Tcmb_r, Tcmc_r} <= {Tcma_in, Tcmb_in, Tcmc_in};
            else
                {Tcma_r, Tcmb_r, Tcmc_r} <= {Tcma_r, Tcmb_r, Tcmc_r} ;
        end

//===========================================================================
//三相桥壁控制导通
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {phase_a_high_side_r, phase_a_low_side_r} <= 'b00;   //全部关闭
    else if ((!system_initilization_done_in)||emergency_stop_in)
        {phase_a_high_side_r, phase_a_low_side_r} <= 'b00;   //全部关闭
    else if (pwm_cnt_r > Tcma_r)
        {phase_a_high_side_r, phase_a_low_side_r} <= 'b10;   //上开下闭
    else
    {phase_a_high_side_r, phase_a_low_side_r} <= 'b01;   //上闭下开
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {phase_b_high_side_r, phase_b_low_side_r} <= 'b00;   //全部关闭
    else if ((!system_initilization_done_in)||emergency_stop_in)
        {phase_b_high_side_r, phase_b_low_side_r} <= 'b00;   //全部关闭
    else if (pwm_cnt_r > Tcmb_r)
        {phase_b_high_side_r, phase_b_low_side_r} <= 'b10;   //上开下闭
    else
    {phase_b_high_side_r, phase_b_low_side_r} <= 'b01;   //上闭下开
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {phase_c_high_side_r, phase_c_low_side_r} <= 'b00;   //全部关闭
    else if ((!system_initilization_done_in)||emergency_stop_in)
        {phase_c_high_side_r, phase_c_low_side_r} <= 'b00;   //全部关闭
    else if (pwm_cnt_r > Tcmc_r)
        {phase_c_high_side_r, phase_c_low_side_r} <= 'b10;   //上开下闭
    else
    {phase_c_high_side_r, phase_c_low_side_r} <= 'b01;   //上闭下开
    end

//===========================================================================
//输出信号赋值
//===========================================================================
assign  phase_a_high_side_out = phase_a_high_side_r;
assign  phase_a_low_side_out = phase_a_low_side_r;
assign  phase_b_high_side_out = phase_b_high_side_r;
assign  phase_b_low_side_out = phase_b_low_side_r;
assign  phase_c_high_side_out = phase_c_high_side_r;
assign  phase_c_low_side_out = phase_c_low_side_r;
endmodule
