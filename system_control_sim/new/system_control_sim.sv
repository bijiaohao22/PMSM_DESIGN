//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/24
// Design Name:PMSM_DESIGN
// Module Name: system_control_sim.sv
// Target Device:
// Tool versions:
// Description：系统调度功能仿真
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module system_control_sim();
//===========================================================================
//内部变量声明
//===========================================================================
logic sys_clk ,reset_n;
logic location_loop_control_enable;
logic location_detection_enable;
logic current_enable;
logic channela_detect_done;
logic channelb_detect_done;
logic channela_detect_err;
logic channelb_detect_err;
logic [`DATA_WIDTH-1:0] current_detect_status;
logic current_loop_control_enable;
logic gate_driver_init_enable;
logic gate_driver_init_done;
logic gate_driver_error;
logic electrical_rotation_phase_forecast_enable;
logic can_init_enable;
logic can_init_done;
logic [(`DATA_WIDTH/2)-1:0] band_breaks_mode;
logic [(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode;
logic [(`DATA_WIDTH/4)-1:0] pmsm_work_mode_in;
logic emergency_stop;
logic speed_control_enable;
logic system_initilization_done;
//===========================================================================
//DUT
//===========================================================================
system_control_unit dut(
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
                    .pmsm_work_mode_in(pmsm_work_mode_in),     //电机工作模式指令输入

                    //栅极驱动器
                    .emergency_stop_out(emergency_stop),                            //   紧急停机指令，用于电流或栅极驱动器发生异常时停止运行，高点平有效

                    //速度闭环控制
                    .speed_control_enable_out(speed_control_enable),    //速度控制使能信号
                                                                        //系统初始化完成标志
                    .system_initilization_done_out(system_initilization_done)              //  系统初始化完成输入,高电平有效
                    );
//===========================================================================
//复位与时钟
//===========================================================================
initial
    begin
        reset_n=0;
        sys_clk=0;
        channela_detect_done=0;
        channelb_detect_done=0;
        channela_detect_err=0;
        channelb_detect_err=0;
        gate_driver_init_done=0;
        gate_driver_error=0;
        can_init_done=0;
        band_breaks_mode=0;
        pmsm_start_stop_mode=0;
        pmsm_work_mode_in=0;
        #100;
        reset_n=1;
    end
initial
    begin
    forever
        #1 sys_clk = ~sys_clk;
    end
//===========================================================================
//初始化应答
//===========================================================================
initial
    begin
        wait(gate_driver_init_enable)
        #1000;
    @(posedge sys_clk)
        gate_driver_init_done<='d1;
    end
initial
    begin
    wait(can_init_enable)
    #100;
    @(posedge sys_clk)
        can_init_done<='d1;
    @(posedge sys_clk)
        can_init_done<='d0;
    end
//===========================================================================
//数据注入
//===========================================================================
initial
    begin
        wait(system_initilization_done)
            @(posedge sys_clk )
             band_breaks_mode<=`BAND_BREAK_CLOSE;
            #200;
        @(posedge sys_clk )
            pmsm_work_mode_in<=`MOTOR_LOCATION_MODE;
            pmsm_start_stop_mode<=`MOTOR_START_CMD;
        #10_000_000;
        //错误指令注入
        @(posedge sys_clk )
        channela_detect_err<='d1;
        current_detect_status<=16'h23da;
        @(posedge sys_clk )
        channela_detect_err<='d0;
        #100;
        @(posedge sys_clk)
        current_detect_status<='d0;

        @(posedge sys_clk )
        channelb_detect_err<='d1;
        current_detect_status<=16'hfad3;
        @(posedge sys_clk )
        channelb_detect_err<='d0;
        #100;
        @(posedge sys_clk)
        current_detect_status<='d0;

        #100;
        @(posedge sys_clk)
        gate_driver_error<='d1;
        #100;
        @(posedge sys_clk)
        gate_driver_error<='d0;
        //工作模式改变
        #100;
        pmsm_start_stop_mode<=`MOTOR_STOP_CMD;
        @(posedge sys_clk)
        pmsm_work_mode_in<=`MOTOR_SPEED_MODE;
        pmsm_start_stop_mode<=`MOTOR_START_CMD;
        #10_000_000;
        $stop();
    end
endmodule
