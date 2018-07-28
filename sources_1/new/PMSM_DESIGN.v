`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: li-xiaochuang
// Create Date: 2018/3/13
// Design Name:PMSM_DESIGN
// Module Name: PMSM_DESIGN.v
// Target Device:
// Tool versions:vivado 2015.4
// Description: TOP_DESIGN
// Dependencies:
// Revision:1.00
// Additional Comments:
//====================================================================================
`include "project_param.v"
module PMSM_DESIGN(
                   input        clk_50MHz_in,                //global clock input ,50MHz
                   input        reset_n_in,                            //reset signal ,low-active

                   //hall signal input
                   input        hall_u_in,
                   input        hall_v_in,
                   input        hall_w_in,

                   //incremental encoder input
                   input        heds_9040_ch_a_in,
                   input        heds_9040_ch_b_in,
                   input        heds_9040_ch_i_in,

                   //absolute encoder input port
                   input        vlx_data_in,
                   output      vlx_clk_out,

                   //current_sensor input port
                   input        current_u_data_in,
                   input        current_u_ocd,
                   output      current_u_cs_n_out,
                   output      current_u_clk_out,

                   input        current_v_data_in,
                   input        current_v_ocd,
                   output      current_v_cs_n_out,
                   output      current_v_clk_out,

                   //mosfet gate driver output
                   output      drv8320s_inh_a_out,       //phase a high side mosfet  gate driver
                   output      drv8320s_inl_a_out,        //phase a low side mosfet  gate driver
                   output      drv8320s_inh_b_out,       //phase b high side mosfet  gate driver
                   output      drv8320s_inl_b_out,        //phase b low side mosfet  gate driver
                   output      drv8320s_inh_c_out,       //phase c high side mosfet  gate driver
                   output      drv8320s_inl_c_out,        //phase c low side mosfet  gate driver

                   output      drv8320_enable_out,
                   output      drv8320s_nscs_out,
                   output      drv8320s_clk_out,
                   output      drv8320s_sdi_out,
                   input        drv8320s_sdo_in,
                   input        drc8320s_nfault,

                   //Band Brake output (emergency cutoff)
                   output     band_brake_out,

                   //can���߽ӿ�
                   input       can_rx_in,
                   output     can_tx_out
                   );
//===========================================================================
//�ڲ���������
//===========================================================================
wire     sys_clk;    //  ȫ��ʱ�ӣ�50MHz
wire     can_phy_clk;    //can���������ʱ�ӣ�20MHz
wire     clk_gen_locked;   //ʱ�������ź�
wire     reset_n;                //   ȫ�ָ�λ�źţ��͵�ƽ��Ч

wire [`DATA_WIDTH-1:0]  pmsm_reated_current; //  �����ֵ��*10��
wire [`DATA_WIDTH-1:0]  pmsm_rated_speed;    //  �ת��

//ϵͳ���ȿ���ģ�鵥Ԫ����
wire location_loop_control_enable;
wire location_detection_enable;
wire current_loop_control_enable;
wire gate_driver_init_enable;
wire gate_driver_init_done;
wire electrical_rotation_phase_forecast_enable;
wire can_init_enable;
wire emergency_stop;
wire speed_control_enable;
wire system_initilization_done;

//ת���������ת�ǶȲ�����Ԫ
wire [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin;
wire [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos;
wire  [`DATA_WIDTH-1:0]  standardization_detect_speed;   //ת�ٲ������

//  ������ⵥԪ
wire [`DATA_WIDTH-1:0] current_detect_status;
wire [`DATA_WIDTH-1:0] phase_a_current;
wire [`DATA_WIDTH-1:0] phase_b_current;
wire current_enable;
wire channela_detect_done;
wire channelb_detect_done;
wire channela_detect_err;
wire channelb_detect_err;

//�����ջ�����
wire [`DATA_WIDTH-1:0]    current_d_param_p;
wire [`DATA_WIDTH-1:0]    current_d_param_i;
wire [`DATA_WIDTH-1:0]    current_d_param_d;
wire [`DATA_WIDTH-1:0]    current_q_param_p;
wire [`DATA_WIDTH-1:0]    current_q_param_i;
wire [`DATA_WIDTH-1:0]    current_q_param_d;
wire [`DATA_WIDTH-1:0]    voltage_alpha;
wire [`DATA_WIDTH-1:0]    voltage_beta;
wire current_loop_control_done;

//q������趨ֵ
wire [`DATA_WIDTH-1:0]    current_q_set_val;

//ת�ٱջ�����
wire [`DATA_WIDTH-1:0]    speed_set_val;
wire [`DATA_WIDTH-1:0]    speed_control_param_p;
wire [`DATA_WIDTH-1:0]    speed_control_param_i;
wire [`DATA_WIDTH-1:0]    speed_control_param_d;
wire  speed_loop_cal_done;

//λ�ÿ���ģ��
wire [`DATA_WIDTH-1:0]    pmsm_location_control_speed_set_value;
wire  [`ABSOLUTION_TOTAL_BIT-1:0]   location_detection_value;
wire pmsm_location_control_done;
//canͨѶģ��
wire [(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value;
wire can_init_done;
wire [(`DATA_WIDTH/2)-1:0] band_breaks_mode;  //��բ����ģʽ���
wire [(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode;   //�����ָͣ�����
wire [(`DATA_WIDTH/4)-1:0] pmsm_work_mode;     //�������ģʽָ�����
wire [`DATA_WIDTH-1:0]   pmsm_speed_set_value;   //  ���ת���趨ֵ���

//դ��������ģ��
wire [`DATA_WIDTH-1:0]    gate_driver_register_1;
wire [`DATA_WIDTH-1:0]    gate_driver_register_2;
wire                                        gate_driver_error;

//svpwm
wire [`DATA_WIDTH-1:0]   Tcma;
wire [`DATA_WIDTH-1:0]   Tcmb;
wire [`DATA_WIDTH-1:0]   Tcmc;
wire svpwm_cal_done;
(* dont_touch="true" *) wire phase_a_high_side;                     //    a�����űڿ���
wire phase_a_low_side;                      //    a�����űۿ���
wire phase_b_high_side;                    //    b�����űۿ���
wire phase_b_low_side;                     //    b�����űۿ���
wire phase_c_high_side;                    //     c�����űۿ���
wire phase_c_low_side;                     //     c�����űۿ���




//===========================================================================
//ʱ�ӹ���Ԫ
//===========================================================================
clk_wiz_0 global_clk_gen
(
 // Clock in ports
 .clk_in1(clk_50MHz_in),      // input clk_in1
                              // Clock out ports
 .clk_out1(sys_clk),     // output clk_out1
 .clk_out2(can_phy_clk),     // output clk_out2
                             // Status and control signals
 .resetn(reset_n_in), // input resetn
 .locked(clk_gen_locked));      // output locked

//===========================================================================
//ȫ�ָ�λ�ź�
//===========================================================================
assign reset_n = reset_n_in && clk_gen_locked;
//===========================================================================
//ϵͳ���Ƶ�Ԫ
//===========================================================================
system_control_unit system_control_inst(
                                        .sys_clk(sys_clk),
                                        .reset_n(reset_n),

                                        //λ��ģʽ����
                                        .location_loop_control_enable_out(location_loop_control_enable),    //  λ�ÿ���ʹ�����
                                        .location_detection_enable_out(location_detection_enable),          //  λ�ü��ʹ�����

                                        //�������
                                        .current_enable_out(current_enable) , //detect_enable signale
                                        .channela_detect_done_in(channela_detect_done),    //channel a detect done signal in
                                        .channelb_detect_done_in(channelb_detect_done),    //channel b detect done signal in
                                        .channela_detect_err_in(channela_detect_err),       //current detect error triger
                                        .channelb_detect_err_in(channelb_detect_err),     //current detect error triger
                                        .current_detect_status_out(current_detect_status),

                                        //�����ջ�����
                                        .current_loop_control_enable_out(current_loop_control_enable),      //����ʹ�����룬high-active

                                        //դ������������
                                        .gate_driver_init_enable_out(gate_driver_init_enable),  //  դ���������ϵ��λ���ʼ��ʹ��
                                        .gate_driver_init_done_in(gate_driver_init_done),  //  դ����������ʼ����ɱ�־
                                        .gate_driver_error_in(gate_driver_error),   //դ���Ĵ������ϱ������룬�ߵ�ƽ��Ч

                                        //ת�����Ƕȼ���
                                        .electrical_rotation_phase_forecast_enable_out(electrical_rotation_phase_forecast_enable),

                                        //can����
                                        .can_init_enable_out(can_init_enable),    //   can��ʼ��ʹ�ܱ�־
                                        .can_init_done_in(can_init_done),    //    can��ʼ����ɱ�־
                                        .band_breaks_mode_in(band_breaks_mode),  //��բ����ģʽ����
                                        .pmsm_start_stop_mode_in(pmsm_start_stop_mode),   //�����ָͣ������
                                        .pmsm_work_mode_in(pmsm_work_mode),     //�������ģʽָ������

                                        //դ��������
                                        .emergency_stop_out(emergency_stop),                            //   ����ͣ��ָ����ڵ�����դ�������������쳣ʱֹͣ���У��ߵ�ƽ��Ч

                                        //�ٶȱջ�����
                                        .speed_control_enable_out(speed_control_enable),    //�ٶȿ���ʹ���ź�
                                                                                            //ϵͳ��ʼ����ɱ�־
                                        .system_initilization_done_out(system_initilization_done)              //  ϵͳ��ʼ���������,�ߵ�ƽ��Ч
                                        );
//===========================================================================
//������ⵥԪ����
//===========================================================================
current_detect current_detect_inst(
                                   .sys_clk(sys_clk),                //system clock
                                   .reset_n(reset_n),                //reset signal,low active

                                   .detect_enable_in(current_enable) , //detect_enable signale
                                   .pmsm_imax_in(pmsm_reated_current),  //��������ֵ

                                   //channel a port
                                   .channela_sdat_in(current_u_data_in),     //spi data input
                                   .channela_ocd_in(current_u_ocd),     //over_current_detect input
                                   .channela_sclk_out(current_u_clk_out),   //spi clk output
                                   .channela_cs_n_out(current_u_cs_n_out),  //chip select otuput

                                   //channel b port
                                   .channelb_sdat_in(current_v_data_in),     //spi data input
                                   .channelb_ocd_in(current_v_ocd),     //over_current_detect input
                                   .channelb_sclk_out(current_v_clk_out),   //spi clk output
                                   .channelb_cs_n_out(current_v_cs_n_out),  //chip select otuput

                                   //current detect
                                   .phase_a_current_out(phase_a_current),
                                   .phase_b_current_out(phase_b_current),

                                   //current_detect_err_message output
                                   .current_detect_status_out(current_detect_status),
                                   .channela_detect_err_out(channela_detect_err), //current detect error triger
                                   .channelb_detect_err_out(channelb_detect_err), //current detect error triger
                                                                                  //detect done signal
                                   .channela_detect_done_out(channela_detect_done),    //channel a detect done signal out
                                   .channelb_detect_done_out(channelb_detect_done)     //channel b detect done signal out
                                   );
//===========================================================================
//��Ƕ���ת�ٲ�����Ԫ
//===========================================================================
speed_and_phase_trig_calculation_module speed_and_phase_trig_calculation_inst (
                                                                               .sys_clk(sys_clk),                //system clock
                                                                               .reset_n(reset_n),                //reset signal,low active
                                                                                                                 //   ��������������
                                                                               .hall_u_in(hall_u_in),
                                                                               .hall_v_in(hall_v_in),
                                                                               .hall_w_in(hall_w_in),

                                                                               //   ��������������
                                                                               .incremental_encode_ch_a_in(heds_9040_ch_a_in),
                                                                               .incremental_encode_ch_b_in(heds_9040_ch_b_in),

                                                                               //   ��Ƕ�Ԥ��ʹ��
                                                                               .electrical_rotation_phase_forecast_enable_in(electrical_rotation_phase_forecast_enable),

                                                                               //�ת������
                                                                               .rated_speed_in(pmsm_rated_speed),

                                                                               //ת�ӵ�Ƕ������Ҽ������
                                                                               .electrical_rotation_phase_sin_out(electrical_rotation_phase_sin), //������ת�Ƕ��������
                                                                               .electrical_rotation_phase_cos_out(electrical_rotation_phase_cos), //������ת�Ƕ��������
                                                                               .electrical_rotation_phase_trig_calculate_valid_out(),                       //�����Ҽ�����Ч��־���

                                                                               //ת��ת�����
                                                                               .standardization_speed_out(standardization_detect_speed)
                                                                               );
//===========================================================================
//�����ջ�����
//===========================================================================
current_loop_control current_loop_control_inst(
                                               .sys_clk(sys_clk),                //system clock
                                               .reset_n(reset_n),                //reset signal,low active

                                               .current_loop_control_enable_in(current_loop_control_enable),      //����ʹ�����룬high-active

                                               .electrical_rotation_phase_sin_in(electrical_rotation_phase_sin),   //  �����Ƕ�����ֵ����
                                               .electrical_rotation_phase_cos_in(electrical_rotation_phase_cos),  //  �����Ƕ�����ֵ����

                                               .phase_a_current_in(phase_a_current),                      //  a��������ֵ
                                               .phase_b_current_in(phase_b_current),                      //  b��������ֵ

                                               .current_d_param_p_in(current_d_param_p),         //d�������P����
                                               .current_d_param_i_in(current_d_param_i),          //d�������I����
                                               .current_d_param_d_in(current_d_param_d),         //d�������D����

                                               .current_d_set_val_in(16'd0),            //d������趨ֵ

                                               .current_q_param_p_in(current_q_param_p),         //q�������P����
                                               .current_q_param_i_in(current_q_param_i),          //q�������I����
                                               .current_q_param_d_in(current_q_param_d),         //q�������D����

                                               .current_q_set_val_in(current_q_set_val),            //q������趨ֵ

                                               .voltage_alpha_out(voltage_alpha), //U_alpha��ѹ���
                                               .voltage_beta_out(voltage_beta),   //U_beta��ѹ���
                                               .current_loop_control_done_out(current_loop_control_done)     //��ѹ�����Ч��־
                                               );
//===========================================================================
//ת�ٱջ�����
//===========================================================================
speed_loop_control speed_loop_control_inst(
                                           .sys_clk(sys_clk),                //system clock
                                           .reset_n(reset_n),                //reset signal,low active

                                           .speed_control_enable_in(speed_control_enable),   //�ٶȿ���ʹ���ź�
                                           .speed_control_param_p_in(speed_control_param_p),   //�ٶȱջ�����P����
                                           .speed_control_param_i_in(speed_control_param_i),   //�ٶȱջ�����I����
                                           .speed_control_param_d_in(speed_control_param_d),   //�ٶȱջ�����D����

                                           .speed_set_val_in(speed_set_val),       //�ٶ��趨ֵ
                                           .speed_detect_val_in(standardization_detect_speed),  //ʵ���ٶȼ��ֵ

                                           .current_q_set_val_out(current_q_set_val),    //Q������趨ֵ
                                           .speed_loop_cal_done_out(speed_loop_cal_done)   //  �����ջ��������
                                           );
assign speed_set_val=(pmsm_work_mode==`MOTOR_LOCATION_MODE)?pmsm_location_control_speed_set_value:pmsm_speed_set_value;
//===========================================================================
//λ�ÿ��Ʊջ�����
//===========================================================================
location_control_unit location_control_inst(
                                            .sys_clk(sys_clk),                //system clock
                                            .reset_n(reset_n),                //reset signal,low active

                                            .location_loop_control_enable_in(location_loop_control_enable),    //  λ�ÿ���ʹ������
                                            .location_detection_enable_in(location_detection_enable),          //  λ�ü��ʹ������

                                            .vlx_data_in(vlx_data_in),                         //  ssi�ӿ���������
                                            .vlx_clk_out(vlx_clk_out),                        //  ssi�ӿ�ʱ�����

                                            .pmsm_location_set_value_in(pmsm_location_set_value),    //λ��ģʽ�趨ֵ������ת��λ�ü�ת���ٶ�

                                            .pmsm_location_control_speed_set_value_out(pmsm_location_control_speed_set_value),    // λ�ÿ���ģʽ��ת���趨ֵ���
                                            .location_detection_value_out(location_detection_value),        //λ�ü�����

                                            .pmsm_location_control_done_out(pmsm_location_control_done)   //λ�ÿ���ģʽ���Ƽ�����ɱ�־
                                            );
//===========================================================================
//SVPWMģ��
//===========================================================================
(* dont_touch="true" *)svpwm_unit_module svpwm_unit_module_inst(
                  .sys_clk(sys_clk),                //system clock
                  .reset_n(reset_n),                //reset signal,low active

                  .svpwm_cal_enable_in(current_loop_control_done),                 //     SVPWM����ʹ��
                  .system_initilization_done_in(system_initilization_done),              //  ϵͳ��ʼ���������,�ߵ�ƽ��Ч

                  .emergency_stop_in(emergency_stop),                            //   ����ͣ��ָ����ڵ�����դ�������������쳣ʱֹͣ���У��ߵ�ƽ��Ч

                  .U_alpha_in(voltage_alpha),       //    Ualpha��ѹ����
                  .U_beta_in(voltage_beta),         //    Ubeta��ѹ����

                  .phase_a_high_side_out(phase_a_high_side),                     //    a�����űڿ���
                  .phase_a_low_side_out(phase_a_low_side),                      //    a�����űۿ���
                  .phase_b_high_side_out(phase_b_high_side),                    //    b�����űۿ���
                  .phase_b_low_side_out(phase_b_low_side),                     //    b�����űۿ���
                  .phase_c_high_side_out(phase_c_high_side),                    //     c�����űۿ���
                  .phase_c_low_side_out(phase_c_low_side),                     //     c�����űۿ���

                  .Tcma_out(Tcma),
                  .Tcmb_out(Tcmb),
                  .Tcmc_out(Tcmc),
                  .svpwm_cal_done_out(svpwm_cal_done)
                  );
//===========================================================================
//
//===========================================================================
gate_driver_unit gate_driver_inst(
                 .sys_clk(sys_clk),                //system clock
                 .reset_n(reset_n),                //reset signal,low active

                 .gate_driver_init_enable_in(gate_driver_init_enable),  //  դ���������ϵ��λ���ʼ��ʹ������
                 .gate_driver_init_done_out(gate_driver_init_done),  //  դ����������ʼ����ɱ�־

                 .gate_a_high_side_in(phase_a_high_side),                     //    a�����űڿ���
                 .gate_a_low_side_in(phase_a_low_side),                      //    a�����űۿ���
                 .gate_b_high_side_in(phase_b_high_side),                    //    b�����űۿ���
                 .gate_b_low_side_in(phase_b_low_side),                     //    b�����űۿ���
                 .gate_c_high_side_in(phase_c_high_side),                    //     c�����űۿ���
                 .gate_c_low_side_in(phase_c_low_side),                      //     c�����űۿ���

                .gate_driver_enable_out(drv8320_enable_out),
                 .gate_driver_nscs_out(drv8320s_nscs_out),
                 .gate_driver_sclk_out(drv8320s_clk_out),
                 .gate_driver_sdi_out(drv8320s_sdi_out),
                 .gate_driver_sdo_in(drv8320s_sdo_in),
                 .gate_driver_nfault_in(drc8320s_nfault),

                 .gate_a_high_side_out(drv8320s_inh_a_out),                     //    a�����űڿ���
                 .gate_a_low_side_out(drv8320s_inl_a_out),                      //    a�����űۿ���
                 .gate_b_high_side_out(drv8320s_inh_b_out),                    //    b�����űۿ���
                 .gate_b_low_side_out(drv8320s_inl_b_out),                     //    b�����űۿ���
                 .gate_c_high_side_out(drv8320s_inh_c_out),                    //     c�����űۿ���
                 .gate_c_low_side_out(drv8320s_inl_c_out),                     //     c�����űۿ���

                 .gate_driver_register_1_out(gate_driver_register_1),  //  դ���Ĵ���״̬1�Ĵ������
                 .gate_driver_register_2_out(gate_driver_register_2),  //  դ���Ĵ���״̬2�Ĵ������
                 .gate_driver_error_out(gate_driver_error)   //դ���Ĵ������ϱ������
                 );
//===========================================================================
//can����ͨѶģ��
//===========================================================================
can_transaction_unit can_transaction_inst(
                                          .sys_clk(sys_clk),                //system clock
                                          .reset_n(reset_n),                //reset signal,low active

                                          //  can�����˿�
                                          .can_phy_rx(can_rx_in),
                                          .can_phy_tx(can_tx_out),
                                          .can_clk(can_phy_clk),

                                          .system_initilization_done_in(system_initilization_done),              //  ϵͳ��ʼ���������,�ߵ�ƽ��Ч

                                          .can_init_enable_in(can_init_enable),    //   can��ʼ��ʹ�ܱ�־
                                          .can_init_done_out(can_init_done),    //    can��ʼ����ɱ�־

                                          .current_rated_value_out(pmsm_reated_current),  //  �����ֵ���
                                          .speed_rated_value_out(pmsm_rated_speed),  //  �ת��ֵ���

                                          .current_d_param_p_out(current_d_param_p),  //    ������d����Ʋ���p���
                                          .current_d_param_i_out(current_d_param_i),   //    ������d����Ʋ���i���
                                          .current_d_param_d_out(current_d_param_d),  //    ������d����Ʋ���d���

                                          .current_q_param_p_out(current_q_param_p),         //q�������P����
                                          .current_q_param_i_out(current_q_param_i),          //q�������I����
                                          .current_q_param_d_out(current_q_param_d),         //q�������D����

                                          .speed_control_param_p_out(speed_control_param_p),   //�ٶȱջ�����P����
                                          .speed_control_param_i_out(speed_control_param_i),   //�ٶȱջ�����I����
                                          .speed_control_param_d_out(speed_control_param_d),   //�ٶȱջ�����D����

                                          .location_control_param_p_out(),   //λ�ñջ�����P����
                                          .location_control_param_i_out(),   //λ�ñջ�����I����
                                          .location_control_param_d_out(),   //λ�ñջ�����D����

                                          .band_breaks_mode_out(band_breaks_mode),  //��բ����ģʽ���

                                          .pmsm_start_stop_mode_out(pmsm_start_stop_mode),   //�����ָͣ�����

                                          .pmsm_work_mode_out(pmsm_work_mode),     //�������ģʽָ�����

                                          .pmsm_speed_set_value_out(pmsm_speed_set_value),   //  ���ת���趨ֵ���
                                          .pmsm_location_set_value_out(pmsm_location_set_value),    //���λ���趨ֵ���

                                          .gate_driver_register_1_in(gate_driver_register_1),  //  դ���Ĵ���״̬1�Ĵ�������
                                          .gate_driver_register_2_in(gate_driver_register_2),  //  դ���Ĵ���״̬2�Ĵ�������
                                          .gate_driver_error_in(gate_driver_error),          //դ���Ĵ������ϱ�������

                                          .current_detect_status_in(current_detect_status),
                                          .channela_detect_err_in(channela_detect_err),    //current detect error triger
                                          .channelb_detect_err_in(channelb_detect_err),   //current detect error triger
                                          .phase_a_current_in(phase_a_current),     //  a��������ֵ
                                          .phase_b_current_in(phase_b_current),    //  b��������ֵ
                                          .electrical_rotation_phase_sin_in(electrical_rotation_phase_sin),   //  �����Ƕ�����ֵ����
                                          .electrical_rotation_phase_cos_in(electrical_rotation_phase_cos),  //  �����Ƕ�����ֵ����
                                          .current_loop_control_enable_in(current_loop_control_enable),     //����������ʹ�����룬���ڴ������������Ƕ�ֵ�ϴ�

                                          .U_alpha_in(voltage_alpha),       //    Ualpha��ѹ����
                                          .U_beta_in(voltage_beta),         //    Ubeta��ѹ����
                                          .current_loop_control_done_in(current_loop_control_done),     //��ѹ�����Ч��־����

                                          .Tcma_in(Tcma),    //  a ��ʱ���л������
                                          .Tcmb_in(Tcmb),    //   b��ʱ���л������
                                          .Tcmc_in(Tcmc),    //   c��ʱ���л������
                                          .svpwm_cal_done_in(svpwm_cal_done),  //svpwm����������룬��������ʱ���л��������ϴ�

                                          .speed_detect_val_in(standardization_detect_speed),      //ʵ���ٶȼ��ֵ
                                          .current_q_set_val_in(current_q_set_val),    //Q������趨ֵ
                                          .speed_loop_cal_done_in(speed_loop_cal_done),     //  �ٶȱջ���ɱ�־

                                          .pmsm_location_detect_value_in(location_detection_value),   //λ�ü������
                                          .speed_set_value_in(pmsm_location_control_speed_set_value),  //  λ��ģʽ�ٶ��趨ֵ����
                                          .pmsm_location_cal_done_in(pmsm_location_control_done),   //λ�ñջ�������ɱ�־

                                          .ds_18b20_temp_in(16'd0),  //  �����¶�����
                                          .ds_18b20_update_done_in(16'd0)  //�����¶ȸ���ָ��
                                          );
endmodule
