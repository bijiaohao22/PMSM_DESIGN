//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/18
// Design Name:PMSM_DESIGN
// Module Name: can_bus_app_unit.v
// Target Device:
// Tool versions:
// Description:  ͨѶӦ�ò����ʵ�֣������շ������ٲ�
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module can_bus_app_unit(
                        input    sys_clk,
                        input    reset_n,

                        output [31:0]   tx_dw1r_out,    //  ���ݷ�����1
                        output [31:0]   tx_dw2r_out,    //  ���ݷ�����2
                        output              tx_valid_out,   //  ������Ч��־
                        input                tx_ready_in,     //  ����׼��������

                        input   [31:0]   rx_dw1r_in,     //  ���ݽ�����1
                        input   [31:0]   rx_dw2r_in,     //  ���ݽ�����2
                        input               rx_valid_in,      //  ���ݽ�����Ч��־����
                        output             rx_ready_out,   //  ���ݽ���׼�������

                        output[`DATA_WIDTH-1:0]  current_rated_value_out,  //  �����ֵ���
                        output[`DATA_WIDTH-1:0]  speed_rated_value_out,  //  �ת��ֵ���

                        output [`DATA_WIDTH-1:0]    current_d_param_p_out,  //    ������d����Ʋ���p���
                        output [`DATA_WIDTH-1:0]    current_d_param_i_out,   //    ������d����Ʋ���i���
                        output [`DATA_WIDTH-1:0]    current_d_param_d_out,  //    ������d����Ʋ���d���

                        output [`DATA_WIDTH-1:0]    current_q_param_p_out,         //q�������P����
                        output [`DATA_WIDTH-1:0]    current_q_param_i_out,          //q�������I����
                        output [`DATA_WIDTH-1:0]    current_q_param_d_out,         //q�������D����

                        output  [`DATA_WIDTH-1:0]    speed_control_param_p_out,   //�ٶȱջ�����P����
                        output  [`DATA_WIDTH-1:0]    speed_control_param_i_out,   //�ٶȱջ�����I����
                        output  [`DATA_WIDTH-1:0]    speed_control_param_d_out,   //�ٶȱջ�����D����

                        output  [`DATA_WIDTH-1:0]    location_control_param_p_out,   //λ�ñջ�����P����
                        output  [`DATA_WIDTH-1:0]    location_control_param_i_out,   //λ�ñջ�����I����
                        output  [`DATA_WIDTH-1:0]    location_control_param_d_out,   //λ�ñջ�����D����

                        output[(`DATA_WIDTH/2)-1:0] band_breaks_mode_out,  //��բ����ģʽ���

                        output[(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode_out,   //�����ָͣ�����

                        output [(`DATA_WIDTH/4)-1:0] pmsm_work_mode_out,     //�������ģʽָ�����

                        output[`DATA_WIDTH-1:0]   pmsm_speed_set_value_out,   //  ���ת���趨ֵ���
                        output[(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value_out,    //���λ���趨ֵ���

                        input   [`DATA_WIDTH-1:0]    gate_driver_register_1_in,  //  դ���Ĵ���״̬1�Ĵ�������
                        input   [`DATA_WIDTH-1:0]    gate_driver_register_2_in,  //  դ���Ĵ���״̬2�Ĵ�������
                        input                                          gate_driver_error_in,          //դ���Ĵ������ϱ�������

                        input  [`DATA_WIDTH-1:0] current_detect_status_in,
                        input   channela_detect_err_in,    //current detect error triger
                        input   channelb_detect_err_in,   //current detect error triger
                        input signed[`DATA_WIDTH-1:0] phase_a_current_in,     //  a��������ֵ
                        input signed[`DATA_WIDTH-1:0] phase_b_current_in,    //  b��������ֵ
                        input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_in,   //  �����Ƕ�����ֵ����
                        input    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_in,  //  �����Ƕ�����ֵ����
                        input current_loop_control_enable_in,     //����������ʹ�����룬���ڴ������������Ƕ�ֵ�ϴ�

                        input signed   [`DATA_WIDTH-1:0]      U_alpha_in,       //    Ualpha��ѹ����
                        input signed   [`DATA_WIDTH-1:0]      U_beta_in,         //    Ubeta��ѹ����
                        input  current_loop_control_done_in,     //��ѹ�����Ч��־����

                        input [`DATA_WIDTH-1:0]   Tcma_in,    //  a ��ʱ���л������
                        input [`DATA_WIDTH-1:0]   Tcmb_in,    //   b��ʱ���л������
                        input [`DATA_WIDTH-1:0]   Tcmc_in,    //   c��ʱ���л������
                        input svpwm_cal_done_in,  //svpwm����������룬��������ʱ���л��������ϴ�

                        input    [`DATA_WIDTH-1:0]       speed_detect_val_in,      //ʵ���ٶȼ��ֵ
                        input    [`DATA_WIDTH-1:0]  current_q_set_val_in,    //Q������趨ֵ
                        input    speed_loop_cal_done_in,     //  �ٶȱջ���ɱ�־

                        input    [(`DATA_WIDTH*2+2)-1:0]pmsm_location_detect_value_in,   //λ�ü������
                        input    [`DATA_WIDTH-1:0]    speed_set_value_in,  //  λ��ģʽ�ٶ��趨ֵ����
                        input    pmsm_location_cal_done_in,   //λ�ñջ�������ɱ�־

                        input    [`DATA_WIDTH-1:0]    ds_18b20_temp_in,  //  �����¶�����
                        input    ds_18b20_update_done_in  //�����¶ȸ���ָ��
                        );
//===========================================================================
//�ڲ���������
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_RX_ACK=1<<1;
localparam FSM_GR=1<<2;    //  դ����������״̬�Ĵ����ϴ�
localparam FSM_CS=1<<3;    //  ����״̬��Ϣ�ϴ�
localparam FSM_EPT=1<<4;  //  ������ת�Ƕ������ҷ���
localparam FSM_CLC=1<<5; //  ���������Ʋ����ϴ�
localparam FSM_STSV=1<<6; // SVPWM�л�ʱ���ϴ�
localparam FSM_SLC=1<<7;  //  �ٶȻ����������ϴ�
localparam FSM_LLC=1<<8;  //  λ�û����������ϴ�
localparam FSM_DTV = 1 << 9; //  �������¶�ֵ�����ϴ�

localparam GR=0;
localparam CS=1;
localparam EPT=2;
localparam CLC=3;
localparam STSV=4;
localparam SLC=5;
localparam LLC=6;
localparam DTV=7;

localparam CSUR=1;        //Current and speed rated value update
localparam CDCV=1<<1; //  Current_d_control_param_value update
localparam CQCV=1<<2; //  Current q control param value update
localparam SPV=1<<3;     //  Speed param value update
localparam LPV=1<<4;     //  Location patam value update
localparam BBV=1<<5;    //Band break value update
localparam MMV=1<<6;  //  Motor mode value update;
localparam MWV=1<<7; //  Motor work mode value update

localparam CSUR_ADDR=8'h01;
localparam CDCV_ADDR=8'h02;
localparam CQCV_ADDR=8'h03;
localparam SPV_ADDR=8'h04;
localparam LPV_ADDR=8'h05;
localparam BBV_ADDR=8'h06;
localparam MMV_ADDR=8'h07;
localparam MWV_ADDR=8'h08;

//===========================================================================
//�ڲ���������
//===========================================================================
reg[9:0]   fsm_cs,
    fsm_ns;    //  ����״̬����ǰ״̬������һ״̬
reg[31:0]   rx_state_r;            //  ����״̬�Ĵ���
reg[31:0]   tx_state_r;            //  ����״̬�Ĵ���

reg[31:0]   tx_dw1r_r;    //  ���ݷ�����1
reg[31:0]   tx_dw2r_r;   //  ���ݷ�����2
reg              tx_valid_r;  //  ������Ч��־

reg             rx_ready_r;   //  ���ݽ���׼�������

reg[`DATA_WIDTH-1:0]  current_rated_value_r;  //  �����ֵ���
reg[`DATA_WIDTH-1:0]  speed_rated_value_r;    //  �ת��ֵ���

reg[`DATA_WIDTH-1:0]    current_d_param_p_r;  //    ������d����Ʋ���p���
reg[`DATA_WIDTH-1:0]    current_d_param_i_r;   //    ������d����Ʋ���i���
reg[`DATA_WIDTH-1:0]    current_d_param_d_r;  //    ������d����Ʋ���d���

reg[`DATA_WIDTH-1:0]    current_q_param_p_r;         //q�������P����
reg[`DATA_WIDTH-1:0]    current_q_param_i_r;          //q�������I����
reg[`DATA_WIDTH-1:0]    current_q_param_d_r;        //q�������D����

reg[`DATA_WIDTH-1:0]    speed_control_param_p_r;   //�ٶȱջ�����P����
reg[`DATA_WIDTH-1:0]    speed_control_param_i_r;   //�ٶȱջ�����I����
reg[`DATA_WIDTH-1:0]    speed_control_param_d_r;   //�ٶȱջ�����D����

reg[`DATA_WIDTH-1:0]    location_control_param_p_r;   //λ�ñջ�����P����
reg[`DATA_WIDTH-1:0]    location_control_param_i_r;   //λ�ñջ�����I����
reg[`DATA_WIDTH-1:0]    location_control_param_d_r;   //λ�ñջ�����D����

reg[(`DATA_WIDTH/2)-1:0] band_breaks_mode_r;  //��բ����ģʽ���

reg[(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode_r;   //�����ָͣ�����

reg[(`DATA_WIDTH/4)-1:0] pmsm_work_mode_r;     //�������ģʽָ�����

reg[`DATA_WIDTH-1:0]   pmsm_speed_set_value_r;   //  ���ת���趨ֵ���
reg[(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value_r;    //���λ���趨ֵ���

wire[7:0] rx_db0,
    rx_db1,
    rx_db2,
    rx_db3,
    rx_db4,
    rx_db5,
    rx_db6,
    rx_db7;  //���ݽ�������

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
always @(*)
    begin
    case (fsm_cs)
        FSM_IDLE: begin
                if (rx_state_r != 'd0)    // ���ȴ�����գ�������״̬�Ĵ�����Ϊ0����������ݽ��գ�������Ӧ֡
                    fsm_ns = FSM_RX_ACK;
                else begin  //���������Ƿ��з�������
                    if (tx_state_r[GR])
                        fsm_ns = FSM_GR;
                    else if (tx_state_r[CS])
                        fsm_ns = FSM_CS;
                    else if (tx_state_r[EPT])
                        fsm_ns = FSM_EPT;
                    else if (tx_state_r[CLC])
                        fsm_ns = FSM_CLC;
                    else if (tx_state_r[STSV])
                        fsm_ns = FSM_STSV;
                    else if (tx_state_r[SLC])
                        fsm_ns = FSM_SLC;
                    else if (tx_state_r[LLC])
                        fsm_ns = FSM_LLC;
                    else if (tx_state_r[DTV])
                        fsm_ns = FSM_DTV;
                    else
                        fsm_ns = fsm_cs;
                end
            end
        FSM_RX_ACK,
                FSM_GR,
                FSM_CS,
                FSM_EPT,
                FSM_CLC,
                FSM_STSV,
                FSM_SLC,
                FSM_LLC,
                FSM_DTV: begin  //�յ��²㷢��׼���ñ�־����״̬�Ĵ������ݸ��¡�
                if (tx_ready_in)
                        fsm_ns = FSM_IDLE;
                else
                    fsm_ns = fsm_cs;
                end
        default :fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//���ݶ�����
//===========================================================================
assign rx_db0 = rx_dw1r_in[31:24];
assign rx_db1 = rx_dw1r_in[23:16];
assign rx_db2 = rx_dw1r_in[15:8];
assign rx_db3 = rx_dw1r_in[7:0];
assign rx_db4 = rx_dw2r_in[31:24];
assign rx_db5 = rx_dw2r_in[23:16];
assign rx_db6 = rx_dw2r_in[15:8];
assign rx_db7 = rx_dw2r_in[7:0];
//�����ֵ����
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_rated_value_r <= 'd0;
    else if (rx_valid_in && rx_ready_r && (rx_db0 == CSUR_ADDR))
        current_rated_value_r <= {rx_db1, rx_db2};
    else
        current_rated_value_r <= current_rated_value_r;
    end
//ת�ٶֵ���
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        speed_rated_value_r <= 'd0;
    else if (rx_valid_in && rx_ready_r && (rx_db0 == CSUR_ADDR))
        speed_rated_value_r <= {rx_db3, rx_db4};
    else
        speed_rated_value_r <= speed_rated_value_r;
    end
//����d����Ʋ���ע��
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        current_d_param_p_r <= 'd0;
        current_d_param_i_r <= 'd0;
        current_d_param_d_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == CDCV_ADDR))
        begin
        current_d_param_p_r <= {rx_db1, rx_db2};
        current_d_param_i_r <= {rx_db3, rx_db4};
        current_d_param_d_r <= {rx_db5, rx_db6};
        end else
        begin
        current_d_param_p_r <= current_d_param_p_r;
        current_d_param_i_r <= current_d_param_i_r;
        current_d_param_d_r <= current_d_param_d_r;
        end
    end
//����q����Ʋ���ע��
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        current_q_param_p_r <= 'd0;
        current_q_param_i_r <= 'd0;
        current_q_param_d_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == CQCV_ADDR))
        begin
        current_q_param_p_r <= {rx_db1, rx_db2};
        current_q_param_i_r <= {rx_db3, rx_db4};
        current_q_param_d_r <= {rx_db5, rx_db6};
        end else
        begin
        current_q_param_p_r <= current_q_param_p_r;
        current_q_param_i_r <= current_q_param_i_r;
        current_q_param_d_r <= current_q_param_d_r;
        end
    end
//ת�ٻ����Ʋ���ע��
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        speed_control_param_p_r <= 'd0;
        speed_control_param_i_r <= 'd0;
        speed_control_param_d_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == SPV_ADDR))
        begin
        speed_control_param_p_r <= {rx_db1, rx_db2};
        speed_control_param_i_r <= {rx_db3, rx_db4};
        speed_control_param_d_r <= {rx_db5, rx_db6};
        end else
        begin
        speed_control_param_p_r <= speed_control_param_p_r;
        speed_control_param_i_r <= speed_control_param_i_r;
        speed_control_param_d_r <= speed_control_param_d_r;
        end
    end
//λ�û����Ʋ���ע��
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        location_control_param_p_r <= 'd0;
        location_control_param_i_r <= 'd0;
        location_control_param_d_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == LPV_ADDR))
        begin
        location_control_param_p_r <= {rx_db1, rx_db2};
        location_control_param_i_r <= {rx_db3, rx_db4};
        location_control_param_d_r <= {rx_db5, rx_db6};
        end else
        begin
        location_control_param_p_r <= location_control_param_p_r;
        location_control_param_i_r <= location_control_param_i_r;
        location_control_param_d_r <= location_control_param_d_r;
        end
    end
//��բ����ָ��ע��
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        band_breaks_mode_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == BBV_ADDR))
        begin
        band_breaks_mode_r <= rx_db1;
        end else
        begin
        band_breaks_mode_r <= band_breaks_mode_r;
        end
    end
//���ͣ��ָ��ע��
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pmsm_start_stop_mode_r <= 'd0;
    else if (rx_valid_in && rx_ready_r && (rx_db0 == MMV_ADDR))
        pmsm_start_stop_mode_r <= rx_db1;
    else
        pmsm_start_stop_mode_r <= pmsm_start_stop_mode_r;
    end
//�������ģʽע��
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        pmsm_work_mode_r <= 'd0; //Ĭ�Ϲ������ٶ�ģʽ��
        pmsm_speed_set_value_r <= 'd0;
        pmsm_location_set_value_r <= 'd0;
        end else if (rx_valid_in && rx_ready_r && (rx_db0 == MWV_ADDR))
        begin
        pmsm_work_mode_r <= rx_db1[7:4]; //Ĭ�Ϲ������ٶ�ģʽ��
        pmsm_speed_set_value_r <= {rx_db2, rx_db3};
        pmsm_location_set_value_r <= {rx_db4, rx_db5, rx_db1[1:0], rx_db6, rx_db7};
        end else
        begin
        pmsm_work_mode_r <= pmsm_work_mode_r; //Ĭ�Ϲ������ٶ�ģʽ��
        pmsm_speed_set_value_r <= pmsm_speed_set_value_r;
        pmsm_location_set_value_r <= pmsm_location_set_value_r;
        end
    end
//===========================================================================
//����״̬�Ĵ�����ֵ
//===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            rx_state_r <= 'd0;
        else if (rx_valid_in && rx_ready_r)
            begin
            case (rx_db0)
                CSUR_ADDR:rx_state_r <= rx_state_r | (32'h1 << 0);
                CDCV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 1);
                CQCV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 2);
                SPV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 3);
                LPV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 4);
                BBV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 5);
                MMV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 6);
                MWV_ADDR:rx_state_r <= rx_state_r | (32'h1 << 7);
                default:rx_state_r <= rx_state_r;
            endcase
            end else if ((fsm_cs == FSM_IDLE) && (rx_state_r != 'd0))  //Ӧ��֡����,�����Ӧ��־λ
            begin
            if (rx_state_r[0]) //  ������ת��ָ����Ӧ
                rx_state_r <= rx_state_r & (~32'h1);
            else if (rx_state_r[1])
                rx_state_r <= rx_state_r & (~32'h2); //����d�����Ʋ���ָ��ע��
            else if (rx_state_r[2])
                rx_state_r <= rx_state_r & (~32'h4); //����q�����Ʋ���ָ��ע��
            else if (rx_state_r[3])
                rx_state_r <= rx_state_r & (~32'h8); //�ٶȻ����Ʋ���ָ��ע����Ӧ
            else if (rx_state_r[4])
                rx_state_r <= rx_state_r & (~32'd16); //λ�û����Ʋ���ָ��ע����Ӧ
            else if (rx_state_r[5])
                rx_state_r <= rx_state_r & (~32'd32); //��բ����ָ�����ָ����Ӧ
            else if (rx_state_r[6])
                rx_state_r <= rx_state_r & (~32'd64); //�����ָͣ��ע��
            else if (rx_state_r[7])
                rx_state_r <= rx_state_r & (~32'd128); //�������ģʽָ��ע����Ӧ
            else
                rx_state_r <= rx_state_r;
            end else
            rx_state_r <= rx_state_r;
        end
//===========================================================================
//����״̬�Ĵ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        tx_state_r <= 32'd0;
    else if(fsm_cs==FSM_IDLE)
        begin
             if (gate_driver_error_in) //դ��������������
        tx_state_r <= tx_state_r | (32'h1 << 0);
    //else if (current_loop_control_enable_in) //ʹ�ܵ����ջ����Ƽ�����ϴ����������Ϣ��������ת��������ֵ
    //    tx_state_r <= tx_state_r | (32'h6);
    else if (channela_detect_err_in || channelb_detect_err_in||current_loop_control_done_in)
        tx_state_r <= tx_state_r | (32'h1 << 1);
    //else if (current_loop_control_done_in) //�����ջ�������ɺ�����ϴ�����
    //    tx_state_r <= tx_state_r | (32'h1 << 3);
    //else if (svpwm_cal_done_in)
    //    tx_state_r <= tx_state_r | (32'h1 << 4);
    else if (speed_loop_cal_done_in)
        tx_state_r <= tx_state_r | (32'h1 << 5);
    else if (pmsm_location_cal_done_in)
        tx_state_r <= tx_state_r | (32'h1 << 6);
    else if (ds_18b20_update_done_in)
        tx_state_r <= tx_state_r | (32'h1 << 7);
    else
        tx_state_r<=tx_state_r;
        end
    else
        begin
        case (fsm_cs)  
            FSM_GR:tx_state_r <= (tx_state_r & (~32'h1))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_CS:tx_state_r <= (tx_state_r & (~32'h2))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_EPT:tx_state_r <=( tx_state_r & (~32'h4))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_CLC:tx_state_r <= (tx_state_r & (~32'h8))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_STSV:tx_state_r <= (tx_state_r & (~32'd16))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_SLC:tx_state_r <= (tx_state_r & (~32'd32))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_LLC:tx_state_r <= (tx_state_r & (~32'd64))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            FSM_DTV:tx_state_r <=( tx_state_r & (~32'd128))|({24'd0,ds_18b20_update_done_in, pmsm_location_cal_done_in,  speed_loop_cal_done_in, svpwm_cal_done_in,  current_loop_control_done_in,current_loop_control_enable_in,(current_loop_control_enable_in||channela_detect_err_in || channelb_detect_err_in),gate_driver_error_in});
            default :tx_state_r <= tx_state_r;
        endcase
        end
    end
//===========================================================================
//���ݷ��͸�ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {tx_dw1r_r, tx_dw2r_r} <= 'd0;
    else if ((fsm_cs == FSM_IDLE) && (rx_state_r != 'd0))
        begin
        if (rx_state_r[0])    //�������ת��ָ����Ӧ
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h01,  8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[1])   //����d��ָ��ע����Ӧ
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h02,8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[2])    //����q��ָ��ע����Ӧ
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h03, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[3])    //ת�ٻ����Ʋ���ָ��ע����Ӧ
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h04, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[4])    //λ�û����Ʋ���ָ��ע����Ӧ
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h05, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[5])    //��բ����ָ��ע����Ӧ
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h06, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[6])    //�����ָͣ��ע����Ӧ
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h07,8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else if (rx_state_r[7])    //�������ģʽָ��ע����Ӧ
            {tx_dw1r_r, tx_dw2r_r} <= {8'hff,8'h08,8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
        else
        {tx_dw1r_r, tx_dw2r_r} <= {tx_dw1r_r, tx_dw2r_r};
        end else
        case (fsm_cs)
            FSM_GR:{tx_dw1r_r, tx_dw2r_r} <= {8'h81, gate_driver_register_1_in, gate_driver_register_2_in, 8'h00, 8'h00, 8'h00};
                FSM_CS: {tx_dw1r_r, tx_dw2r_r} <= {8'h82, phase_a_current_in, phase_b_current_in, current_detect_status_in, 8'h00};
    FSM_EPT: {tx_dw1r_r, tx_dw2r_r} <= {8'h83, electrical_rotation_phase_sin_in, electrical_rotation_phase_cos_in, 8'h00, 8'h00, 8'h00};
    FSM_CLC: {tx_dw1r_r, tx_dw2r_r} <= {8'h84, U_alpha_in, U_beta_in, 8'h00, 8'h00, 8'h00};
    FSM_STSV: {tx_dw1r_r, tx_dw2r_r} <= {8'h85, Tcma_in, Tcmb_in, Tcmc_in, 8'h00};
    FSM_SLC: {tx_dw1r_r, tx_dw2r_r} <= {8'h86, speed_detect_val_in, current_q_set_val_in, 8'h00, 8'h00, 8'h00};
    FSM_LLC: {tx_dw1r_r, tx_dw2r_r} <= {8'h87, pmsm_location_detect_value_in[33:18], 6'h00, pmsm_location_detect_value_in[17:0], speed_set_value_in};
    FSM_DTV: {tx_dw1r_r, tx_dw2r_r} <= {8'h88, ds_18b20_temp_in, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
    default :{tx_dw1r_r, tx_dw2r_r} <= {tx_dw1r_r, tx_dw2r_r};
    endcase
end
    //===========================================================================
    //������Ч��־
    //===========================================================================
    always @(posedge sys_clk or  negedge reset_n) 
    begin
    if (!reset_n)
        tx_valid_r <= 'd0;
    else if (fsm_cs != FSM_IDLE)
        tx_valid_r <= 'd1;
    else
        tx_valid_r <= 'd0;
   end
//===========================================================================
//����׼���ñ�־
//===========================================================================
always @(posedge sys_clk or  negedge reset_n) 
    begin
        if (!reset_n)
            rx_ready_r<='d0;
        else if (rx_valid_in)   
             rx_ready_r<='d0;
        else
            rx_ready_r<='d1;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign tx_dw1r_out=tx_dw1r_r;
assign tx_dw2r_out=tx_dw2r_r;
assign tx_valid_out=tx_valid_r;
assign rx_ready_out=rx_ready_r;
assign current_rated_value_out=current_rated_value_r;
assign speed_rated_value_out=speed_rated_value_r;
assign current_d_param_p_out=current_d_param_p_r;
assign current_d_param_i_out=current_d_param_i_r;
assign current_d_param_d_out=current_d_param_d_r;
assign current_q_param_p_out=current_q_param_p_r;   
assign current_q_param_i_out= current_q_param_i_r ;  
assign current_q_param_d_out=current_q_param_d_r;
assign speed_control_param_p_out=speed_control_param_p_r; 
assign speed_control_param_i_out =speed_control_param_i_r; 
assign speed_control_param_d_out=speed_control_param_d_r;
assign location_control_param_p_out=location_control_param_p_r;
assign location_control_param_i_out= location_control_param_i_r;
assign location_control_param_d_out=location_control_param_d_r;
assign  band_breaks_mode_out=band_breaks_mode_r;
assign pmsm_start_stop_mode_out=pmsm_start_stop_mode_r;
assign pmsm_work_mode_out=pmsm_work_mode_r;
assign pmsm_speed_set_value_out=pmsm_speed_set_value_r;
assign pmsm_location_set_value_out=pmsm_location_set_value_r;
    endmodule
