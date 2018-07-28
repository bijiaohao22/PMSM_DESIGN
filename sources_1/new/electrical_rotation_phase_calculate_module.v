`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/12
// Design Name:PMSM_DESIGN
// Module Name: electrical_rotation_phase_calculate_module.v
// Target Device:
// Tool versions:
// Description:根据增量编码器与霍尔编码器获取电机转子的电角度
// Dependencies:
// Revision:
// Additional Comments:
//当收到电气旋转角度相位预测使能时，根据霍尔传感器的状态输出电角度预测值，在正常工作模式下，根据旋转
//方向实时获取转子电气角度，当霍尔传感器相位变化时，校准电气角度，单个脉冲对应的电气角度增量为2*极对数
//*2048/增量编码器线数
//====================================================================================
`include "project_param.v"
module electrical_rotation_phase_calculate_module(
                                                  input    sys_clk,
                                                  input    reset_n,

                                                  input    electrical_rotation_phase_forecast_enable_in,            //电气旋转角度相位预测使能，用于上电或复位时相位预判

                                                  //增量编码器信息输入
                                                  input    heds_9040_decoder_in,           //增量编码器正交编码输入
                                                  input    rotate_direction_in,                  //旋转方向输入

                                                  //霍尔传感器输入
                                                  input    hall_u_in,
                                                  input    hall_v_in,
                                                  input    hall_w_in,

                                                  //电气角度输出
                                                  output  [`DATA_WIDTH-1:0]   electrical_rotation_phase_out,
                                                  output                                        electrical_rotation_phase_valid_out
                                                  );

//===========================================================================
//内部变量与常量声明
//===========================================================================
localparam   DELTA_PHASE=2*`PMSM_POLE_PAIRS*2048/`INCREMENTAL_CODER_CPR; //增量编码器单个脉冲对应的电角度值
reg   hall_u_r,hall_v_r, hall_w_r;  //霍尔传感器输入缓存
reg   heds_9040_decoder_r;//增量编码器正交编码缓存

reg[13:0]   electrical_rotation_phase_r,electrical_rotation_phase_r_ns;      //转子电气角度计量及其下一状态
reg               electrical_rotation_phase_valid_out_r;                                    //转子电气角度有效值
wire[2:0]     hall_current_value,hall_next_value;                                        //霍尔传感器当前状态及其下一状态

//===========================================================================
//霍尔传感器输入缓存
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {hall_u_r, hall_v_r, hall_w_r} <= 'd0;
    else
    {hall_u_r, hall_v_r, hall_w_r} <= {hall_u_in, hall_v_in, hall_w_in};
    end

assign hall_current_value = {hall_u_r, hall_v_r, hall_w_r};
assign hall_next_value=
    {
    hall_u_in,hall_v_in,hall_w_in
    };
//===========================================================================
//增量编码器正交编码器缓存
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
        if(!reset_n)
            heds_9040_decoder_r<='d0;
        else
            heds_9040_decoder_r <= heds_9040_decoder_in;
    end


//===========================================================================
//转子电气角度计算
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        electrical_rotation_phase_r <= 'd0;
    else
        electrical_rotation_phase_r <= electrical_rotation_phase_r_ns;
    end
always @(*)
    begin
    if (electrical_rotation_phase_forecast_enable_in)        //收到电气角度预测时对转子位置预判
        begin
        case (hall_current_value)
            3'b101:  electrical_rotation_phase_r_ns = 14'h555;           //30度电角度
            3'b100:  electrical_rotation_phase_r_ns = 14'h1000;          //90度电角度
            3'b110:  electrical_rotation_phase_r_ns = 14'h1aaa;          //150度电角度
            3'b010:  electrical_rotation_phase_r_ns = 14'h2555;           //210度电角度
            3'b011:  electrical_rotation_phase_r_ns = 14'h3000;           //270度电角度
            3'b001:  electrical_rotation_phase_r_ns = 14'h3aaa;           //330度电角度
            default:electrical_rotation_phase_r_ns = electrical_rotation_phase_r;
        endcase
        end 
        else if (hall_next_value != hall_current_value)    //当霍尔传感器信号发生变化时，对电角度进行校正
        begin
        if (rotate_direction_in) //反转情况
            case (hall_next_value)
                3'b101:  electrical_rotation_phase_r_ns = 14'h0aaa;           //60度电角度
                3'b100:  electrical_rotation_phase_r_ns = 14'h1555;          //120度电角度
                3'b110:  electrical_rotation_phase_r_ns = 14'h2000;          //180度电角度
                3'b010:  electrical_rotation_phase_r_ns = 14'h2aaa;           //240度电角度
                3'b011:  electrical_rotation_phase_r_ns = 14'h3555;           //300度电角度
                3'b001:  electrical_rotation_phase_r_ns = 14'h0000;           //0度电角度
                default:electrical_rotation_phase_r_ns = electrical_rotation_phase_r;
            endcase
        else //正转情况
            case (hall_next_value)
                3'b101:  electrical_rotation_phase_r_ns = 14'h0000;           //0度电角度
                3'b100:  electrical_rotation_phase_r_ns = 14'h0aaa;          //60度电角度
                3'b110:  electrical_rotation_phase_r_ns = 14'h1555;          //120度电角度
                3'b010:  electrical_rotation_phase_r_ns = 14'h2000;           //180度电角度
                3'b011:  electrical_rotation_phase_r_ns = 14'h2aaa;           //240度电角度
                3'b001:  electrical_rotation_phase_r_ns = 14'h3555;           //300度电角度
                default:electrical_rotation_phase_r_ns = electrical_rotation_phase_r;
            endcase
        end 
        else if (({heds_9040_decoder_r, heds_9040_decoder_in}==2'b01)||({heds_9040_decoder_r, heds_9040_decoder_in}==2'b10))
        begin
        if (rotate_direction_in) //反转情况
            electrical_rotation_phase_r_ns = electrical_rotation_phase_r - DELTA_PHASE;
        else //正转情况
            electrical_rotation_phase_r_ns = electrical_rotation_phase_r + DELTA_PHASE;
        end
        else
            electrical_rotation_phase_r_ns=electrical_rotation_phase_r;
    end
    //===========================================================================
    //输出有效状态赋值
    //===========================================================================
    always  @(posedge sys_clk or negedge reset_n)
        begin
            if(!reset_n)
                electrical_rotation_phase_valid_out_r<='d0;
            else
                electrical_rotation_phase_valid_out_r<=1'd1;
        end
        //===========================================================================
        //输出状态赋值
        //===========================================================================
        assign electrical_rotation_phase_out={electrical_rotation_phase_r[13],electrical_rotation_phase_r[13],electrical_rotation_phase_r};
        assign electrical_rotation_phase_valid_out=electrical_rotation_phase_valid_out_r;
endmodule
