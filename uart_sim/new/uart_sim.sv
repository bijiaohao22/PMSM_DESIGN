//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/6/4
// Design Name:PMSM_DESIGN
// Module Name: uart_sim.sv
// Target Device:
// Tool versions:
// Description:uart物理层功能仿真
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module uart_sim();
//===========================================================================
//内部变量声明
//===========================================================================
logic sys_clk;
logic reset_n;
logic out_connect;
logic[31:0]  wr_data1,
wr_data2;
logic[31:0]  rx_data1,
rx_data2;
logic wr_data_valid;
logic wr_data_ready;
logic rx_valid;
logic rx_ready;
//===========================================================================
//dut
//===========================================================================
uart_phy dut(
             .sys_clk(sys_clk),
             .reset_n(reset_n),

             .wr_data1_in(wr_data1),
             .wr_data2_in(wr_data2),
             . wr_data_valid_in(wr_data_valid),
             . wr_data_ready_out(wr_data_ready),

             .rx_data1_out(rx_data1),
             .rx_data2_out(rx_data2),
             .rx_valid_out(rx_valid),
             .rx_ready_in(rx_ready),

             .uart_rx_in(out_connect),
             .uart_tx_out(out_connect)
             );
//===========================================================================
//时钟与复位信号产生
//===========================================================================
initial
    begin
    reset_n = 'b0;
    sys_clk = 'd0;
    wr_data1 = 1;
    wr_data2 = 0;
    rx_ready = 1;
    wr_data_valid = 0;
    #100;
    reset_n = 'b1;
    end
initial
    begin
    forever
        begin
        #1 sys_clk = ~sys_clk;
        end
    end
//===========================================================================
//测试数据生成
//===========================================================================
task data_gen(logic[31:0] data1, data2);
    $display("time:%t\t,transaction data: %h\t%h\t", $time, data1, data2);
    @(posedge sys_clk)
        wr_data1 <= data1;
    wr_data2 <= data2;
    wr_data_valid <= 'd1;
    while (!wr_data_ready)
        begin
        @(posedge sys_clk);
        end
    @(posedge sys_clk)
        wr_data_valid <= 'd0;
endtask
//===========================================================================
//激励生成
//===========================================================================
initial
    begin
    #200;
    data_gen({8'h12, 8'had, 8'h43, 8'h65}, {8'hff, 8'hae, 8'h4c, 8'h2a});
    data_gen({8'h15, 8'h3d, 8'hf3, 8'h62}, {8'hfa, 8'hfe, 8'h6c, 8'h2e});
    data_gen({8'h32, 8'h1f, 8'hae, 8'hbc}, {8'hdf, 8'hfa, 8'hfc, 8'h2c});
    #500_000;
    $stop();
    end
//===========================================================================
//接收数据监控
//===========================================================================
initial
    begin
    forever
        begin
        @(posedge sys_clk)
            if (rx_valid)
            rx_ready <= 'd0;
        else
            rx_ready <= 'd1;
        end
    end
initial
    begin
    forever
        begin
        @(posedge rx_valid)
            $display("time:%t\t,receive data: %h\t%h\t", $time, rx_data1, rx_data2);
        end
    end
endmodule
