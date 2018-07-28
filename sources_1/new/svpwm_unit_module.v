//====================================================================================
// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/5/2
// Design Name:PMSM_DESIGN
// Module Name: svpwm_unit_module.v
// Target Device:
// Tool versions:
// Description:  根据电压U_alpha和U_Beta产生三相SVPWM脉宽调制
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module svpwm_unit_module(
                         input    sys_clk,
                         input    reset_n,

                         input    svpwm_cal_enable_in,                 //     SVPWM计算使能
                         input    system_initilization_done_in,              //  系统初始化完成输入,高电平有效

                         input    emergency_stop_in,                            //   紧急停机指令，用于电流或栅极驱动器发生异常时停止运行，高点平有效

                         input signed   [`DATA_WIDTH-1:0]      U_alpha_in,       //    Ualpha电压输入
                         input signed   [`DATA_WIDTH-1:0]      U_beta_in,         //    Ubeta电压输入

                         output  phase_a_high_side_out,                     //    a相上桥壁控制
                         output  phase_a_low_side_out,                      //    a相下桥臂控制
                         output  phase_b_high_side_out,                    //    b相上桥臂控制
                         output  phase_b_low_side_out,                     //    b相下桥臂控制
                         output  phase_c_high_side_out,                    //     c相上桥臂控制
                         output  phase_c_low_side_out,                     //     c相下桥臂控制

                         output [`DATA_WIDTH-1:0]   Tcma_out,
                         output [`DATA_WIDTH-1:0]   Tcmb_out,
                         output [`DATA_WIDTH-1:0]   Tcmc_out,
                         output svpwm_cal_done_out
                         );

//===========================================================================
//内部变量声明
//===========================================================================
wire [`DATA_WIDTH-1:0]     Tcma_w,Tcmb_w,Tcmc_w;
//===========================================================================
//SVPWM计算IP核例化
//===========================================================================
svpwm_time_cal svpwm_time_cal_inst(
                                   .sys_clk(sys_clk),
                                   .reset_n(reset_n),

                                   .U_alpha_in(U_alpha_in),       //    Ualpha电压输入
                                   .U_beta_in(U_beta_in),         //    Ubeta电压输入
                                   .svpwm_cal_enable_in(svpwm_cal_enable_in),                                //     SVPWM计算使能

                                   .Tcma_out(Tcma_w),               //      a相 时间切换点
                                   .Tcmb_out(Tcmb_w),               //      b相时间切换点2
                                   .Tcmc_out(Tcmc_w),               //      c相时间切换点3
                                   .svpwm_cal_done_out(svpwm_cal_done_out)
                                   );
//===========================================================================
//SVPWM脉冲产生IP核例化
//===========================================================================
svpwm_gen_module svpwm_gen_inst(
                                . sys_clk(sys_clk),
                                . reset_n(reset_n),

                                . system_initilization_done_in(system_initilization_done_in),              //  系统初始换完成标志
                                .emergency_stop_in(emergency_stop_in),

                                .Tcma_in(Tcma_w),      //  a 相时间切换点
                                .Tcmb_in(Tcmb_w),     //   b相时间切换点
                                .Tcmc_in(Tcmc_w),     //   c相时间切换点

                                .phase_a_high_side_out(phase_a_high_side_out),                     //    a相上桥壁控制
                                .phase_a_low_side_out(phase_a_low_side_out),                      //    a相下桥臂控制
                                .phase_b_high_side_out(phase_b_high_side_out),                    //    b相上桥臂控制
                                .phase_b_low_side_out(phase_b_low_side_out),                     //    b相下桥臂控制
                                .phase_c_high_side_out(phase_c_high_side_out),                    //     c相上桥臂控制
                                .phase_c_low_side_out(phase_c_low_side_out)                      //     c相下桥臂控制
                                );
//===========================================================================
//输出端口赋值
//===========================================================================
assign Tcma_out=Tcma_w;
assign Tcmb_out=Tcmb_w;
assign Tcmc_out=Tcmc_w;
endmodule
