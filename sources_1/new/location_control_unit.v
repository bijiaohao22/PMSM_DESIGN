//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/23
// Design Name:PMSM_DESIGN
// Module Name: location_control_unit.v
// Target Device:
// Tool versions:
// Description:位置控制模块实现
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module location_control_unit(
                             input    sys_clk,
                             input    reset_n,

                             input    location_loop_control_enable_in,    //  位置控制使能输入
                             input    location_detection_enable_in,          //  位置检测使能输入

                             input        vlx_data_in,                         //  ssi接口数据输入
                             output      vlx_clk_out,                        //  ssi接口时钟输出

                             input    [(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value_in,    //转速模式设定值，包含转动位置及转动速度

                             output  [`DATA_WIDTH-1:0]    pmsm_location_control_speed_set_value_out,    // 位置控制模式下转速设定值输出
                             output  [`ABSOLUTION_TOTAL_BIT-1:0]   location_detection_value_out,        //位置检测输出

                             output  pmsm_location_control_done_out   //位置控制模式控制计算完成标志
                             );
//===========================================================================
//内部变量声明
//===========================================================================

//===========================================================================
//位置检测模块例化
//===========================================================================
absolution_location_encoder absolution_location_encoder_inst(
                                   .sys_clk(sys_clk),
                                   .reset_n(reset_n),

                                   .location_detection_enable_in(location_detection_enable_in),  //  位置检测使能输入

                                   .vlx_data_in(vlx_data_in),                         //  ssi接口数据输入
                                   .vlx_clk_out(vlx_clk_out),                        //  ssi接口时钟输出

                                   .location_detection_value_out(location_detection_value_out)
                                   );
//===========================================================================
//位置控制模块例化
//===========================================================================
location_loop_control location_loop_control_inst(
                             .sys_clk(sys_clk),
                                   .reset_n(reset_n),

                             .location_loop_control_enable_in(location_loop_control_enable_in),    //  位置控制使能输入

                             .pmsm_location_set_value_in(pmsm_location_set_value_in),    //转速模式设定值，包含转动位置及转动速度
                             .pmsm_detect_location_value_in(location_detection_value_out),    //  负载位置检测值输入

                             .pmsm_location_control_speed_set_value_out(pmsm_location_control_speed_set_value_out),    // 位置控制模式下转速设定值输出

                             .pmsm_location_control_done_out(pmsm_location_control_done_out)   //位置控制模式控制计算完成标志
                             );
endmodule
