//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/23
// Design Name:PMSM_DESIGN
// Module Name: location_loop_control.v
// Target Device:
// Tool versions:
// Description:位置模式闭环控制
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module location_loop_control(
                             input    sys_clk,
                             input    reset_n,

                             input    location_loop_control_enable_in,    //  位置控制使能输入

                             input    [(`DATA_WIDTH*2+2-1):0]    pmsm_location_set_value_in,    //转速模式设定值，包含转动位置及转动速度
                             input    [`DATA_WIDTH+2-1:0]          pmsm_detect_location_value_in,    //  负载位置检测值输入

                             output  [`DATA_WIDTH-1:0]    pmsm_location_control_speed_set_value_out,    // 位置控制模式下转速设定值输出

                             output  pmsm_location_control_done_out   //位置控制模式控制计算完成标志
                             );
//===========================================================================
//内部常量声明
//===========================================================================

//===========================================================================
//内部变量声明
//===========================================================================
reg   signed[`DATA_WIDTH-1:0]    pmsm_location_control_speed_set_value_r;
reg   pmsm_location_control_done_r;
//===========================================================================
//位置模式转速设定值输出
//===========================================================================
always @(posedge sys_clk or  negedge reset_n)
    begin
    if (!reset_n)
        pmsm_location_control_speed_set_value_r <= 'sd0;
    else if (location_loop_control_enable_in)
        begin
        if (((pmsm_location_set_value_in[17:0] - pmsm_detect_location_value_in) <`location_control_error) || ((pmsm_detect_location_value_in - pmsm_location_set_value_in[17:0])<`location_control_error)) //达到控制指标
            pmsm_location_control_speed_set_value_r <= 'sd0;
        else
            pmsm_location_control_speed_set_value_r <= pmsm_location_set_value_in[(`DATA_WIDTH * 2 + 2-1) -:16];
end else
    pmsm_location_control_speed_set_value_r <= pmsm_location_control_speed_set_value_r;
end
//===========================================================================
//位置控制计算完成标志
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pmsm_location_control_done_r <= 'd0;
    else
        pmsm_location_control_done_r <= location_loop_control_enable_in;
    end
//===========================================================================
//输出端口赋值
//===========================================================================
assign pmsm_location_control_speed_set_value_out=pmsm_location_control_speed_set_value_r;
assign pmsm_location_control_done_out=pmsm_location_control_done_r;
endmodule
