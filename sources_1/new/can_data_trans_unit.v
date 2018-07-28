//====================================================================================
// Company:
// Engineer: LiXIaochuang
// Create Date: 2018/5/16
// Design Name:PMSM_DESIGN
// Module Name: can_data_trans_unit.v
// Target Device:
// Tool versions:
// Description:can数据传输层，接收应用层传送数据，上传链路层接收到的数据，读写仲裁
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module can_data_trans_unit(
                           input    sys_clk,
                           input    reset_n,

                           input    [31:0]  tx_dw1r_in,       //   数据发送字1，
                           input    [31:0]  tx_dw2r_in,       //   数据发送字2，
                           input               tx_valid_in,       //   数据发送有效标志位
                           output             tx_ready_out,    //  数据发送准备好标志

                           output  [31:0] rx_dw1r_out,    //  接收数据字1
                           output  [31:0] rx_dw2r_out,    //  接收数据字2
                           output            rx_valid_out,     //  接收数据有效标志
                           input              rx_ready_in,      //  接收准备好标志输入

                           output  [7:0]   wr_addr_out,
                           output  [31:0] wr_data_out,
                           output            wr_enable_out,
                           input              wr_done_in,
                           input              wr_busy_in,

                           output  [7:0]  rd_addr_out,
                           output           rd_enable_out,
                           input [31:0]  rd_data_in,
                           input            rd_done_in,
                           input            rd_busy_in,

                           input            ip2bus_intrevent_in

                           );
//===========================================================================
//内部常量声明
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_ISR_READ=1<<1;
localparam FSM_ISR_ADJUST=1<<2;  //中断类型判别
localparam FSM_DATA_ID_REC=1<<3;
localparam FSM_DATA_DLC_REC=1<<4;
localparam FSM_DATA_DW1_REC=1<<5;
localparam FSM_DATA_DW2_REC=1<<6;
localparam FSM_DATA_REC_UPDATE=1<<7;
localparam FSM_ISR_CLEAR=1<<8;
localparam FSM_TX_ID=1<<9;
localparam FSM_TX_DLC=1<<10;
localparam FSM_TX_DW1=1<<11;
localparam FSM_TX_DW2=1<<12;
localparam FSM_TX_FULL_DETECT=1<<13;

localparam SR_ADDR=8'h18;
localparam ISR_ADDR=8'h1C;
localparam ICR_ADDR=8'h24;
localparam TX_ID_ADDR=8'h30;
localparam TX_DLC_ADDR=8'h34;
localparam TX_DW1_ADDR=8'h38;
localparam TX_DW2_ADDR=8'h3c;
localparam RX_ID_ADDR=8'h50;
localparam RX_DLC_ADDR=8'h54;
localparam RX_DW1_ADDR=8'h58;
localparam RX_DW2_ADDR=8'h5c;

localparam CAN_ID_VALUE=
    {
    `CAN_NODE_ID,1'b0,1'b0,18'b0,1'b0
    };
localparam CAN_DLC_VALUE=
    {
    4'd8,28'd0
    };
//===========================================================================
//内部变量声明
//===========================================================================
reg[13:0]  fsm_cs,
    fsm_ns; //  有限状态机寄存器

reg[31:0]  can_isr_r;          //  中断状态寄存器
reg   tx_fifo_full_flag;       //  发送缓冲区满标志

reg[31:0] tx_dw1r_cache; //待发送数据缓存
reg[31:0] tx_dw2r_cache;

reg   tx_ready_r;              //  准备接收标志
reg[31:0]  rx_dw1r_r;   //接收数据字1寄存器
reg[31:0]  rx_dw2r_r;   //接收数据字2寄存器
reg              rx_valid_r;    //  接收数据有效标志
reg[7:0]   wr_addr_r;     //  发送数据地址
reg[31:0]  wr_data_r;    //  发送数据寄存器
reg               wr_enable_r;    //  发送使能寄存器
reg[7:0]   rd_addr_r;      //  读地址寄存器
reg   rd_enable_r;             //  读使能寄存器

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
                if (ip2bus_intrevent_in)    //当中断指示为高时，表明有接收到数据或写满中断，此时进入中断处理，中断中若有接收到数据则接收数据处理，若是写满中断直接清中断即可（清楚后若仍满会再次触发中断循环处理，直至非满，可进入正常数据发送）
                    fsm_ns = FSM_ISR_READ;
                else if (tx_valid_in)   //  否则收到发送有效标志则进行数据发送处理
                    begin
                        if (tx_fifo_full_flag)
                            fsm_ns = FSM_TX_FULL_DETECT;
                        else
                            fsm_ns = FSM_TX_ID;
                    end            
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ISR_READ: begin   //  读取ISR寄存器获取中断状态
                if (rd_done_in)   //   读取完成则进入中断类型判断状态
                    fsm_ns = FSM_ISR_ADJUST;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ISR_ADJUST: begin
                if (can_isr_r[4]) //  若是接收到数据，则进行数据读取操作
                    fsm_ns = FSM_DATA_ID_REC;
                else   //  否则（收到TX满中断），直接进行中断清除操作即可
                    fsm_ns = FSM_ISR_CLEAR;
            end
        FSM_DATA_ID_REC: begin
                if (rd_done_in)    //   读取完成后进入dlc读取状态
                    fsm_ns = FSM_DATA_DLC_REC;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_DLC_REC: begin
                if (rd_done_in)    //   读取完成后进入dw1读取状态
                    fsm_ns = FSM_DATA_DW1_REC;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_DW1_REC: begin
                if (rd_done_in)    //   读取完成后进入dw2读取状态
                    fsm_ns = FSM_DATA_DW2_REC;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_DW2_REC: begin
                if (rd_done_in)    //   读取完成后进入数据更新状态
                    fsm_ns = FSM_DATA_REC_UPDATE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_REC_UPDATE: begin
                if (rx_ready_in) //   当应用层做好接收准备后即可进入中断清除状态
                    fsm_ns = FSM_ISR_CLEAR;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ISR_CLEAR: begin
                if (wr_done_in)    //写操作完成后即可返回初始状态
                    fsm_ns = FSM_IDLE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_TX_ID: begin
                if (wr_done_in)    //写操作完成后即可进入DLC写操作
                    fsm_ns = FSM_TX_DLC;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_TX_DLC: begin
                if (wr_done_in)    //写操作完成后即可进入DW1写操作
                    fsm_ns = FSM_TX_DW1;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_TX_DW1: begin
                if (wr_done_in)    //写操作完成后即可进入DW2写操作
                    fsm_ns = FSM_TX_DW2;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_TX_DW2: begin
                if (wr_done_in)    //写操作完成后查询发送缓冲区是否写满//即可进入初始状态
                  fsm_ns = FSM_TX_FULL_DETECT ;//FSM_IDLE;
                else
                    fsm_ns = fsm_cs;
        end
        FSM_TX_FULL_DETECT:
        begin
            if(rd_done_in)
                fsm_ns= FSM_IDLE;
            else
                fsm_ns=fsm_cs;
        end
        default :fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//中断状态寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        can_isr_r <= 'd0;
    else if ((fsm_cs == FSM_ISR_READ) && rd_done_in)
        can_isr_r <= rd_data_in;
    else
        can_isr_r <= can_isr_r;
    end
//===========================================================================
//发送状态满标志查询
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        tx_fifo_full_flag <= 'd0;
    else if ((fsm_cs == FSM_TX_FULL_DETECT) && rd_done_in)
        tx_fifo_full_flag <= rd_data_in[10];
    else
        tx_fifo_full_flag <= tx_fifo_full_flag;
    end
//===========================================================================
//数据发送准备好标志
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        tx_ready_r <= 'd0;
        else if ((fsm_cs == FSM_IDLE) && (~ip2bus_intrevent_in) && (~tx_fifo_full_flag))
        tx_ready_r <= 'd1;
    else
        tx_ready_r <= 'd0;
    end
//===========================================================================
//接收数据字节1赋值
//===========================================================================
always @(posedge sys_clk or  negedge reset_n)
    begin
    if (!reset_n)
        rx_dw1r_r <= 'd0;
    else if ((fsm_cs == FSM_DATA_DW1_REC) && rd_done_in)
        rx_dw1r_r <= rd_data_in;
    else
        rx_dw1r_r <= rx_dw1r_r;
    end
//===========================================================================
//接收数据字节2赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_dw2r_r <= 'd0;
    else if ((fsm_cs == FSM_DATA_DW2_REC) && rd_done_in)
        rx_dw2r_r <= rd_data_in;
    else
        rx_dw2r_r <= rx_dw2r_r;
    end
//===========================================================================
//接收数据有效标志赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_valid_r <= 'd0;
    else if (fsm_cs == FSM_DATA_REC_UPDATE)
        rx_valid_r <= 'd1;
    else
        rx_valid_r <= 'd0;
    end
//===========================================================================
//发送数据地址赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_addr_r <= 'd0;
    else
        begin
        case (fsm_cs)
            FSM_ISR_CLEAR:    wr_addr_r <= ICR_ADDR;
            FSM_TX_ID:              wr_addr_r <= TX_ID_ADDR;
            FSM_TX_DLC:          wr_addr_r <= TX_DLC_ADDR;
            FSM_TX_DW1:          wr_addr_r <= TX_DW1_ADDR;
            FSM_TX_DW2:          wr_addr_r <= TX_DW2_ADDR;
            default :wr_addr_r <= wr_addr_r;
        endcase
        end
    end
//===========================================================================
//发送数据寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_data_r <= 'd0;
    else
        begin
        case (fsm_cs)
            FSM_ISR_CLEAR:    wr_data_r <= {20'd0, 12'h014};
            FSM_TX_ID:              wr_data_r <= CAN_ID_VALUE;
            FSM_TX_DLC:          wr_data_r <= CAN_DLC_VALUE;
            FSM_TX_DW1:          wr_data_r <= tx_dw1r_cache;
            FSM_TX_DW2:          wr_data_r <= tx_dw2r_cache;
            default :wr_data_r <= wr_data_r;
        endcase
        end
    end
//===========================================================================
//待发送数据缓存
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        tx_dw1r_cache <= 'd0;
        tx_dw2r_cache <= 'd0;
        end else if ((fsm_cs == FSM_IDLE) && (~ip2bus_intrevent_in) && (tx_valid_in))
        begin
        tx_dw1r_cache <= tx_dw1r_in;
        tx_dw2r_cache <= tx_dw2r_in;
        end else
        begin
        tx_dw1r_cache <= tx_dw1r_cache;
        tx_dw2r_cache <= tx_dw2r_cache;
        end
    end
//===========================================================================
//数据发送使能
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_enable_r <= 'd0;
    else if (((fsm_cs == FSM_ISR_CLEAR) || (fsm_cs == FSM_TX_ID) || (fsm_cs == FSM_TX_DLC) || (fsm_cs == FSM_TX_DW1) || (fsm_cs == FSM_TX_DW2)) && ((~wr_busy_in) && (~wr_done_in)))
        wr_enable_r <= 'd1;
    else
        wr_enable_r <= 'd0;
    end
//===========================================================================
//读地址寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_addr_r <= 'd0;
    else
        begin
        case (fsm_cs)
            FSM_ISR_READ:   rd_addr_r <= ISR_ADDR;
            FSM_DATA_ID_REC:   rd_addr_r <= RX_ID_ADDR;
            FSM_DATA_DLC_REC:   rd_addr_r <= RX_DLC_ADDR;
            FSM_DATA_DW1_REC:  rd_addr_r <= RX_DW1_ADDR;
            FSM_DATA_DW2_REC:  rd_addr_r <= RX_DW2_ADDR;
            FSM_TX_FULL_DETECT:rd_addr_r<=SR_ADDR;
            default:rd_addr_r <= rd_addr_r;
        endcase
        end
    end
//===========================================================================
//读使能寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_enable_r <= 'd0;
        else if (((fsm_cs == FSM_ISR_READ) || (fsm_cs == FSM_DATA_ID_REC) || (fsm_cs == FSM_DATA_DLC_REC) || (fsm_cs == FSM_DATA_DW1_REC) || (fsm_cs == FSM_DATA_DW2_REC) || (fsm_cs == FSM_TX_FULL_DETECT)) && ((~rd_done_in) && (~rd_busy_in)))
        rd_enable_r <= 'd1;
    else
        rd_enable_r <= 'd0;
    end
//===========================================================================
//输出端口赋值
//===========================================================================
assign tx_ready_out = tx_ready_r;
assign rx_dw1r_out = rx_dw1r_r;
assign rx_dw2r_out = rx_dw2r_r;
assign rx_valid_out = rx_valid_r;
assign wr_addr_out = wr_addr_r;
assign wr_data_out = wr_data_r;
assign wr_enable_out = wr_enable_r;
assign rd_addr_out = rd_addr_r;
assign rd_enable_out = rd_enable_r;
endmodule

