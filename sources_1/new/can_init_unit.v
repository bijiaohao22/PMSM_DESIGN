//====================================================================================
// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/5/15
// Design Name:PMSM_DESIGN
// Module Name: can_init_unit.v
// Target Device:
// Tool versions:
// Description:完成CAN IP核的初始化
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module can_init_unit(
                     input    sys_clk,
                     input    reset_n,

                     input    can_init_enable_in,    //   can初始化使能标志
                     output  can_init_done_out,    //    can初始化完成标志

                     output  [7:0]    wr_addr_out, //can总线写地址
                     output  [31:0]  wr_data_out, //can总线写数据
                     output             wr_enable_out, //can总线写使能
                     input    wr_done_in,    //can写操作完成输入
                     input    wr_busy_in,    //can总线写操作忙标志

                     output  [7:0]    rd_addr_out, //can总线读地址
                     output             rd_enable_out, //can总线读使能
                     input               rd_done_in,   //can总线读完成输入
                     input   [31:0]  rd_data_in     //can总线读数据输入
                     );
//===========================================================================
//内部常量声明
//===========================================================================
localparam MSR_ADDR=8'h04;
localparam MSR_VALUE=32'd2;   //32'd2:loopback model,32'd0:normal_model
localparam BRPR_ADDR=8'h08;
localparam BRPR_VALUE=32'd1;
localparam BTR_ADDR=8'h0c;
localparam BTR_VALUE=32'd184;
localparam AFR_ADDR=8'h60;
localparam SR_ADDR=8'h18;
localparam AFMR1_ADDR=8'h64;
localparam AFMR1_VALUE=
    {
    `CAN_MODE_MASK,1'b0,1'b0,18'b0,1'b0
    };
localparam AFIR1_ADDR=8'h68;
localparam AFIR1_VALUE=
    {
    `CAN_NODE_ID,1'b0,1'b0,19'd0
    };
localparam IER_ADDDR=8'h20;
localparam IER_VALUE=  //  使能接收中断与TX_FIFO满中断
    {
    20'b0,12'd16
    };
localparam SRR_ADDR=8'h00;
localparam SRR_VALUE=23'd2;

localparam FSM_IDLE=1<<0;
localparam FSM_INIT1=1<<1;
localparam FSM_SR_POLL=1<<2;
localparam FSM_ACFBSY_WAIT=1<<3;
localparam FSM_INIT2=1<<4;
localparam FSM_INIT_DONE=1<<5;
//===========================================================================
//内部变量声明
//===========================================================================
reg[5:0]    fsm_cs,
    fsm_ns;
reg[3:0]    can_config_index_r;    //can配置次序计数
reg[31:0]  can_rd_data_r;             //can总线读数据寄存器
reg[7:0]    can_rd_addr_r;            //can总线读地址
reg           can_rd_enable_r;        //can总线读使能寄存器
wire         sr_acfbsy_w;

reg[7:0]    can_wr_addr_r;         //can总线写地址寄存器
reg[31:0]  can_wr_data_r;         //can总线写数据寄存器
reg           can_wr_enable_r;      //can总线写使能寄存器

reg   can_init_done_r;               //can总线配置完成标志

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
                if (can_init_enable_in)  //初始化使能
                    fsm_ns = FSM_INIT1;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_INIT1: begin    //配置完成MSR，BRPR,BTR，AFR寄存器后进入SR查询状态
                if (can_config_index_r == 4'd3 && wr_done_in) //成功完成四次配置
                    fsm_ns = FSM_SR_POLL;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_SR_POLL: begin
                if (rd_done_in)  //完成一次SR寄存器读取
                    fsm_ns = FSM_ACFBSY_WAIT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ACFBSY_WAIT: begin
                if (~sr_acfbsy_w) //等待sr寄存器中acfbsy为0
                    fsm_ns = FSM_INIT2;
                else
                    fsm_ns = FSM_SR_POLL;
            end
        FSM_INIT2: begin
                if (can_config_index_r == 4'd8 && wr_done_in) //成功完成其余所有配置
                    fsm_ns = FSM_INIT_DONE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_INIT_DONE:
            fsm_ns = FSM_IDLE;
        default:fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//can配置次数计数寄存器
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        can_config_index_r <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        can_config_index_r <= 'd0;
    else if (wr_done_in)  //完成一次写操作进行一次计数加1
        can_config_index_r <= can_config_index_r + 1'b1;
    else
        can_config_index_r <= can_config_index_r;
    end
//===========================================================================
//can写地址及写数据寄存器配置
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {can_wr_addr_r, can_wr_data_r} <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        {can_wr_addr_r, can_wr_data_r} <= 'd0;
    else
        begin
        case (can_config_index_r)
            'd0:{can_wr_addr_r, can_wr_data_r} <= {MSR_ADDR, MSR_VALUE};  //MSR寄存器配置
                'd1:{can_wr_addr_r, can_wr_data_r} <= {BRPR_ADDR, BRPR_VALUE}; //BRPR寄存器配置
                'd2:{can_wr_addr_r, can_wr_data_r} <= {BTR_ADDR, BTR_VALUE}; //BTR寄存器配置
                'd3:{can_wr_addr_r, can_wr_data_r} <= {AFR_ADDR, 32'd0};   //AFR寄存器配置
                'd4:{can_wr_addr_r, can_wr_data_r} <= {AFMR1_ADDR, AFMR1_VALUE};  //AFMR1寄存器配置
                'd5:{can_wr_addr_r, can_wr_data_r} <= {AFIR1_ADDR, AFIR1_VALUE};  //AFIR寄存器配置
                'd6:{can_wr_addr_r, can_wr_data_r} <= {AFR_ADDR, 32'd1};   //AFR寄存器配置
                'd7:{can_wr_addr_r, can_wr_data_r} <= {IER_ADDDR, IER_VALUE}; //IER寄存器配置
                'd8:{can_wr_addr_r, can_wr_data_r} <= {SRR_ADDR, SRR_VALUE}; //SRR寄存器配置
                default:{can_wr_addr_r, can_wr_data_r} <= {can_wr_addr_r, can_wr_data_r};
                endcase
        end
        end

        //===========================================================================
        //写使能
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            can_wr_enable_r <= 'd0;
        else if (fsm_cs == FSM_INIT1 || fsm_cs == FSM_INIT2)
            begin
            if (can_wr_enable_r)
                can_wr_enable_r <= 'd0;
            else if ((~wr_busy_in) && (~wr_done_in))
                can_wr_enable_r <= 'd1;
            end else
            can_wr_enable_r <= 'd0;
    end
        //===========================================================================
        //读使能
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            can_rd_enable_r <= 'd0;
        else if ((fsm_cs == FSM_INIT1 || fsm_cs == FSM_ACFBSY_WAIT) && (fsm_cs != fsm_ns))
            can_rd_enable_r <= 'd1;
        else
            can_rd_enable_r <= 'd0;
    end
        //===========================================================================
        //读数据寄存器
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            can_rd_data_r <= 'd0;
        else if (rd_done_in)
            can_rd_data_r <= rd_data_in;
        else
            can_rd_data_r <= 'd0;
    end
        assign sr_acfbsy_w = can_rd_data_r[11];
        //===========================================================================
        //读地址寄存器赋值
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            can_rd_addr_r <= 'd0;
        else
            can_rd_addr_r <= SR_ADDR;
    end
        //===========================================================================
        //初始化完成标志
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            can_init_done_r <= 'd0;
        else if (fsm_cs == FSM_INIT_DONE)
            can_init_done_r <= 'd1;
        else
            can_init_done_r <= 'd0;
    end
        //===========================================================================
        //输出接口赋值
        //==========================================================================
        assign can_init_done_out = can_init_done_r;
        assign wr_addr_out = can_wr_addr_r;
        assign wr_data_out = can_wr_data_r;
        assign wr_enable_out = can_wr_enable_r;
        assign rd_addr_out = can_rd_addr_r;
        assign rd_enable_out = can_rd_enable_r;
        endmodule
