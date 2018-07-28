`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: li-xiaochuang
// Create Date: 2018/3/13
// Design Name:PMSM_DESIGN
// Module Name: PMSM_DESIGN.v
// Target Device:
// Tool versions:vivado 2015.4
// Description: TOP_DESIGN
// Dependencies:
// Revision:1.00
// Additional Comments:
//====================================================================================
`include "project_param.v"
module PMSM_DESIGN(
                   input        clk_50MHz_in,                //global clock input ,50MHz
                   input        reset_n_in,                            //reset signal ,low-active

                   //hall signal input
                   input        hall_u_in,
                   input        hall_v_in,
                   input        hall_w_in,

                   //incremental encoder input
                   input        heds_9040_ch_a_in,
                   input        heds_9040_ch_b_in,
                   input        heds_9040_ch_i_in,

                   //absolute encoder input port
                   input        vlx_data_in,
                   output      vlx_clk_out,

                   //current_sensor input port
                   input        current_u_data_in,
                   input        current_u_ocd,
                   output      current_u_cs_n_out,
                   output      current_u_clk_out,

                   input        current_v_data_in,
                   input        current_v_ocd,
                   output      current_v_cs_n_out,
                   output      current_v_clk_out,

                   //mosfet gate driver output
                   output      drv8320s_inh_a_out,       //phase a high side mosfet  gate driver
                   output      drv8320s_inl_a_out,        //phase a low side mosfet  gate driver
                   output      drv8320s_inh_b_out,       //phase b high side mosfet  gate driver
                   output      drv8320s_inl_b_out,        //phase b low side mosfet  gate driver
                   output      drv8320s_inh_c_out,       //phase c high side mosfet  gate driver
                   output      drv8320s_inl_c_out,        //phase c low side mosfet  gate driver

                   output      drv8320_enable_out,
                   output      drv8320s_nscs_out,
                   output      drv8320s_clk_out,
                   output      drv8320s_sdi_out,
                   input        drv8320s_sdo_in,
                   input        drc8320s_nfault,

                   //Band Brake output (emergency cutoff)
                   output     band_brake_out,

                   //can总线接口
                   input       can_rx_in,
                   output     can_tx_out
                   );
//===========================================================================
//内部变量声明
//===========================================================================
wire     sys_clk;    //  全局时钟，50MHz
wire     can_phy_clk;    //can总线物理层时钟，20MHz
wire     clk_gen_locked;   //时钟锁定信号
wire     reset_n;                //   全局复位信号，低电平有效

wire [`DATA_WIDTH-1:0]  pmsm_reated_current; //  额定电流值（*10）
wire [`DATA_WIDTH-1:0]  pmsm_rated_speed;    //  额定转速

//系统调度控制模块单元变量
wire location_loop_control_enable;
wire location_detection_enable;
wire current_loop_control_enable;
wire gate_driver_init_enable;
wire gate_driver_init_done;
wire electrical_rotation_phase_forecast_enable;
wire can_init_enable;
wire emergency_stop;
wire speed_control_enable;
wire system_initilization_done;

//转速与电气旋转角度测量单元
wire [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin;
wire [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos;
wire  [`DATA_WIDTH-1:0]  standardization_detect_speed;   //转速测量输出

//  电流检测单元
wire [`DATA_WIDTH-1:0] current_detect_status;
wire [`DATA_WIDTH-1:0] phase_a_current;
wire [`DATA_WIDTH-1:0] phase_b_current;
wire current_enable;
wire channela_detect_done;
wire channelb_detect_done;
wire channela_detect_err;
wire channelb_detect_err;

//电流闭环控制
wire [`DATA_WIDTH-1:0]    current_d_param_p;
wire [`DATA_WIDTH-1:0]    current_d_param_i;
wire [`DATA_WIDTH-1:0]    current_d_param_d;
wire [`DATA_WIDTH-1:0]    current_q_param_p;
wire [`DATA_WIDTH-1:0]    current_q_param_i;
wire [`DATA_WIDTH-1:0]    current_q_param_d;
wire [`DATA_WIDTH-1:0]    voltage_alpha;
wire [`DATA_WIDTH-1:0]    voltage_beta;
wire current_loop_control_done;

//q轴电流设定值
wire [`DATA_WIDTH-1:0]    current_q_set_val;

//转速闭环控制
wire [`DATA_WIDTH-1:0]    speed_set_val;
wire [`DATA_WIDTH-1:0]    speed_control_param_p;
wire [`DATA_WIDTH-1:0]    speed_control_param_i;
wire [`DATA_WIDTH-1:0]    speed_control_param_d;
wire  speed_loop_cal_done;

//位置控制模块
wire [`DATA_WIDTH-1:0]    pmsm_location_control_speed_set_value;
wire  [`ABSOLUTION_TOTAL_BIT-1:0]   location_detection_value;
wire pmsm_location_control_done;
//can通讯模块
wire [(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value;
wire can_init_done;
wire [(`DATA_WIDTH/2)-1:0] band_breaks_mode;  //抱闸工作模式输出
wire [(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode;   //电机启停指令输出
wire [(`DATA_WIDTH/4)-1:0] pmsm_work_mode;     //电机工作模式指令输出
wire [`DATA_WIDTH-1:0]   pmsm_speed_set_value;   //  电机转速设定值输出

//栅极驱动器模块
wire [`DATA_WIDTH-1:0]    gate_driver_register_1;
wire [`DATA_WIDTH-1:0]    gate_driver_register_2;
wire                                        gate_driver_error;

//svpwm
wire [`DATA_WIDTH-1:0]   Tcma;
wire [`DATA_WIDTH-1:0]   Tcmb;
wire [`DATA_WIDTH-1:0]   Tcmc;
wire svpwm_cal_done;
(* dont_touch="true" *) wire phase_a_high_side;                     //    a相上桥壁控制
wire phase_a_low_side;                      //    a相下桥臂控制
wire phase_b_high_side;                    //    b相上桥臂控制
wire phase_b_low_side;                     //    b相下桥臂控制
wire phase_c_high_side;                    //     c相上桥臂控制
wire phase_c_low_side;                     //     c相下桥臂控制




//===========================================================================
//时钟管理单元
//===========================================================================
clk_wiz_0 global_clk_gen
(
 // Clock in ports
 .clk_in1(clk_50MHz_in),      // input clk_in1
                              // Clock out ports
 .clk_out1(sys_clk),     // output clk_out1
 .clk_out2(can_phy_clk),     // output clk_out2
                             // Status and control signals
 .resetn(reset_n_in), // input resetn
 .locked(clk_gen_locked));      // output locked

//===========================================================================
//全局复位信号
//===========================================================================
assign reset_n = reset_n_in && clk_gen_locked;
//===========================================================================
//系统控制单元
//===========================================================================
system_control_unit system_control_inst(
                                        .sys_clk(sys_clk),
                                        .reset_n(reset_n),

                                        //位置模式控制
                                        .location_loop_control_enable_out(location_loop_control_enable),    //  位置控制使能输出
                                        .location_detection_enable_out(location_detection_enable),          //  位置检测使能输出

                                        //电流检测
                                        .current_enable_out(current_enable) , //detect_enable signale
                                        .channela_detect_done_in(channela_detect_done),    //channel a detect done signal in
                                        .channelb_detect_done_in(channelb_detect_done),    //channel b detect done signal in
                                        .channela_detect_err_in(channela_detect_err),       //current detect error triger
                                        .channelb_detect_err_in(channelb_detect_err),     //current detect error triger
                                        .current_detect_status_out(current_detect_status),

                                        //电流闭环控制
                                        .current_loop_control_enable_out(current_loop_control_enable),      //控制使能输入，high-active

                                        //栅极驱动器控制
                                        .gate_driver_init_enable_out(gate_driver_init_enable),  //  栅极驱动器上电或复位后初始化使能
                                        .gate_driver_init_done_in(gate_driver_init_done),  //  栅极驱动器初始化完成标志
                                        .gate_driver_error_in(gate_driver_error),   //栅极寄存器故障报警输入，高电平有效

                                        //转速与电角度计算
                                        .electrical_rotation_phase_forecast_enable_out(electrical_rotation_phase_forecast_enable),

                                        //can总线
                                        .can_init_enable_out(can_init_enable),    //   can初始化使能标志
                                        .can_init_done_in(can_init_done),    //    can初始化完成标志
                                        .band_breaks_mode_in(band_breaks_mode),  //抱闸工作模式输入
                                        .pmsm_start_stop_mode_in(pmsm_start_stop_mode),   //电机启停指令输入
                                        .pmsm_work_mode_in(pmsm_work_mode),     //电机工作模式指令输入

                                        //栅极驱动器
                                        .emergency_stop_out(emergency_stop),                            //   紧急停机指令，用于电流或栅极驱动器发生异常时停止运行，高点平有效

                                        //速度闭环控制
                                        .speed_control_enable_out(speed_control_enable),    //速度控制使能信号
                                                                                            //系统初始化完成标志
                                        .system_initilization_done_out(system_initilization_done)              //  系统初始化完成输入,高电平有效
                                        );
//===========================================================================
//电流检测单元例化
//===========================================================================
current_detect current_detect_inst(
                                   .sys_clk(sys_clk),                //system clock
                                   .reset_n(reset_n),                //reset signal,low active

                                   .detect_enable_in(current_enable) , //detect_enable signale
                                   .pmsm_imax_in(pmsm_reated_current),  //电机额定电流值

                                   //channel a port
                                   .channela_sdat_in(current_u_data_in),     //spi data input
                                   .channela_ocd_in(current_u_ocd),     //over_current_detect input
                                   .channela_sclk_out(current_u_clk_out),   //spi clk output
                                   .channela_cs_n_out(current_u_cs_n_out),  //chip select otuput

                                   //channel b port
                                   .channelb_sdat_in(current_v_data_in),     //spi data input
                                   .channelb_ocd_in(current_v_ocd),     //over_current_detect input
                                   .channelb_sclk_out(current_v_clk_out),   //spi clk output
                                   .channelb_cs_n_out(current_v_cs_n_out),  //chip select otuput

                                   //current detect
                                   .phase_a_current_out(phase_a_current),
                                   .phase_b_current_out(phase_b_current),

                                   //current_detect_err_message output
                                   .current_detect_status_out(current_detect_status),
                                   .channela_detect_err_out(channela_detect_err), //current detect error triger
                                   .channelb_detect_err_out(channelb_detect_err), //current detect error triger
                                                                                  //detect done signal
                                   .channela_detect_done_out(channela_detect_done),    //channel a detect done signal out
                                   .channelb_detect_done_out(channelb_detect_done)     //channel b detect done signal out
                                   );
//===========================================================================
//电角度与转速测量单元
//===========================================================================
speed_and_phase_trig_calculation_module speed_and_phase_trig_calculation_inst (
                                                                               .sys_clk(sys_clk),                //system clock
                                                                               .reset_n(reset_n),                //reset signal,low active
                                                                                                                 //   霍尔传感器输入
                                                                               .hall_u_in(hall_u_in),
                                                                               .hall_v_in(hall_v_in),
                                                                               .hall_w_in(hall_w_in),

                                                                               //   增量编码器输入
                                                                               .incremental_encode_ch_a_in(heds_9040_ch_a_in),
                                                                               .incremental_encode_ch_b_in(heds_9040_ch_b_in),

                                                                               //   电角度预测使能
                                                                               .electrical_rotation_phase_forecast_enable_in(electrical_rotation_phase_forecast_enable),

                                                                               //额定转速输入
                                                                               .rated_speed_in(pmsm_rated_speed),

                                                                               //转子电角度正余弦计算输出
                                                                               .electrical_rotation_phase_sin_out(electrical_rotation_phase_sin), //电气旋转角度正弦输出
                                                                               .electrical_rotation_phase_cos_out(electrical_rotation_phase_cos), //电气旋转角度余弦输出
                                                                               .electrical_rotation_phase_trig_calculate_valid_out(),                       //正余弦计算有效标志输出

                                                                               //转子转速输出
                                                                               .standardization_speed_out(standardization_detect_speed)
                                                                               );
//===========================================================================
//电流闭环控制
//===========================================================================
current_loop_control current_loop_control_inst(
                                               .sys_clk(sys_clk),                //system clock
                                               .reset_n(reset_n),                //reset signal,low active

                                               .current_loop_control_enable_in(current_loop_control_enable),      //控制使能输入，high-active

                                               .electrical_rotation_phase_sin_in(electrical_rotation_phase_sin),   //  电气角度正弦值输入
                                               .electrical_rotation_phase_cos_in(electrical_rotation_phase_cos),  //  电气角度余弦值输入

                                               .phase_a_current_in(phase_a_current),                      //  a相电流检测值
                                               .phase_b_current_in(phase_b_current),                      //  b相电流检测值

                                               .current_d_param_p_in(current_d_param_p),         //d轴电流环P参数
                                               .current_d_param_i_in(current_d_param_i),          //d轴电流环I参数
                                               .current_d_param_d_in(current_d_param_d),         //d轴电流环D参数

                                               .current_d_set_val_in(16'd0),            //d轴电流设定值

                                               .current_q_param_p_in(current_q_param_p),         //q轴电流环P参数
                                               .current_q_param_i_in(current_q_param_i),          //q轴电流环I参数
                                               .current_q_param_d_in(current_q_param_d),         //q轴电流环D参数

                                               .current_q_set_val_in(current_q_set_val),            //q轴电流设定值

                                               .voltage_alpha_out(voltage_alpha), //U_alpha电压输出
                                               .voltage_beta_out(voltage_beta),   //U_beta电压输出
                                               .current_loop_control_done_out(current_loop_control_done)     //电压输出有效标志
                                               );
//===========================================================================
//转速闭环控制
//===========================================================================
speed_loop_control speed_loop_control_inst(
                                           .sys_clk(sys_clk),                //system clock
                                           .reset_n(reset_n),                //reset signal,low active

                                           .speed_control_enable_in(speed_control_enable),   //速度控制使能信号
                                           .speed_control_param_p_in(speed_control_param_p),   //速度闭环控制P参数
                                           .speed_control_param_i_in(speed_control_param_i),   //速度闭环控制I参数
                                           .speed_control_param_d_in(speed_control_param_d),   //速度闭环控制D参数

                                           .speed_set_val_in(speed_set_val),       //速度设定值
                                           .speed_detect_val_in(standardization_detect_speed),  //实际速度检测值

                                           .current_q_set_val_out(current_q_set_val),    //Q轴电流设定值
                                           .speed_loop_cal_done_out(speed_loop_cal_done)   //  电流闭环计算输出
                                           );
assign speed_set_val=(pmsm_work_mode==`MOTOR_LOCATION_MODE)?pmsm_location_control_speed_set_value:pmsm_speed_set_value;
//===========================================================================
//位置控制闭环控制
//===========================================================================
location_control_unit location_control_inst(
                                            .sys_clk(sys_clk),                //system clock
                                            .reset_n(reset_n),                //reset signal,low active

                                            .location_loop_control_enable_in(location_loop_control_enable),    //  位置控制使能输入
                                            .location_detection_enable_in(location_detection_enable),          //  位置检测使能输入

                                            .vlx_data_in(vlx_data_in),                         //  ssi接口数据输入
                                            .vlx_clk_out(vlx_clk_out),                        //  ssi接口时钟输出

                                            .pmsm_location_set_value_in(pmsm_location_set_value),    //位置模式设定值，包含转动位置及转动速度

                                            .pmsm_location_control_speed_set_value_out(pmsm_location_control_speed_set_value),    // 位置控制模式下转速设定值输出
                                            .location_detection_value_out(location_detection_value),        //位置检测输出

                                            .pmsm_location_control_done_out(pmsm_location_control_done)   //位置控制模式控制计算完成标志
                                            );
//===========================================================================
//SVPWM模块
//===========================================================================
(* dont_touch="true" *)svpwm_unit_module svpwm_unit_module_inst(
                  .sys_clk(sys_clk),                //system clock
                  .reset_n(reset_n),                //reset signal,low active

                  .svpwm_cal_enable_in(current_loop_control_done),                 //     SVPWM计算使能
                  .system_initilization_done_in(system_initilization_done),              //  系统初始化完成输入,高电平有效

                  .emergency_stop_in(emergency_stop),                            //   紧急停机指令，用于电流或栅极驱动器发生异常时停止运行，高点平有效

                  .U_alpha_in(voltage_alpha),       //    Ualpha电压输入
                  .U_beta_in(voltage_beta),         //    Ubeta电压输入

                  .phase_a_high_side_out(phase_a_high_side),                     //    a相上桥壁控制
                  .phase_a_low_side_out(phase_a_low_side),                      //    a相下桥臂控制
                  .phase_b_high_side_out(phase_b_high_side),                    //    b相上桥臂控制
                  .phase_b_low_side_out(phase_b_low_side),                     //    b相下桥臂控制
                  .phase_c_high_side_out(phase_c_high_side),                    //     c相上桥臂控制
                  .phase_c_low_side_out(phase_c_low_side),                     //     c相下桥臂控制

                  .Tcma_out(Tcma),
                  .Tcmb_out(Tcmb),
                  .Tcmc_out(Tcmc),
                  .svpwm_cal_done_out(svpwm_cal_done)
                  );
//===========================================================================
//
//===========================================================================
gate_driver_unit gate_driver_inst(
                 .sys_clk(sys_clk),                //system clock
                 .reset_n(reset_n),                //reset signal,low active

                 .gate_driver_init_enable_in(gate_driver_init_enable),  //  栅极驱动器上电或复位后初始化使能输入
                 .gate_driver_init_done_out(gate_driver_init_done),  //  栅极驱动器初始化完成标志

                 .gate_a_high_side_in(phase_a_high_side),                     //    a相上桥壁控制
                 .gate_a_low_side_in(phase_a_low_side),                      //    a相下桥臂控制
                 .gate_b_high_side_in(phase_b_high_side),                    //    b相上桥臂控制
                 .gate_b_low_side_in(phase_b_low_side),                     //    b相下桥臂控制
                 .gate_c_high_side_in(phase_c_high_side),                    //     c相上桥臂控制
                 .gate_c_low_side_in(phase_c_low_side),                      //     c相下桥臂控制

                .gate_driver_enable_out(drv8320_enable_out),
                 .gate_driver_nscs_out(drv8320s_nscs_out),
                 .gate_driver_sclk_out(drv8320s_clk_out),
                 .gate_driver_sdi_out(drv8320s_sdi_out),
                 .gate_driver_sdo_in(drv8320s_sdo_in),
                 .gate_driver_nfault_in(drc8320s_nfault),

                 .gate_a_high_side_out(drv8320s_inh_a_out),                     //    a相上桥壁控制
                 .gate_a_low_side_out(drv8320s_inl_a_out),                      //    a相下桥臂控制
                 .gate_b_high_side_out(drv8320s_inh_b_out),                    //    b相上桥臂控制
                 .gate_b_low_side_out(drv8320s_inl_b_out),                     //    b相下桥臂控制
                 .gate_c_high_side_out(drv8320s_inh_c_out),                    //     c相上桥臂控制
                 .gate_c_low_side_out(drv8320s_inl_c_out),                     //     c相下桥臂控制

                 .gate_driver_register_1_out(gate_driver_register_1),  //  栅极寄存器状态1寄存器输出
                 .gate_driver_register_2_out(gate_driver_register_2),  //  栅极寄存器状态2寄存器输出
                 .gate_driver_error_out(gate_driver_error)   //栅极寄存器故障报警输出
                 );
//===========================================================================
//can总线通讯模块
//===========================================================================
can_transaction_unit can_transaction_inst(
                                          .sys_clk(sys_clk),                //system clock
                                          .reset_n(reset_n),                //reset signal,low active

                                          //  can物理层端口
                                          .can_phy_rx(can_rx_in),
                                          .can_phy_tx(can_tx_out),
                                          .can_clk(can_phy_clk),

                                          .system_initilization_done_in(system_initilization_done),              //  系统初始化完成输入,高电平有效

                                          .can_init_enable_in(can_init_enable),    //   can初始化使能标志
                                          .can_init_done_out(can_init_done),    //    can初始化完成标志

                                          .current_rated_value_out(pmsm_reated_current),  //  额定电流值输出
                                          .speed_rated_value_out(pmsm_rated_speed),  //  额定转速值输出

                                          .current_d_param_p_out(current_d_param_p),  //    电流环d轴控制参数p输出
                                          .current_d_param_i_out(current_d_param_i),   //    电流环d轴控制参数i输出
                                          .current_d_param_d_out(current_d_param_d),  //    电流环d轴控制参数d输出

                                          .current_q_param_p_out(current_q_param_p),         //q轴电流环P参数
                                          .current_q_param_i_out(current_q_param_i),          //q轴电流环I参数
                                          .current_q_param_d_out(current_q_param_d),         //q轴电流环D参数

                                          .speed_control_param_p_out(speed_control_param_p),   //速度闭环控制P参数
                                          .speed_control_param_i_out(speed_control_param_i),   //速度闭环控制I参数
                                          .speed_control_param_d_out(speed_control_param_d),   //速度闭环控制D参数

                                          .location_control_param_p_out(),   //位置闭环控制P参数
                                          .location_control_param_i_out(),   //位置闭环控制I参数
                                          .location_control_param_d_out(),   //位置闭环控制D参数

                                          .band_breaks_mode_out(band_breaks_mode),  //抱闸工作模式输出

                                          .pmsm_start_stop_mode_out(pmsm_start_stop_mode),   //电机启停指令输出

                                          .pmsm_work_mode_out(pmsm_work_mode),     //电机工作模式指令输出

                                          .pmsm_speed_set_value_out(pmsm_speed_set_value),   //  电机转速设定值输出
                                          .pmsm_location_set_value_out(pmsm_location_set_value),    //电机位置设定值输出

                                          .gate_driver_register_1_in(gate_driver_register_1),  //  栅极寄存器状态1寄存器输入
                                          .gate_driver_register_2_in(gate_driver_register_2),  //  栅极寄存器状态2寄存器输入
                                          .gate_driver_error_in(gate_driver_error),          //栅极寄存器故障报警输入

                                          .current_detect_status_in(current_detect_status),
                                          .channela_detect_err_in(channela_detect_err),    //current detect error triger
                                          .channelb_detect_err_in(channelb_detect_err),   //current detect error triger
                                          .phase_a_current_in(phase_a_current),     //  a相电流检测值
                                          .phase_b_current_in(phase_b_current),    //  b相电流检测值
                                          .electrical_rotation_phase_sin_in(electrical_rotation_phase_sin),   //  电气角度正弦值输入
                                          .electrical_rotation_phase_cos_in(electrical_rotation_phase_cos),  //  电气角度余弦值输入
                                          .current_loop_control_enable_in(current_loop_control_enable),     //电流环控制使能输入，用于触发电流电气角度值上传

                                          .U_alpha_in(voltage_alpha),       //    Ualpha电压输入
                                          .U_beta_in(voltage_beta),         //    Ubeta电压输入
                                          .current_loop_control_done_in(current_loop_control_done),     //电压输出有效标志输入

                                          .Tcma_in(Tcma),    //  a 相时间切换点输出
                                          .Tcmb_in(Tcmb),    //   b相时间切换点输出
                                          .Tcmc_in(Tcmc),    //   c相时间切换点输出
                                          .svpwm_cal_done_in(svpwm_cal_done),  //svpwm计算完成输入，用于三相时间切换点数据上传

                                          .speed_detect_val_in(standardization_detect_speed),      //实际速度检测值
                                          .current_q_set_val_in(current_q_set_val),    //Q轴电流设定值
                                          .speed_loop_cal_done_in(speed_loop_cal_done),     //  速度闭环完成标志

                                          .pmsm_location_detect_value_in(location_detection_value),   //位置检测输入
                                          .speed_set_value_in(pmsm_location_control_speed_set_value),  //  位置模式速度设定值输入
                                          .pmsm_location_cal_done_in(pmsm_location_control_done),   //位置闭环控制完成标志

                                          .ds_18b20_temp_in(16'd0),  //  环境温度输入
                                          .ds_18b20_update_done_in(16'd0)  //环境温度更新指令
                                          );
endmodule
