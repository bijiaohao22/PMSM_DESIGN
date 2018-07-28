//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/18
// Design Name:PMSM_DESIGN
// Module Name: can_bus_app_unit.v
// Target Device:
// Tool versions:
// Description:  通讯应用层设计实现，数据收发处理仲裁
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module can_bus_app_unit(
                        input    sys_clk,
                        input    reset_n,

                        output [31:0]   tx_dw1r_out,    //  数据发送字1
                        output [31:0]   tx_dw2r_out,    //  数据发送字2
                        output              tx_valid_out,   //  发送有效标志
                        input                tx_ready_in,     //  发送准备好输入

                        input   [31:0]   rx_dw1r_in,     //  数据接收字1
                        input   [31:0]   rx_dw2r_in,     //  数据接收字2
                        input               rx_valid_in,      //  数据接收有效标志输入
                        output             rx_ready_out,   //  数据接收准备好输出

                        output[`DATA_WIDTH-1:0]  current_rated_value_out,  //  额定电流值输出
                        output[`DATA_WIDTH-1:0]  speed_rated_value_out,  //  额定转速值输出

                        output [`DATA_WIDTH-1:0]    current_d_param_p_out,  //    电流环d轴控制参数p输出
                        output [`DATA_WIDTH-1:0]    current_d_param_i_out,   //    电流环d轴控制参数i输出
                        output [`DATA_WIDTH-1:0]    current_d_param_d_out,  //    电流环d轴控制参数d输出

                        output [`DATA_WIDTH-1:0]    current_q_param_p_out,         //q轴电流环P参数
                        output [`DATA_WIDTH-1:0]    current_q_param_i_out,          //q轴电流环I参数
                        output [`DATA_WIDTH-1:0]    current_q_param_d_out,         //q轴电流环D参数

                        output  [`DATA_WIDTH-1:0]    speed_control_param_p_out,   //速度闭环控制P参数
                        output  [`DATA_WIDTH-1:0]    speed_control_param_i_out,   //速度闭环控制I参数
                        output  [`DATA_WIDTH-1:0]    speed_control_param_d_out,   //速度闭环控制D参数

                        output  [`DATA_WIDTH-1:0]    location_control_param_p_out,   //位置闭环控制P参数
                        output  [`DATA_WIDTH-1:0]    location_control_param_i_out,   //位置闭环控制I参数
                        output  [`DATA_WIDTH-1:0]    location_control_param_d_out,   //位置闭环控制D参数

                        output[(`DATA_WIDTH/2)-1:0] band_breaks_mode_out,  //抱闸工作模式输出

                        output[(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode_out,   //电机启停指令输出

                        output [(`DATA_WIDTH/4)-1:0] pmsm_work_mode_out,     //电机工作模式指令输出

                        output[`DATA_WIDTH-1:0]   pmsm_speed_set_value_out,   //  电机转速设定值输出
                        output[(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value_out,    //电机位置设定值输出

                        input   [`DATA_WIDTH-1:0]    gate_driver_register_1_in,  //  栅极寄存器状态1寄存器输入
                        input   [`DATA_WIDTH-1:0]    gate_driver_register_2_in,  //  栅极寄存器状态2寄存器输入
                        input                                          gate_driver_error_in,          //栅极寄存器故障报警输入

                        input  [`DATA_WIDTH-1:0] current_detect_status_in,
                        input   channela_detect_err_in,    //current detect error triger
                        input   channelb_detect_err_in,   //current detect error triger
                        input signed[`DATA_WIDTH-1:0] phase_a_current_in,     //  a相电流检测值
                        input signed[`DATA_WIDTH-1:0] phase_b_current_in,    //  b相电流检测值
                        input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_in,   //  电气角度正弦值输入
                        input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_in,  //  电气角度余弦值输入
                        input current_loop_control_enable_in,     //电流环控制使能输入，用于触发电流电气角度值上传

                        input signed   [`DATA_WIDTH-1:0]      U_alpha_in,       //    Ualpha电压输入
                        input signed   [`DATA_WIDTH-1:0]      U_beta_in,         //    Ubeta电压输入
                        input  current_loop_control_done_in,     //电压输出有效标志输入

                        input [`DATA_WIDTH-1:0]   Tcma_in,    //  a 相时间切换点输出
                        input [`DATA_WIDTH-1:0]   Tcmb_in,    //   b相时间切换点输出
                        input [`DATA_WIDTH-1:0]   Tcmc_in,    //   c相时间切换点输出
                        input svpwm_cal_done_in,  //svpwm计算完成输入，用于三相时间切换点数据上传

                        input    [`DATA_WIDTH-1:0]       speed_detect_val_in,      //实际速度检测值
                        input    [`DATA_WIDTH-1:0]  current_q_set_val_in,    //Q轴电流设定值
                        input    speed_loop_cal_done_in,     //  速度闭环完成标志

                        input    [(`DATA_WIDTH*2+2)-1:0]pmsm_location_detect_value_in,   //位置检测输入
                        input    [`DATA_WIDTH-1:0]    speed_set_value_in,  //  位置模式速度设定值输入
                        input    pmsm_location_cal_done_in,   //位置闭环控制完成标志

                        input    [`DATA_WIDTH-1:0]    ds_18b20_temp_in,  //  环境温度输入
                        input    ds_18b20_update_done_in  //环境温度更新指令
                        );
//===========================================================================
//内部常量声明
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_RX_ACK=1<<1;
localparam FSM_GR=1<<2;    //  栅极驱动错误状态寄存器上传
localparam FSM_CS=1<<3;    //  电流状态信息上传
localparam FSM_EPT=1<<4;  //  电气旋转角度正余弦发送
localparam FSM_CLC=1<<5; //  电流环控制参数上传
localparam FSM_STSV=1<<6; // SVPWM切换时间上传
localparam FSM_SLC=1<<7;  //  速度环控制数据上传
localparam FSM_LLC=1<<8;  //  位置环控制数据上传
localparam FSM_DTV = 1 << 9; //  驱动器温度值数据上传

localparam GR=0;
localparam CS=1;
localparam EPT=2;
localparam CLC=3;
localparam STSV=4;
localparam SLC=5;
localparam LLC=6;
localparam DTV=7;

localparam CSUR=1;        //Current and speed rated value update
localparam CDCV=1<<1; //  Current_d_control_param_value update
localparam CQCV=1<<2; //  Current q control param value update
localparam SPV=1<<3;     //  Speed param value update
localparam LPV=1<<4;     //  Location patam value update
localparam BBV=1<<5;    //Band break value update
localparam MMV=1<<6;  //  Motor mode value update;
localparam MWV=1<<7; //  Motor work mode value update

localparam CSUR_ADDR=8'h01;
localparam CDCV_ADDR=8'h02;
localparam CQCV_ADDR=8'h03;
localparam SPV_ADDR=8'h04;
localparam LPV_ADDR=8'h05;
localparam BBV_ADDR=8'h06;
localparam MMV_ADDR=8'h07;
localparam MWV_ADDR=8'h08;

//===========================================================================
//内部变量声明
//===========================================================================
reg[9:0]   fsm_cs,
    fsm_ns;    //  有限状态机当前状态及其下一状态
reg[31:0]   rx_state_r;            //  接收状态寄存器
reg[31:0]   tx_state_r;            //  发送状态寄存器

reg[31:0]   tx_dw1r_r;    //  数据发送字1
reg[31:0]   tx_dw2r_r;   //  数据发送字2
reg              tx_valid_r;  //  发送有效标志

reg             rx_ready_r;   //  数据接收准备好输出

reg[`DATA_WIDTH-1:0]  current_rated_value_r;  //  额定电流值输出
reg[`DATA_WIDTH-1:0]  speed_rated_value_r;    //  额定转速值输出

reg[`DATA_WIDTH-1:0]    current_d_param_p_r;  //    电流环d轴控制参数p输出
reg[`DATA_WIDTH-1:0]    current_d_param_i_r;   //    电流环d轴控制参数i输出
reg[`DATA_WIDTH-1:0]    current_d_param_d_r;  //    电流环d轴控制参数d输出

reg[`DATA_WIDTH-1:0]    current_q_param_p_r;         //q轴电流环P参数
reg[`DATA_WIDTH-1:0]    current_q_param_i_r;          //q轴电流环I参数
reg[`DATA_WIDTH-1:0]    current_q_param_d_r;        //q轴电流环D参数

reg[`DATA_WIDTH-1:0]    speed_control_param_p_r;   //速度闭环控制P参数
reg[`DATA_WIDTH-1:0]    speed_control_param_i_r;   //速度闭环控制I参数
reg[`DATA_WIDTH-1:0]    speed_control_param_d_r;   //速度闭环控制D参数

reg[`DATA_WIDTH-1:0]    location_control_param_p_r;   //位置闭环控制P参数
reg[`DATA_WIDTH-1:0]    location_control_param_i_r;   //位置闭环控制I参数
reg[`DATA_WIDTH-1:0]    location_control_param_d_r;   //位置闭环控制D参数

reg[(`DATA_WIDTH/2)-1:0] band_breaks_mode_r;  //抱闸工作模式输出

reg[(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode_r;   //电机启停指令输出

reg[(`DATA_WIDTH/4)-1:0] pmsm_work_mode_r;     //电机工作模式指令输出

reg[`DATA_WIDTH-1:0]   pmsm_speed_set_value_r;   //  电机转速设定值输出
reg[(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value_r;    //电机位置设定值输出

wire[7:0] rx_db0,
    rx_db1,
    rx_db2,
    rx_db3,
    rx_db4,
    rx_db5,
    rx_db6,
    rx_db7;  //数据接收线网

//===========================================================================
//有限状态机状态转移
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        fsm_cs <= FSM_IDLE;
    else
        fsm_cs <= fsm_ns;
    end
always @(*)
    begin
    case (fsm_cs)
        FSM_IDLE: begin
                if (rx_state_r != 'd0)    // 首先处理接收，当接收状态寄存器不为0则表明有数据接收，发送响应帧
                    fsm_ns = FSM_RX_ACK;
                else begin  //否则侦听是否有发送请求
                    if (tx_state_r[GR])
                        fsm_ns = FSM_GR;
                    else if (tx_state_r[CS])
                        fsm_ns = FSM_CS;
                    else if (tx_state_r[EPT])
                        fsm_ns = FSM_EPT;
                    else if (tx_state_r[CLC])
                        fsm_ns = FSM_CLC;
                    else if (tx_state_r[STSV])
                        fsm_ns = FSM_STSV;
                    else if (tx_state_r[SLC])
                        fsm_ns = FSM_SLC;
                    else if (tx_state_r[LLC])
                        fsm_ns = FSM_LLC;
                    else if (tx_state_r[DTV])
                        fsm_ns = FSM_DTV;
                    else
                        fsm_ns = fsm_cs;
                end
            end
        FSM_RX_ACK,
                FSM_GR,
                FSM_CS,
                FSM_EPT,
                FSM_CLC,
                FSM_STSV,
                FSM_SLC,
                FSM_LLC,
                FSM_DTV: begin  //收到下层发送准备好标志进行状态寄存器数据更新。
                if (tx_ready_in)
                        fsm_ns = FSM_IDLE;
                else
                    fsm_ns = fsm_cs;
                end
        default :fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//数据读处理
//===========================================================================
assign rx_db0 = rx_dw1r_in[31:24];
assign rx_db1 = rx_dw1r_in[23:16];
assign rx_db2 = rx_dw1r_in[15:8];
assign rx_db3 = rx_dw1r_in[7:0];
assign rx_db4 = rx_dw2r_in[31:24];
assign rx_db5 = rx_dw2r_in[23:16];
assign rx_db6 = rx_dw2r_in[15:8];
assign rx_db7 = rx_dw2r_in[7:0];
//电流额定值接收
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_rated_value_r <= 'd0;
    else if (rx_valid_in && rx_ready_r && (rx_db0 == CSUR_ADDR))
        current_rated_value_r <= {rx_db1, rx_db2};
    else
        current_rated_value_r <= current_rated_value_r;
    end
//转速额定值输出
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_rated_value_r <= 'd0;
    else if (rx_valid_in && rx_ready_r && (rx_db0 == CSUR_ADDR))
        speed_rated_value_r <= {rx_db3, rx_db4};
    else
        speed_rated_value_r <= speed_rated_value_r;
    end
//电流d轴控制参数注入
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        current_d_param_p_r <= 'd0;
        current_d_param_i_r <= 'd0;
        current_d_param_d_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == CDCV_ADDR))
        begin
        current_d_param_p_r <= {rx_db1, rx_db2};
        current_d_param_i_r <= {rx_db3, rx_db4};
        current_d_param_d_r <= {rx_db5, rx_db6};
        end else
        begin
        current_d_param_p_r <= current_d_param_p_r;
        current_d_param_i_r <= current_d_param_i_r;
        current_d_param_d_r <= current_d_param_d_r;
        end
    end
//电流q轴控制参数注入
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        current_q_param_p_r <= 'd0;
        current_q_param_i_r <= 'd0;
        current_q_param_d_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == CQCV_ADDR))
        begin
        current_q_param_p_r <= {rx_db1, rx_db2};
        current_q_param_i_r <= {rx_db3, rx_db4};
        current_q_param_d_r <= {rx_db5, rx_db6};
        end else
        begin
        current_q_param_p_r <= current_q_param_p_r;
        current_q_param_i_r <= current_q_param_i_r;
        current_q_param_d_r <= current_q_param_d_r;
        end
    end
//转速环控制参数注入
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        speed_control_param_p_r <= 'd0;
        speed_control_param_i_r <= 'd0;
        speed_control_param_d_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == SPV_ADDR))
        begin
        speed_control_param_p_r <= {rx_db1, rx_db2};
        speed_control_param_i_r <= {rx_db3, rx_db4};
        speed_control_param_d_r <= {rx_db5, rx_db6};
        end else
        begin
        speed_control_param_p_r <= speed_control_param_p_r;
        speed_control_param_i_r <= speed_control_param_i_r;
        speed_control_param_d_r <= speed_control_param_d_r;
        end
    end
//位置环控制参数注入
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        location_control_param_p_r <= 'd0;
        location_control_param_i_r <= 'd0;
        location_control_param_d_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == LPV_ADDR))
        begin
        location_control_param_p_r <= {rx_db1, rx_db2};
        location_control_param_i_r <= {rx_db3, rx_db4};
        location_control_param_d_r <= {rx_db5, rx_db6};
        end else
        begin
        location_control_param_p_r <= location_control_param_p_r;
        location_control_param_i_r <= location_control_param_i_r;
        location_control_param_d_r <= location_control_param_d_r;
        end
    end
//抱闸动作指令注入
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        band_breaks_mode_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == BBV_ADDR))
        begin
        band_breaks_mode_r <= rx_db1;
        end else
        begin
        band_breaks_mode_r <= band_breaks_mode_r;
        end
    end
//电机停启指令注入
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pmsm_start_stop_mode_r <= 'd0;
    else if (rx_valid_in && rx_ready_r && (rx_db0 == MMV_ADDR))
        pmsm_start_stop_mode_r <= rx_db1;
    else
        pmsm_start_stop_mode_r <= pmsm_start_stop_mode_r;
    end
//电机工作模式注入
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        pmsm_work_mode_r <= 'd0; //默认工作在速度模式下
        pmsm_speed_set_value_r <= 'd0;
        pmsm_location_set_value_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == MWV_ADDR))
        begin
        pmsm_work_mode_r <= rx_db1[7:4]; //默认工作在速度模式下
        pmsm_speed_set_value_r <= {rx_db2, rx_db3};
        pmsm_location_set_value_r <= {rx_db4, rx_db5, rx_db1[1:0], rx_db6, rx_db7};
        end else
        begin
        pmsm_work_mode_r <= pmsm_work_mode_r; //默认工作在速度模式下
        pmsm_speed_set_value_r <= pmsm_speed_set_value_r;
        pmsm_location_set_value_r <= pmsm_location_set_value_r;
        end
    end
//===========================================================================
//接收状态寄存器赋值
//===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            rx_state_r <= 'd0;
        else if (rx_valid_in && rx_ready_r)
            begin
            case (rx_db0)
                CSUR_ADDR:rx_state_r <= rx_state_r | (32'h1 << 0);
                CDCV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 1);
                CQCV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 2);
                SPV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 3);
                LPV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 4);
                BBV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 5);
                MMV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 6);
                MWV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 7);
                default:rx_state_r <= rx_state_r;
            endcase
            end else if ((fsm_cs == FSM_IDLE) && (rx_state_r != 'd0))  //应答帧发送,清除相应标志位
            begin
            if (rx_state_r[0]) //  电流与转速指令响应
                rx_state_r <= rx_state_r & (~32'h1);
            else if (rx_state_r[1])
                rx_state_r <= rx_state_r & (~32'h2); //电流d环控制参数指令注入
            else if (rx_state_r[2])
                rx_state_r <= rx_state_r & (~32'h4); //电流q环控制参数指令注入
            else if (rx_state_r[3])
                rx_state_r <= rx_state_r & (~32'h8); //速度环控制参数指令注入响应
            else if (rx_state_r[4])
                rx_state_r <= rx_state_r & (~32'd16); //位置环控制参数指令注入响应
            else if (rx_state_r[5])
                rx_state_r <= rx_state_r & (~32'd32); //抱闸控制指令参数指令响应
            else if (rx_state_r[6])
                rx_state_r <= rx_state_r & (~32'd64); //电机启停指令注入
            else if (rx_state_r[7])
                rx_state_r <= rx_state_r & (~32'd128); //电机工作模式指令注入响应
            else
                rx_state_r <= rx_state_r;
            end else
            rx_state_r <= rx_state_r;
        end
//===========================================================================
//发送状态寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        tx_state_r <= 32'd0;
    else if(fsm_cs==FSM_IDLE)
        begin
             if (gate_driver_error_in) //栅极驱动器错误发生
        tx_state_r <= tx_state_r | (32'h1 << 0);
    //else if (current_loop_control_enable_in) //使能电流闭环控制计算后上传电流检测信息，电气旋转角正余弦值
    //    tx_state_r <= tx_state_r | (32'h6);
    else if (channela_detect_err_in || channelb_detect_err_in||current_loop_control_done_in)
        tx_state_r <= tx_state_r | (32'h1 << 1);
    //else if (current_loop_control_done_in) //电流闭环计算完成后计算上传数据
    //    tx_state_r <= tx_state_r | (32'h1 << 3);
    //else if (svpwm_cal_done_in)
    //    tx_state_r <= tx_state_r | (32'h1 << 4);
    else if (speed_loop_cal_done_in)
        tx_state_r <= tx_state_r | (32'h1 << 5);
    else if (pmsm_location_cal_done_in)
        tx_state_r <= tx_state_r | (32'h1 << 6);
    else if (ds_18b20_update_done_in)
        tx_state_r <= tx_state_r | (32'h1 << 7);
    else
        tx_state_r<=tx_state_r;
        end
    else
        begin
        case (fsm_cs)  
            FSM_GR:tx_state_r <= (tx_state_r & (~32'h1))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_CS:tx_state_r <= (tx_state_r & (~32'h2))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_EPT:tx_state_r <=( tx_state_r & (~32'h4))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_CLC:tx_state_r <= (tx_state_r & (~32'h8))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_STSV:tx_state_r <= (tx_state_r & (~32'd16))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_SLC:tx_state_r <= (tx_state_r & (~32'd32))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_LLC:tx_state_r <= (tx_state_r & (~32'd64))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_DTV:tx_state_r <=( tx_state_r & (~32'd128))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            default :tx_state_r <= tx_state_r;
        endcase
        end
    end
//===========================================================================
//数据发送赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {tx_dw1r_r, tx_dw2r_r} <= 'd0;
    else if ((fsm_cs == FSM_IDLE) && (rx_state_r != 'd0))
        begin
        if (rx_state_r[0])    //额定电流与转速指令响应
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h01,  8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[1])   //电流d轴指令注入响应
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h02,8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[2])    //电流q轴指令注入响应
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h03, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[3])    //转速环控制参数指令注入响应
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h04, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[4])    //位置环控制参数指令注入响应
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h05, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[5])    //抱闸动作指令注入响应
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h06, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[6])    //电机启停指令注入响应
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h07,8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[7])    //电机工作模式指令注入响应
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h08,8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else
        {tx_dw1r_r, tx_dw2r_r} <= {tx_dw1r_r, tx_dw2r_r};
        end else
        case (fsm_cs)
            FSM_GR:{tx_dw1r_r, tx_dw2r_r} <= {8'h81, gate_driver_register_1_in, gate_driver_register_2_in, 8'h00, 8'h00, 8'h00};
                FSM_CS: {tx_dw1r_r, tx_dw2r_r} <= {8'h82, phase_a_current_in, phase_b_current_in, current_detect_status_in, 8'h00};
    FSM_EPT: {tx_dw1r_r, tx_dw2r_r} <= {8'h83, electrical_rotation_phase_sin_in, electrical_rotation_phase_cos_in, 8'h00, 8'h00, 8'h00};
    FSM_CLC: {tx_dw1r_r, tx_dw2r_r} <= {8'h84, U_alpha_in, U_beta_in, 8'h00, 8'h00, 8'h00};
    FSM_STSV: {tx_dw1r_r, tx_dw2r_r} <= {8'h85, Tcma_in, Tcmb_in, Tcmc_in, 8'h00};
    FSM_SLC: {tx_dw1r_r, tx_dw2r_r} <= {8'h86, speed_detect_val_in, current_q_set_val_in, 8'h00, 8'h00, 8'h00};
    FSM_LLC: {tx_dw1r_r, tx_dw2r_r} <= {8'h87, pmsm_location_detect_value_in[33:18], 6'h00, pmsm_location_detect_value_in[17:0], speed_set_value_in};
    FSM_DTV: {tx_dw1r_r, tx_dw2r_r} <= {8'h88, ds_18b20_temp_in, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
    default :{tx_dw1r_r, tx_dw2r_r} <= {tx_dw1r_r, tx_dw2r_r};
    endcase
end
    //===========================================================================
    //发送有效标志
    //===========================================================================
    always @(posedge sys_clk or  negedge reset_n) 
    begin
    if (!reset_n)
        tx_valid_r <= 'd0;
    else if (fsm_cs != FSM_IDLE)
        tx_valid_r <= 'd1;
    else
        tx_valid_r <= 'd0;
   end
//===========================================================================
//接收准备好标志
//===========================================================================
always @(posedge sys_clk or  negedge reset_n) 
    begin
        if (!reset_n)
            rx_ready_r<='d0;
        else if (rx_valid_in)   
             rx_ready_r<='d0;
        else
            rx_ready_r<='d1;
    end
//===========================================================================
//输出端口赋值
//===========================================================================
assign tx_dw1r_out=tx_dw1r_r;
assign tx_dw2r_out=tx_dw2r_r;
assign tx_valid_out=tx_valid_r;
assign rx_ready_out=rx_ready_r;
assign current_rated_value_out=current_rated_value_r;
assign speed_rated_value_out=speed_rated_value_r;
assign current_d_param_p_out=current_d_param_p_r;
assign current_d_param_i_out=current_d_param_i_r;
assign current_d_param_d_out=current_d_param_d_r;
assign current_q_param_p_out=current_q_param_p_r;   
assign current_q_param_i_out= current_q_param_i_r ;  
assign current_q_param_d_out=current_q_param_d_r;
assign speed_control_param_p_out=speed_control_param_p_r; 
assign speed_control_param_i_out =speed_control_param_i_r; 
assign speed_control_param_d_out=speed_control_param_d_r;
assign location_control_param_p_out=location_control_param_p_r;
assign location_control_param_i_out= location_control_param_i_r;
assign location_control_param_d_out=location_control_param_d_r;
assign  band_breaks_mode_out=band_breaks_mode_r;
assign pmsm_start_stop_mode_out=pmsm_start_stop_mode_r;
assign pmsm_work_mode_out=pmsm_work_mode_r;
assign pmsm_speed_set_value_out=pmsm_speed_set_value_r;
assign pmsm_location_set_value_out=pmsm_location_set_value_r;
    endmodule
