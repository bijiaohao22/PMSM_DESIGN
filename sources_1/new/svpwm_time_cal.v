//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/28
// Design Name:PMSM_DESIGN
// Module Name: svpwm_time_cal.v
// Target Device:
// Tool versions:
// Description:根据SVPWM计算PWM状态切换点
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module svpwm_time_cal(
                      input        sys_clk,
                      input        reset_n,

                      input signed   [`DATA_WIDTH-1:0]      U_alpha_in,       //    Ualpha电压输入
                      input signed   [`DATA_WIDTH-1:0]      U_beta_in,         //    Ubeta电压输入
                      input              svpwm_cal_enable_in,                                //     SVPWM计算使能

                      output            [`DATA_WIDTH-1:0]      Tcma_out,               //      a相 时间切换点
                      output            [`DATA_WIDTH-1:0]      Tcmb_out,               //      b相时间切换点2
                      output            [`DATA_WIDTH-1:0]      Tcmc_out,               //      c相时间切换点3
                      output                                                      svpwm_cal_done_out   //  svpwm计算完成标志
                      );

//===========================================================================
//内部常量声明
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_DUTY_CYCLE_CAL=1<<1;          //占空比计算
localparam FSM_TIME_ARBITRATION=1<<2;       //时间超时仲裁判定
localparam FSM_DATA_MODULATION=1<<3;      //数据调制
localparam FSM_SWITCHING_POINT_CAL = 1 << 4; //切换点计算

//===========================================================================
//内部变量声明
//===========================================================================
reg[2:0] sector_node_r,
    sector_node_r_ns;                 //扇区结点寄存器及其下一状态
reg   signed[`DATA_WIDTH-1:0] time_X_r;     //X寄存器
reg   signed[`DATA_WIDTH*2-1:0] time_Y_r; //Y寄存器，数据格式1Q30
reg   signed[`DATA_WIDTH*2-1:0] time_Z_r; //Z 寄存器，数据格式1Q30
wire signed[`DATA_WIDTH*2:0]  time_Y_w,time_Z_w; // Y,Z寄存器中间计算结果缓存，2Q30
wire signed[`DATA_WIDTH*2-2:0]   U_beta_mul_sqrt_3_val;  //用于存放Ubeta/sqrt(3),数据格式，Q30
reg   signed[`DATA_WIDTH-1:0]    time_1_r;              //时间t1寄存器
reg   signed[`DATA_WIDTH-1:0]    time_2_r;              //时间t2寄存器
reg[`DATA_WIDTH-1:0]    Tcma_r;     //a相时间切换点寄存器
reg[`DATA_WIDTH-1:0]    Tcmb_r;     //b相时间切换点寄存器
reg[`DATA_WIDTH-1:0]    Tcmc_r;     //c相时间切换点寄存器

wire[`DATA_WIDTH-1:0]   Time_a,
    Time_b,
    Time_c;

reg   modulation_enable_r;   //校准使能信号
wire signed [23:0]  svpwm_divisor_w;   //数据校正除数
wire signed [31:0]  svpwm_dividend_w; //数据校正被除数
wire[47:0]   svpwm_divider_tdata_w;     //[30:15]   quoitent,[14:0] fractional
wire data_modulation_valid_r;     //数据校准完成标志
reg   svpwm_cal_done_r; //  svpwm数据计算完成寄存器
reg[4:0]    fsm_cs,
    fsm_ns;
//===========================================================================
//数字逻辑设计
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
                if (svpwm_cal_enable_in) //启动转换
                    fsm_ns = FSM_DUTY_CYCLE_CAL;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DUTY_CYCLE_CAL:  //占空比计算
            fsm_ns = FSM_TIME_ARBITRATION;
        FSM_TIME_ARBITRATION: begin    // 超时仲裁
                if (time_1_r + time_2_r >= 17'sh07fff) //说明超时
                    fsm_ns = FSM_DATA_MODULATION;
                else  //否则进入切换点计算
                    fsm_ns = FSM_SWITCHING_POINT_CAL;
            end
        FSM_DATA_MODULATION: begin  //数据校正
                if (data_modulation_valid_r)    //校正完成进入切换点计算
                    fsm_ns = FSM_SWITCHING_POINT_CAL;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_SWITCHING_POINT_CAL:    //切换点计算
            fsm_ns = FSM_IDLE;
        default :fsm_ns = FSM_IDLE;
    endcase
    end

//===========================================================================
//扇区位置判断
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        sector_node_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && svpwm_cal_enable_in)  //在空闲状态下收到svpwm计算使能信号时进行扇区结点判定
        sector_node_r <= sector_node_r_ns;
    else
        sector_node_r <= sector_node_r;
    end

always @(*)
    begin
    if (U_beta_in > 16'sd0)
        sector_node_r_ns[0] = 1'b1;
    else
        sector_node_r_ns[0] = 1'b0;
    end
assign U_beta_mul_sqrt_3_val = (((U_beta_in <<< 'd14) + (U_beta_in <<< 'd11)) + ((U_beta_in <<< 9) - (U_beta_in <<< 5)) + ((U_beta_in <<< 2) + (U_beta_in <<< 1)));
always @(*)
    begin
    if ((U_alpha_in <<< 'd15) > U_beta_mul_sqrt_3_val)
        sector_node_r_ns[1] = 1'b1;
    else
        sector_node_r_ns[1] = 1'b0;
    end

always @(*)
    begin
    if ((U_alpha_in <<< 'd15) + U_beta_mul_sqrt_3_val < 32'sd0)
        sector_node_r_ns[2] = 1'b1;
    else
        sector_node_r_ns[2] = 1'b0;
    end

//===========================================================================
//X,Y,Z时间寄存器的计算
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_X_r <= 'sd0;
    else if (fsm_cs == FSM_IDLE && svpwm_cal_enable_in)  //在空闲状态下收到svpwm计算使能信号时进时间寄存器计算
        time_X_r <= U_beta_in;
    else
        time_X_r <= time_X_r;
    end

always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_Y_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && svpwm_cal_enable_in)  //在空闲状态下收到svpwm计算使能信号时进时间寄存器计算
        time_Y_r <= time_Y_w[`DATA_WIDTH * 2 -: 32];
    else
        time_Y_r <= time_Y_r;
    end

assign time_Y_w = (((U_alpha_in <<< 'd16) - (U_alpha_in <<< 'd13)) - ((U_alpha_in <<< 'd9) + (U_alpha_in <<< 'd6))) - (((U_alpha_in <<< 'd4) - (U_alpha_in <<< 'd1)) - (U_beta_in <<< 'd15));

always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_Z_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && svpwm_cal_enable_in)  //在空闲状态下收到svpwm计算使能信号时进时间寄存器计算
        time_Z_r <= time_Z_w[`DATA_WIDTH * 2 -: 32];
    else
        time_Z_r <= time_Z_r;
    end

assign time_Z_w = (((U_alpha_in <<< 'd13) - (U_alpha_in <<< 'd16)) + ((U_alpha_in <<< 'd9) + (U_alpha_in <<< 'd6))) + (((U_alpha_in <<< 'd4) - (U_alpha_in <<< 'd1)) + (U_beta_in <<< 'd15));

//===========================================================================
//占空比计算
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_1_r <= 'd0;
    else if (fsm_cs == FSM_DUTY_CYCLE_CAL)
        begin
        case (sector_node_r)
            'd1:  time_1_r <= (^time_Z_r[(`DATA_WIDTH * 2 - 1) -: 2]) ? {time_Z_r[`DATA_WIDTH * 2 - 1], {(`DATA_WIDTH - 1){time_Z_r[`DATA_WIDTH * 2 - 2]}}} : {time_Z_r[`DATA_WIDTH * 2 - 1], time_Z_r[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]};
            'd2:  time_1_r <= (^time_Y_r[(`DATA_WIDTH * 2 - 1) -: 2]) ? {time_Y_r[`DATA_WIDTH * 2 - 1], {(`DATA_WIDTH - 1){time_Y_r[`DATA_WIDTH * 2 - 2]}}} : {time_Y_r[`DATA_WIDTH * 2 - 1], time_Y_r[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]};
            'd3:  time_1_r <= 16'sd0 - ((^time_Z_r[(`DATA_WIDTH * 2 - 1) -: 2]) ? {time_Z_r[`DATA_WIDTH * 2 - 1], {(`DATA_WIDTH - 1){time_Z_r[`DATA_WIDTH * 2 - 2]}}} : {time_Z_r[`DATA_WIDTH * 2 - 1], time_Z_r[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]});
            'd4:  time_1_r = 16'sd0 - time_X_r;
            'd5:  time_1_r = time_X_r;
            'd6:  time_1_r <= 16'sd0 - ((^time_Y_r[(`DATA_WIDTH * 2 - 1) -: 2]) ? {time_Y_r[`DATA_WIDTH * 2 - 1], {(`DATA_WIDTH - 1){time_Y_r[`DATA_WIDTH * 2 - 2]}}} : {time_Y_r[`DATA_WIDTH * 2 - 1], time_Y_r[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]});
            default : time_1_r <= 'd0; //扇区为0或7时表示为零矢量扇区，此时输出应为0
        endcase
        end else if (fsm_cs == FSM_DATA_MODULATION &&   data_modulation_valid_r) //数据校准完成
        time_1_r <= {svpwm_divider_tdata_w[47], svpwm_divider_tdata_w[31:17]};
    else
        time_1_r <= time_1_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_2_r <= 'd0;
    else if (fsm_cs == FSM_DUTY_CYCLE_CAL)
        begin
        case (sector_node_r)
            'd1:  time_2_r <= (^time_Y_r[(`DATA_WIDTH * 2 - 1) -: 2]) ? {time_Y_r[`DATA_WIDTH * 2 - 1], {(`DATA_WIDTH - 1){time_Y_r[`DATA_WIDTH * 2 - 2]}}} : {time_Y_r[`DATA_WIDTH * 2 - 1], time_Y_r[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]};
            'd2:  time_2_r <= 16'sd0 - time_X_r;
            'd3:  time_2_r <= time_X_r;
            'd4:  time_2_r = (^time_Z_r[(`DATA_WIDTH * 2 - 1) -: 2]) ? {time_Z_r[`DATA_WIDTH * 2 - 1], {(`DATA_WIDTH - 1){time_Z_r[`DATA_WIDTH * 2 - 2]}}} : {time_Z_r[`DATA_WIDTH * 2 - 1], time_Z_r[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]};
            'd5:  time_2_r = 16'sd0 - ((^time_Y_r[(`DATA_WIDTH * 2 - 1) -: 2]) ? {time_Y_r[`DATA_WIDTH * 2 - 1], {(`DATA_WIDTH - 1){time_Y_r[`DATA_WIDTH * 2 - 2]}}} : {time_Y_r[`DATA_WIDTH * 2 - 1], time_Y_r[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]});
            'd6:  time_2_r <= 16'sd0 - ((^time_Z_r[(`DATA_WIDTH * 2 - 1) -: 2]) ? {time_Z_r[`DATA_WIDTH * 2 - 1], {(`DATA_WIDTH - 1){time_Z_r[`DATA_WIDTH * 2 - 2]}}} : {time_Z_r[`DATA_WIDTH * 2 - 1], time_Z_r[(`DATA_WIDTH * 2 - 3) -: (`DATA_WIDTH - 1)]});
            default : time_2_r <= 'd0;
        endcase
        end else if (fsm_cs == FSM_DATA_MODULATION &&   data_modulation_valid_r) //数据校准完成
        time_2_r <= 16'sh7fff - {svpwm_divider_tdata_w[47], svpwm_divider_tdata_w[31:17]};
    else
        time_2_r <= time_2_r;
    end

//===========================================================================
//时间切换点计算
//===========================================================================
assign Time_a = (16'h7fff - time_1_r - time_2_r) >> 1;
assign Time_b = (16'h7fff + time_1_r - time_2_r) >> 1;
assign Time_c = (16'h7fff + time_1_r + time_2_r) >> 1;
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {Tcma_r, Tcmb_r, Tcmc_r} <= 'd0;
    else if (fsm_cs == FSM_SWITCHING_POINT_CAL)
        begin
        case (sector_node_r)
            'd1:{Tcma_r, Tcmb_r, Tcmc_r} <= {Time_b, Time_a, Time_c};
                'd2:{Tcma_r, Tcmb_r, Tcmc_r} <= {Time_a, Time_c, Time_b};
                'd3:{Tcma_r, Tcmb_r, Tcmc_r} <= {Time_a, Time_b, Time_c};
                'd4:{Tcma_r, Tcmb_r, Tcmc_r} <= {Time_c, Time_b, Time_a};
                'd5:{Tcma_r, Tcmb_r, Tcmc_r} <= {Time_c, Time_a, Time_b};
                'd6:{Tcma_r, Tcmb_r, Tcmc_r} <= {Time_b, Time_c, Time_a};
                default:{Tcma_r, Tcmb_r, Tcmc_r} <= {Time_a, Time_b, Time_c};
                endcase
        end else
            {Tcma_r, Tcmb_r, Tcmc_r} <= {Tcma_r, Tcmb_r, Tcmc_r};
        end
        //===========================================================================
        //数据计算完成标志
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            svpwm_cal_done_r <= 'd0;
        else if (fsm_cs == FSM_SWITCHING_POINT_CAL)
            svpwm_cal_done_r <= 'd1;
        else
            svpwm_cal_done_r <= 'd0;
    end
        //===========================================================================
        //数据校准除法器IP核调用
        //===========================================================================
        assign svpwm_divisor_w = time_1_r + time_2_r; //{{7{time_1_r[`DATA_WIDTH - 1]}}, time_1_r} + {{7{time_2_r[`DATA_WIDTH - 1]}}, time_2_r};
        assign svpwm_dividend_w = (time_1_r <<< 'd15) - time_1_r;
        svpwm_data_modulation_divider svpwm_data_modulation_divider_inst(
                                                                             .aclk(sys_clk),                                      // input wire aclk
                                                                             .aresetn(reset_n),                                // input wire aresetn
                                                                             .s_axis_divisor_tvalid(modulation_enable_r),    // input wire s_axis_divisor_tvalid
                                                                             .s_axis_divisor_tready(),
                                                                             .s_axis_divisor_tdata(({8'h00, time_1_r} + {8'h00, time_2_r})),      // input wire [23 : 0] s_axis_divisor_tdata
                                                                             .s_axis_dividend_tvalid(modulation_enable_r),  // input wire s_axis_dividend_tvalid
                                                                             .s_axis_dividend_tready(),
                                                                             .s_axis_dividend_tdata({time_1_r[`DATA_WIDTH - 1], time_1_r, 15'h00}),    // input wire [15 : 0] s_axis_dividend_tdata
                                                                             .m_axis_dout_tvalid(data_modulation_valid_r),          // output wire m_axis_dout_tvalid
                                                                             .m_axis_dout_tdata(svpwm_divider_tdata_w)            // output wire [31 : 0] m_axis_dout_tdata
    );

        //===========================================================================
        //数据校准使能信号
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            modulation_enable_r <= 'd0;
        else if ((fsm_cs == FSM_TIME_ARBITRATION) && (fsm_ns == FSM_DATA_MODULATION))
            modulation_enable_r <= 'd1;
        else
            modulation_enable_r <= 'd0;
    end
        //===========================================================================
        //输出信号赋值
        //===========================================================================
        assign  Tcma_out = Tcma_r;
        assign   Tcmb_out = Tcmb_r;
        assign   Tcmc_out = Tcmc_r;
        assign   svpwm_cal_done_out = svpwm_cal_done_r;
        endmodule
