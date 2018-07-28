//====================================================================================
// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/5/2
// Design Name:PMSM_DESIGN
// Module Name: svpwm_unit_module.v
// Target Device:
// Tool versions:
// Description:  ���ݵ�ѹU_alpha��U_Beta��������SVPWM�������
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module svpwm_unit_module(
                         input    sys_clk,
                         input    reset_n,

                         input    svpwm_cal_enable_in,                 //     SVPWM����ʹ��
                         input    system_initilization_done_in,              //  ϵͳ��ʼ���������,�ߵ�ƽ��Ч

                         input    emergency_stop_in,                            //   ����ͣ��ָ����ڵ�����դ�������������쳣ʱֹͣ���У��ߵ�ƽ��Ч

                         input signed   [`DATA_WIDTH-1:0]      U_alpha_in,       //    Ualpha��ѹ����
                         input signed   [`DATA_WIDTH-1:0]      U_beta_in,         //    Ubeta��ѹ����

                         output  phase_a_high_side_out,                     //    a�����űڿ���
                         output  phase_a_low_side_out,                      //    a�����űۿ���
                         output  phase_b_high_side_out,                    //    b�����űۿ���
                         output  phase_b_low_side_out,                     //    b�����űۿ���
                         output  phase_c_high_side_out,                    //     c�����űۿ���
                         output  phase_c_low_side_out,                     //     c�����űۿ���

                         output [`DATA_WIDTH-1:0]   Tcma_out,
                         output [`DATA_WIDTH-1:0]   Tcmb_out,
                         output [`DATA_WIDTH-1:0]   Tcmc_out,
                         output svpwm_cal_done_out
                         );

//===========================================================================
//�ڲ���������
//===========================================================================
wire [`DATA_WIDTH-1:0]     Tcma_w,Tcmb_w,Tcmc_w;
//===========================================================================
//SVPWM����IP������
//===========================================================================
svpwm_time_cal svpwm_time_cal_inst(
                                   .sys_clk(sys_clk),
                                   .reset_n(reset_n),

                                   .U_alpha_in(U_alpha_in),       //    Ualpha��ѹ����
                                   .U_beta_in(U_beta_in),         //    Ubeta��ѹ����
                                   .svpwm_cal_enable_in(svpwm_cal_enable_in),                                //     SVPWM����ʹ��

                                   .Tcma_out(Tcma_w),               //      a�� ʱ���л���
                                   .Tcmb_out(Tcmb_w),               //      b��ʱ���л���2
                                   .Tcmc_out(Tcmc_w),               //      c��ʱ���л���3
                                   .svpwm_cal_done_out(svpwm_cal_done_out)
                                   );
//===========================================================================
//SVPWM�������IP������
//===========================================================================
svpwm_gen_module svpwm_gen_inst(
                                . sys_clk(sys_clk),
                                . reset_n(reset_n),

                                . system_initilization_done_in(system_initilization_done_in),              //  ϵͳ��ʼ����ɱ�־
                                .emergency_stop_in(emergency_stop_in),

                                .Tcma_in(Tcma_w),      //  a ��ʱ���л���
                                .Tcmb_in(Tcmb_w),     //   b��ʱ���л���
                                .Tcmc_in(Tcmc_w),     //   c��ʱ���л���

                                .phase_a_high_side_out(phase_a_high_side_out),                     //    a�����űڿ���
                                .phase_a_low_side_out(phase_a_low_side_out),                      //    a�����űۿ���
                                .phase_b_high_side_out(phase_b_high_side_out),                    //    b�����űۿ���
                                .phase_b_low_side_out(phase_b_low_side_out),                     //    b�����űۿ���
                                .phase_c_high_side_out(phase_c_high_side_out),                    //     c�����űۿ���
                                .phase_c_low_side_out(phase_c_low_side_out)                      //     c�����űۿ���
                                );
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign Tcma_out=Tcma_w;
assign Tcmb_out=Tcmb_w;
assign Tcmc_out=Tcmc_w;
endmodule
