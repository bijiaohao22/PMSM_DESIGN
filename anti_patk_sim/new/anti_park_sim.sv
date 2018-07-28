`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module anti_park_sim;
//===========================================================================
//��������
//===========================================================================
logic sys_clk,reset_n;
logic anti_park_enable;
logic [`DATA_WIDTH-1:0]    voltage_d,voltage_q;
logic[`DATA_WIDTH-1:0]     phase_sin,phase_cos;
logic [`DATA_WIDTH-1:0]    voltage_alpha,voltage_beta;
logic cal_done;

real   sin_theta,cos_theta,pi,ualpha,ubeta;
logic [`DATA_WIDTH-1:0]    u_alpha,u_beta;
//===========================================================================
//DUT
//===========================================================================
anti_park_unit anti_park_unit_inst(
                      .sys_clk(sys_clk ),
               .reset_n(reset_n),

                      .anti_park_cal_enable_in(anti_park_enable),       //��Park�任ʹ������

                      .voltage_d_in(voltage_d),   //Ud��ѹ����
                      .voltage_q_in(voltage_q),   //Uq��ѹ����
                      .electrical_rotation_phase_sin_in(phase_sin),   //  �����Ƕ�����ֵ
                      .electrical_rotation_phase_cos_in(phase_cos),  //  �����Ƕ�����ֵ

                      .voltage_alpha_out(voltage_alpha), //U_alpha��ѹ���
                      .voltage_beta_out(voltage_beta),   //U_beta��ѹ���
                      .anti_park_cal_valid_out(cal_done)     //��ѹ�����Ч��־
                      );
//===========================================================================
//��������
//===========================================================================
initial
    begin
        reset_n=0;
        sys_clk=0;
        pi=3.1415926;
        #20;
        reset_n=1;
    end
always #1 sys_clk =~sys_clk;
initial
    begin
        #100;
       data_gen(-1,-1,0);
       data_gen(-1,-1,60);
       data_gen(-1,-1,120);
       data_gen(-1,-1,180);
       data_gen(-1,-1,240);
       data_gen(-1,-1,300);
       
       data_gen(-0.5,-1,0);
       data_gen(-0.5,-1,60);
       data_gen(-0.5,-1,120);
       data_gen(-0.5,-1,180);
       data_gen(-0.5,-1,240);
       data_gen(-0.5,-1,300);

       data_gen(0,-1,0);
       data_gen(0,-1,60);
       data_gen(0,-1,120);
       data_gen(0,-1,180);
       data_gen(0,-1,240);
       data_gen(0,-1,300);

       data_gen(0.5,-1,0);
       data_gen(0.5,-1,60);
       data_gen(0.5,-1,120);
       data_gen(0.5,-1,180);
       data_gen(0.5,-1,240);
       data_gen(0.5,-1,300);

       data_gen(1,-1,0);
       data_gen(1,-1,60);
       data_gen(1,-1,120);
       data_gen(1,-1,180);
       data_gen(1,-1,240);
       data_gen(1,-1,300);


       data_gen(-1,-0.5,0);
       data_gen(-1,-0.5,60);
       data_gen(-1,-0.5,120);
       data_gen(-1,-0.5,180);
       data_gen(-1,-0.5,240);
       data_gen(-1,-0.5,300);
       
       data_gen(-0.5,-0.5,0);
       data_gen(-0.5,-0.5,60);
       data_gen(-0.5,-0.5,120);
       data_gen(-0.5,-0.5,180);
       data_gen(-0.5,-0.5,240);
       data_gen(-0.5,-0.5,300);

       data_gen(0,-0.5,0);
       data_gen(0,-0.5,60);
       data_gen(0,-0.5,120);
       data_gen(0,-0.5,180);
       data_gen(0,-0.5,240);
       data_gen(0,-0.5,300);

       data_gen(0.5,-0.5,0);
       data_gen(0.5,-0.5,60);
       data_gen(0.5,-0.5,120);
       data_gen(0.5,-0.5,180);
       data_gen(0.5,-0.5,240);
       data_gen(0.5,-0.5,300);

       data_gen(1,-0.5,0);
       data_gen(1,-0.5,60);
       data_gen(1,-0.5,120);
       data_gen(1,-0.5,180);
       data_gen(1,-0.5,240);
       data_gen(1,-0.5,300);


       data_gen(-1,0,0);
       data_gen(-1,0,60);
       data_gen(-1,0,120);
       data_gen(-1,0,180);
       data_gen(-1,0,240);
       data_gen(-1,0,300);
       
       data_gen(-0.5,0,0);
       data_gen(-0.5,0,60);
       data_gen(-0.5,0,120);
       data_gen(-0.5,0,180);
       data_gen(-0.5,0,240);
       data_gen(-0.5,0,300);

       data_gen(0,0,0);
       data_gen(0,0,60);
       data_gen(0,0,120);
       data_gen(0,0,180);
       data_gen(0,0,240);
       data_gen(0,0,300);

       data_gen(0.5,0,0);
       data_gen(0.5,0,60);
       data_gen(0.5,0,120);
       data_gen(0.5,0,180);
       data_gen(0.5,0,240);
       data_gen(0.5,0,300);

       data_gen(1,0,0);
       data_gen(1,0,60);
       data_gen(1,0,120);
       data_gen(1,0,180);
       data_gen(1,0,240);
       data_gen(1,0,300);


       data_gen(-1,0.5,0);
       data_gen(-1,0.5,60);
       data_gen(-1,0.5,120);
       data_gen(-1,0.5,180);
       data_gen(-1,0.5,240);
       data_gen(-1,0.5,300);
       
       data_gen(-0.5,0.5,0);
       data_gen(-0.5,0.5,60);
       data_gen(-0.5,0.5,120);
       data_gen(-0.5,0.5,180);
       data_gen(-0.5,0.5,240);
       data_gen(-0.5,0.5,300);

       data_gen(0,0.5,0);
       data_gen(0,0.5,60);
       data_gen(0,0.5,120);
       data_gen(0,0.5,180);
       data_gen(0,0.5,240);
       data_gen(0,0.5,300);

       data_gen(0.5,0.5,0);
       data_gen(0.5,0.5,60);
       data_gen(0.5,0.5,120);
       data_gen(0.5,0.5,180);
       data_gen(0.5,0.5,240);
       data_gen(0.5,0.5,300);

       data_gen(1,0.5,0);
       data_gen(1,0.5,60);
       data_gen(1,0.5,120);
       data_gen(1,0.5,180);
       data_gen(1,0.5,240);
       data_gen(1,0.5,300);


       data_gen(-1,1,0);
       data_gen(-1,1,60);
       data_gen(-1,1,120);
       data_gen(-1,1,180);
       data_gen(-1,1,240);
       data_gen(-1,1,300);
       
       data_gen(-0.5,1,0);
       data_gen(-0.5,1,60);
       data_gen(-0.5,1,120);
       data_gen(-0.5,1,180);
       data_gen(-0.5,1,240);
       data_gen(-0.5,1,300);

       data_gen(0,1,0);
       data_gen(0,1,60);
       data_gen(0,1,120);
       data_gen(0,1,180);
       data_gen(0,1,240);
       data_gen(0,1,300);

       data_gen(0.5,1,0);
       data_gen(0.5,1,60);
       data_gen(0.5,1,120);
       data_gen(0.5,1,180);
       data_gen(0.5,1,240);
       data_gen(0.5,1,300);

       data_gen(1,1,0);
       data_gen(1,1,60);
       data_gen(1,1,120);
       data_gen(1,1,180);
       data_gen(1,1,240);
       data_gen(1,1,300);
       #100;
       $stop;
    end
//===========================================================================
//��������
//===========================================================================
task data_gen(real ud,uq,theta);
    $display("time: %t",$time);
    @(posedge sys_clk );
    anti_park_enable<=1'b1;
    sin_theta = $sin(theta*pi/180);
    cos_theta = $cos(theta*pi/180);
    $display("sin_theta=%f\tcos_theta=%f", sin_theta, cos_theta);
    phase_sin = sin_theta*(2**15-1);
    phase_cos = cos_theta*(2**15-1);
    voltage_d=ud*(2**15-1);
    voltage_q=uq*(2**15-1);
    $display("voltage_d=%f\voltage_q=%f", ud, uq);
    @(posedge sys_clk );
    anti_park_enable<=1'b0;
    @(posedge cal_done);
    reference_module(ud,uq,theta);
    $display("calculate value:u_alpha=%d\tu_beta=%d\t",voltage_alpha,voltage_beta);
    @(posedge sys_clk);
endtask
//===========================================================================
//�ο�ģ��
//===========================================================================��
function  reference_module(real ud,uq,theta);
    ualpha= $cos(theta*pi/180)*ud-$sin(theta*pi/180)*uq;
    ubeta=$sin(theta*pi/180)*ud+$cos(theta*pi/180)*uq;
     $display("reference_module:ualpha=%f\tubeta=%f\t",ualpha,ubeta);
    if(ualpha>1)
        begin
          $display("ualpha should adjust");
          ualpha=1;  
        end
    if(ualpha<-1)
        begin
          $display("ualpha should adjust");
          ualpha=-1;  
        end
     if(ubeta>1)
        begin
          $display("ubeta should adjust");
          ubeta=1;  
        end
    if(ubeta<-1)
        begin
          $display("ubeta should adjust");
          ubeta=-1;  
        end
    $display("reference_module:ualpha=%f\tubeta=%f\t",ualpha,ubeta);
    u_alpha = ualpha*(2**15-1);
    u_beta = ubeta*(2**15-1);
     $display("reference_module:u_alpha=%d\tu_beta=%d\t",u_alpha,u_beta);
endfunction
endmodule
