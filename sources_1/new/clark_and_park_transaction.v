`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/25
// Design Name:PMSM_DESIGN
// Module Name: clark_and_park_transaction.v
// Target Device:
// Tool versions:
// Description: 收到使能信号后进行Clark和Park变换，获取Iq，Id
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module clark_and_park_transaction(
                                  input    sys_clk,    //system clock
                                  input    reset_n,    //active-low,reset signal

                                  input    transaction_enable_in,  //转换使能信号

                                  input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_in,   //  电气角度正弦值
                                  input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_in,  //  电气角度余弦值

                                  input    signed [`DATA_WIDTH-1:0]    phase_a_current_in,                      //  a相电流检测值
                                  input    signed [`DATA_WIDTH-1:0]    phase_b_current_in,                      //  b相电流检测值

                                  output    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_out,   //  电气角度正弦值输出，用于反Park变换
                                  output    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_out,  //  电气角度余弦值输出

                                  output  signed [`DATA_WIDTH-1:0]    current_q_out,                              //  Iq电流输出
                                  output  signed [`DATA_WIDTH-1:0]    current_d_out,                              //  Id电流输出
                                  output                                          transaction_valid_out                               //转换输出有效信号
                                  );
//===========================================================================
//内部常量声明
//===========================================================================
localparam FSM_IDLE=1<<0;                    //  初始状态
localparam FSM_PARK_MULT=1<<1;    //   PARK变换乘法操作
localparam FSM_PARK_SUM=1<<2;      //    PARK变换求和操作
localparam FSM_CAL_DONE = 1 << 3;      //    CLARK和PARK转换完成状态

//===========================================================================
//内部变量声明
//===========================================================================
reg signed[`DATA_WIDTH-1:0]      current_alpha_r;        //  Ialpha电流值
reg signed[`DATA_WIDTH*2-1:0]  current_beta_r;      //  Ibeta电流值     由于牵涉到乘法位宽扩展
reg signed[`DATA_WIDTH*2-1:0]   multiplicand_r;    //  被乘数寄存器
reg signed[`DATA_WIDTH-1:0]       multipler_r;          //乘数寄存器
reg signed[`DATA_WIDTH-1:0]       electrical_rotation_phase_sin_r;    //电角度正弦寄存器
reg signed[`DATA_WIDTH-1:0]       electrical_rotation_phase_cos_r;   //电角度余弦寄存器
reg signed[`DATA_WIDTH*3-1:0]       product_cache_r;                         //乘法器结果缓存寄存器
wire signed[`DATA_WIDTH*3-1:0]       product_w;                                //乘法器输出连线
wire [`DATA_WIDTH*3:0]    product_sum_w;                                        //乘法器输出结果求和缓存
reg[4:0]   fsm_cs,
    fsm_ns;                                    //状态机寄存器及其下一状态
reg           transaction_valid_r;                              //转换完成标志寄存器
reg[1:0]   delay_time_cnt;                                   //乘法器延迟计数
reg  signed[`DATA_WIDTH-1:0]    current_q_r;            //  Iq电流输出寄存器
reg  signed[`DATA_WIDTH-1:0]    current_d_r;        //  Id电流输出寄存器

//===========================================================================
//逻辑功能实现
//===========================================================================
//状态机状态转移
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
                if (transaction_enable_in)  //收到转换使能信号
                    fsm_ns = FSM_PARK_MULT;   //进行PARK求和操作
                else
                    fsm_ns = fsm_cs;
            end
        FSM_PARK_MULT: begin
                if (delay_time_cnt == 'd3)       //由于要进行四次乘法运算，故延迟四个时钟周期
                    fsm_ns = FSM_PARK_SUM;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_PARK_SUM: begin
                if (delay_time_cnt == 'd3)       //由于要进行四次乘法运算，故延迟四个时钟周期
                    fsm_ns = FSM_CAL_DONE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_CAL_DONE:
            fsm_ns = FSM_IDLE;
        default : fsm_ns = FSM_IDLE;
    endcase
    end

//clark变换寄存器赋值
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_alpha_r <= 'd0;
    else if (transaction_enable_in)
        current_alpha_r <= phase_a_current_in;
    else
        current_alpha_r <= current_alpha_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_beta_r <= 'd0;
    else if (transaction_enable_in)   //收到转换使能时进行clark变换
        current_beta_r <= (((phase_a_current_in << 'd14) + (phase_a_current_in << 'd11)) + ((phase_a_current_in << 9) - (phase_a_current_in << 5))) + (((phase_a_current_in << 2) + (phase_a_current_in << 1)) + ((phase_b_current_in << 15) + (phase_b_current_in << 12))) + (((phase_b_current_in << 10) - (phase_b_current_in << 6)) + ((phase_b_current_in << 3) + (phase_b_current_in << 2)));
    else
        current_beta_r <= current_beta_r;
    end
//正余弦值锁存
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {electrical_rotation_phase_sin_r, electrical_rotation_phase_cos_r} <= 'd0;
    else if (transaction_enable_in)
        {electrical_rotation_phase_sin_r, electrical_rotation_phase_cos_r} <= {electrical_rotation_phase_sin_in, electrical_rotation_phase_cos_in};
    else
    {electrical_rotation_phase_sin_r, electrical_rotation_phase_cos_r} <= {electrical_rotation_phase_sin_r, electrical_rotation_phase_cos_r};
    end
//乘法器延迟寄存器计数，兼具乘法分步功能
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        delay_time_cnt <= 'd0;
    else if (fsm_cs == FSM_PARK_MULT || fsm_cs == FSM_PARK_SUM)
        delay_time_cnt <= delay_time_cnt + 'b1;
    else
        delay_time_cnt <= 'd0;
    end
//被乘数与乘数赋值
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {multiplicand_r, multipler_r} <= 'd0;
    else if (fsm_cs == FSM_PARK_MULT)
        begin
        case (delay_time_cnt)
            'd0:{multiplicand_r, multipler_r} <= {current_alpha_r[`DATA_WIDTH - 1],current_alpha_r,{(`DATA_WIDTH-1){1'b0}}, electrical_rotation_phase_cos_r};   //计算cos(theta)*Ialpha
                'd1:{multiplicand_r, multipler_r} <= {current_beta_r, electrical_rotation_phase_sin_r};         //计算Ibeta*sin(theta)
                'd2:{multiplicand_r, multipler_r} <= {current_alpha_r[`DATA_WIDTH - 1],current_alpha_r,{(`DATA_WIDTH-1){1'b0}}, (16'sd0 - electrical_rotation_phase_sin_r)}; //计算-sin(alpha)*Ialpha
                'd3:{multiplicand_r, multipler_r} <= {current_beta_r, electrical_rotation_phase_cos_r};
                default :{multiplicand_r, multipler_r} <= 'd0;
                endcase
        end else
            {multiplicand_r, multipler_r} <= 'd0;
        end

        //乘法器输出缓存赋值
        always @(posedge sys_clk or  negedge reset_n) begin
        if (!reset_n)
            product_cache_r <= 'd0;
        else if (fsm_cs == FSM_PARK_SUM)
            product_cache_r <= product_w;
        else
            product_cache_r <= 'd0;
    end
        //乘法器输出结果求和缓存
        assign product_sum_w = {product_cache_r[`DATA_WIDTH*3-1],product_cache_r }+{product_w[`DATA_WIDTH*3-1], product_w};
        //Id赋值
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            current_d_r <= 'd0;
        else if ((fsm_cs == FSM_PARK_SUM) && (delay_time_cnt == 'd1))
            begin
                if (product_sum_w[(`DATA_WIDTH*3)-:4]==4'd0||product_sum_w[(`DATA_WIDTH*3)-:4]==4'hf)
                current_d_r <= {product_sum_w[`DATA_WIDTH*3],product_sum_w[(`DATA_WIDTH*3-4)-:15]};
            else
                current_d_r <=product_sum_w[`DATA_WIDTH*3]?16'h7fff:16'h8000;
            end else
            current_d_r <= current_d_r;
    end

        //Iq赋值
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            current_q_r <= 'd0;
        else  if ((fsm_cs == FSM_PARK_SUM) && (delay_time_cnt == 'd3))
            begin
            if (product_sum_w[(`DATA_WIDTH*3)-:4]==4'd0||product_sum_w[(`DATA_WIDTH*3)-:4]==4'hf)
                current_q_r <= {product_sum_w[`DATA_WIDTH*3],product_sum_w[(`DATA_WIDTH*3-4)-:15]};
            else
                current_q_r <=product_sum_w[`DATA_WIDTH*3]?16'h7fff:16'h8000;;
            end else
            current_q_r <= current_q_r;
    end
        //输出有效标志
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            transaction_valid_r <= 'd0;
        else if (fsm_cs == FSM_CAL_DONE)
            transaction_valid_r <= 1'b1;
        else
            transaction_valid_r <= 1'b0;
    end

        //===========================================================================
        //乘法器核调用
        //===========================================================================
        park_multiplier_module park_multipler(
                                                  .CLK(sys_clk),    // input wire CLK
                                                  .A(multiplicand_r),        // input wire [31 : 0] A
                                                  .B(multipler_r),        // input wire [15 : 0] B
                                                  .SCLR(~reset_n),  // input wire SCLR
                                                  .P(product_w)        // output wire [15 : 0] P
    );
        //===========================================================================
        //输出端口赋值
        //===========================================================================
        assign current_q_out = current_q_r;
        assign current_d_out = current_d_r;
        assign transaction_valid_out = transaction_valid_r;
        assign electrical_rotation_phase_sin_out=electrical_rotation_phase_sin_r;
        assign electrical_rotation_phase_cos_out = electrical_rotation_phase_cos_r;
endmodule
