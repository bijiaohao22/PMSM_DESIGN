//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/3
// Design Name:PMSM_DESIGN
// Module Name: pid_cal_sim.sv
// Target Device:
// Tool versions:
// Description:PID模型仿真
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module pid_cal_sim;
//===========================================================================
//信号声明
//===========================================================================
logic sys_clk,reset_n;
logic pid_cal_enable;
logic [`DATA_WIDTH-1:0]    pid_param_p,pid_param_i,pid_param_d;
logic [`DATA_WIDTH-1:0]    set_value,detect_value;
logic [`DATA_WIDTH-1:0]    pid_cal_value;
logic pid_cal_done;

real pid_error,pid_last_error,pid_prev_error;
real pid_cal_out,det_out;
logic [`DATA_WIDTH-1:0] error,last_error,prev_error,cal_out,det;
//===========================================================================
//DUT
//===========================================================================
pid_cal_unit pid_cal_unit_inst(
                               .sys_clk(sys_clk ),
                               .reset_n(reset_n),

                               .pid_cal_enable_in(pid_cal_enable),       //PID计算使能信号

                               .pid_param_p_in(pid_param_p),  //参数p输入
                               .pid_param_i_in(pid_param_i),   //参数i输入
                               .pid_param_d_in(pid_param_d),  //参数d输入

                               .set_value_in(set_value),        //设定值输入
                               .detect_value_in(detect_value),   //检测值输入

                               .pid_cal_value_out(pid_cal_value),    //pid计算结果输出
                               .pid_cal_done_out(pid_cal_done)                         //计算完成标志
                               );
//===========================================================================
//仿真逻辑
//===========================================================================
initial
    begin
        sys_clk=0;
        reset_n=0;
        pid_error=0;
        pid_last_error=0;
        pid_prev_error=0;
        #10;
        reset_n=1;
    end
always #1 sys_clk = ~sys_clk;
initial
    begin
        #40;
        data_generation(0.2,0,0,-1,-1);
        data_generation(0.2,0,0,-1,-0.5);
        data_generation(0.2,0,0,-1,0);
        data_generation(0.2,0,0,-1,0.5);
        data_generation(0.2,0,0,-1,1);

        data_generation(0.5,0,0,-1,-1);
        data_generation(0.5,0,0,-1,-0.5);
        data_generation(0.5,0,0,-1,0);
        data_generation(0.5,0,0,-1,0.5);
        data_generation(0.5,0,0,-1,1);

        data_generation(1,0,0,-1,-1);
        data_generation(1,0,0,-1,-0.5);
        data_generation(1,0,0,-1,0);
        data_generation(1,0,0,-1,0.5);
        data_generation(1,0,0,-1,1);

        data_generation(0.2,0.2,0,-1,-1);
        data_generation(0.2,0.2,0,-1,-0.5);
        data_generation(0.2,0.2,0,-1,0);
        data_generation(0.2,0.2,0,-1,0.5);
        data_generation(0.2,0.2,0,-1,1);

        data_generation(0.2,0.6,0,-1,-1);
        data_generation(0.2,0.6,0,-1,-0.5);
        data_generation(0.2,0.6,0,-1,0);
        data_generation(0.2,0.6,0,-1,0.5);
        data_generation(0.2,0.6,0,-1,1);

        data_generation(0.2,1,0,-1,-1);
        data_generation(0.2,1,0,-1,-0.5);
        data_generation(0.2,1,0,-1,0);
        data_generation(0.2,1,0,-1,0.5);
        data_generation(0.2,1,0,-1,1);

        data_generation(1,1,0,-1,-1);
        data_generation(1,1,0,-1,-0.5);
        data_generation(1,1,0,-1,0);
        data_generation(1,1,0,-1,0.5);
        data_generation(1,1,0,-1,1);


        data_generation(0.2,0,0,-0.5,-1);
        data_generation(0.2,0,0,-0.5,-0.5);
        data_generation(0.2,0,0,-0.5,0);
        data_generation(0.2,0,0,-0.5,0.5);
        data_generation(0.2,0,0,-0.5,1);

        data_generation(0.5,0,0,-0.5,-1);
        data_generation(0.5,0,0,-0.5,-0.5);
        data_generation(0.5,0,0,-0.5,0);
        data_generation(0.5,0,0,-0.5,0.5);
        data_generation(0.5,0,0,-0.5,1);

        data_generation(1,0,0,-0.5,-1);
        data_generation(1,0,0,-0.5,-0.5);
        data_generation(1,0,0,-0.5,0);
        data_generation(1,0,0,-0.5,0.5);
        data_generation(1,0,0,-0.5,1);

        data_generation(0.2,0.2,0,-0.5,-1);
        data_generation(0.2,0.2,0,-0.5,-0.5);
        data_generation(0.2,0.2,0,-0.5,0);
        data_generation(0.2,0.2,0,-0.5,0.5);
        data_generation(0.2,0.2,0,-0.5,1);

        data_generation(0.2,0.6,0,-0.5,-1);
        data_generation(0.2,0.6,0,-0.5,-0.5);
        data_generation(0.2,0.6,0,-0.5,0);
        data_generation(0.2,0.6,0,-0.5,0.5);
        data_generation(0.2,0.6,0,-0.5,1);

        data_generation(0.2,1,0,-0.5,-1);
        data_generation(0.2,1,0,-0.5,-0.5);
        data_generation(0.2,1,0,-0.5,0);
        data_generation(0.2,1,0,-0.5,0.5);
        data_generation(0.2,1,0,-0.5,1);

        data_generation(1,1,0,-0.5,-1);
        data_generation(1,1,0,-0.5,-0.5);
        data_generation(1,1,0,-0.5,0);
        data_generation(1,1,0,-0.5,0.5);
        data_generation(1,1,0,-0.5,1);

        
        data_generation(0.2,0,0,0,-1);
        data_generation(0.2,0,0,0,-0.5);
        data_generation(0.2,0,0,0,0);
        data_generation(0.2,0,0,0,0.5);
        data_generation(0.2,0,0,0,1);

        data_generation(0.5,0,0,0,-1);
        data_generation(0.5,0,0,0,-0.5);
        data_generation(0.5,0,0,0,0);
        data_generation(0.5,0,0,0,0.5);
        data_generation(0.5,0,0,0,1);

        data_generation(1,0,0,0,-1);
        data_generation(1,0,0,0,-0.5);
        data_generation(1,0,0,0,0);
        data_generation(1,0,0,0,0.5);
        data_generation(1,0,0,0,1);

        data_generation(0.2,0.2,0,0,-1);
        data_generation(0.2,0.2,0,0,-0.5);
        data_generation(0.2,0.2,0,0,0);
        data_generation(0.2,0.2,0,0,0.5);
        data_generation(0.2,0.2,0,0,1);

        data_generation(0.2,0.6,0,0,-1);
        data_generation(0.2,0.6,0,0,-0.5);
        data_generation(0.2,0.6,0,0,0);
        data_generation(0.2,0.6,0,0,0.5);
        data_generation(0.2,0.6,0,0,1);

        data_generation(0.2,1,0,0,-1);
        data_generation(0.2,1,0,0,-0.5);
        data_generation(0.2,1,0,0,0);
        data_generation(0.2,1,0,0,0.5);
        data_generation(0.2,1,0,0,1);

        data_generation(1,1,0,0,-1);
        data_generation(1,1,0,0,-0.5);
        data_generation(1,1,0,0,0);
        data_generation(1,1,0,0,0.5);
        data_generation(1,1,0,0,1);

        
        data_generation(0.2,0,0,0.5,-1);
        data_generation(0.2,0,0,0.5,-0.5);
        data_generation(0.2,0,0,0.5,0);
        data_generation(0.2,0,0,0.5,0.5);
        data_generation(0.2,0,0,0.5,1);

        data_generation(0.5,0,0,0.5,-1);
        data_generation(0.5,0,0,0.5,-0.5);
        data_generation(0.5,0,0,0.5,0);
        data_generation(0.5,0,0,0.5,0.5);
        data_generation(0.5,0,0,0.5,1);

        data_generation(1,0,0,0.5,-1);
        data_generation(1,0,0,0.5,-0.5);
        data_generation(1,0,0,0.5,0);
        data_generation(1,0,0,0.5,0.5);
        data_generation(1,0,0,0.5,1);

        data_generation(0.2,0.2,0,0.5,-1);
        data_generation(0.2,0.2,0,0.5,-0.5);
        data_generation(0.2,0.2,0,0.5,0);
        data_generation(0.2,0.2,0,0.5,0.5);
        data_generation(0.2,0.2,0,0.5,1);

        data_generation(0.2,0.6,0,0.5,-1);
        data_generation(0.2,0.6,0,0.5,-0.5);
        data_generation(0.2,0.6,0,0.5,0);
        data_generation(0.2,0.6,0,0.5,0.5);
        data_generation(0.2,0.6,0,0.5,1);

        data_generation(0.2,1,0,0.5,-1);
        data_generation(0.2,1,0,0.5,-0.5);
        data_generation(0.2,1,0,0.5,0);
        data_generation(0.2,1,0,0.5,0.5);
        data_generation(0.2,1,0,0.5,1);

        data_generation(1,1,0,0.5,-1);
        data_generation(1,1,0,0.5,-0.5);
        data_generation(1,1,0,0.5,0);
        data_generation(1,1,0,0.5,0.5);
        data_generation(1,1,0,0.5,1);

        
        data_generation(0.2,0,0,1,-1);
        data_generation(0.2,0,0,1,-0.5);
        data_generation(0.2,0,0,1,0);
        data_generation(0.2,0,0,1,0.5);
        data_generation(0.2,0,0,1,1);

        data_generation(0.5,0,0,1,-1);
        data_generation(0.5,0,0,1,-0.5);
        data_generation(0.5,0,0,1,0);
        data_generation(0.5,0,0,1,0.5);
        data_generation(0.5,0,0,1,1);

        data_generation(1,0,0,1,-1);
        data_generation(1,0,0,1,-0.5);
        data_generation(1,0,0,1,0);
        data_generation(1,0,0,1,0.5);
        data_generation(1,0,0,1,1);

        data_generation(0.2,0.2,0,1,-1);
        data_generation(0.2,0.2,0,1,-0.5);
        data_generation(0.2,0.2,0,1,0);
        data_generation(0.2,0.2,0,1,0.5);
        data_generation(0.2,0.2,0,1,1);

        data_generation(0.2,0.6,0,1,-1);
        data_generation(0.2,0.6,0,1,-0.5);
        data_generation(0.2,0.6,0,1,0);
        data_generation(0.2,0.6,0,1,0.5);
        data_generation(0.2,0.6,0,1,1);

        data_generation(0.2,1,0,1,-1);
        data_generation(0.2,1,0,1,-0.5);
        data_generation(0.2,1,0,1,0);
        data_generation(0.2,1,0,1,0.5);
        data_generation(0.2,1,0,1,1);

        data_generation(1,1,0,1,-1);
        data_generation(1,1,0,1,-0.5);
        data_generation(1,1,0,1,0);
        data_generation(1,1,0,1,0.5);
        data_generation(1,1,0,1,1);
        #100
        $stop;
    end

//===========================================================================
//测试用例生成
//===========================================================================
task data_generation(real pid_p,pid_i,pid_d,set_val,detect_val);
    $display("time:%t\t",$time);
    $display("p=%f\ti=%f\td=%f\tset=%f\tdetect=%f", pid_p,pid_i,pid_d,set_val,detect_val);
    @(posedge sys_clk);
    pid_param_p <= pid_p*(2**15-1);
    pid_param_i <= pid_i*(2**15-1);
    pid_param_d <= pid_d*(2**15-1);
    set_value <= set_val*(2**15-1);
    detect_value <= detect_val*(2**15-1);
    pid_cal_enable<='d1;
    @(posedge sys_clk);
    pid_cal_enable<='d0;
    reference_module(pid_p,pid_i,pid_d,set_val,detect_val);
    @(negedge pid_cal_done);
endtask
function reference_module(real pid_p,pid_i,pid_d,set_val,detect_val);
    pid_error = set_val - detect_val;
    $display("error=%f\tlast_error=%f\tprev_error=%f", pid_error, pid_last_error, pid_prev_error);
    error = pid_error*(2**15-1);
    det_out=pid_p * (pid_error - pid_last_error) + pid_i * (pid_error) + pid_d * (pid_error - 2 * pid_last_error + pid_prev_error);
    $display("delta value=%f", det_out);
    det=det_out*(2**15-1);
    pid_cal_out =pid_cal_out+det_out;
    if (pid_cal_out>1)
        begin
        $display("data should be adjueted");
        $display("pid cal out=%f", pid_cal_out);
        pid_cal_out=1;
        end
     if (pid_cal_out<-1)
        begin
        $display("data should be adjueted");
        $display("pid cal out=%f", pid_cal_out);
        pid_cal_out=-1;
        end  
    $display("pid cal out=%f", pid_cal_out);
    cal_out = pid_cal_out*(2**15-1);
    pid_prev_error=pid_last_error;
    pid_last_error=pid_error;    
    last_error=pid_last_error*(2**15-1);
    prev_error = pid_prev_error*(2**15-1);
endfunction
endmodule
