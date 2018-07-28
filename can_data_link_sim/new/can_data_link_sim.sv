//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/22
// Design Name:PMSM_DESIGN
// Module Name: can_data_link_sim.sv
// Target Device:
// Tool versions:
// Description:can总线通信数据链路仿真
// Dependencies:
// Revision:
// Additional Comments:
//===================================================================================
module can_data_link_sim();
    //===========================================================================
    //内部变量声明
    //===========================================================================
    logic sys_clk,
        reset_n,
        can_clk;
    logic can_phy_rx,
        can_phy_tx;
    logic system_initilization_done;
    logic can_init_enable,
        can_init_done;
    logic[31:0] tx_dw1r,
        tx_dw2r;
    logic tx_valid,
        tx_ready;
    logic[31:0]  rx_dw1r;
    logic[31:0]  rx_dw2r;
    logic rx_valid;
    logic rx_ready;
    integer write_log_id,read_log_id;
    //===========================================================================
    //DUT
    //===========================================================================
    can_data_link dut(
                      .sys_clk(sys_clk),
                      .can_clk(can_clk),   //  can物理层时钟
                      .reset_n(reset_n),

                      //  can物理层端口
                      .can_phy_rx(can_phy_rx),
                      .can_phy_tx(can_phy_tx),

                      .system_initilization_done_in(system_initilization_done),              //  系统初始化完成输入,高电平有效

                      .can_init_enable_in(can_init_enable),    //   can初始化使能标志
                      .can_init_done_out(can_init_done),    //    can初始化完成标志

                      .tx_dw1r_in(tx_dw1r),       //   数据发送字1，
                      .tx_dw2r_in(tx_dw2r),       //   数据发送字2，
                      .tx_valid_in(tx_valid),       //   数据发送有效标志位
                      .tx_ready_out(tx_ready),    //  数据发送准备好标志

                      .rx_dw1r_out(rx_dw1r),    //  接收数据字1
                      .rx_dw2r_out(rx_dw2r),    //  接收数据字2
                      .rx_valid_out(rx_valid),     //  接收数据有效标志
                      .rx_ready_in(rx_ready)      //  接收准备好标志输入
    );
    //===========================================================================
    //时钟产生
    //===========================================================================
    initial
        begin
        forever
            #10 sys_clk = ~sys_clk;
        end
    initial
        begin
        forever
            #25 can_clk = ~can_clk;
        end
    //===========================================================================
    //复位与初始化
    //===========================================================================
    initial
        begin
        reset_n = 0;
        sys_clk = 0;
        can_clk = 0;
        system_initilization_done = 0;
        #100;
        reset_n = 1;
        #100;
        @(posedge sys_clk)
            can_init_enable <= 'b1;
        @(posedge sys_clk)
            can_init_enable <= 'b0;
        wait(can_init_done);
        $display("%t\t,init done", $time);
        @(posedge sys_clk)
            system_initilization_done <= 1;
        end
    //===========================================================================
    //文件记录
    //===========================================================================
    initial
        begin
            write_log_id = $fopen("write_log.txt","w+");
            read_log_id = $fopen("read_log.txt","w+");
        end
    //===========================================================================
    //数据收发
    //===========================================================================
    initial
        begin
        wait(system_initilization_done);
        #100;
        for (int i = 0; i < 128; i++)
            begin
                logic [7:0] data;
                data=i;
                data_transaction({data,data+4'd1, data+4'd2, data+4'd3}, {data+4'd4,data+4'd5, data+4'd6, data+4'd7});
            end
        //data_transaction({8'h25, 8'h28, 8'h63, 8'h38}, {8'h98, 8'h5f, 8'hc2, 8'h45});
        #20_000_000;
            $fclose(write_log_id);
            $fclose(read_log_id);
        $stop;
        end
    task data_transaction(logic[31:0] tx_data1, tx_data2);
        $fdisplay(write_log_id,"time:%t\tsend data=%h\t%h\t%h\t%h\t%h\t%h\t%h\t%h\t", $time, tx_data1[31 -: 8], tx_data1[23 -: 8], tx_data1[15 -: 8], tx_data1[7 -: 8], tx_data2[31 -: 8], tx_data2[23 -: 8], tx_data2[15 -: 8], tx_data2[7 -: 8]);
        @(posedge sys_clk)
            tx_dw1r <= tx_data1;
        tx_dw2r <= tx_data2;
        tx_valid <= 'b1;
        @(posedge sys_clk);
        while (~tx_ready)
            @(posedge sys_clk);
        tx_valid <= 'd0;
    endtask
    //===========================================================================
    //接收数据监控
    //===========================================================================
    initial
        begin
        forever
            begin
            @(posedge sys_clk)
                begin
                if (rx_valid)
                    rx_ready <= 'B0;
                else
                    rx_ready <= 'b1;
                end
            end
        end
    initial
        begin
        forever
            begin
            @(posedge sys_clk)
                begin
                if (rx_valid && rx_ready)
                    $fdisplay(read_log_id, "time:%t\trecive data=%h\t%h\t%h\t%h\t%h\t%h\t%h\t%h\t", $time, rx_dw1r[31 -: 8], rx_dw1r[23 -: 8], rx_dw1r[15 -: 8], rx_dw1r[7 -: 8], rx_dw2r[31 -: 8], rx_dw2r[23 -: 8], rx_dw2r[15 -: 8], rx_dw2r[7 -: 8]);
                end
            end
        end
endmodule
