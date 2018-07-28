//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/23
// Design Name:PMSM_DESIGN
// Module Name: absolution_location_encoder.v
// Target Device:
// Tool versions:
// Description:  绝对编码器数据解析
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module absolution_location_encoder(
                                   input    sys_clk,
                                   input    reset_n,

                                   input    location_detection_enable_in,  //  位置检测使能输入

                                   input        vlx_data_in,                         //  ssi接口数据输入
                                   output      vlx_clk_out,                        //  ssi接口时钟输出

                                   output  [`ABSOLUTION_TOTAL_BIT-1:0]   location_detection_value_out
                                   );
//===========================================================================
//内部常量声明
//===========================================================================
localparam SSI_PERIOD_CNT=`ABSOLUTION_PERIOD/`SYS_CLK_PERIOD;
localparam FSM_IDLE=1<<0;
localparam FSM_DETECTION=1<<1;
localparam FSM_DETECT_UPDATE=1<<2;
//===========================================================================
//内部变量声明
//===========================================================================
reg[$clog2(SSI_PERIOD_CNT)-1:0]  ssi_period_cnt_r;  //周期计数寄存器
reg[`ABSOLUTION_TOTAL_BIT-1:0]   location_detection_cache_r;   //位置检测缓存
reg[`ABSOLUTION_TOTAL_BIT-1:0]   location_detection_r;   //位置检测值
reg[2:0]   fsm_cs,
    fsm_ns;
reg[$clog2(`ABSOLUTION_TOTAL_BIT)-1:0] ssi_bit_cnt;  //位计数器
reg   vlx_clk_r;
reg[1:0] vlx_data_cache_r;

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
                if (location_detection_enable_in)
                    fsm_ns = FSM_DETECTION;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DETECTION: begin
                if ((ssi_bit_cnt == `ABSOLUTION_TOTAL_BIT) && (ssi_period_cnt_r == SSI_PERIOD_CNT - 1'b1))
                    fsm_ns = FSM_DETECT_UPDATE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DETECT_UPDATE: begin
                fsm_ns = FSM_IDLE;
            end
        default :fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//ssi时钟周期计数
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        ssi_period_cnt_r <= 'd0;
    else if (fsm_cs == FSM_DETECTION)
        begin
        if (ssi_period_cnt_r == SSI_PERIOD_CNT - 1'b1)
            ssi_period_cnt_r <= 'd0;
        else
            ssi_period_cnt_r <= ssi_period_cnt_r + 1'b1;
        end else
        ssi_period_cnt_r <= 'd0;
    end
//===========================================================================
//ssi比特计数器
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        ssi_bit_cnt <= 'd0;
    else if (fsm_cs == FSM_DETECTION)
        begin
        if (ssi_period_cnt_r == SSI_PERIOD_CNT - 1'b1)
            ssi_bit_cnt <= ssi_bit_cnt + 1'b1;
        else
            ssi_bit_cnt <= ssi_bit_cnt;
        end else
        ssi_bit_cnt <= 'd0;
    end
//===========================================================================
//ssi时钟生成
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        vlx_clk_r <= 'd1;
    else if (fsm_cs == FSM_DETECTION)
        begin
        if (ssi_period_cnt_r < SSI_PERIOD_CNT / 'd2)
            vlx_clk_r <= 'd0;
        else
            vlx_clk_r <= 'd1;
        end else
        vlx_clk_r <= 'd1;
    end
//===========================================================================
//ssi数据读取
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        vlx_data_cache_r <= 'd0;
    else
        vlx_data_cache_r <= {vlx_data_cache_r[0], vlx_data_in};
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        location_detection_cache_r <= 'd0;
    else if (fsm_cs == FSM_DETECTION)
        begin
        if ((ssi_period_cnt_r == SSI_PERIOD_CNT - 1'b1) && (ssi_bit_cnt < `ABSOLUTION_TOTAL_BIT))
            location_detection_cache_r <= {location_detection_cache_r[`ABSOLUTION_TOTAL_BIT - 1:0], vlx_data_cache_r[1]};
        else
            location_detection_cache_r <= location_detection_cache_r;
        end else
        location_detection_cache_r <= location_detection_cache_r;
    end
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        location_detection_r <= 'd0;
    else if (fsm_cs == FSM_DETECT_UPDATE)
        location_detection_r <= location_detection_cache_r;
    else
        location_detection_r <= location_detection_r;
    end
//===========================================================================
//输出端口赋值
//===========================================================================
assign location_detection_value_out = location_detection_r;
assign vlx_clk_out=vlx_clk_r;
endmodule
