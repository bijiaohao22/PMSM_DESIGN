//====================================================================================
// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/5/3
// Design Name:PMSM_DESIGN
// Module Name: pid_cal_unit.v
// Target Device:
// Tool versions:
// Description:  增量型PID算法实现
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module pid_cal_unit(
                    input    sys_clk,
                    input    reset_n,

                    input    pid_cal_enable_in,       //PID计算使能信号

                    input[`DATA_WIDTH-1:0]    pid_param_p_in,  //参数p输入
                    input[`DATA_WIDTH-1:0]    pid_param_i_in,   //参数i输入
                    input[`DATA_WIDTH-1:0]    pid_param_d_in,  //参数d输入

                    input signed[`DATA_WIDTH-1:0]    set_value_in,        //设定值输入
                    input signed[`DATA_WIDTH-1:0]    detect_value_in,   //检测值输入

                    output signed [`DATA_WIDTH-1:0] pid_cal_value_out,    //pid计算结果输出
                    output pid_cal_done_out                         //计算完成标志
                    );
//===========================================================================
//内部参数声明
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_MULT=1<<1;
localparam FSM_ADDER=1<<2;
localparam FSM_RESULT_ADJUST=1<<3;
//===========================================================================
//  内部变量声明
//===========================================================================
reg[3:0]     fsm_cs,
    fsm_ns;    //  有限状态机当前状态及其下一状态
reg[1:0]     period_cnt_r;         //时钟周期计数寄存器
                                   //  pid 参数寄存器
reg[`DATA_WIDTH-1:0]    param_p_r;
reg[`DATA_WIDTH-1:0]    param_i_r;
reg[`DATA_WIDTH-1:0]    param_d_r;
//PID计算内部变量
reg signed[`DATA_WIDTH:0]    pid_error_r;             //  误差值，格式1Q15（求差造成）
reg signed[`DATA_WIDTH:0]    pid_last_error_r;
reg signed[`DATA_WIDTH:0]    pid_prev_error_r;
reg signed[`DATA_WIDTH*2+4:0]   pid_det_value_r;  //pid增量值，数据格式6Q30；
reg signed[`DATA_WIDTH-1:0]    pid_cal_value_r;      //PID计算结果输出值
wire signed[`DATA_WIDTH*2+5:0] pid_cal_value_w; //pid计算结果中间变量7Q30
                                                //乘法器变量
reg[`DATA_WIDTH-1:0]     multiplicand_r;    //被乘数寄存器,Q15
reg[`DATA_WIDTH+2:0]    multiplier_r;        //乘数寄存器，3Q15
wire[`DATA_WIDTH*2+2:0] product_w;       //乘积，4Q30

reg pid_cal_done_r;

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
                if (pid_cal_enable_in)  //  收到计算使能信号后开始进行乘法操作
                    fsm_ns = FSM_MULT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_MULT: begin        //经四个时钟周期后跳转进入累加操作
                if (period_cnt_r == 'd3)
                    fsm_ns = FSM_ADDER;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ADDER: begin      //经三个时钟周期后跳转进入数据调整操作
                if (period_cnt_r == 'd2)
                    fsm_ns = FSM_RESULT_ADJUST;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_RESULT_ADJUST:
            fsm_ns = FSM_IDLE;
        default :fsm_ns = FSM_IDLE;
    endcase
    end
//周期计数赋值
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        period_cnt_r <= 'd0;
    else if (fsm_cs == FSM_MULT || fsm_cs == FSM_ADDER)
        period_cnt_r <= period_cnt_r + 1'b1;
    else
        period_cnt_r <= 'd0;
    end
//===========================================================================
//数据锁存操作
//在空闲状态下收到pid计算使能操作后进行相应数据锁存
//===========================================================================
//pid 参数锁存
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {param_p_r, param_i_r, param_d_r} <= 'd0;
    else if (fsm_cs == FSM_IDLE && pid_cal_enable_in)
        {param_p_r, param_i_r, param_d_r} <= {pid_param_p_in, pid_param_i_in, pid_param_d_in};
    else
    {param_p_r, param_i_r, param_d_r} <= {param_p_r, param_i_r, param_d_r};
    end
//误差值赋值
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pid_error_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && pid_cal_enable_in)
        pid_error_r <= {set_value_in[`DATA_WIDTH - 1], set_value_in} - {detect_value_in[`DATA_WIDTH - 1], detect_value_in};
    else
        pid_error_r <= pid_error_r;
    end
//===========================================================================
//乘法操作赋值
//===========================================================================
//被乘数赋值
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        multiplicand_r <= 'd0;
    else if (fsm_cs == FSM_MULT)
        begin
        case (period_cnt_r)
            'd0:  multiplicand_r <= param_p_r;    //比例计算
            'd1:  multiplicand_r <= param_i_r;     //积分计算
            'd2:  multiplicand_r <= param_d_r;    //微分计算
            default :multiplicand_r <= 'd0;
        endcase
        end else
        multiplicand_r <= 'd0;
    end
//乘数赋值 3Q15
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        multiplier_r <= 'd0;
    else if (fsm_cs == FSM_MULT)
        begin
        case (period_cnt_r)
            'd0:multiplier_r <= {{2{pid_error_r[`DATA_WIDTH]}}, pid_error_r} - {{2{pid_last_error_r[`DATA_WIDTH ]}}, pid_last_error_r};
            'd1:multiplier_r <= {{2{pid_error_r[`DATA_WIDTH]}}, pid_error_r};
            'd2:multiplier_r <= ({{2{pid_error_r[`DATA_WIDTH]}}, pid_error_r} - {{2{pid_last_error_r[`DATA_WIDTH ]}}, pid_last_error_r}) - ({{2{pid_last_error_r[`DATA_WIDTH ]}}, pid_last_error_r} - {{2{pid_prev_error_r[`DATA_WIDTH ]}}, pid_prev_error_r});
            default multiplier_r <= 'd0;
        endcase
        end else
        multiplier_r <= 'd0;
    end
//===========================================================================
//乘积项结果累加
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pid_det_value_r <= 'd0;
    else if (fsm_cs == FSM_ADDER)
        pid_det_value_r <= pid_det_value_r + {{2{product_w[`DATA_WIDTH * 2 + 2]}}, product_w};
    else
        pid_det_value_r <= 'd0;
    end
//===========================================================================
//pid计算结果输出
//===========================================================================
assign pid_cal_value_w = {pid_det_value_r[`DATA_WIDTH * 2 + 4], pid_det_value_r} + {{7{pid_cal_value_r[`DATA_WIDTH - 1]}}, pid_cal_value_r,15'd0}; //增量与原始数据之和
//输出数据截取与限幅
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pid_cal_value_r <= 'd0;
    else if (fsm_cs == FSM_RESULT_ADJUST)
        begin
        if (pid_cal_value_w[(`DATA_WIDTH * 2 + 5) -: 8] != 8'd0 && pid_cal_value_w[(`DATA_WIDTH * 2 + 5) -: 8] != 8'hff)    //表明数值超值
            pid_cal_value_r <= {pid_cal_value_w[`DATA_WIDTH * 2 + 5], {(`DATA_WIDTH - 1){~pid_cal_value_w[`DATA_WIDTH * 2 + 5]}}};
        else
            pid_cal_value_r <= {pid_cal_value_w[`DATA_WIDTH * 2 + 5], pid_cal_value_w[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]};
        end else
        pid_cal_value_r <= pid_cal_value_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pid_cal_done_r <= 'd0;
    else if (fsm_cs == FSM_RESULT_ADJUST)
        pid_cal_done_r <= 'd1;
    else
        pid_cal_done_r <= 'd0;
    end
//===========================================================================
//pid中间结果缓存
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {pid_last_error_r, pid_prev_error_r} <= 'd0;
    else if (fsm_cs == FSM_RESULT_ADJUST)
        {pid_last_error_r, pid_prev_error_r} <= {pid_error_r, pid_last_error_r};
    else
    {pid_last_error_r, pid_prev_error_r} <= {pid_last_error_r, pid_prev_error_r};
    end
//===========================================================================
//乘法器IP核调用
//===========================================================================
pid_cal_mul pid_cal_mul_inst(
                             .CLK(sys_clk),    // input wire CLK
                             .A(multiplicand_r),        // input wire [15 : 0] A
                             .B(multiplier_r),        // input wire [18 : 0] B
                             .SCLR(~reset_n),  // input wire SCLR
                             .P(product_w)        // output wire [34 : 0] P
);
//===========================================================================
//输出端口赋值
//===========================================================================
assign  pid_cal_value_out = pid_cal_value_r;
assign pid_cal_done_out = pid_cal_done_r;
endmodule
