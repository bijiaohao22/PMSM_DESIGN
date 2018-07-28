//====================================================================================
// Company:
// Engineer: li_xiaochaung
// Create Date: 2018/3/30
// Design Name:PMSM_DESIGN
// Module Name: current_standardization_sim.sv
// Target Device:
// Tool versions:
// Description:电流检测标幺化功能仿真
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module current_standardization_sim();
    logic    sys_clk;
    logic    reset_n;
    logic    current_value_valid;
    logic signed   [`DATA_WIDTH-1:0] current_value;
    logic    [`DATA_WIDTH-1:0] pmsm_imax;
    logic    [`DATA_WIDTH-1:0] current_standardization;
    logic    current_porce_done;

    always #10 sys_clk=~sys_clk;

    initial
        begin
            sys_clk=0;
        end
    current_per_unit_module dut(
                                 .sys_clk(sys_clk),
                                 .reset_n(reset_n),
                                 
                                 .current_value_valid_in(current_value_valid),                                             //电流有效标志
                                 .current_value_in(current_value),                  //电流检测值
                                 
                                 . pmsm_imax_in(pmsm_imax),                    //电机额定电流值
                                 
                                 .current_standardization_out(current_standardization),  //电流标幺化输出值
                                 .current_porce_done_out(current_porce_done)                                              //电流标幺化完成标志
                               );
    current_standardization_test test(
    .sys_clk(sys_clk),
    .reset_n(reset_n),
    .current_value_valid(current_value_valid),
    .current_value(current_value),
    .pmsm_imax(pmsm_imax),
    .current_standardization(current_standardization),
    .current_porce_done(current_porce_done)
    );
endmodule
module current_standardization_test(
    input  logic    sys_clk,
    output logic    reset_n,
    output logic    current_value_valid,
    output logic signed   [`DATA_WIDTH-1:0] current_value,
    output logic    [`DATA_WIDTH-1:0] pmsm_imax,
    input  logic  signed  [`DATA_WIDTH-1:0] current_standardization,
    input  logic    current_porce_done
    );

    initial
        begin
            reset_n<='d0;
            repeat(20) @(posedge sys_clk);
            reset_n<='d1;
            repeat(10) @(posedge sys_clk);
        send_current_value('sd180,'sd2880);
        send_current_value('sd180,'sd2000);
        send_current_value('sd180,'sd1000);
        send_current_value('sd180,'sd0);
        send_current_value('sd180,-'sd2880);
        send_current_value('sd180,-'sd2000);
        send_current_value('sd180,-'sd1000);
        $stop();
        end
    task send_current_value(input logic [`DATA_WIDTH-1:0] pmsm_imax_in,
                                          input  logic signed [`DATA_WIDTH-1:0] current_value_in
                                        );
        $display("current value:%d, standardization:%d", $signed(current_value_in/160), $signed((current_value_in*(2**15-1)/(160*pmsm_imax_in))));
        @(posedge sys_clk);
        current_value_valid<='d0;
        @(posedge sys_clk);
        current_value <= current_value_in;
        pmsm_imax<=pmsm_imax_in;
        @(posedge sys_clk);
        @(posedge sys_clk);
        current_value_valid<='d1;
        @(posedge sys_clk);
        current_value_valid<='d0;
        repeat(20) @(posedge sys_clk);      
    endtask

    initial
        begin
        forever
            @(posedge current_porce_done)
                $display("standardization:%d",$signed(current_standardization));
        end
    endmodule
