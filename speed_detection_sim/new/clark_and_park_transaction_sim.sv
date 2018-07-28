//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/26
// Design Name:PMSM_DESIGN
// Module Name: clark_and_park_transaction_sim.sv
// Target Device:
// Tool versions:
// Description:验证CLARK变换和PARK变换的正确性
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"

module clark_and_park_transaction_sim;
logic sys_clk;
logic reset_n;
logic transaction_enable;
logic    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_in;   //  电气角度正弦值
logic    signed [`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_in;  //  电气角度余弦值

logic    signed [`DATA_WIDTH-1:0]    phase_a_current_in;                      //  a相电流检测值
logic    signed [`DATA_WIDTH-1:0]    phase_b_current_in;                      //  b相电流检测值
logic    signed [`DATA_WIDTH-1:0]    current_q_out;
logic    signed [`DATA_WIDTH-1:0]    current_d_out;
logic    transaction_valid_out;
real     current_alpha,current_beta, current_q,
    current_d;
    real pi;
real current_a,current_b;
logic    signed [`DATA_WIDTH-1:0]  error_d,error_q;
//===========================================================================
//模块例化
//===========================================================================
clark_and_park_transaction clark_and_park_transaction_inst(
                                                           .sys_clk(sys_clk),    //system clock
                                                           .reset_n(reset_n),    //active-low,reset signal

                                                           .transaction_enable_in(transaction_enable),  //转换使能信号

                                                           .electrical_rotation_phase_sin_in(electrical_rotation_phase_sin_in),   //  电气角度正弦值
                                                           .electrical_rotation_phase_cos_in(electrical_rotation_phase_cos_in),  //  电气角度余弦值

                                                           .phase_a_current_in(phase_a_current_in),                      //  a相电流检测值
                                                           .phase_b_current_in(phase_b_current_in),                      //  b相电流检测值

                                                           .current_q_out(current_q_out),                              //  Iq电流输出
                                                           .current_d_out(current_d_out),                              //  Id电流输出
                                                           .transaction_valid_out(transaction_valid_out)                               //转换输出有效信号
);
initial
    begin
    sys_clk = 0;
    reset_n = 0;
    transaction_enable = 0;
    pi=3.1415926;
    #10 reset_n = 1;
    end
always #1 sys_clk=~sys_clk;
initial
    begin
       #20;
///     data_generator(0.5,0.5,0);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0.5,60);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0.5,90);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0.5,145);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0.5,225);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0.5,270);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0.5,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(1,1,0);
///     @(negedge transaction_valid_out);
///     data_generator(1,1,60);
///     @(negedge transaction_valid_out);
///     data_generator(1,1,90);
///     @(negedge transaction_valid_out);
///     data_generator(1,1,145);
///     @(negedge transaction_valid_out);
///     data_generator(1,1,225);
///     @(negedge transaction_valid_out);
///     data_generator(1,1,270);
///     @(negedge transaction_valid_out);
///     data_generator(1,1,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(0,0.5,0);
///     @(negedge transaction_valid_out);
///     data_generator(0,0.5,60);
///     @(negedge transaction_valid_out);
///     data_generator(0,0.5,90);
///     @(negedge transaction_valid_out);
///     data_generator(0,0.5,145);
///     @(negedge transaction_valid_out);
///     data_generator(0,0.5,225);
///     @(negedge transaction_valid_out);
///     data_generator(0,0.5,270);
///     @(negedge transaction_valid_out);
///     data_generator(0,0.5,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(0.5,0,0);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0,60);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0,90);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0,145);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0,225);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0,270);
///     @(negedge transaction_valid_out);
///     data_generator(0.5,0,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(0,1,0);
///     @(negedge transaction_valid_out);
///     data_generator(0,1,60);
///     @(negedge transaction_valid_out);
///     data_generator(0,1,90);
///     @(negedge transaction_valid_out);
///     data_generator(0,1,145);
///     @(negedge transaction_valid_out);
///     data_generator(0,1,225);
///     @(negedge transaction_valid_out);
///     data_generator(0,1,270);
///     @(negedge transaction_valid_out);
///     data_generator(0,1,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(1,0,0);
///     @(negedge transaction_valid_out);
///     data_generator(1,0,60);
///     @(negedge transaction_valid_out);
///     data_generator(1,0,90);
///     @(negedge transaction_valid_out);
///     data_generator(1,0,145);
///     @(negedge transaction_valid_out);
///     data_generator(1,0,225);
///     @(negedge transaction_valid_out);
///     data_generator(1,0,270);
///     @(negedge transaction_valid_out);
///     data_generator(1,0,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(-0.5,-0.5,0);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,-0.5,60);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,-0.5,90);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,-0.5,145);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,-0.5,225);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,-0.5,270);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,-0.5,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(-1,-1,0);
///     @(negedge transaction_valid_out);
///     data_generator(-1,-1,60);
///     @(negedge transaction_valid_out);
///     data_generator(-1,-1,90);
///     @(negedge transaction_valid_out);
///     data_generator(-1,-1,145);
///     @(negedge transaction_valid_out);
///     data_generator(-1,-1,225);
///     @(negedge transaction_valid_out);
///     data_generator(-1,-1,270);
///     @(negedge transaction_valid_out);
///     data_generator(-1,-1,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(0,-0.5,0);
///     @(negedge transaction_valid_out);
///     data_generator(0,-0.5,60);
///     @(negedge transaction_valid_out);
///     data_generator(0,-0.5,90);
///     @(negedge transaction_valid_out);
///     data_generator(0,-0.5,145);
///     @(negedge transaction_valid_out);
///     data_generator(0,-0.5,225);
///     @(negedge transaction_valid_out);
///     data_generator(0,-0.5,270);
///     @(negedge transaction_valid_out);
///     data_generator(0,-0.5,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(-0.5,0,0);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,0,60);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,0,90);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,0,145);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,0,225);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,0,270);
///     @(negedge transaction_valid_out);
///     data_generator(-0.5,0,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(0,-1,0);
///     @(negedge transaction_valid_out);
///     data_generator(0,-1,60);
///     @(negedge transaction_valid_out);
///     data_generator(0,-1,90);
///     @(negedge transaction_valid_out);
///     data_generator(0,-1,145);
///     @(negedge transaction_valid_out);
///     data_generator(0,-1,225);
///     @(negedge transaction_valid_out);
///     data_generator(0,-1,270);
///     @(negedge transaction_valid_out);
///     data_generator(0,-1,300);
///     @(negedge transaction_valid_out);
///
///     data_generator(-1,0,0);
///     @(negedge transaction_valid_out);
///     data_generator(-1,0,60);
///     @(negedge transaction_valid_out);
///     data_generator(-1,0,90);
///     @(negedge transaction_valid_out);
///     data_generator(-1,0,145);
///     @(negedge transaction_valid_out);
///     data_generator(-1,0,225);
///     @(negedge transaction_valid_out);
///     data_generator(-1,0,270);
///     @(negedge transaction_valid_out);
///     data_generator(-1,0,300);
///     @(negedge transaction_valid_out);
    for(int i=0;i<=720;i++)
        begin
            data_generator(i);
        end
        $stop;
    end
/////===========================================================================
/////数据产生函数
/////===========================================================================
///task data_generator(real current_a, real current_b, real theta);
///    @(negedge sys_clk);
///    electrical_rotation_phase_sin_in = (2 ** 15 - 1) * $sin(theta*pi/180);
///    electrical_rotation_phase_cos_in = (2 ** 15 - 1) * $cos(theta*pi/180);
///    phase_a_current_in = (2 ** 15 - 1) * (current_a);
///    phase_b_current_in = (2 ** 15 - 1) * current_b;
///    transaction_enable=1;
///    current_alpha =current_a;
///    current_beta=current_a/$sqrt(3)+current_b*2/$sqrt(3);
///    current_d= $cos(theta*pi/180)*current_alpha+$sin(theta*pi/180)*current_beta;
///    current_q=-$sin(theta*pi/180)*current_alpha+$cos(theta*pi/180)*current_beta;
///    $display("current_a=%f\tcurrent_b=%f\ttheta=%f", current_a, current_b, theta);
///    @(negedge sys_clk);
///    transaction_enable=0;
///endtask

//===========================================================================
//数据产生函数
//===========================================================================
task data_generator( real theta);
    @(negedge sys_clk);
    current_a=$cos(theta*pi/180);
    current_b=$cos((theta+120)*pi/180);
    electrical_rotation_phase_sin_in = (2 ** 15 - 1) * $sin(theta*pi/180);
    electrical_rotation_phase_cos_in = (2 ** 15 - 1) * $cos(theta*pi/180);
    phase_a_current_in = (2 ** 15 - 1) * (current_a);
    phase_b_current_in = (2 ** 15 - 1) * current_b;
    transaction_enable=1;
    current_alpha =current_a;
    current_beta=current_a/$sqrt(3)+current_b*2/$sqrt(3);
    current_d= $cos(theta*pi/180)*current_alpha+$sin(theta*pi/180)*current_beta;
    current_q=-$sin(theta*pi/180)*current_alpha+$cos(theta*pi/180)*current_beta;
    $display("current_a=%f\tcurrent_b=%f\ttheta=%f", current_a, current_b, theta);
    @(negedge sys_clk);
    transaction_enable=0;
    @(negedge transaction_valid_out);
endtask
always @(posedge sys_clk)
    begin
        if(clark_and_park_transaction_inst.fsm_cs=='d4&&(clark_and_park_transaction_inst.delay_time_cnt=='d1||clark_and_park_transaction_inst.delay_time_cnt=='d3))
             if(clark_and_park_transaction_inst.product_sum_w[(`DATA_WIDTH*3)-:4]!=4'd0&&clark_and_park_transaction_inst.product_sum_w[(`DATA_WIDTH*3)-:4]!=4'hf)
              $display("%t:\t out of range",$time);
    end
always @(transaction_valid_out)
    begin
        error_d=current_d*(2**15-1)-current_d_out;
        error_q = current_q * (2 ** 15 - 1)- current_q_out;
    end

endmodule
