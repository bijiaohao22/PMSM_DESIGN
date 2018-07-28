//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/23
// Design Name:PMSM_DESIGN
// Module Name: location_control_sim.sv
// Target Device:
// Tool versions:
// Description:
// Dependencies:位置控制模式功能仿真
// Revision:
// Additional Comments:
//====================================================================================
`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module location_control_sim();
//===========================================================================
//变量声明
//===========================================================================
logic sys_clk;
logic reset_n;
logic location_loop_control_enable;
logic location_detection_enable;
logic vlx_data,vlx_clk;
logic  [(`DATA_WIDTH*2+2)-1:0]    pmsm_location_set_value;
logic  [`DATA_WIDTH-1:0]    pmsm_location_control_speed_set_value;
logic  pmsm_location_control_done;
//===========================================================================
//DUT
//===========================================================================
location_control_unit dut(
                          .sys_clk(sys_clk),
                          .reset_n(reset_n),

                          .location_loop_control_enable_in(location_loop_control_enable),    //  位置控制使能输入
                          .location_detection_enable_in(location_detection_enable),          //  位置检测使能输入

                          .vlx_data_in(vlx_data),                         //  ssi接口数据输入
                          .vlx_clk_out(vlx_clk),                        //  ssi接口时钟输出

                          .pmsm_location_set_value_in(pmsm_location_set_value),    //转速模式设定值，包含转动位置及转动速度

                          .pmsm_location_control_speed_set_value_out(pmsm_location_control_speed_set_value),    // 位置控制模式下转速设定值输出

                          .pmsm_location_control_done_out(pmsm_location_control_done)   //位置控制模式控制计算完成标志
                          );
//===========================================================================
//时钟与复位
//===========================================================================
initial
    begin
    reset_n = 'd0;
    sys_clk = 0;
    
    vlx_data = 1;
    pmsm_location_set_value = 0;
    #100;
    reset_n = 1;
    end
initial
    begin
    forever
        #1 sys_clk = ~sys_clk;
    end
//===========================================================================
//数据注入
//===========================================================================
initial
    begin
        #1000;
        ssi_data_gen(18'h1fd3a);
        location_set_gen(16'h7000,18'h1a34f);
        ssi_data_gen(18'h1a34f-'d40);
        location_set_gen(16'h7000,18'h1a34f);
        ssi_data_gen(18'h1a34f+'d40);
        location_set_gen(16'h7000,18'h1a34f);
        ssi_data_gen(18'h132f1);
        location_set_gen(16'h7000,18'h0);
        ssi_data_gen(18'h0-'d40);
        location_set_gen(16'h7000,18'h0);
        ssi_data_gen(18'h0+'d40);
        location_set_gen(16'h7000,18'h0);

        ssi_data_gen(18'h1fd3a);
        location_set_gen(16'hf000,18'h1a34f);
        ssi_data_gen(18'h1a34f-'d40);
        location_set_gen(16'hf000,18'h1a34f);
        ssi_data_gen(18'h1a34f+'d40);
        location_set_gen(16'hf000,18'h1a34f);
        ssi_data_gen(18'h132f1);
        location_set_gen(16'hf000,18'h0);
        ssi_data_gen(18'h0-'d40);
        location_set_gen(16'hf000,18'h0);
        ssi_data_gen(18'h0+'d40);
        location_set_gen(16'hf000,18'h0);
        #1000;
        $stop;
    end
task location_set_gen(logic [15:0] speed_set_value,logic [17:0] set_value);
    #20;
    @(posedge sys_clk )
    location_loop_control_enable<=1;
    pmsm_location_set_value<={speed_set_value,set_value};
    @(posedge sys_clk )
    location_loop_control_enable<=0;
endtask
task ssi_data_gen(logic[17:0]  location_value);
    @(posedge sys_clk)
        location_detection_enable <= 'b1;
    @(posedge sys_clk)
        location_detection_enable <= 'd0;
    for (int i = 0; i <= 17; i++)
        begin
        @(posedge vlx_clk)
            vlx_data <= location_value[17 - i];
        end
        @(posedge vlx_clk)
        vlx_data<='d1;
        #100;
endtask
endmodule
