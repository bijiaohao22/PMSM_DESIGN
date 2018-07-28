//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/2
// Design Name:PMSM_DESIGN
// Module Name: svpwm_gen_module.v
// Target Device:
// Tool versions:
// Description:����SVPWM������Tcma��Tcmb��Tcmc������Ӧ�����űڵ�ͨ�ϣ�����PWM����
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module svpwm_gen_module(
                        input    sys_clk,
                        input    reset_n,

                        input    system_initilization_done_in,              //  ϵͳ��ʼ����ɱ�־
                        input    emergency_stop_in,                            //   ����ͣ��ָ����ڵ�����դ�������������쳣ʱֹͣ���У��ߵ�ƽ��Ч

                        input    [`DATA_WIDTH-1:0]    Tcma_in,      //  a ��ʱ���л���
                        input    [`DATA_WIDTH-1:0]    Tcmb_in,     //   b��ʱ���л���
                        input    [`DATA_WIDTH-1:0]    Tcmc_in,     //   c��ʱ���л���

                        output  phase_a_high_side_out,                     //    a�����űڿ���
                        output  phase_a_low_side_out,                      //    a�����űۿ���
                        output  phase_b_high_side_out,                    //    b�����űۿ���
                        output  phase_b_low_side_out,                     //    b�����űۿ���
                        output  phase_c_high_side_out,                    //     c�����űۿ���
                        output  phase_c_low_side_out                      //     c�����űۿ���
                        );

//===========================================================================
//�ڲ���������
//===========================================================================
reg[`DATA_WIDTH-1:0]    time_cnt_r;      //PWMʱ�������
reg[`DATA_WIDTH-1:0]    pwm_cnt_r;     //PWM���ǲ�������
reg[`DATA_WIDTH-1:0]   Tcma_r,
    Tcmb_r,
    Tcmc_r;  //����ʱ���л���Ĵ���
reg  phase_a_high_side_r;  //a�����űڿ��ƼĴ���
reg  phase_b_high_side_r;  //b�����űڿ��ƼĴ���
reg  phase_c_high_side_r;  //c�����űڿ��ƼĴ���
reg  phase_a_low_side_r;  //a�����űڿ��ƼĴ���
reg  phase_b_low_side_r;  //b�����űڿ��ƼĴ���
reg  phase_c_low_side_r;  //c�����űڿ��ƼĴ���

//===========================================================================
//PWM���ǲ�������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_cnt_r <= 'd0;
    else if (!system_initilization_done_in)
        time_cnt_r <= 'd0;
    else
        time_cnt_r <= time_cnt_r + `DELTA_INC_VAL;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        pwm_cnt_r <= 'd0;
    else if (time_cnt_r[`DATA_WIDTH - 1])    //����λΪ1������з�ת
        pwm_cnt_r <= ~time_cnt_r;
    else
        pwm_cnt_r <= time_cnt_r;
    end
//===========================================================================
//����ʱ���л���Ĵ�����ֵ
//�ھ�ݲ����״���ֵ��������PWM��������ʱ���л���ı仯�Բ��ε�Ӱ��
//===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
            if (!reset_n)
                {Tcma_r, Tcmb_r, Tcmc_r}<='d0;
            else if (time_cnt_r=='d0)
                {Tcma_r, Tcmb_r, Tcmc_r} <= {Tcma_in, Tcmb_in, Tcmc_in};
            else
                {Tcma_r, Tcmb_r, Tcmc_r} <= {Tcma_r, Tcmb_r, Tcmc_r} ;
        end

//===========================================================================
//�����űڿ��Ƶ�ͨ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {phase_a_high_side_r, phase_a_low_side_r} <= 'b00;   //ȫ���ر�
    else if ((!system_initilization_done_in)||emergency_stop_in)
        {phase_a_high_side_r, phase_a_low_side_r} <= 'b00;   //ȫ���ر�
    else if (pwm_cnt_r > Tcma_r)
        {phase_a_high_side_r, phase_a_low_side_r} <= 'b10;   //�Ͽ��±�
    else
    {phase_a_high_side_r, phase_a_low_side_r} <= 'b01;   //�ϱ��¿�
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {phase_b_high_side_r, phase_b_low_side_r} <= 'b00;   //ȫ���ر�
    else if ((!system_initilization_done_in)||emergency_stop_in)
        {phase_b_high_side_r, phase_b_low_side_r} <= 'b00;   //ȫ���ر�
    else if (pwm_cnt_r > Tcmb_r)
        {phase_b_high_side_r, phase_b_low_side_r} <= 'b10;   //�Ͽ��±�
    else
    {phase_b_high_side_r, phase_b_low_side_r} <= 'b01;   //�ϱ��¿�
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {phase_c_high_side_r, phase_c_low_side_r} <= 'b00;   //ȫ���ر�
    else if ((!system_initilization_done_in)||emergency_stop_in)
        {phase_c_high_side_r, phase_c_low_side_r} <= 'b00;   //ȫ���ر�
    else if (pwm_cnt_r > Tcmc_r)
        {phase_c_high_side_r, phase_c_low_side_r} <= 'b10;   //�Ͽ��±�
    else
    {phase_c_high_side_r, phase_c_low_side_r} <= 'b01;   //�ϱ��¿�
    end

//===========================================================================
//����źŸ�ֵ
//===========================================================================
assign  phase_a_high_side_out = phase_a_high_side_r;
assign  phase_a_low_side_out = phase_a_low_side_r;
assign  phase_b_high_side_out = phase_b_high_side_r;
assign  phase_b_low_side_out = phase_b_low_side_r;
assign  phase_c_high_side_out = phase_c_high_side_r;
assign  phase_c_low_side_out = phase_c_low_side_r;
endmodule
