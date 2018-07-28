//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/15
// Design Name:PMSM_DESIGN
// Module Name: cmd_to_axi_lite_unit.v
// Target Device:
// Tool versions:
// Description:cmd与axi_lite接口数据交换，完成数据处理层与链路层数据交换
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module cmd_to_axi_lite_unit(
                            input    sys_clk,
                            input    reset_n,

                            input    [7:0]   wr_addr_in,
                            input    [31:0] wr_data_in,
                            input              wr_enable_in,   //  写指令有效标志
                            output            wr_done_out,   //   写操作完成标志
                            output            wr_busy_out,   //    写操作忙标志

                            input   [7:0]    rd_addr_in,    //  读操作地址输入
                            input              rd_enable_in, //   读操作使能标志
                            output  [31:0] rd_data_out,  //  读操作数据输出
                            output  rd_done_out,
                            output  rd_busy_out,

                            output [7:0]  s_axi_awaddr_out,
                            output          s_axi_awvalid_out,
                            input            s_axi_awready_in,

                            output  [31:0]  s_axi_wdata_out,
                            output  [3:0]    s_axi_wstrb_out,
                            output              s_axi_wvalid_in,
                            input                s_axi_wready_in,
                            input    [1:0]    s_axi_bresp_in,
                            input                s_axi_bvalid_in,
                            output              s_axi_bready_out,

                            output  [7:0]    s_axi_araddr_out,
                            output             s_axi_arvalid_out,
                            input               s_axi_arready_in,
                            input   [31:0]   s_axi_rdata_in,
                            input   [1:0]     s_axi_rresp_in,
                            input               s_axi_rvalid_in,
                            output             s_axi_rready_out
                            );
//===========================================================================
//内部变量声明
//===========================================================================
localparam FSM_WR_IDLE=1<<0;
localparam FSM_WR_ADDR=1<<1;
localparam FSM_WR_DATA=1<<2;
localparam FSM_WR_RESP=1<<3;
localparam FSM_WR_DONE=1<<4;

localparam FSM_RD_IDLE=1<<0;
localparam FSM_RD_ADDR=1<<1;
localparam FSM_RD_DATA=1<<2;
localparam FSM_RD_DONE=1<<3;
//===========================================================================
//内部变量声明
//===========================================================================
reg[7:0]    axi_awaddr_r;   //axi写地址寄存器
reg               axi_awvalid_r; //axi写地址有效标志寄存器
reg[31:0]  axi_wdata_r;    //axi写数据寄存器
reg[3:0]    axi_wstrb_r;    //axi写选通寄存器
reg      axi_wvalid_r;          //axi写有效寄存器
reg      axi_bready_r;          //写响应准备好标志
reg      wr_done_r;             //写完成标志
reg      wr_busy_r;             //写忙碌标志
reg[4:0]   fsm_wr_cs,
    fsm_wr_ns;

reg[7:0]   axi_araddr_r;    //axi读地址寄存器
reg          axi_arvalid_r;    //axi读地址有效寄存器
reg          axi_rready_r;     //axi读响应有效标志位
reg[31:0] rd_data_r;
reg          rd_done_r;
reg           rd_busy_r;
reg[3:0]          fsm_rd_cs,
    fsm_rd_ns;

//===========================================================================
//axi-lite写时序状态机转换
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        fsm_wr_cs <= FSM_WR_IDLE;
    else
        fsm_wr_cs <= fsm_wr_ns;
    end
always @(*)
    begin
    case (fsm_wr_cs)
        FSM_WR_IDLE: begin
                if (wr_enable_in) //接收到写使能启动axi写时序
                    fsm_wr_ns = FSM_WR_ADDR;
                else
                    fsm_wr_ns = fsm_wr_cs;
            end
        FSM_WR_ADDR: begin  //收到s_axi_awready_in表示写地址完成，进入数据写阶段
                if (s_axi_awready_in)
                    fsm_wr_ns = FSM_WR_RESP;//FSM_WR_DATA;
                else
                    fsm_wr_ns = fsm_wr_cs;
            end
//      FSM_WR_DATA: begin  //收到s_axi_wready_in表示写数据完成，可进入写数据响应状态
//              if (s_axi_wready_in)
//                  fsm_wr_ns = FSM_WR_RESP;
//              else
//                  fsm_wr_ns = fsm_wr_cs;
//            end
        FSM_WR_RESP : begin  //等待bvalid信号有效标志，判定bresp状态
                if (s_axi_bvalid_in)
                    begin
                    if (s_axi_bresp_in == 'd0)  //表示信息写成功
                        fsm_wr_ns = FSM_WR_DONE;
                    else
                        fsm_wr_ns = FSM_WR_DATA;
                    end else
                    fsm_wr_ns = fsm_wr_cs;
            end
        FSM_WR_DONE:
            fsm_wr_ns = FSM_WR_IDLE;
        default :fsm_wr_ns = FSM_WR_IDLE;
    endcase
    end
//===========================================================================
//写地址寄存器，写数据寄存器更新
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {axi_awaddr_r, axi_wdata_r} <= 'd0;
    else if ((fsm_wr_cs == FSM_WR_IDLE) && wr_enable_in)   //空闲状态 接收到写使能信号
        {axi_awaddr_r, axi_wdata_r} <= {wr_addr_in, wr_data_in};
    else
    {axi_awaddr_r, axi_wdata_r} <= {wr_addr_in, wr_data_in};
    end
//===========================================================================
//axi写地址有效标志寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_awvalid_r <= 'd0;
    else if (s_axi_awready_in) //检测到总线写地址准备好即可拉低有效标志位
        axi_awvalid_r <= 'b0;
    else if (fsm_wr_cs == FSM_RD_ADDR)
        axi_awvalid_r <= 'd1;
    else
        axi_awvalid_r <= 'd0;
    end
//===========================================================================
//axi写数据有效标志位
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_wvalid_r <= 'd0;
    else if (s_axi_wready_in) //检测到总线总线写准备好即可拉低有效标志位
        axi_wvalid_r <= 'd0;
    else if(fsm_wr_cs == FSM_WR_ADDR)//  (fsm_wr_cs == FSM_RD_DATA)
        axi_wvalid_r <= 'd1;
    else
        axi_wvalid_r <= 'd0;
    end
//===========================================================================
//axi写数据掩码寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_wstrb_r <= 'd0;
    else
        axi_wstrb_r <= 'b1111;
    end
//===========================================================================
//写响应准备好寄存器标志
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_bready_r <= 'd0;
    else if (s_axi_bvalid_in)
        axi_bready_r <= 'd0;
    else if (fsm_wr_cs == FSM_WR_ADDR)// (fsm_wr_cs == FSM_WR_RESP)
        axi_bready_r <= 'd1;
    else
        axi_bready_r <= 'd0;
    end
//===========================================================================
//写操作完成标志,忙标志赋值
//===========================================================================
always @(posedge sys_clk or  negedge reset_n)
    begin
    if (!reset_n)
        wr_done_r <= 'd0;
    else if (fsm_wr_cs == FSM_WR_DONE)
        wr_done_r <= 'd1;
    else
        wr_done_r <= 'd0;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_busy_r <= 'd0;
    else if ((fsm_wr_cs == FSM_WR_IDLE)&&(~wr_enable_in))
        wr_busy_r <= 'd0;
    else
        wr_busy_r <= 'd1;
    end

//===========================================================================
//读操作有限状态机状态转移
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        fsm_rd_cs <= FSM_RD_IDLE;
    else
        fsm_rd_cs <= fsm_rd_ns;
    end
always @(*)
    begin
    case (fsm_rd_cs)
        FSM_RD_IDLE: begin
                if (rd_enable_in)  //在空闲状态下收到读使能则跳转至有限读地址写阶段
                    fsm_rd_ns = FSM_RD_ADDR;
                else
                    fsm_rd_ns = fsm_rd_cs;
            end
        FSM_RD_ADDR: begin
                if (s_axi_arready_in)    //从机准备好接受地址信号后即可跳转至数据读阶段
                    fsm_rd_ns = FSM_RD_DATA;
                else
                    fsm_rd_ns = fsm_rd_cs;
            end
        FSM_RD_DATA: begin
                if (s_axi_rvalid_in)  //接收到从机读数有效标志后即可完成读数
                    begin
                    if (s_axi_rresp_in == 'd0)
                        fsm_rd_ns = FSM_RD_DONE;
                    else
                        fsm_rd_ns = FSM_RD_ADDR;
                    end else
                    fsm_rd_ns = fsm_rd_cs;
            end
        FSM_RD_DONE:
            fsm_rd_ns = FSM_RD_IDLE;
        default:fsm_rd_ns = FSM_RD_IDLE;
    endcase
    end
//===========================================================================
//读地址寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_araddr_r <= 'd0;
    else if ((fsm_rd_cs == FSM_RD_IDLE) && rd_enable_in)
        axi_araddr_r <= rd_addr_in;
    else
        axi_araddr_r <= axi_araddr_r;
    end
//===========================================================================
//读地址有效标志寄存器
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_arvalid_r <= 'd0;
    else if (s_axi_arready_in)
        axi_arvalid_r <= 'd0;
    else if (fsm_rd_cs == FSM_RD_ADDR)
        axi_arvalid_r <= 'd1;
    else
        axi_arvalid_r <= 'd0;
    end
//===========================================================================
//读准备标志寄存器
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_rready_r <= 'd0;
    else if (s_axi_rvalid_in)
        axi_rready_r <= 'd0;
    else if (fsm_rd_cs == FSM_RD_ADDR)
        axi_rready_r <= 'd1;
    else
        axi_rready_r <= 'd0;
    end
//===========================================================================
//读数据寄存器赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_data_r <= 'd0;
    else if (fsm_rd_cs == FSM_RD_DATA && (s_axi_rresp_in == 'd0) && (s_axi_rvalid_in))
        rd_data_r <= s_axi_rdata_in;
    else
        rd_data_r <= rd_data_r;
    end
//===========================================================================
//读操作忙标志与完成标志
//===========================================================================
always @(posedge sys_clk or  negedge reset_n)
    begin
    if (!reset_n)
        rd_done_r <= 'd0;
    else if (fsm_rd_cs == FSM_RD_DONE)
        rd_done_r <= 'd1;
    else
        rd_done_r <= 'd0;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_busy_r <= 'd0;
    else if (fsm_rd_cs == FSM_RD_IDLE)
        rd_busy_r <= 'd0;
    else
        rd_busy_r <= 'd1;
    end
//===========================================================================
//输出端口赋值
//===========================================================================
assign wr_done_out=wr_done_r;
assign wr_busy_out=wr_busy_r;
assign rd_data_out=rd_data_r;
assign rd_done_out=rd_done_r;
assign rd_busy_out=rd_busy_r;

assign s_axi_awaddr_out=axi_awaddr_r;
assign s_axi_awvalid_out=axi_awvalid_r;
assign s_axi_wdata_out=axi_wdata_r;
assign s_axi_wstrb_out=axi_wstrb_r;
assign s_axi_wvalid_in=axi_wvalid_r;
assign s_axi_bready_out=axi_bready_r;

assign s_axi_araddr_out=axi_araddr_r;
assign s_axi_arvalid_out=axi_arvalid_r;
assign s_axi_rready_out=axi_rready_r;
endmodule

