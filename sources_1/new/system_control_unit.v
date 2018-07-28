//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/24
// Design Name:PMSM_DESIGN
// Module Name: system_control_unit.v
// Target Device:
// Tool versions:
// Description:系统全局调度，实时监控系统运行
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module system_control_unit(
                           input    sys_clk,
                           input    reset_n,

                           //位置模式控制
                           output    location_loop_control_enable_out,    //  位置控制使能输出
                           output    location_detection_enable_out,          //  位置检测使能输出

                           //电流检测
                           output    current_enable_out , //detect_enable signale
                           input channela_detect_done_in,    //channel a detect done signal in
                           input channelb_detect_done_in,    //channel b detect done signal in
                           input  channela_detect_err_in,       //current detect error triger
                           input  channelb_detect_err_in,     //current detect error triger
                           input [`DATA_WIDTH-1:0] current_detect_status_out,

                           //电流闭环控制
                           output    current_loop_control_enable_out,      //控制使能输入，high-active

                           //栅极驱动器控制
                           output    gate_driver_init_enable_out,  //  栅极驱动器上电或复位后初始化使能
                           input  gate_driver_init_done_in,  //  栅极驱动器初始化完成标志
                           input  gate_driver_error_in,   //栅极寄存器故障报警输入，高电平有效

                           //转速与电角度计算
                           output     electrical_rotation_phase_forecast_enable_out,

                           //can总线
                           output    can_init_enable_out,    //   can初始化使能标志
                           input  can_init_done_in,    //    can初始化完成标志
                           input [(`DATA_WIDTH/2)-1:0] band_breaks_mode_in,  //抱闸工作模式输入
                           input [(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode_in,   //电机启停指令输入
                           input [(`DATA_WIDTH/4)-1:0] pmsm_work_mode_in,     //电机工作模式指令输入

                           //栅极驱动器
                           output    emergency_stop_out,                            //   紧急停机指令，用于电流或栅极驱动器发生异常时停止运行，高点平有效

                           //速度闭环控制
                           output    speed_control_enable_out,    //速度控制使能信号
                           //系统初始化完成标志
                           output    system_initilization_done_out              //  系统初始化完成输入,高电平有效
                           );
//===========================================================================
//内部常量声明
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_INIT=1<<1; //  系统初始化
localparam FSM_MOTOR_AWAIT=1<<2;    //  电机待机
localparam FSM_MOTOR_NORMAL=1<<3;    //  电机运行
localparam FSM_MOTOR_EXCPE=1<<4;        //   异常处理

localparam TIME_1_MS_NUM = 1_000_000 / `SYS_CLK_PERIOD;
//===========================================================================
//内部变量声明
//===========================================================================
reg[4:0]    fsm_cs,
    fsm_ns;
reg[$clog2(100)-1:0]   time_100ms_cnt_r;   //100ms计数器
reg[$clog2(TIME_1_MS_NUM)-1:0]  time_1ms_cnt_r;  //1ms计数器
reg[$clog2(10)-1:0] time_10ms_cnt_r; //  10ms计数器
reg can_transaction_init_done_r;  //  can总线初始化完成标志

reg  location_loop_control_enable_r;    //  位置控制使能输出
reg  location_detection_enable_r;          //  位置检测使能输出
reg  current_enable_r;                       //current detect_enable signale
reg  current_loop_control_enable_r; //  电流闭环控制使能输出
reg  gate_driver_init_enable_r;         //   栅极驱动器上电或复位后初始化使能
reg  electrical_rotation_phase_forecast_enable_r;  //转速与电角度预测使能
reg  can_init_enable_r;                     //   can总线初始化使能
reg   emergency_stop_r;                   //   紧急停机指令，用于电流或栅极驱动器发生异常时停止运行，高点平有效
reg   speed_control_enable_r;           //  速度控制使能
reg   system_initilization_done_r;     //  系统初始化完成标志寄存器

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
always@(*)
    begin
    case (fsm_cs)
        FSM_IDLE: begin    //  延迟100ms进入初始化状态
                if ((time_1ms_cnt_r == TIME_1_MS_NUM - 1'b1) && (time_100ms_cnt_r == 'd99))
                    fsm_ns = FSM_INIT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_INIT: begin
                if (can_transaction_init_done_r && gate_driver_init_done_in)    //栅极驱动器和can总线初始化完成后进入电机待机状态
                    fsm_ns = FSM_MOTOR_AWAIT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_MOTOR_AWAIT: begin    //收到电机启动命令并且抱闸关闭，工作模式选择正常后进入电机运行状态
                if ((band_breaks_mode_in == `BAND_BREAK_CLOSE) && (pmsm_start_stop_mode_in == `MOTOR_START_CMD) && (pmsm_work_mode_in == `MOTOR_SPEED_MODE || pmsm_work_mode_in == `MOTOR_LOCATION_MODE))
                    fsm_ns = FSM_MOTOR_NORMAL;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_MOTOR_NORMAL:    begin
                if (pmsm_start_stop_mode_in == `MOTOR_STOP_CMD)    //收到电机关机指令后进入电机待机状态
                    fsm_ns = FSM_MOTOR_AWAIT;
                else if (channela_detect_err_in || channelb_detect_err_in || gate_driver_error_in) //检测到电流超值或栅极驱动器错误后进入异常处理状态
                    fsm_ns = FSM_MOTOR_EXCPE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_MOTOR_EXCPE: begin
                if (pmsm_start_stop_mode_in == `MOTOR_STOP_CMD)    //收到电机关机指令后进入电机待机状态
                    fsm_ns = FSM_MOTOR_AWAIT;
                else if ((current_detect_status_out == 'd0) && (~gate_driver_error_in)) //所有异常情况均消失后进入电机正常运行模式
                    fsm_ns = FSM_MOTOR_NORMAL;
                else
                    fsm_ns = fsm_cs;
            end
        default:fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//1ms计数器赋值
//电流环控制周期，电流采样控制
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_1ms_cnt_r <= 'd0;
    else if (fsm_cs != fsm_ns)
        time_1ms_cnt_r <= 'd0;
    else if (fsm_cs == FSM_IDLE || fsm_cs == FSM_MOTOR_EXCPE || fsm_cs == FSM_MOTOR_NORMAL)
        begin
        if (time_1ms_cnt_r == TIME_1_MS_NUM - 1)
            time_1ms_cnt_r <= 'd0;
        else
            time_1ms_cnt_r <= time_1ms_cnt_r + 1'b1;
        end else
        time_1ms_cnt_r <= 'd0;
    end
//===========================================================================
//10ms计数器
//速度环,位置环控制周期
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_10ms_cnt_r <= 'd0;
    else if (fsm_cs == FSM_MOTOR_NORMAL)
        begin
        if ((time_10ms_cnt_r == 'd9) && (time_1ms_cnt_r == TIME_1_MS_NUM - 1))
            time_10ms_cnt_r <= 'd0;
        else if (time_1ms_cnt_r == TIME_1_MS_NUM - 1)
            time_10ms_cnt_r <= time_10ms_cnt_r + 1'b1;
        else
            time_10ms_cnt_r <= time_10ms_cnt_r;
        end else
        time_10ms_cnt_r <= 'd0;
    end
//===========================================================================
//100ms计数器
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_100ms_cnt_r <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        begin
        if (time_1ms_cnt_r == TIME_1_MS_NUM - 1'b1)
            time_100ms_cnt_r <= time_100ms_cnt_r + 1'b1;
        else
            time_100ms_cnt_r <= time_100ms_cnt_r;
        end else
        time_100ms_cnt_r <= 'd0;
    end
//===========================================================================
//can总线初始化完成标志寄存
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        can_transaction_init_done_r <= 'd0;
    else if ((fsm_cs == FSM_INIT) && can_init_done_in)
        can_transaction_init_done_r <= 'd1;
    else
        can_transaction_init_done_r <= can_transaction_init_done_r;
    end
//===========================================================================
//位置控制使能输出
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        location_loop_control_enable_r <= 'd0;
    else if ((pmsm_work_mode_in == `MOTOR_LOCATION_MODE) && ((time_10ms_cnt_r == 'd3) && (time_1ms_cnt_r == TIME_1_MS_NUM - 1)))   //4ms处
        location_loop_control_enable_r <= 1'b1;
    else
        location_loop_control_enable_r <= 'b0;
    end
//===========================================================================
//位置检测使能
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        location_detection_enable_r <= 'd0;
    else if ((pmsm_work_mode_in == `MOTOR_LOCATION_MODE) && ((time_10ms_cnt_r == 'd3) && (time_1ms_cnt_r == (TIME_1_MS_NUM * 9 / 10) - 1)))   //3.9ms
        location_detection_enable_r <= 'd1;
    else
        location_detection_enable_r <= 'd0;
    end
//===========================================================================
//电流检测使能
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_enable_r <= 'd0;
    else if ((fsm_cs == FSM_MOTOR_EXCPE || fsm_cs == FSM_MOTOR_NORMAL) && (time_1ms_cnt_r == (TIME_1_MS_NUM * 9 / 10) - 1)) //0.9ms
        current_enable_r <= 'd1;
    else
        current_enable_r <= 'd0;
    end
//===========================================================================
//电流闭环控制使能输出
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_loop_control_enable_r <= 'd0;
    else if ((fsm_cs == FSM_MOTOR_NORMAL) && (time_1ms_cnt_r == TIME_1_MS_NUM  - 1))
        current_loop_control_enable_r <= 'd1;
    else
        current_loop_control_enable_r <= 'd0;
    end
//===========================================================================
//栅极驱动器初始化使能
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_init_enable_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && (fsm_cs != fsm_ns))
        gate_driver_init_enable_r <= 'd1;
    else
        gate_driver_init_enable_r <= 'd0;
    end
//===========================================================================
//电角度预测使能
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        electrical_rotation_phase_forecast_enable_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && (fsm_cs != fsm_ns))
        electrical_rotation_phase_forecast_enable_r <= 'd1;
    else
        electrical_rotation_phase_forecast_enable_r <= 'd0;
    end
//===========================================================================
//can总线初始化使能
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        can_init_enable_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && (fsm_cs != fsm_ns))
        can_init_enable_r <= 'd1;
    else
        can_init_enable_r <= 'd0;
    end
//===========================================================================
// 紧急停机指令，用于电流或栅极驱动器发生异常时停止运行，高点平有效
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        emergency_stop_r <= 'd0;
    else if (fsm_cs == FSM_MOTOR_EXCPE)
        emergency_stop_r <= 'd1;
    else
        emergency_stop_r <= 'd0;
    end
//===========================================================================
//速度控制使能
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_control_enable_r <= 'd0;
    else if ((fsm_cs == FSM_MOTOR_NORMAL) && ((time_10ms_cnt_r == 'd4) && (time_1ms_cnt_r == TIME_1_MS_NUM - 1)))
        speed_control_enable_r <= 'd1;
    else
        speed_control_enable_r <= 'd0;
    end
//===========================================================================
//系统初始化完成标志
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        system_initilization_done_r <= 'd0;
    else if ((fsm_cs == FSM_INIT) && (fsm_cs != fsm_ns))
        system_initilization_done_r <= 'd1;
    else
        system_initilization_done_r <= system_initilization_done_r;
    end
//===========================================================================
//输出端口赋值
//===========================================================================
assign location_loop_control_enable_out=location_loop_control_enable_r;
assign location_detection_enable_out=location_detection_enable_r;
assign current_enable_out=current_enable_r;
assign current_loop_control_enable_out=current_loop_control_enable_r;
assign gate_driver_init_enable_out=gate_driver_init_enable_r;
assign electrical_rotation_phase_forecast_enable_out=electrical_rotation_phase_forecast_enable_r;
assign can_init_enable_out=can_init_enable_r;
assign emergency_stop_out=emergency_stop_r;
assign speed_control_enable_out=speed_control_enable_r;
assign system_initilization_done_out=system_initilization_done_r;
endmodule
