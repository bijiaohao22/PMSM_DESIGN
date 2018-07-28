//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/24
// Design Name:PMSM_DESIGN
// Module Name: system_control_sim.sv
// Target Device:
// Tool versions:
// Description��ϵͳ���ȹ��ܷ���
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module system_control_sim();
//===========================================================================
//�ڲ���������
//===========================================================================
logic sys_clk ,reset_n;
logic location_loop_control_enable;
logic location_detection_enable;
logic current_enable;
logic channela_detect_done;
logic channelb_detect_done;
logic channela_detect_err;
logic channelb_detect_err;
logic [`DATA_WIDTH-1:0] current_detect_status;
logic current_loop_control_enable;
logic gate_driver_init_enable;
logic gate_driver_init_done;
logic gate_driver_error;
logic electrical_rotation_phase_forecast_enable;
logic can_init_enable;
logic can_init_done;
logic [(`DATA_WIDTH/2)-1:0] band_breaks_mode;
logic [(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode;
logic [(`DATA_WIDTH/4)-1:0] pmsm_work_mode_in;
logic emergency_stop;
logic speed_control_enable;
logic system_initilization_done;
//===========================================================================
//DUT
//===========================================================================
system_control_unit dut(
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
                    .pmsm_work_mode_in(pmsm_work_mode_in),     //�������ģʽָ������

                    //դ��������
                    .emergency_stop_out(emergency_stop),                            //   ����ͣ��ָ����ڵ�����դ�������������쳣ʱֹͣ���У��ߵ�ƽ��Ч

                    //�ٶȱջ�����
                    .speed_control_enable_out(speed_control_enable),    //�ٶȿ���ʹ���ź�
                                                                        //ϵͳ��ʼ����ɱ�־
                    .system_initilization_done_out(system_initilization_done)              //  ϵͳ��ʼ���������,�ߵ�ƽ��Ч
                    );
//===========================================================================
//��λ��ʱ��
//===========================================================================
initial
    begin
        reset_n=0;
        sys_clk=0;
        channela_detect_done=0;
        channelb_detect_done=0;
        channela_detect_err=0;
        channelb_detect_err=0;
        gate_driver_init_done=0;
        gate_driver_error=0;
        can_init_done=0;
        band_breaks_mode=0;
        pmsm_start_stop_mode=0;
        pmsm_work_mode_in=0;
        #100;
        reset_n=1;
    end
initial
    begin
    forever
        #1 sys_clk = ~sys_clk;
    end
//===========================================================================
//��ʼ��Ӧ��
//===========================================================================
initial
    begin
        wait(gate_driver_init_enable)
        #1000;
    @(posedge sys_clk)
        gate_driver_init_done<='d1;
    end
initial
    begin
    wait(can_init_enable)
    #100;
    @(posedge sys_clk)
        can_init_done<='d1;
    @(posedge sys_clk)
        can_init_done<='d0;
    end
//===========================================================================
//����ע��
//===========================================================================
initial
    begin
        wait(system_initilization_done)
            @(posedge sys_clk )
             band_breaks_mode<=`BAND_BREAK_CLOSE;
            #200;
        @(posedge sys_clk )
            pmsm_work_mode_in<=`MOTOR_LOCATION_MODE;
            pmsm_start_stop_mode<=`MOTOR_START_CMD;
        #10_000_000;
        //����ָ��ע��
        @(posedge sys_clk )
        channela_detect_err<='d1;
        current_detect_status<=16'h23da;
        @(posedge sys_clk )
        channela_detect_err<='d0;
        #100;
        @(posedge sys_clk)
        current_detect_status<='d0;

        @(posedge sys_clk )
        channelb_detect_err<='d1;
        current_detect_status<=16'hfad3;
        @(posedge sys_clk )
        channelb_detect_err<='d0;
        #100;
        @(posedge sys_clk)
        current_detect_status<='d0;

        #100;
        @(posedge sys_clk)
        gate_driver_error<='d1;
        #100;
        @(posedge sys_clk)
        gate_driver_error<='d0;
        //����ģʽ�ı�
        #100;
        pmsm_start_stop_mode<=`MOTOR_STOP_CMD;
        @(posedge sys_clk)
        pmsm_work_mode_in<=`MOTOR_SPEED_MODE;
        pmsm_start_stop_mode<=`MOTOR_START_CMD;
        #10_000_000;
        $stop();
    end
endmodule
