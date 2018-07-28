
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/22
// Design Name:PMSM_DESIGN
// Module Name: can_bus_app_sim.v
// Target Device:
// Tool versions:
// Description:CAN����Ӧ�ò㹦�ܷ���
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module can_bus_app_sim();
//===========================================================================
//�ڲ���������
//===========================================================================
logic sys_clk,reset_n;
logic [31:0]  tx_dw1r,tx_dw2r;
logic tx_valid,tx_ready;
logic [31:0] rx_dw1r,rx_dw2r;
logic [31:0]rx_valid,rx_ready;
logic [`DATA_WIDTH-1:0] current_rated_value;
logic [`DATA_WIDTH-1:0]  speed_rated_value;
logic [`DATA_WIDTH-1:0]    current_d_param_p;
logic [`DATA_WIDTH-1:0]    current_d_param_i;
logic [`DATA_WIDTH-1:0]    current_d_param_d;
logic [`DATA_WIDTH-1:0]    current_q_param_p;
logic [`DATA_WIDTH-1:0]    current_q_param_i;
logic [`DATA_WIDTH-1:0]    current_q_param_d;
logic [`DATA_WIDTH-1:0]    speed_control_param_p;
logic [`DATA_WIDTH-1:0]    speed_control_param_i;
logic [`DATA_WIDTH-1:0]    speed_control_param_d;
logic [`DATA_WIDTH-1:0]    location_control_param_p;
logic [`DATA_WIDTH-1:0]    location_control_param_i;
logic [`DATA_WIDTH-1:0]    location_control_param_d;
logic [(`DATA_WIDTH/2)-1:0] band_breaks_mode;
logic [(`DATA_WIDTH/2)-1:0] pmsm_start_stop_mode;
logic  [(`DATA_WIDTH/4)-1:0] pmsm_work_mode;
logic [`DATA_WIDTH-1:0]   pmsm_speed_set_value;
logic [(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value;
logic [`DATA_WIDTH-1:0]    gate_driver_register_1;
logic [`DATA_WIDTH-1:0]    gate_driver_register_2;
logic gate_driver_error;
logic [`DATA_WIDTH-1:0] current_detect_status;
logic  channela_detect_err;
logic  channelb_detect_err;
logic [`DATA_WIDTH-1:0] phase_a_current;
logic [`DATA_WIDTH-1:0] phase_b_current;
logic [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin;
logic [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos;
logic current_loop_control_enable;
logic [`DATA_WIDTH-1:0]      U_alpha;
logic [`DATA_WIDTH-1:0]      U_beta;
logic current_loop_control_done;
logic [`DATA_WIDTH-1:0]   Tcma;
logic [`DATA_WIDTH-1:0]   Tcmb;
logic [`DATA_WIDTH-1:0]   Tcmc;
logic svpwm_cal_done;
logic [`DATA_WIDTH-1:0]       speed_detect_val;
logic [`DATA_WIDTH-1:0]  current_q_set_val;
logic speed_loop_cal_done;
logic [(`DATA_WIDTH*2+2)-1:0]pmsm_location_detect_value;
logic [`DATA_WIDTH-1:0]    speed_set_value;
logic pmsm_location_cal_done;
logic [`DATA_WIDTH-1:0]    ds_18b20_temp;
logic ds_18b20_update_done;

integer write_log_id,
    read_log_id,
    monitor_log_id;
//===========================================================================
//DUT
//===========================================================================
can_bus_app_unit dut(
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

                 .current_rated_value_out(current_rated_value),  //  �����ֵ���
                 .speed_rated_value_out(speed_rated_value),  //  �ת��ֵ���

                 .current_d_param_p_out(current_d_param_p),  //    ������d����Ʋ���p���
                 .current_d_param_i_out(current_d_param_i),   //    ������d����Ʋ���i���
                 .current_d_param_d_out(current_d_param_d),  //    ������d����Ʋ���d���

                 .current_q_param_p_out(current_q_param_p),         //q�������P����
                 .current_q_param_i_out(current_q_param_i),          //q�������I����
                 .current_q_param_d_out(current_q_param_d),         //q�������D����

                 .speed_control_param_p_out(speed_control_param_p),   //�ٶȱջ�����P����
                 .speed_control_param_i_out(speed_control_param_i),   //�ٶȱջ�����I����
                 .speed_control_param_d_out(speed_control_param_d),   //�ٶȱջ�����D����

                 .location_control_param_p_out(location_control_param_p),   //λ�ñջ�����P����
                 .location_control_param_i_out(location_control_param_i),   //λ�ñջ�����I����
                 .location_control_param_d_out(location_control_param_d),   //λ�ñջ�����D����

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

                 . U_alpha_in(U_alpha),       //    Ualpha��ѹ����
                 . U_beta_in(U_beta),         //    Ubeta��ѹ����
                 .current_loop_control_done_in(current_loop_control_done),     //��ѹ�����Ч��־����

                 .Tcma_in(Tcma),    //  a ��ʱ���л������
                 .Tcmb_in(Tcmb),    //   b��ʱ���л������
                 .Tcmc_in(Tcmc),    //   c��ʱ���л������
                 .svpwm_cal_done_in(svpwm_cal_done),  //svpwm����������룬��������ʱ���л��������ϴ�

                 .speed_detect_val_in(speed_detect_val),      //ʵ���ٶȼ��ֵ
                 .current_q_set_val_in(current_q_set_val),    //Q������趨ֵ
                 .speed_loop_cal_done_in(speed_loop_cal_done),     //  �ٶȱջ���ɱ�־

                 .pmsm_location_detect_value_in(pmsm_location_detect_value),   //λ�ü������
                 .speed_set_value_in(speed_set_value),  //  λ��ģʽ�ٶ��趨ֵ����
                 .pmsm_location_cal_done_in(pmsm_location_cal_done),   //λ�ñջ�������ɱ�־

                 .ds_18b20_temp_in(ds_18b20_temp),  //  �����¶�����
                 .ds_18b20_update_done_in(ds_18b20_update_done)  //�����¶ȸ���ָ��
                 );
//===========================================================================
//ʱ���븴λ
//===========================================================================
initial
    begin
    reset_n = 0;
    sys_clk = 0;
    channelb_detect_err=0;
    gate_driver_error=0;
    channela_detect_err=0;
    current_loop_control_enable=0;
    current_loop_control_done=0;
    svpwm_cal_done=0;
    speed_loop_cal_done=0;
    pmsm_location_cal_done=0;
    ds_18b20_update_done=0;

    #100;
    reset_n = 1;
    end
initial
    begin
    forever
        #1 sys_clk = ~sys_clk;
    end
//===========================================================================
//���ݼ��
//===========================================================================
initial
    begin
    write_log_id = $fopen("write_log.txt", "w+");
    read_log_id = $fopen("read_log.txt", "w+");
    monitor_log_id = $fopen("monitor_log_id.txt", "w+");
    end
initial
    begin
    #10;
        //      $fstrobe(write_log_id, "time:%t\tgate driver state register set value %h\t%h\t", $time, gate_driver_register_1, gate_driver_register_2);
        //      $fstrobe(write_log_id, "time:%t\tcurrent_value:a=%h\t,b=%h\t,state=%h\t", $time, phase_a_current, phase_b_current, current_detect_status);
        //      $fstrobe(write_log_id, "time:%t\telectrical_rotation_phase:\tsin=%h\t,cos=%h\t", $time, electrical_rotation_phase_sin, electrical_rotation_phase_cos);
        //      $fstrobe(write_log_id, "time:%t\tU_alpha=%h\t,U_beta=%h\t", $time, U_alpha, U_beta);
        //      $fstrobe(write_log_id, "time:%t\tSVPWM switch time:\tTcma=%h\t,Tcmb=%h,Tcmc=%h\t", $time, Tcma, Tcmb, Tcmc);
        //      $fstrobe(write_log_id, "time:%t\tspeed_contriol:\tspeed_detect_val=%h\t,current_q_set_val=%h\t", $time, speed_detect_val, current_q_set_val);
        //      $fstrobe(write_log_id, "time:%t\tlocation_contriol:\tpmsm_location_detect_value=%h\t,speed_set_value=%h\t", $time, pmsm_location_detect_value, speed_set_value);
        //      $fstrobe(write_log_id, "time:%t\tdriver_temp:\t%h", $time, ds_18b20_temp);

    $fmonitor(write_log_id, "time:%t\tcurrent_rated_set_value:%h", $time, current_rated_value);
        $fmonitor(write_log_id, "time:%t\tspeed_rated_set_value:%h", $time, speed_rated_value);
        $fmonitor(write_log_id, "time:%t\tcurrent_control_param:\tcurrent_d_p=%h\t,current_d_i=%h\t,current_d_d=%h\t", $time, current_d_param_p, current_d_param_i, current_d_param_d);
        $fmonitor(write_log_id, "time:%t\tcurrent_control_param:\tcurrent_q_p=%h\t,current_q_i=%h\t,current_q_d=%h\t", $time, current_q_param_p, current_q_param_i, current_q_param_d);
        $fmonitor(write_log_id, "time:%t\tspeed_control_param:\tspeed_p=%h\t,speed_i=%h\t,speed_d=%h\t", $time, speed_control_param_p, speed_control_param_i, speed_control_param_d);
        $fmonitor(write_log_id, "time:%t\tlocation_control_param:\tlocation_p=%h\t,location_i=%h\t,location_d=%h\t", $time, location_control_param_p, location_control_param_i, location_control_param_d);
        $fmonitor(write_log_id, "time:%t\tband_breaks_mode:\t%h\t", $time, band_breaks_mode);
        $fmonitor(write_log_id, "time:%t\tpmsm_start_stop_mode:\t%h\t", $time, pmsm_start_stop_mode);
        $fmonitor(write_log_id, "time:%t\tpmsm_work_mode:\t%h\t", $time, pmsm_work_mode);
        $fmonitor(write_log_id, "time:%t\tpmsm_speed_set_value:\t%h\t", $time, pmsm_speed_set_value);
        $fmonitor(write_log_id, "time:%t\tpmsm_location_set_value:\t%h\t", $time, pmsm_location_set_value);
    end
//===========================================================================
//�����ϴ�����
//===========================================================================
initial
    begin
    #1000;
    gate_error_update(16'hf3a6, 16'h98da);
    #100
        current_update(16'h2389, 16'hfda5, 16'h4328, 16'h8943, 16'hffae, 1'b1);
    #100
        current_loop_update(16'h3476, 16'h9853);
    current_update(16'h2389, 16'hfda5, 16'h4328, 16'h8943, 16'hffae, 1'b0);
    #20;
    svpwm_update(16'hefda, 16'hfde8,16'hfad5);
    #20;
    speed_loop_update(16'h4273, 16'h8735);
    #10;
    location_loop_update(16'h3428, 16'hfad3);
    temp_update(16'had3e);
    #1000;
    $fclose(write_log_id);
    $fclose(read_log_id);
    $fclose(monitor_log_id);
    $stop;
    end

//===========================================================================
//�����ϴ�
//===========================================================================
task gate_error_update(logic[15:0] state1, state2);
    $fdisplay(read_log_id, "time:\t%t,gate error state:\t%h\t%h", $time, state1, state2);
    @(posedge sys_clk)
        gate_driver_register_1 <= state1;
    gate_driver_register_2 <= state2;
    gate_driver_error <= 'b1;
    @(posedge sys_clk)
        gate_driver_error <= 'd0;
endtask
//�������ֵ�ϴ�
task current_update(logic[15:0] state1, state2, state, sin, cos, logic error_flag);
    $fdisplay(read_log_id, "time:\t%t,current value:\t%h\t%h\tstate:\t%h\t", $time, state1, state2, state);
    @(posedge sys_clk)
        phase_a_current <= state1;
    phase_b_current <= state2;
    current_detect_status <= state;
    if (error_flag)
        begin
        channela_detect_err <= 'b1;
        @(posedge sys_clk)
            channela_detect_err <= 'b0;
        end else
        begin
        $fdisplay(read_log_id,  "time:%t\telectrical_rotation_phase:\tsin=%h\t,cos=%h\t", $time, sin, cos);
        electrical_rotation_phase_sin <= sin;
        electrical_rotation_phase_cos <= cos;
        current_loop_control_enable <= 'd1;
        @(posedge sys_clk)
            current_loop_control_enable <= 'b0;
        end
endtask
//�����ջ������ϴ�ֵ�ϴ�
task current_loop_update(logic[15:0] state1, state2);
    $fdisplay(read_log_id, "time:%t\tU_alpha=%h\t,U_beta=%h\t", $time, state1, state2);
    @(posedge sys_clk)
        U_alpha <= state1;
    U_beta <= state2;
    current_loop_control_done <= 'b1;
    @(posedge sys_clk)
        current_loop_control_done <= 'd0;
endtask
//�������л�ʱ���ϴ�
task svpwm_update(logic[15:0] state1, state2, state3);
    $fdisplay(read_log_id, "time:%t\tSVPWM switch time:\tTcma=%h\t,Tcmb=%h,Tcmc=%h\t", $time, state1, state2, state3);
    @(posedge sys_clk)
        Tcma <= state1;
    Tcmb <= state2;
    Tcmc <= state3;
    svpwm_cal_done <= 'b1;
    @(posedge sys_clk)
        svpwm_cal_done <= 'd0;
endtask
//�ٶȻ������ϴ�
task speed_loop_update(logic[15:0] state1, state2);
    $fdisplay(read_log_id, "time:%t\tspeed_contriol:\tspeed_detect_val=%h\t,current_q_set_val=%h\t", $time, state1, state2);
    @(posedge sys_clk)
        speed_detect_val <= state1;
    current_q_set_val <= state2;
    speed_loop_cal_done <= 'b1;
    @(posedge sys_clk)
        speed_loop_cal_done <= 'd0;
endtask
//λ�û������ϴ�
task location_loop_update(logic[15:0] state1, state2);
    $fdisplay(read_log_id, "time:%t\tlocation_contriol:\tpmsm_location_detect_value=%h\t,speed_set_value=%h\t", $time, state1, state2);
    @(posedge sys_clk)
        pmsm_location_detect_value <= state1;
    speed_set_value <= state2;
    pmsm_location_cal_done <= 'b1;
    @(posedge sys_clk)
        pmsm_location_cal_done <= 'd0;
endtask
//�¶������ϴ�
task temp_update(logic[15:0] state1);
    $fdisplay(read_log_id, "time:%t\tdriver_temp:\t%h", $time, state1);
    @(posedge sys_clk)
        ds_18b20_temp <= state1;
    ds_18b20_update_done <= 'b1;
    @(posedge sys_clk)
        ds_18b20_update_done <= 'd0;
endtask
//===========================================================================
//����ע�����
//===========================================================================
initial
    begin
    #1000;
    speed_current_rated_reload(16'h3426, 16'hfad2);
    #10;
    curent_d_param_reload(16'hfaf2, 16'h8964, 16'h9fa2);
    #10;
    curent_q_param_reload(16'hfdf2, 16'hf964, 16'h9fa4);
    #10;
    speed_param_reload(16'hf4f2, 16'h2964, 16'h9da2);
    #10;
    location_param_reload(16'hfadc, 16'hadf3, 16'hafe9);
    #10;
    band_break_reload(8'hf2);
    #10;
    motor_start_stop_reload(8'hd3);
    #10;
    motor_work_mode_reload(8'hf3, 16'h3429, 16'hfad3);
    #100;
    end
//��ٶ�,����ֵע��
task speed_current_rated_reload(logic[15:0] state1, state2);
    $fdisplay(monitor_log_id, "time:%t\tcurrent_rated_set_value:%h", $time, state1);
    $fdisplay(monitor_log_id, "time:%t\tspeed_rated_set_value:%h", $time, state2);
    @(posedge sys_clk)
        {rx_dw1r, rx_dw2r} <= {8'h01, state1, state2, 24'd0};
    rx_valid <= 'b1;
    @(negedge rx_ready)
        rx_valid <= 'b0;
endtask
//����d�����Ʋ���ע��
task curent_d_param_reload(logic[15:0] state1, state2, state3);
    $fdisplay(monitor_log_id,  "time:%t\tcurrent_control_param:\tcurrent_d_p=%h\t,current_d_i=%h\t,current_d_d=%h\t", $time, state1, state2, state3);
    @(posedge sys_clk)
        {rx_dw1r, rx_dw2r} <= {8'h02, state1, state2, state3, 8'h00};
    rx_valid <= 'b1;
    @(negedge rx_ready)
        rx_valid <= 'b0;
endtask
task curent_q_param_reload(logic[15:0] state1, state2, state3);
    $fdisplay(monitor_log_id,  "time:%t\tcurrent_control_param:\tcurrent_q_p=%h\t,current_q_i=%h\t,current_q_d=%h\t", $time, state1, state2, state3);
    @(posedge sys_clk)
        {rx_dw1r, rx_dw2r} <= {8'h03, state1, state2, state3, 8'h00};
    rx_valid <= 'b1;
    @(negedge rx_ready)
        rx_valid <= 'b0;
endtask
//ת�ٻ�ע��
task speed_param_reload(logic[15:0] state1, state2, state3);
    $fdisplay(monitor_log_id,  "time:%t\tspeed_control_param:\tspeed_p=%h\t,speed_i=%h\t,speed_d=%h\t", $time, state1, state2, state3);
    @(posedge sys_clk)
        {rx_dw1r, rx_dw2r} <= {8'h04, state1, state2, state3, 8'h00};
    rx_valid <= 'b1;
    @(negedge rx_ready)
        rx_valid <= 'b0;
endtask
//λ�û����Ʋ���ע��
task location_param_reload(logic[15:0] state1, state2, state3);
    $fdisplay(monitor_log_id,  "time:%t\tlocation_control_param:\tlocation_p=%h\t,location_i=%h\t,location_d=%h\t", $time, state1, state2, state3);
    @(posedge sys_clk)
        {rx_dw1r, rx_dw2r} <= {8'h05, state1, state2, state3, 8'h00};
    rx_valid <= 'b1;
    @(negedge rx_ready)
        rx_valid <= 'b0;
endtask
//��բָ��ע��
task band_break_reload(logic[7:0] state1);
    $fdisplay(monitor_log_id,  "time:%t\tband_breaks_mode:\t%h\t", $time, state1);
    @(posedge sys_clk)
        {rx_dw1r, rx_dw2r} <= {8'h06, state1, 48'd0};
    rx_valid <= 'b1;
    @(negedge rx_ready)
        rx_valid <= 'b0;
endtask
//���ͣ��ָ��ע��
task motor_start_stop_reload(logic[7:0] state1);
    $fdisplay(monitor_log_id, "time:%t\tpmsm_start_stop_mode:\t%h\t", $time, state1);
    @(posedge sys_clk)
        {rx_dw1r, rx_dw2r} <= {8'h07, state1, 48'd0};
    rx_valid <= 'b1;
    @(negedge rx_ready)
        rx_valid <= 'b0;
endtask
//�������ģʽע��
task motor_work_mode_reload(logic[7:0] state1, logic[15:0] state2, state3);
    $fdisplay(monitor_log_id, "time:%t\tpmsm_work_mode:\t%h\t", $time, state1[7:4]);
    $fdisplay(monitor_log_id, "time:%t\tpmsm_speed_set_value:\t%h\t", $time, state2);
    $fdisplay(monitor_log_id, "time:%t\tpmsm_location_set_value:\t%h\t", $time, state3);
    @(posedge sys_clk)
        {rx_dw1r, rx_dw2r} <= {8'h08, state1, state2,16'd0,state3};
    rx_valid <= 'b1;
    @(negedge rx_ready)
        rx_valid <= 'b0;
endtask
//===========================================================================
//�ϴ����ݼ��
//===========================================================================
initial
    begin
    forever
        begin
        @(posedge sys_clk)
            if (tx_valid)
            tx_ready <= 'd0;
        else
            tx_ready <= 'd1;
        end
    end
initial
    begin
    forever
        begin
        @(posedge sys_clk)
            if (tx_valid && tx_ready)
            begin
            case (tx_dw1r[31 -: 8])
                8'h81: $fdisplay(monitor_log_id,  "time:%t\tgate driver state register set value %h\t%h\t", $time, tx_dw1r[23 -: 16], {tx_dw1r[7:0], tx_dw2r[31:24]
                                                                                                                                      });
                8'h82:$fdisplay(monitor_log_id,   "time:%t\tcurrent_value:a=%h\t,b=%h\t,state=%h\t", $time, tx_dw1r[23:8], {tx_dw1r[7:0], tx_dw2r[31:24]
                                                                                                                           }, tx_dw2r[23:8]);
                8'h83:$fdisplay(monitor_log_id,   "time:%t\telectrical_rotation_phase:\tsin=%h\t,cos=%h\t", $time, tx_dw1r[23 -: 16], {tx_dw1r[7:0], tx_dw2r[31:24]});
                8'h84:$fdisplay(monitor_log_id,   "time:%t\tU_alpha=%h\t,U_beta=%h\t", $time, tx_dw1r[23 -: 16], {tx_dw1r[7:0], tx_dw2r[31:24]});
                8'h85:$fdisplay(monitor_log_id,  "time:%t\tSVPWM switch time:\tTcma=%h\t,Tcmb=%h,Tcmc=%h\t", $time,  tx_dw1r[23:8], {tx_dw1r[7:0], tx_dw2r[31:24]
                                                                                                                                    }, tx_dw2r[23:8]);
                8'h86:$fdisplay(monitor_log_id,  "time:%t\tspeed_contriol:\tspeed_detect_val=%h\t,current_q_set_val=%h\t", $time, tx_dw1r[23 -: 16], {tx_dw1r[7:0], tx_dw2r[31:24]});
                8'h87:$fdisplay(monitor_log_id,  "time:%t\tlocation_contriol:\tpmsm_location_detect_value=%h\t,speed_set_value=%h\t", $time, {tx_dw1r[23:0], tx_dw2r[31:16]}, tx_dw2r[15:0]);
                8'h88:$fdisplay(monitor_log_id, "time:%t\tdriver_temp:\t%h", $time, tx_dw1r[23:8]);
                8'hff:ack_detection(tx_dw1r[23:16]);
                default: begin
                        $fdisplay(monitor_log_id, "time:%terror data received!!!", $time); $stop();
                    end
            endcase
            end
        end
    end

function void ack_detection(logic[7:0] id);
    case (id)
        8'h01: $fdisplay(monitor_log_id,  "time:%t\trated speed and current receive sucessful", $time);
        8'h02:$fdisplay(monitor_log_id,  "time:%t\tcurrent d control param receive sucessful", $time);
        8'h03:$fdisplay(monitor_log_id,  "time:%t\tcurrent q control param receive sucessful", $time);
        8'h04:$fdisplay(monitor_log_id,  "time:%t\tspeed control param receive sucessful", $time);
        8'h05:$fdisplay(monitor_log_id,  "time:%t\tlocation control param receive sucessful", $time);
        8'h06:$fdisplay(monitor_log_id,  "time:%t\tband break mode receive sucessful", $time);
        8'h07:$fdisplay(monitor_log_id,  "time:%t\tmotor start and stop receive sucessful", $time);
        8'h08:$fdisplay(monitor_log_id,  "time:%t\twork mode receive sucessful", $time);
        default: begin
                $fdisplay(monitor_log_id, "time:%terror data ack!!!", $time); $stop();
            end
    endcase
endfunction
endmodule


