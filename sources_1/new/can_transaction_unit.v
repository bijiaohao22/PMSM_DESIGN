`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2018/05/22 22:24:18
// Design Name:
// Module Name: can_transaction_unit
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`include "project_param.v"
module can_transaction_unit(
                            input    sys_clk,
                            input    reset_n,

                            //  can�����˿�
                            input    can_phy_rx,
                            output  can_phy_tx,
                            input    can_clk,

                            input   system_initilization_done_in,              //  ϵͳ��ʼ���������,�ߵ�ƽ��Ч

                            input    can_init_enable_in,    //   can��ʼ��ʹ�ܱ�־
                            output  can_init_done_out,    //    can��ʼ����ɱ�־

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
wire  [31:0]  tx_dw1r,tx_dw2r;
wire  tx_valid,tx_ready;
wire  [31:0] rx_dw1r,rx_dw2r;
wire  rx_valid,rx_ready;
//===========================================================================
//CAN����Ӧ�ò�ͨѶ����
//===========================================================================
can_bus_app_unit can_bus_app_inst(
                                  .sys_clk(sys_clk),
                                  .reset_n(reset_n),

                                  .tx_dw1r_out(tx_dw1r),    //  ���ݷ�����1
                                  .tx_dw2r_out(tx_dw2r),    //  ���ݷ�����2
                                  . tx_valid_out(tx_valid),   //  ������Ч��־
                                  . tx_ready_in(tx_ready),     //  ����׼��������

                                  .rx_dw1r_in(rx_dw1r),     //  ���ݽ�����1
                                  .rx_dw2r_in(rx_dw2r),     //  ���ݽ�����2
                                  .rx_valid_in(rx_valid),      //  ���ݽ�����Ч��־����
                                  .rx_ready_out(rx_ready),   //  ���ݽ���׼�������

                                  .current_rated_value_out(current_rated_value_out),  //  �����ֵ���
                                  .speed_rated_value_out(speed_rated_value_out),  //  �ת��ֵ���

                                  .current_d_param_p_out(current_d_param_p_out),  //    ������d����Ʋ���p���
                                  .current_d_param_i_out(current_d_param_i_out),   //    ������d����Ʋ���i���
                                  .current_d_param_d_out(current_d_param_d_out),  //    ������d����Ʋ���d���

                                  .current_q_param_p_out(current_q_param_p_out),         //q�������P����
                                  .current_q_param_i_out(current_q_param_i_out),          //q�������I����
                                  .current_q_param_d_out(current_q_param_d_out),         //q�������D����

                                  .speed_control_param_p_out(speed_control_param_p_out),   //�ٶȱջ�����P����
                                  .speed_control_param_i_out(speed_control_param_i_out),   //�ٶȱջ�����I����
                                  .speed_control_param_d_out(speed_control_param_d_out),   //�ٶȱջ�����D����

                                  .location_control_param_p_out(location_control_param_p_out),   //λ�ñջ�����P����
                                  .location_control_param_i_out(location_control_param_i_out),   //λ�ñջ�����I����
                                  .location_control_param_d_out(location_control_param_d_out),   //λ�ñջ�����D����

                                  .band_breaks_mode_out(band_breaks_mode_out),  //��բ����ģʽ���

                                  .pmsm_start_stop_mode_out(pmsm_start_stop_mode_out),   //�����ָͣ�����

                                  .pmsm_work_mode_out(pmsm_work_mode_out),     //�������ģʽָ�����

                                  .pmsm_speed_set_value_out(pmsm_speed_set_value_out),   //  ���ת���趨ֵ���
                                  .pmsm_location_set_value_out(pmsm_location_set_value_out),    //���λ���趨ֵ���

                                  .gate_driver_register_1_in(gate_driver_register_1_in),  //  դ���Ĵ���״̬1�Ĵ�������
                                  .gate_driver_register_2_in(gate_driver_register_2_in),  //  դ���Ĵ���״̬2�Ĵ�������
                                  .gate_driver_error_in(gate_driver_error_in),          //դ���Ĵ������ϱ�������

                                  .current_detect_status_in(current_detect_status_in),
                                  .channela_detect_err_in(channela_detect_err_in),    //current detect error triger
                                  .channelb_detect_err_in(channelb_detect_err_in),   //current detect error triger
                                  .phase_a_current_in(phase_a_current_in),     //  a��������ֵ
                                  .phase_b_current_in(phase_b_current_in),    //  b��������ֵ
                                  .electrical_rotation_phase_sin_in(electrical_rotation_phase_sin_in),   //  �����Ƕ�����ֵ����
                                  .electrical_rotation_phase_cos_in(electrical_rotation_phase_cos_in),  //  �����Ƕ�����ֵ����
                                  .current_loop_control_enable_in(current_loop_control_enable_in),     //����������ʹ�����룬���ڴ������������Ƕ�ֵ�ϴ�

                                  . U_alpha_in(U_alpha_in),       //    Ualpha��ѹ����
                                  . U_beta_in(U_beta_in),         //    Ubeta��ѹ����
                                  .current_loop_control_done_in(current_loop_control_done_in),     //��ѹ�����Ч��־����

                                  .Tcma_in(Tcma_in),    //  a ��ʱ���л������
                                  .Tcmb_in(Tcmb_in),    //   b��ʱ���л������
                                  .Tcmc_in(Tcmc_in),    //   c��ʱ���л������
                                  .svpwm_cal_done_in(svpwm_cal_done_in),  //svpwm����������룬��������ʱ���л��������ϴ�

                                  .speed_detect_val_in(speed_detect_val_in),      //ʵ���ٶȼ��ֵ
                                  .current_q_set_val_in(current_q_set_val_in),    //Q������趨ֵ
                                  .speed_loop_cal_done_in(speed_loop_cal_done_in),     //  �ٶȱջ���ɱ�־

                                  .pmsm_location_detect_value_in(pmsm_location_detect_value_in),   //λ�ü������
                                  .speed_set_value_in(speed_set_value_in),  //  λ��ģʽ�ٶ��趨ֵ����
                                  .pmsm_location_cal_done_in(pmsm_location_cal_done_in),   //λ�ñջ�������ɱ�־

                                  .ds_18b20_temp_in(ds_18b20_temp_in),  //  �����¶�����
                                  .ds_18b20_update_done_in(ds_18b20_update_done_in)  //�����¶ȸ���ָ��
                                  );
//===========================================================================
//uartģ������
//===========================================================================
uart_phy uart_phy_inst(
             .sys_clk(sys_clk),
             .reset_n(reset_n),

             .wr_data1_in(tx_dw1r),
             .wr_data2_in(tx_dw2r),
             . wr_data_valid_in(tx_valid),
             . wr_data_ready_out(tx_ready),

             .rx_data1_out(rx_dw1r),
             .rx_data2_out(rx_dw2r),
             .rx_valid_out(rx_valid),
             .rx_ready_in(rx_ready),

             .uart_rx_in(can_phy_rx),
             .uart_tx_out(can_phy_tx)
             );
assign can_init_done_out='b1;
//===========================================================================
//can����������·������
//===========================================================================
//can_data_link can_data_link_inst(
//                                 .sys_clk(sys_clk),
//                                 .can_clk(can_clk),   //  can�����ʱ��
//                                 .reset_n(reset_n),
//
//                                 //  can�����˿�
//                                 .can_phy_rx(can_phy_rx),
//                                 .can_phy_tx(can_phy_tx),
//
//                                 .system_initilization_done_in(system_initilization_done_in),              //  ϵͳ��ʼ���������,�ߵ�ƽ��Ч
//
//                                 .can_init_enable_in(can_init_enable_in),    //   can��ʼ��ʹ�ܱ�־
//                                 .can_init_done_out(can_init_done_out),    //    can��ʼ����ɱ�־
//
//                                 .tx_dw1r_in(tx_dw1r),       //   ���ݷ�����1��
//                                 .tx_dw2r_in(tx_dw2r),       //   ���ݷ�����2��
//                                 .tx_valid_in(tx_valid),       //   ���ݷ�����Ч��־λ
//                                 .tx_ready_out(tx_ready),    //  ���ݷ���׼���ñ�־
//
//                                 .rx_dw1r_out(rx_dw1r),    //  ����������1
//                                 .rx_dw2r_out(rx_dw2r),    //  ����������2
//                                 .rx_valid_out(rx_valid),     //  ����������Ч��־
//                                 .rx_ready_in(rx_ready)      //  ����׼���ñ�־����
//                                 );
endmodule
