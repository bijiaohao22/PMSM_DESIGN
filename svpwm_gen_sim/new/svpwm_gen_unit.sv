       // Company:
// Engineer: LiXiaoChuang
// Create Date: 2018/5/2
// Design Name:PMSM_DESIGN
// Module Name: svpwm_gen_unit.sv
// Target Device:
// Tool versions:
// Description: svpwm仿真验证模块
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module svpwm_gen_unit;
//===========================================================================
//变量声明
//===========================================================================
logic sys_clk,reset_n;
logic svpwm_cal_enable;
logic system_initilization_done;
logic signed [`DATA_WIDTH-1:0] U_alpha,U_beta;
logic phase_a_high_side,phase_a_low_side,phase_b_high_side,phase_b_low_side,phase_c_high_side,phase_c_low_side;

int N_node;
real value_x,
    value_y,
    value_z;
logic signed[`DATA_WIDTH-1:0] value_x_r,
    value_y_r,
    value_z_r;
real time_t1,
    time_t2;
logic signed[`DATA_WIDTH-1:0] t1,t2;
real ta,tb,tc;
logic signed[`DATA_WIDTH-1:0]Ta,Tb,Tc,Tcma,Tcmb,Tcmc;
wire [30:0]   ualpha,ubeta;
assign ualpha ={U_alpha ,15'd0};
assign ubeta=(((U_beta <<< 'd14) + (U_beta <<< 'd11)) + ((U_beta <<< 9) - (U_beta <<< 5)) + ((U_beta <<< 2) + (U_beta <<< 1)));

//===========================================================================
//DUT
//===========================================================================
svpwm_unit_module svpwm_unit(
                             .sys_clk(sys_clk),
                             .reset_n(reset_n),

                             .svpwm_cal_enable_in(svpwm_cal_enable),                 //     SVPWM计算使能
                             .system_initilization_done_in(system_initilization_done),              //  系统初始换完成输入,高电平有效

                             .U_alpha_in(U_alpha),       //    Ualpha电压输入
                             .U_beta_in(U_beta),         //    Ubeta电压输入

                             .phase_a_high_side_out(phase_a_high_side),                     //    a相上桥壁控制
                             .phase_a_low_side_out(phase_a_low_side),                      //    a相下桥臂控制
                             .phase_b_high_side_out(phase_b_high_side),                    //    b相上桥臂控制
                             .phase_b_low_side_out(phase_b_low_side),                     //    b相下桥臂控制
                             .phase_c_high_side_out(phase_c_high_side),                    //     c相上桥臂控制
                             .phase_c_low_side_out(phase_c_low_side)                      //     c相下桥臂控制
);
//===========================================================================
//
//===========================================================================
initial
    begin
    reset_n = 0;
    sys_clk = 0;
    svpwm_cal_enable = 0;
    system_initilization_done = 0;
    U_alpha = 16'h3fff;
    U_beta = 16'h1fff;
    #10;
    reset_n = 1;
    system_initilization_done=1;
    end
always #1 sys_clk = ~sys_clk;
initial
    begin
        #20000;
        Data_generation(-1,-1);
        Data_generation(-1,-0.5);
        Data_generation(-1,0);
        Data_generation(-1,0.5);
        Data_generation(-1,1);

        Data_generation(-0.5,-1);
        Data_generation(-0.5,-0.5);
        Data_generation(-0.5,0);
        Data_generation(-0.5,0.5);
        Data_generation(-0.5,1);

        Data_generation(0,-1);
        Data_generation(0,-0.5);
        Data_generation(0,0);
        Data_generation(0,0.5);
        Data_generation(0,1);

        Data_generation(0.5,-1);
        Data_generation(0.5,-0.5);
        Data_generation(0.5,0);
        Data_generation(0.5,0.5);
        Data_generation(0.5,1);

        Data_generation(1,-1);
        Data_generation(1,-0.5);
        Data_generation(1,0);
        Data_generation(1,0.5);
        Data_generation(1,1);
        $stop;
    end
//===========================================================================
//数据产生于验证
//===========================================================================
task Data_generation(real v_alpha, real v_beta);
    $display("time:%t\t, v_alpha=%f,v_beta=%f", $time, v_alpha, v_beta);
    @(posedge sys_clk);
    svpwm_cal_enable <= 1;
    U_alpha <= v_alpha * (2 ** 15 - 1);
    U_beta <= v_beta * (2 ** 15 - 1);
    @(posedge sys_clk);
    svpwm_cal_enable <= 0;
    svpwm_reference(v_alpha, v_beta);
    #20000;
endtask

function void  svpwm_reference(real v_alpha, real v_beta);
    int A,B,C;
    //initial
        begin
        if (v_beta > 0)
            A = 1;
        else
            A = 0;
        if (($sqrt(3) * v_alpha - v_beta) > 0)
            B = 1;
        else
            B = 0;
        if ((-$sqrt(3) * v_alpha - v_beta) > 0)
            C = 1;
        else
            C = 0;
        N_node = 4 * C + 2 * B + A;
        $display("N_node=%d", N_node);
        value_x = v_beta;
        value_y = ($sqrt(3) * v_alpha + v_beta) / 2;
        value_z = (-$sqrt(3) * v_alpha + v_beta) / 2;
        value_x_r = value_x * (2 ** 15 - 1);
        value_y_r = value_y * (2 ** 15 - 1);
        value_z_r = value_z * (2 ** 15 - 1);
        $display("value_x=%f\nvalue_y=%f\nvalue=%f", value_x, value_y, value_z);
        $display("value_x=%d\nvalue_y=%d\nvalue=%d", value_x_r, value_y_r, value_z_r);
        case (N_node)
            'd1: begin
                    time_t1 = value_z;
                    time_t2 = value_y;
                end
            'd2: begin
                    time_t1 = value_y;
                    time_t2 = -value_x;
                end
            'd3: begin
                    time_t1 = -value_z;
                    time_t2 = value_x;
                end
            'd4: begin
                    time_t1 = -value_x;
                    time_t2 = value_z;
                end
            'd5: begin
                    time_t1 = value_x;
                    time_t2 = -value_y;
                end
            'd6: begin
                time_t1 = -value_y;
                time_t2 = -value_z;
            end
            default:$display("cal error!!!!!");
        endcase
            if (time_t1 + time_t2 > 1)
                begin
                $display("time_t1=%f\n,time_t2=%f", time_t1, time_t2);
                 $display("reculate");
                time_t1 = time_t1 / (time_t1 + time_t2);
                time_t2 =1-time_t1;
                end
            $display("time_t1=%f\n,time_t2=%f", time_t1, time_t2);
                t1=time_t1*(2**15-1);
                t2=time_t2*(2**15-1);
             $display("t1=%d\n,t2=%d", t1, t2);
                ta=(1-time_t1-time_t2)/2;
                tb=ta+time_t1;
                tc=tb+time_t2;
                $display("ta=%f\ntb=%f\n,tc=%f",ta,tb,tc);
                Ta=ta*(2**15-1);
                Tb=tb*(2**15-1);
                Tc=tc*(2**15-1);
                $display("Ta=%d\nTb=%d\n,Tc=%d",Ta,Tb,Tc);
                case(N_node)
                    'd1:
                    begin
                        Tcma=Tb;
                        Tcmb=Ta;
                        Tcmc=Tc;
                    end
                   'd2:
                    begin
                        Tcma=Ta;
                        Tcmb=Tc;
                        Tcmc=Tb;
                    end
                    'd3:
                    begin
                        Tcma=Ta;
                        Tcmb=Tb;
                        Tcmc=Tc;
                    end
                    'd4:
                    begin
                        Tcma=Tc;
                        Tcmb=Tb;
                        Tcmc=Ta;
                    end
                'd5:
                    begin
                        Tcma=Tc;
                        Tcmb=Ta;
                        Tcmc=Tb;
                    end
                'd6:
                    begin
                        Tcma=Tb;
                        Tcmb=Tc;
                        Tcmc=Ta;
                    end
                default:$display("cal error!");
                endcase
        end
    endfunction

endmodule