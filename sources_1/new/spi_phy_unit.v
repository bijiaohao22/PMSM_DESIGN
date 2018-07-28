//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/7
// Design Name:PMSM_DESIGN
// Module Name: spi_phy_unit.v
// Target Device:
// Tool versions:
// Description:DRV8320S物理层SPI协议驱动
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module spi_phy_unit(
                    input    sys_clk,
                    input    reset_n,

                    input    [`SPI_FRAME_WIDTH-1:0]    wr_data_in,  //  数据写端口
                    input    wr_data_valid_in,                      //  数据写端口有效标志

                    output    [`SPI_FRAME_WIDTH-1:0]    rd_data_out,  //   数据读端口
                    input    rd_data_enable_in,     //  数据读端口使能标志
                    input    [`DATA_WIDTH-1:0]    rd_addr_in,   //  读地址输入

                    output  spi_proc_done_out,   //    spi操作完成标志
                    output  spi_proc_busy_out,   //    spi忙标志

                    output  spi_nscs_out,        //spi使能标志输出
                    output  spi_sclk_out,           //spi时钟端口输出
                    output  spi_sdo_out,           //   spi数据输出端口
                    input    spi_sdi_in               //   spi数据输入端口
                    );
//===========================================================================
//  内部常亮声明
//===========================================================================
localparam   SPI_PHY_500NS_NUM = `SPI_CLK_PERIOD / `SYS_CLK_PERIOD;  // 500ns计数值
localparam   SPI_CLK_HIGH_BEGIN_TIME=SPI_PHY_500NS_NUM*1/4;              //   clk高电平起始时间
localparam   SPI_CLK_HIGH_END_TIME=SPI_PHY_500NS_NUM*3/4;                  //  clk高电平结束时间

localparam   FSM_IDLE=1<<0;
localparam   FSM_DATA_WRITE=1<<1;
localparam   FSM_DATA_READ=1<<2;
localparam   FSM_SPI_DELAY=1<<3;  //  时间延时，nscs两次spi事物之间至少应有400ns延时
localparam   FSM_SPI_PROC_DONE=1<<4;
//===========================================================================
//  内部变量声明
//===========================================================================
reg[4:0]    fsm_cs,
    fsm_ns;     //  有限状态机当前状态及其下一状态
reg[$clog2(`SPI_FRAME_WIDTH)-1:0]  spi_clk_frame_cnt_r;   //  spi帧时钟计数器
reg[$clog2(SPI_PHY_500NS_NUM)-1:0] spi_500ns_cnt;         //  500ns计数器

reg[`SPI_FRAME_WIDTH-1:0]    wr_data_r;    //  待写入数据寄存器
reg[`SPI_FRAME_WIDTH-1:0]    rd_data_r;     //  spi读数据寄存器
reg[`SPI_FRAME_WIDTH-1:0]    rd_data_buffer_r;    //  spi读缓存器
reg   spi_proc_done_r; //  spi处理完成寄存器
reg   spi_proc_busy_r; //  spi忙标志

reg   spi_sclk_r;    //  spi时钟寄存器
reg   spi_sdo_r;    //  spi输出寄存器
reg   spi_nscs_r;   //  spi片选时钟寄存器
reg[1:0]    spi_sdi_buffer;  //  spi数据输入缓存寄存器

//===========================================================================
//  有限状态机状态转移
//===========================================================================
always @(posedge   sys_clk or negedge reset_n)
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
                if (wr_data_valid_in)    //数据写使能
                    fsm_ns = FSM_DATA_WRITE;
                else if (rd_data_enable_in)   //   数据读使能
                    fsm_ns = FSM_DATA_READ;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_WRITE: begin
                if ((spi_clk_frame_cnt_r == `SPI_FRAME_WIDTH - 1) && (spi_500ns_cnt == SPI_PHY_500NS_NUM - 1))
                    fsm_ns = FSM_SPI_DELAY;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_READ: begin
                if ((spi_clk_frame_cnt_r == `SPI_FRAME_WIDTH - 1) && (spi_500ns_cnt == SPI_PHY_500NS_NUM - 1))
                    fsm_ns = FSM_SPI_DELAY;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_SPI_DELAY: begin
                if (spi_500ns_cnt == SPI_PHY_500NS_NUM - 1)  //延迟500ns
                    fsm_ns = FSM_SPI_PROC_DONE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_SPI_PROC_DONE: begin
                fsm_ns = FSM_IDLE;
            end
        default: fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//片选信号生成
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_nscs_r <= 'd1;  //  初始态为高电平
    else if (fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_DATA_READ)
        spi_nscs_r <= 'd0;
    else
        spi_nscs_r <= 'd1;
    end
//===========================================================================
//spi时钟信号生成
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_sclk_r <= 'd0;  //  初始状态为低电平
    else if (fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_DATA_READ)
        begin
        if (spi_500ns_cnt == SPI_CLK_HIGH_BEGIN_TIME - 1)
            spi_sclk_r <= 'd1;
        else if (spi_500ns_cnt == SPI_CLK_HIGH_END_TIME - 1)
            spi_sclk_r <= 'd0;
        else
            spi_sclk_r <= spi_sclk_r;
        end else
        spi_sclk_r <= 'd0;
    end
//===========================================================================
//500ns计数器赋值
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_500ns_cnt <= 'd0;
    else if (fsm_cs == FSM_DATA_READ || fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_SPI_DELAY)
        begin
        if (spi_500ns_cnt == SPI_PHY_500NS_NUM - 1)
            spi_500ns_cnt <= 'd0;
        else
            spi_500ns_cnt <= spi_500ns_cnt + 1'b1;
        end            else
        spi_500ns_cnt <= 'd0;
    end
//===========================================================================
//帧计数器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_clk_frame_cnt_r <= 'd0;
    else if (fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_DATA_READ)
        begin
        if (spi_500ns_cnt == SPI_PHY_500NS_NUM - 1)
            spi_clk_frame_cnt_r <= spi_clk_frame_cnt_r + 1'b1;
        else
            spi_clk_frame_cnt_r <= spi_clk_frame_cnt_r;
        end else
        spi_clk_frame_cnt_r <= 'd0;
    end

//===========================================================================
//待写入数据寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_data_r <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        begin
        if (wr_data_valid_in)    //写使能
            wr_data_r <= wr_data_in;
        else if (rd_data_enable_in)   // 读使能
            wr_data_r <= {1'b1, rd_addr_in[3:0], 11'd0};
        else
            wr_data_r <= 'd0;
        end else if ((fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_DATA_READ) && (spi_500ns_cnt == SPI_CLK_HIGH_BEGIN_TIME - 1)) //在发送或接收上升沿处进行左移一位操作
        wr_data_r <= (wr_data_r << 1'b1);
    else
        wr_data_r <= wr_data_r;
    end
//===========================================================================
//输出寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_sdo_r <= 'd1;
    else if (fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_DATA_READ)
        begin
        if (spi_500ns_cnt == SPI_CLK_HIGH_BEGIN_TIME - 1)
            spi_sdo_r <= wr_data_r[`SPI_FRAME_WIDTH - 1];
        else
            spi_sdo_r <= spi_sdo_r;
        end else
        spi_sdo_r <= 'd1;
    end
//===========================================================================
//spi 输入缓存
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_sdi_buffer <= 'd0;
    else
        spi_sdi_buffer <= {spi_sdi_buffer[0], spi_sdi_in};
    end
//===========================================================================
//spi输入数据读取
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_data_buffer_r <= 'd0;
    else if ((fsm_cs == FSM_DATA_READ) && (spi_500ns_cnt == SPI_CLK_HIGH_END_TIME + 1))
        rd_data_buffer_r <= {rd_data_buffer_r[(`SPI_FRAME_WIDTH - 2) : 0], spi_sdi_buffer[1]};
    else
        rd_data_buffer_r <= rd_data_buffer_r;
    end
//===========================================================================
//spi读寄存器输出缓存
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_data_r <= 'd0;
    else if (fsm_cs == FSM_SPI_PROC_DONE)
        rd_data_r <= rd_data_buffer_r;
    else
        rd_data_r <= rd_data_r;
    end
//===========================================================================
//处理完成标志处理
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_proc_done_r <= 1'b0;
    else if (fsm_cs == FSM_SPI_PROC_DONE)
        spi_proc_done_r <= 'b1;
    else
        spi_proc_done_r <= 'b0;
    end
//===========================================================================
//spi忙标志赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_proc_busy_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && (rd_data_enable_in || wr_data_valid_in))
        spi_proc_busy_r <= 'b1;
    else if (fsm_cs == FSM_SPI_PROC_DONE)
        spi_proc_busy_r <= 1'b0;
    else
        spi_proc_busy_r <= spi_proc_busy_r;
    end
//===========================================================================
//输出端口赋值
//===========================================================================
assign rd_data_out=rd_data_r;
assign spi_proc_done_out=spi_proc_done_r;
assign spi_proc_busy_out=spi_proc_busy_r;
assign spi_nscs_out=spi_nscs_r;
assign spi_sclk_out=spi_sclk_r;
assign spi_sdo_out=spi_sdo_r;
endmodule
