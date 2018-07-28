//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/24
// Design Name:PMSM_DESIGN
// Module Name: system_control_unit.v
// Target Device:
// Tool versions:
// Description:ϵͳȫ�ֵ��ȣ�ʵʱ���ϵͳ����
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module system_control_unit(
                           input    sys_clk,
                           input    reset_n,

                           //λ��ģʽ����
                           output    location_loop_control_enable_out,    //  λ�ÿ���ʹ�����
                           output    location_detection_enable_out,          //  λ�ü��ʹ�����

                           //�������
                           output    current_enable_out , //detect_enable signale
                           input channela_detect_done_in,    //channel a detect done signal in
                           input channelb_detect_done_in,    //channel b detect done signal in
                           input  channela_detect_err_in,       //current detect error triger
                           input  channelb_detect_err_in,     //current detect error triger
                           input [`DATA_WIDTH-1:0] current_detect_status_out,

                           //�����ջ�����
                           output    current_loop_control_enable_out,      //����ʹ�����룬high-active

                           //դ������������
                           output    gate_driver_init_enable_out,  //  դ���������ϵ��λ���ʼ��ʹ��
                           input  gate_driver_init_done_in,  //  դ����������ʼ����ɱ�־
                           input  gate_driver_error_in,   //դ���Ĵ������ϱ������룬�ߵ�ƽ��Ч

                           //ת�����Ƕȼ���
                           output     electrical_rotation_phase_forecast_enable_out,

                           //can����
                           output    can_init_enable_out,    //   can��ʼ��ʹ�ܱ�־
                           input  can_init_done_in,    //    can��ʼ����ɱ�־
                           input [(`DATA_WIDTH/2)-1:0] band_breaks_mode_in,  //��բ����ģʽ����
                           input [(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode_in,   //�����ָͣ������
                           input [(`DATA_WIDTH/4)-1:0] pmsm_work_mode_in,     //�������ģʽָ������

                           //դ��������
                           output    emergency_stop_out,                            //   ����ͣ��ָ����ڵ�����դ�������������쳣ʱֹͣ���У��ߵ�ƽ��Ч

                           //�ٶȱջ�����
                           output    speed_control_enable_out,    //�ٶȿ���ʹ���ź�
                           //ϵͳ��ʼ����ɱ�־
                           output    system_initilization_done_out              //  ϵͳ��ʼ���������,�ߵ�ƽ��Ч
                           );
//===========================================================================
//�ڲ���������
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_INIT=1<<1; //  ϵͳ��ʼ��
localparam FSM_MOTOR_AWAIT=1<<2;    //  �������
localparam FSM_MOTOR_NORMAL=1<<3;    //  �������
localparam FSM_MOTOR_EXCPE=1<<4;        //   �쳣����

localparam TIME_1_MS_NUM = 1_000_000 / `SYS_CLK_PERIOD;
//===========================================================================
//�ڲ���������
//===========================================================================
reg[4:0]    fsm_cs,
    fsm_ns;
reg[$clog2(100)-1:0]   time_100ms_cnt_r;   //100ms������
reg[$clog2(TIME_1_MS_NUM)-1:0]  time_1ms_cnt_r;  //1ms������
reg[$clog2(10)-1:0] time_10ms_cnt_r; //  10ms������
reg can_transaction_init_done_r;  //  can���߳�ʼ����ɱ�־

reg  location_loop_control_enable_r;    //  λ�ÿ���ʹ�����
reg  location_detection_enable_r;          //  λ�ü��ʹ�����
reg  current_enable_r;                       //current detect_enable signale
reg  current_loop_control_enable_r; //  �����ջ�����ʹ�����
reg  gate_driver_init_enable_r;         //   դ���������ϵ��λ���ʼ��ʹ��
reg  electrical_rotation_phase_forecast_enable_r;  //ת�����Ƕ�Ԥ��ʹ��
reg  can_init_enable_r;                     //   can���߳�ʼ��ʹ��
reg   emergency_stop_r;                   //   ����ͣ��ָ����ڵ�����դ�������������쳣ʱֹͣ���У��ߵ�ƽ��Ч
reg   speed_control_enable_r;           //  �ٶȿ���ʹ��
reg   system_initilization_done_r;     //  ϵͳ��ʼ����ɱ�־�Ĵ���

//===========================================================================
//����״̬��״̬ת��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        fsm_cs <= FSM_IDLE;
    else
        fsm_cs <= fsm_ns;
    end
always@(*)
    begin
    case (fsm_cs)
        FSM_IDLE: begin    //  �ӳ�100ms�����ʼ��״̬
                if ((time_1ms_cnt_r == TIME_1_MS_NUM - 1'b1) && (time_100ms_cnt_r == 'd99))
                    fsm_ns = FSM_INIT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_INIT: begin
                if (can_transaction_init_done_r && gate_driver_init_done_in)    //դ����������can���߳�ʼ����ɺ����������״̬
                    fsm_ns = FSM_MOTOR_AWAIT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_MOTOR_AWAIT: begin    //�յ������������ұ�բ�رգ�����ģʽѡ�����������������״̬
                if ((band_breaks_mode_in == `BAND_BREAK_CLOSE) && (pmsm_start_stop_mode_in == `MOTOR_START_CMD) && (pmsm_work_mode_in == `MOTOR_SPEED_MODE || pmsm_work_mode_in == `MOTOR_LOCATION_MODE))
                    fsm_ns = FSM_MOTOR_NORMAL;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_MOTOR_NORMAL:    begin
                if (pmsm_start_stop_mode_in == `MOTOR_STOP_CMD)    //�յ�����ػ�ָ������������״̬
                    fsm_ns = FSM_MOTOR_AWAIT;
                else if (channela_detect_err_in || channelb_detect_err_in || gate_driver_error_in) //��⵽������ֵ��դ�����������������쳣����״̬
                    fsm_ns = FSM_MOTOR_EXCPE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_MOTOR_EXCPE: begin
                if (pmsm_start_stop_mode_in == `MOTOR_STOP_CMD)    //�յ�����ػ�ָ������������״̬
                    fsm_ns = FSM_MOTOR_AWAIT;
                else if ((current_detect_status_out == 'd0) && (~gate_driver_error_in)) //�����쳣�������ʧ���������������ģʽ
                    fsm_ns = FSM_MOTOR_NORMAL;
                else
                    fsm_ns = fsm_cs;
            end
        default:fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//1ms��������ֵ
//�������������ڣ�������������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_1ms_cnt_r <= 'd0;
    else if (fsm_cs != fsm_ns)
        time_1ms_cnt_r <= 'd0;
    else if (fsm_cs == FSM_IDLE || fsm_cs == FSM_MOTOR_EXCPE || fsm_cs == FSM_MOTOR_NORMAL)
        begin
        if (time_1ms_cnt_r == TIME_1_MS_NUM - 1)
            time_1ms_cnt_r <= 'd0;
        else
            time_1ms_cnt_r <= time_1ms_cnt_r + 1'b1;
        end else
        time_1ms_cnt_r <= 'd0;
    end
//===========================================================================
//10ms������
//�ٶȻ�,λ�û���������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_10ms_cnt_r <= 'd0;
    else if (fsm_cs == FSM_MOTOR_NORMAL)
        begin
        if ((time_10ms_cnt_r == 'd9) && (time_1ms_cnt_r == TIME_1_MS_NUM - 1))
            time_10ms_cnt_r <= 'd0;
        else if (time_1ms_cnt_r == TIME_1_MS_NUM - 1)
            time_10ms_cnt_r <= time_10ms_cnt_r + 1'b1;
        else
            time_10ms_cnt_r <= time_10ms_cnt_r;
        end else
        time_10ms_cnt_r <= 'd0;
    end
//===========================================================================
//100ms������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_100ms_cnt_r <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        begin
        if (time_1ms_cnt_r == TIME_1_MS_NUM - 1'b1)
            time_100ms_cnt_r <= time_100ms_cnt_r + 1'b1;
        else
            time_100ms_cnt_r <= time_100ms_cnt_r;
        end else
        time_100ms_cnt_r <= 'd0;
    end
//===========================================================================
//can���߳�ʼ����ɱ�־�Ĵ�
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        can_transaction_init_done_r <= 'd0;
    else if ((fsm_cs == FSM_INIT) && can_init_done_in)
        can_transaction_init_done_r <= 'd1;
    else
        can_transaction_init_done_r <= can_transaction_init_done_r;
    end
//===========================================================================
//λ�ÿ���ʹ�����
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        location_loop_control_enable_r <= 'd0;
    else if ((pmsm_work_mode_in == `MOTOR_LOCATION_MODE) && ((time_10ms_cnt_r == 'd3) && (time_1ms_cnt_r == TIME_1_MS_NUM - 1)))   //4ms��
        location_loop_control_enable_r <= 1'b1;
    else
        location_loop_control_enable_r <= 'b0;
    end
//===========================================================================
//λ�ü��ʹ��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        location_detection_enable_r <= 'd0;
    else if ((pmsm_work_mode_in == `MOTOR_LOCATION_MODE) && ((time_10ms_cnt_r == 'd3) && (time_1ms_cnt_r == (TIME_1_MS_NUM * 9 / 10) - 1)))   //3.9ms
        location_detection_enable_r <= 'd1;
    else
        location_detection_enable_r <= 'd0;
    end
//===========================================================================
//�������ʹ��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_enable_r <= 'd0;
    else if ((fsm_cs == FSM_MOTOR_EXCPE || fsm_cs == FSM_MOTOR_NORMAL) && (time_1ms_cnt_r == (TIME_1_MS_NUM * 9 / 10) - 1)) //0.9ms
        current_enable_r <= 'd1;
    else
        current_enable_r <= 'd0;
    end
//===========================================================================
//�����ջ�����ʹ�����
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_loop_control_enable_r <= 'd0;
    else if ((fsm_cs == FSM_MOTOR_NORMAL) && (time_1ms_cnt_r == TIME_1_MS_NUM  - 1))
        current_loop_control_enable_r <= 'd1;
    else
        current_loop_control_enable_r <= 'd0;
    end
//===========================================================================
//դ����������ʼ��ʹ��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_init_enable_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && (fsm_cs != fsm_ns))
        gate_driver_init_enable_r <= 'd1;
    else
        gate_driver_init_enable_r <= 'd0;
    end
//===========================================================================
//��Ƕ�Ԥ��ʹ��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        electrical_rotation_phase_forecast_enable_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && (fsm_cs != fsm_ns))
        electrical_rotation_phase_forecast_enable_r <= 'd1;
    else
        electrical_rotation_phase_forecast_enable_r <= 'd0;
    end
//===========================================================================
//can���߳�ʼ��ʹ��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        can_init_enable_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && (fsm_cs != fsm_ns))
        can_init_enable_r <= 'd1;
    else
        can_init_enable_r <= 'd0;
    end
//===========================================================================
// ����ͣ��ָ����ڵ�����դ�������������쳣ʱֹͣ���У��ߵ�ƽ��Ч
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        emergency_stop_r <= 'd0;
    else if (fsm_cs == FSM_MOTOR_EXCPE)
        emergency_stop_r <= 'd1;
    else
        emergency_stop_r <= 'd0;
    end
//===========================================================================
//�ٶȿ���ʹ��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_control_enable_r <= 'd0;
    else if ((fsm_cs == FSM_MOTOR_NORMAL) && ((time_10ms_cnt_r == 'd4) && (time_1ms_cnt_r == TIME_1_MS_NUM - 1)))
        speed_control_enable_r <= 'd1;
    else
        speed_control_enable_r <= 'd0;
    end
//===========================================================================
//ϵͳ��ʼ����ɱ�־
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        system_initilization_done_r <= 'd0;
    else if ((fsm_cs == FSM_INIT) && (fsm_cs != fsm_ns))
        system_initilization_done_r <= 'd1;
    else
        system_initilization_done_r <= system_initilization_done_r;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign location_loop_control_enable_out=location_loop_control_enable_r;
assign location_detection_enable_out=location_detection_enable_r;
assign current_enable_out=current_enable_r;
assign current_loop_control_enable_out=current_loop_control_enable_r;
assign gate_driver_init_enable_out=gate_driver_init_enable_r;
assign electrical_rotation_phase_forecast_enable_out=electrical_rotation_phase_forecast_enable_r;
assign can_init_enable_out=can_init_enable_r;
assign emergency_stop_out=emergency_stop_r;
assign speed_control_enable_out=speed_control_enable_r;
assign system_initilization_done_out=system_initilization_done_r;
endmodule
