//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/28
// Design Name:PMSM_DESIGN
// Module Name: svpwm_time_cal.v
// Target Device:
// Tool versions:
// Description:����SVPWM����PWM״̬�л���
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module svpwm_time_cal(
                      input        sys_clk,
                      input        reset_n,

                      input signed   [`DATA_WIDTH-1:0]      U_alpha_in,       //    Ualpha��ѹ����
                      input signed   [`DATA_WIDTH-1:0]      U_beta_in,         //    Ubeta��ѹ����
                      input              svpwm_cal_enable_in,                                //     SVPWM����ʹ��

                      output            [`DATA_WIDTH-1:0]      Tcma_out,               //      a�� ʱ���л���
                      output            [`DATA_WIDTH-1:0]      Tcmb_out,               //      b��ʱ���л���2
                      output            [`DATA_WIDTH-1:0]      Tcmc_out,               //      c��ʱ���л���3
                      output                                                      svpwm_cal_done_out   //  svpwm������ɱ�־
                      );

//===========================================================================
//�ڲ���������
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_DUTY_CYCLE_CAL=1<<1;          //ռ�ձȼ���
localparam FSM_TIME_ARBITRATION=1<<2;       //ʱ�䳬ʱ�ٲ��ж�
localparam FSM_DATA_MODULATION=1<<3;      //���ݵ���
localparam FSM_SWITCHING_POINT_CAL = 1 << 4; //�л������

//===========================================================================
//�ڲ���������
//===========================================================================
reg[2:0] sector_node_r,
    sector_node_r_ns;                 //�������Ĵ���������һ״̬
reg   signed[`DATA_WIDTH-1:0] time_X_r;     //X�Ĵ���
reg   signed[`DATA_WIDTH*2-1:0] time_Y_r; //Y�Ĵ��������ݸ�ʽ1Q30
reg   signed[`DATA_WIDTH*2-1:0] time_Z_r; //Z �Ĵ��������ݸ�ʽ1Q30
wire signed[`DATA_WIDTH*2:0]  time_Y_w,time_Z_w; // Y,Z�Ĵ����м���������棬2Q30
wire signed[`DATA_WIDTH*2-2:0]   U_beta_mul_sqrt_3_val;  //���ڴ��Ubeta/sqrt(3),���ݸ�ʽ��Q30
reg   signed[`DATA_WIDTH-1:0]    time_1_r;              //ʱ��t1�Ĵ���
reg   signed[`DATA_WIDTH-1:0]    time_2_r;              //ʱ��t2�Ĵ���
reg[`DATA_WIDTH-1:0]    Tcma_r;     //a��ʱ���л���Ĵ���
reg[`DATA_WIDTH-1:0]    Tcmb_r;     //b��ʱ���л���Ĵ���
reg[`DATA_WIDTH-1:0]    Tcmc_r;     //c��ʱ���л���Ĵ���

wire[`DATA_WIDTH-1:0]   Time_a,
    Time_b,
    Time_c;

reg   modulation_enable_r;   //У׼ʹ���ź�
wire signed [23:0]  svpwm_divisor_w;   //����У������
wire signed [31:0]  svpwm_dividend_w; //����У��������
wire[47:0]   svpwm_divider_tdata_w;     //[30:15]   quoitent,[14:0] fractional
wire data_modulation_valid_r;     //����У׼��ɱ�־
reg   svpwm_cal_done_r; //  svpwm���ݼ�����ɼĴ���
reg[4:0]    fsm_cs,
    fsm_ns;
//===========================================================================
//�����߼����
//===========================================================================
//״̬��״̬ת��
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
                if (svpwm_cal_enable_in) //����ת��
                    fsm_ns = FSM_DUTY_CYCLE_CAL;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DUTY_CYCLE_CAL:  //ռ�ձȼ���
            fsm_ns = FSM_TIME_ARBITRATION;
        FSM_TIME_ARBITRATION: begin    // ��ʱ�ٲ�
                if (time_1_r + time_2_r >= 17'sh07fff) //˵����ʱ
                    fsm_ns = FSM_DATA_MODULATION;
                else  //��������л������
                    fsm_ns = FSM_SWITCHING_POINT_CAL;
            end
        FSM_DATA_MODULATION: begin  //����У��
                if (data_modulation_valid_r)    //У����ɽ����л������
                    fsm_ns = FSM_SWITCHING_POINT_CAL;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_SWITCHING_POINT_CAL:    //�л������
            fsm_ns = FSM_IDLE;
        default :fsm_ns = FSM_IDLE;
    endcase
    end

//===========================================================================
//����λ���ж�
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        sector_node_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && svpwm_cal_enable_in)  //�ڿ���״̬���յ�svpwm����ʹ���ź�ʱ������������ж�
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
//X,Y,Zʱ��Ĵ����ļ���
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_X_r <= 'sd0;
    else if (fsm_cs == FSM_IDLE && svpwm_cal_enable_in)  //�ڿ���״̬���յ�svpwm����ʹ���ź�ʱ��ʱ��Ĵ�������
        time_X_r <= U_beta_in;
    else
        time_X_r <= time_X_r;
    end

always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_Y_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && svpwm_cal_enable_in)  //�ڿ���״̬���յ�svpwm����ʹ���ź�ʱ��ʱ��Ĵ�������
        time_Y_r <= time_Y_w[`DATA_WIDTH * 2 -: 32];
    else
        time_Y_r <= time_Y_r;
    end

assign time_Y_w = (((U_alpha_in <<< 'd16) - (U_alpha_in <<< 'd13)) - ((U_alpha_in <<< 'd9) + (U_alpha_in <<< 'd6))) - (((U_alpha_in <<< 'd4) - (U_alpha_in <<< 'd1)) - (U_beta_in <<< 'd15));

always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_Z_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && svpwm_cal_enable_in)  //�ڿ���״̬���յ�svpwm����ʹ���ź�ʱ��ʱ��Ĵ�������
        time_Z_r <= time_Z_w[`DATA_WIDTH * 2 -: 32];
    else
        time_Z_r <= time_Z_r;
    end

assign time_Z_w = (((U_alpha_in <<< 'd13) - (U_alpha_in <<< 'd16)) + ((U_alpha_in <<< 'd9) + (U_alpha_in <<< 'd6))) + (((U_alpha_in <<< 'd4) - (U_alpha_in <<< 'd1)) + (U_beta_in <<< 'd15));

//===========================================================================
//ռ�ձȼ���
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
            default : time_1_r <= 'd0; //����Ϊ0��7ʱ��ʾΪ��ʸ����������ʱ���ӦΪ0
        endcase
        end else if (fsm_cs == FSM_DATA_MODULATION &&   data_modulation_valid_r) //����У׼���
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
        end else if (fsm_cs == FSM_DATA_MODULATION &&   data_modulation_valid_r) //����У׼���
        time_2_r <= 16'sh7fff - {svpwm_divider_tdata_w[47], svpwm_divider_tdata_w[31:17]};
    else
        time_2_r <= time_2_r;
    end

//===========================================================================
//ʱ���л������
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
        //���ݼ�����ɱ�־
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
        //����У׼������IP�˵���
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
        //����У׼ʹ���ź�
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
        //����źŸ�ֵ
        //===========================================================================
        assign  Tcma_out = Tcma_r;
        assign   Tcmb_out = Tcmb_r;
        assign   Tcmc_out = Tcmc_r;
        assign   svpwm_cal_done_out = svpwm_cal_done_r;
        endmodule
