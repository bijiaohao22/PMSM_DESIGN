//====================================================================================
// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/5/8
// Design Name:PMSM_DESIGN
// Module Name: gate_driver_init_and_monitor_unit.v
// Target Device:
// Tool versions:
// Description:栅极驱动器初始化及状态监控
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module gate_driver_init_and_monitor_unit(
                                         input    sys_clk,
                                         input    reset_n,

                                         input    gate_driver_init_enable_in,  //  栅极驱动器上电或复位后初始化使能输入
                                         output  gate_driver_init_done_out,  //  栅极驱动器初始化完成标志

                                         input  gate_driver_nfault_in,           //   栅极驱动器错误检测输入，低电平有效
                                         output  gate_driver_enable_out,      //   栅极驱动器使能输出，高电平有效

                                         output[`SPI_FRAME_WIDTH-1:0]  wr_data_out,    //  spi写数据
                                         output  wr_data_enable_out,    //  spi写使能
                                         output[`DATA_WIDTH-1:0]    rd_addr_out, //  spi读寄存器地址
                                         output  rd_data_enable_out, //  spi读使能
                                         input [`SPI_FRAME_WIDTH-1:0]    rd_data_in,   //spi读数据

                                         input    spi_phy_proc_done_in,   //  spi物理层处理完成标志
                                         input    spi_phy_proc_busy_in,   //  spi物理层忙标志

                                         output[`DATA_WIDTH-1:0]    gate_driver_register_1_out,  //  栅极寄存器状态1寄存器输出
                                         output[`DATA_WIDTH-1:0]    gate_driver_register_2_out,  //  栅极寄存器状态2寄存器输出
                                         output  gate_driver_error_out   //栅极寄存器故障报警输出
                                         );
//===========================================================================
//      内部常量声明
//===========================================================================
localparam   FSM_IDLE=1<<0;
localparam   FSM_ENABLE_DELAY=1<<1;
localparam   FSM_GATE_DRIVER_INIT=1<<2;   //  配置栅极驱动器的控制寄存器，兼具复位功能
localparam   FSM_GATE_DRIVER_MONITOR=1<<3;    //  栅极驱动器状态监视
localparam   FSM_GATE_DRIVER_READ_0=1<<4;       //   栅极驱动器状态寄存器0读取
localparam   FSM_GATE_DRIVER_READ_1=1<<5;       //   栅极驱动器状态寄存器1读取
localparam   FSM_GATE_DRIVER_REC_WAIT = 1 << 6;  //   栅极驱动器状态恢复等待状态

localparam   TIME_2MS_NUM = 'd2_000_000 / `SYS_CLK_PERIOD;
//===========================================================================
//内部变量声明
//===========================================================================
reg[6:0]    fsm_cs,
    fsm_ns;     //  state machine and the nest state
reg[$clog2(TIME_2MS_NUM)-1:0]   time_2ms_cnt_r;   //  2ms计数器

reg[1:0]  gate_driver_nfault_buffer_r; //   栅极驱动器错误检测输入缓存

reg  gate_driver_init_done_r;  //  栅极驱动器初始化完成标志
reg  gate_driver_enable_r;    //  栅极驱动器使能寄存器
reg[`SPI_FRAME_WIDTH-1:0]  wr_data_r;    //  spi写数据寄存器
reg  wr_data_enable_r; //spi写使能寄存器
reg[`DATA_WIDTH-1:0]    rd_addr_r;  //  spi读寄存器地址寄存器
reg   rd_data_enable_r; //  spi读使能寄存器
reg[`DATA_WIDTH-1:0]    gate_driver_register_1_r;  //  栅极寄存器状态1寄存器输出
reg[`DATA_WIDTH-1:0]    gate_driver_register_2_r;  //  栅极寄存器状态2寄存器输出
reg   gate_driver_error_r;   //栅极寄存器故障报警输出寄存器

//===========================================================================
//有限状态机状态跳转
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
                if (gate_driver_init_enable_in)  //  收到栅极寄存器使能标志跳转至使能延迟状态
                    fsm_ns = FSM_ENABLE_DELAY;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ENABLE_DELAY: begin   //  栅极寄存器使能后至少等待1ms才能进行SPI读写，故延迟2ms
                if (time_2ms_cnt_r == (TIME_2MS_NUM - 1)) //    2ms延迟结束，跳转至初始化状态
                    fsm_ns = FSM_GATE_DRIVER_INIT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_GATE_DRIVER_INIT: begin
                if (spi_phy_proc_done_in)   //初始化（复位）配置完成后进入状态监控状态
                    fsm_ns = FSM_GATE_DRIVER_MONITOR;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_GATE_DRIVER_MONITOR: begin  //当检测到nFault为低时进入状态寄存器读取状态
                if (!gate_driver_nfault_buffer_r[1])
                    fsm_ns = FSM_GATE_DRIVER_READ_0;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_GATE_DRIVER_READ_0: begin
                if (spi_phy_proc_done_in)  //   收到spi读取完成标志后进入状态寄存器1读取状态
                    fsm_ns = FSM_GATE_DRIVER_READ_1;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_GATE_DRIVER_READ_1: begin
                if (spi_phy_proc_done_in)  //   收到spi读取完成标志后进入错误恢复等待状态
                    fsm_ns = FSM_GATE_DRIVER_REC_WAIT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_GATE_DRIVER_REC_WAIT: begin
                if (gate_driver_nfault_buffer_r[1])   //   检测到nFault变为高电平，则跳转至复位初始化状态清除错误标志位
                    fsm_ns = FSM_GATE_DRIVER_INIT;
                else
                    fsm_ns = fsm_cs;
            end
        default: fsm_ns = FSM_GATE_DRIVER_MONITOR;
    endcase
    end
//===========================================================================
//  2ms计时器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_2ms_cnt_r <= 'd0;
    else if (fsm_cs == FSM_ENABLE_DELAY)
        time_2ms_cnt_r <= time_2ms_cnt_r + 1'b1;
    else
        time_2ms_cnt_r <= 'd0;
    end
//===========================================================================
//  栅极驱动器错误检测输入缓存
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_nfault_buffer_r <= 'b11;
    else
        gate_driver_nfault_buffer_r <= {gate_driver_nfault_buffer_r[0], gate_driver_nfault_in};
    end
//===========================================================================
//栅极驱动器初始化完成标志
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_init_done_r <= 'b0;
    else if ((fsm_cs == FSM_GATE_DRIVER_INIT) && (spi_phy_proc_done_in))  //初始化完成
        gate_driver_init_done_r <= 'b1;
    else
        gate_driver_init_done_r <= gate_driver_init_done_r;
    end
//===========================================================================
//  栅极驱动器使能赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_enable_r <= 'b0;
    else if ((fsm_cs == FSM_IDLE) && gate_driver_init_enable_in)   //收到使能标志使能栅极驱动器
        gate_driver_enable_r <= 'b1;
    else
        gate_driver_enable_r <= gate_driver_enable_r;
    end
//===========================================================================
//spi写数据寄存器
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_data_r <= 'd0;
    else
    wr_data_r <= `DRIVER_CONTROL_REGISTER_VALUE;
    end
//===========================================================================
//spi写数据使能
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_data_enable_r <= 'b0;
    else if (wr_data_enable_r)    //确保wr_data_enable_r仅占一个时钟周期
        wr_data_enable_r <= 'b0;
    else if ((fsm_cs == FSM_GATE_DRIVER_INIT) && (!spi_phy_proc_busy_in) && (~spi_phy_proc_done_in))
        wr_data_enable_r <= 'b1;
    else
        wr_data_enable_r <= 'b0;
    end
//===========================================================================
//读地址寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_addr_r <= 'd0;
    else if (fsm_cs == FSM_GATE_DRIVER_READ_0)
        rd_addr_r <= 'd0;
    else if (fsm_cs == FSM_GATE_DRIVER_READ_1)
        rd_addr_r <= 'd1;
    else
        rd_addr_r <= 'd0;
    end
//===========================================================================
//读使能寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_data_enable_r <= 'b0;
    else if (rd_data_enable_r)  //确保rd_data_enable_r仅占用一个时钟周期
        rd_data_enable_r <= 'd0;
    else if ((fsm_cs == FSM_GATE_DRIVER_READ_0 || fsm_cs == FSM_GATE_DRIVER_READ_1) && (!spi_phy_proc_busy_in) && (!spi_phy_proc_done_in))
        rd_data_enable_r <= 'b1;
    else
        rd_data_enable_r <= 'b0;
    end
//===========================================================================
// 栅极寄存器状态1，2寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_register_1_r <= 'd0;
    else if (fsm_cs == FSM_GATE_DRIVER_READ_0 && spi_phy_proc_done_in)
        gate_driver_register_1_r <= rd_data_in;
    else
        gate_driver_register_1_r <= gate_driver_register_1_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_register_2_r <= 'd0;
    else if (fsm_cs == FSM_GATE_DRIVER_READ_1 && spi_phy_proc_done_in)
        gate_driver_register_2_r <= rd_data_in;
    else
        gate_driver_register_2_r <= gate_driver_register_2_r;
    end
//===========================================================================
//栅极驱动器错误报警输出
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_error_r <= 'd0;
    else if (fsm_cs == FSM_GATE_DRIVER_READ_1 && spi_phy_proc_done_in)   //状态寄存器1，2接收完毕后置位错误报警输出
        gate_driver_error_r = 1'b1;
    else if ((fsm_cs == FSM_GATE_DRIVER_REC_WAIT) && gate_driver_nfault_buffer_r[1])
        gate_driver_error_r = 1'b0;
    else
        gate_driver_error_r <= gate_driver_error_r;
    end
//===========================================================================
//输出端口赋值
//===========================================================================
assign gate_driver_init_done_out=gate_driver_init_done_r;
assign gate_driver_enable_out=gate_driver_enable_r;
assign wr_data_out=wr_data_r;
assign wr_data_enable_out=wr_data_enable_r;
assign rd_addr_out=rd_addr_r;
assign rd_data_enable_out=rd_data_enable_r;
assign gate_driver_register_1_out=gate_driver_register_1_r;
assign gate_driver_register_2_out=gate_driver_register_2_r;
assign gate_driver_error_out=gate_driver_error_r;
endmodule

