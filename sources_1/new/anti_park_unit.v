//====================================================================================
// Company:
// Engineer: LiXiaoChaung
// Create Date: 2018/5/4
// Design Name:PMSM_DESIGN
// Module Name: anti_park_unit.v
// Target Device:
// Tool versions:
// Description:反park变换
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module anti_park_unit(
                      input    sys_clk,
                      input    reset_n,

                      input    anti_park_cal_enable_in,       //反Park变换使能输入

                      input    [`DATA_WIDTH-1:0]    voltage_d_in,   //Ud电压输入
                      input    [`DATA_WIDTH-1:0]    voltage_q_in,   //Uq电压输入
                      input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_in,   //  电气角度正弦值
                      input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_in,  //  电气角度余弦值

                      output  signed [`DATA_WIDTH-1:0]    voltage_alpha_out, //U_alpha电压输出
                      output  signed [`DATA_WIDTH-1:0]    voltage_beta_out,   //U_beta电压输出
                      output  anti_park_cal_valid_out     //电压输出有效标志
                      );
//===========================================================================
//内部常量声明
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_MULT=1<<1;  //乘积操作
localparam FSM_ADDER=1<<2; //  求和操作
localparam FSM_RESULT_ADJUST = 1 << 3;  //  数据调整操作

//===========================================================================
//  内部变量声明
//===========================================================================
reg[3:0]    fsm_cs,
    fsm_ns;     //有限状态机及其下一状态
reg[1:0]    period_cnt;           //周期计数寄存器，乘操作和加操作都需要四个时钟周期

reg  signed[`DATA_WIDTH-1:0]    multiplicand_r;    //  被乘数寄存器
reg signed[`DATA_WIDTH-1:0]   multiplier_r;         //   乘数寄存器
reg[`DATA_WIDTH*2-1:0]  product_cache_r;  //  乘积项缓存
wire[`DATA_WIDTH*2-1:0] product_w;  //乘积项输出

wire[`DATA_WIDTH*2-1:0]  product_sum_w;  //求和连线
reg[`DATA_WIDTH-1:0] voltage_alpha_r;     //Valpha变量
reg[`DATA_WIDTH-1:0] voltage_beta_r;       //  Vbeta变量
reg   anti_park_cal_valid_r;  //  反Park变换输出有效标志位

//===========================================================================
//有限状态机状态转移声明
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
                if (anti_park_cal_enable_in)  //  收到计算使能信号后启动状态机
                    fsm_ns = FSM_MULT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_MULT: begin
                if (period_cnt == 2'b11) //经过四个时钟周期进入累加和操作
                    fsm_ns = FSM_ADDER;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ADDER: begin
                if (period_cnt == 2'b11) //经过四个时钟周期进入累加和操作
                    fsm_ns = FSM_RESULT_ADJUST;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_RESULT_ADJUST: begin
                fsm_ns = FSM_IDLE;
            end
        default :fsm_ns = FSM_IDLE;
    endcase
    end
//状态周期计数
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        period_cnt <= 'd0;
    else if (fsm_cs == FSM_MULT || fsm_cs == FSM_ADDER)
        period_cnt <= period_cnt + 1'b1;
    else
        period_cnt <= 'd0;
    end

//===========================================================================
//乘法器乘数与被乘数赋值
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        multiplicand_r <= 'd0;
        multiplier_r <= 'd0;
        end else if (fsm_cs == FSM_MULT)
        begin
        case (period_cnt)
            'd0: begin  //  cos(theta)*Ud
                    multiplicand_r <= electrical_rotation_phase_cos_in;
                    multiplier_r <= voltage_d_in;
                end
            'd1: begin  //-sin(theta*uq)
                    multiplicand_r <= 16'sd0 - electrical_rotation_phase_sin_in;
                    multiplier_r <= voltage_q_in;
                end
            'd2: begin  //sin(theta)*Ud
                    multiplicand_r <= electrical_rotation_phase_sin_in;
                    multiplier_r <= voltage_d_in;
                end
            'd3: begin  //cos(theta)*Uq
                    multiplicand_r <= electrical_rotation_phase_cos_in;
                    multiplier_r <= voltage_q_in;
                end
            default : begin
                    multiplicand_r <= 'd0;
                    multiplier_r <= 'd0;
                end
        endcase
        end else
        begin
        multiplicand_r <= 'd0;
        multiplier_r <= 'd0;
        end
    end
//===========================================================================
//乘积项输出缓存
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        product_cache_r <= 'd0;
    else if (fsm_cs == FSM_ADDER)
        product_cache_r <= product_w;
    else
        product_cache_r <= 'd0;
    end
//===========================================================================
//U_alpha,U_beta赋值
//===========================================================================
assign product_sum_w = product_cache_r + product_w;
//Ualpha
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        voltage_alpha_r <= 'd0;
    else if (fsm_cs == FSM_ADDER && period_cnt == 'd1)
        begin
        if (^product_sum_w[(`DATA_WIDTH * 2 - 1) -: 2])  //超值处理
            voltage_alpha_r <= {product_sum_w[`DATA_WIDTH * 2 - 1], {(`DATA_WIDTH - 1){~product_sum_w[`DATA_WIDTH * 2 - 1]}}};
        else
            voltage_alpha_r <= {product_sum_w[`DATA_WIDTH * 2 - 1], product_sum_w[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]};
        end else
        voltage_alpha_r <= voltage_alpha_r;
    end
//U_beta
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        voltage_beta_r <= 'd0;
    else if (fsm_cs == FSM_ADDER && period_cnt == 'd3)
        begin
        if (^product_sum_w[(`DATA_WIDTH * 2 - 1) -: 2])  //超值处理
            voltage_beta_r <= {product_sum_w[`DATA_WIDTH * 2 - 1], {(`DATA_WIDTH - 1){~product_sum_w[`DATA_WIDTH * 2 - 1]}}};
        else
            voltage_beta_r <= {product_sum_w[`DATA_WIDTH * 2 - 1], product_sum_w[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]};
        end else
        voltage_beta_r <= voltage_beta_r;
    end
//===========================================================================
//计算完成标志
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        anti_park_cal_valid_r <= 'd0;
    else if (fsm_cs == FSM_RESULT_ADJUST)
        anti_park_cal_valid_r <= 'd1;
    else
        anti_park_cal_valid_r <= 'd0;
    end
//===========================================================================
//乘法器核调用
//===========================================================================
anti_park_mult anti_park_mult_inst(
                                   .CLK(sys_clk),    // input wire CLK
                                   .A(multiplicand_r),        // input wire [15 : 0] A
                                   .B(multiplier_r),        // input wire [15 : 0] B
                                   .SCLR(~reset_n),  // input wire SCLR
                                   .P(product_w)        // output wire [31 : 0] P
);
//===========================================================================
//输出端口赋值
//===========================================================================
    assign voltage_alpha_out=voltage_alpha_r;
    assign voltage_beta_out=voltage_beta_r;
    assign anti_park_cal_valid_out=anti_park_cal_valid_r;
endmodule
