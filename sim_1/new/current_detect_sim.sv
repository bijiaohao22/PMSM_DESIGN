`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/03/20 09:57:00
// Design Name: 
// Module Name: current_detect_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "project_param.v"

interface current_detect_phy_ifc(input sys_clk);
     logic    reset_n;              //reset signal,low active

    logic    detect_enable;    //detect_enable signale

    logic    spi_data_in;       //spi data in
    logic  spi_sclk_out;       //spi sclk out
    logic  spi_cs_n_out;      //chip select out ,low-active

    logic signed [`DATA_WIDTH-1:0] current_out;         //current detect out

    logic  [(`DATA_WIDTH/2)-1:0]   state_out;  //status of the sensor out
    logic  detect_err_out;      //current detect error out

    logic  detect_done_out;   //current detect done out 
    
    clocking test_cb @(posedge sys_clk);
            output reset_n;

            output  detect_enable;

            output spi_data_in;
            input spi_sclk_out;
            input spi_cs_n_out;

            input current_out;
            input state_out;
            input detect_err_out;
            input detect_done_out;
    endclocking

    modport test(
           clocking test_cb
           );
endinterface

//===========================================================================
//顶层测试模块
//===========================================================================
module current_detect_sim(
    );
    logic clk;
    string fsm_state_name;
    always #10 clk=~clk;
    initial
        begin
            clk=0;
        end

    current_detect_phy_ifc current_ifc(clk);
    test_demo test(current_ifc.test);

    current_detect_phy dut(
                              .sys_clk(clk),                //system clock
                              .reset_n(current_ifc.reset_n),                //reset signal,low active
      
                              .detect_enable_in(current_ifc.detect_enable), //detect_enable signale
      
                              .spi_data_in(current_ifc.spi_data_in),         //spi data in
                              .spi_sclk_out(current_ifc.spi_sclk_out),       //spi sclk out
                              .spi_cs_n_out(current_ifc.spi_cs_n_out),      //chip select out ,low-active
      
                              .current_out(current_ifc.current_out),         //current detect out
      
                              .state_out(current_ifc.state_out),  //status of the sensor out
                              .detect_err_out(current_ifc.detect_err_out),      //current detect error out
      
                              .detect_done_out(current_ifc.detect_done_out)   //current detect done out
    );

    always@(*)
        begin
            case(dut.fsm_state_cs)
               'b1:       fsm_state_name="IDLE";
               'b1<<1: fsm_state_name="tcss_wait";
               'b1<<2: fsm_state_name="data_read";
               'b1<<3: fsm_state_name="par_check";
               'b1<<4: fsm_state_name="data_proce";
               'b1<<5: fsm_state_name="tcson_wait";
            endcase
        end

endmodule
//===========================================================================
//测试程序
//===========================================================================
program test_demo(
                  current_detect_phy_ifc.test test_ifc
    );
    initial
        begin
            test_ifc.test_cb.reset_n<=0;
            repeat(10) @test_ifc.test_cb;
            test_ifc.test_cb.reset_n<=1;
            
            //发送正常数据帧
            $display("%t\t send normal data frame,data=%d",$time,$signed(13'h88-'sd4096));
            send_current(13'h88,0,1);
            @(test_ifc.test_cb.detect_done_out or test_ifc.test_cb.detect_err_out);
            //发送正常信息帧
            $display("%t\t send normal message frame,data=%d",$time,$signed(13'h88-'sd4096));
            send_current(13'h88,1,1);
             repeat (16) @(posedge test_ifc.test_cb.spi_sclk_out);
             spi_data_send(16'h4088);
            @(test_ifc.test_cb.detect_done_out or test_ifc.test_cb.detect_err_out);
            //发送OCD错误
            $display("%t\t send OCD error data frame",$time);
            send_current(13'h88,0,1,1);
            @(test_ifc.test_cb.detect_done_out or test_ifc.test_cb.detect_err_out);
            //发送HW错误
            $display("%t\t send HW error data frame",$time);
            send_current(13'hef,1,1,0,1);
            @(test_ifc.test_cb.detect_done_out or test_ifc.test_cb.detect_err_out);
            //发送OL错误
             $display("%t\t send OL error data frame",$time);
            send_current(13'h3f,1,1,0,0,1);
            @(test_ifc.test_cb.detect_done_out or test_ifc.test_cb.detect_err_out);
            //发送OT错误
            $display("%t\t send OT error data frame",$time);
            send_current(13'h3e,1,1,0,0,0,1,0);
            @(test_ifc.test_cb.detect_done_out or test_ifc.test_cb.detect_err_out);
            //发送COM错误
            $display("%t\t send COM error data frame",$time);
            send_current(13'h3e,1,1,0,0,0,0,1);
            @(test_ifc.test_cb.detect_done_out or test_ifc.test_cb.detect_err_out);
            //发送CRC错误
            $display("%t\t send HW_DIS error data frame",$time);
            send_current(13'h3e,1,0,0,0,0,0,0);
            @(test_ifc.test_cb.detect_done_out or test_ifc.test_cb.detect_err_out);
            //发送正常数据帧
            $display("%t\t send normal data frame,data=%d",$time,$signed(13'h1000-'sd4096));
            send_current(13'h1000,0,1);
            @(test_ifc.test_cb.detect_done_out or test_ifc.test_cb.detect_err_out);
            repeat(20) @test_ifc.test_cb;
            $stop; 
        end

    initial
        begin
        forever @(posedge test_ifc.test_cb.detect_done_out)
                $display("%t\t:get a current value=%d", $time, test_ifc.test_cb.current_out);
        end
    
    initial
        begin
        forever @(posedge test_ifc.test_cb.detect_err_out)
                case (test_ifc.test_cb.state_out)
                        8'b0000_0001:$display("%t\t:get a  communication error", $time);
                        8'b0000_0010:$display("%t\t:get a  OT error", $time);
                        8'b0000_0100:$display("%t\t:get a  OL error", $time);
                        8'b0000_1000:$display("%t\t:get a  HW error", $time);
                        8'b0001_0000:$display("%t\t:get a  OCD error", $time);
                        8'b0010_0000:$display("%t\t:get a  HW_DIS error", $time);
                        default:$display("%t\t:get a wrong message", $time);
                endcase
            end
    //===========================================================================
    //数据帧发送
    //===========================================================================
    task automatic send_current(input logic [12:0]  current_value,input logic status,input logic right_crc,input logic OCD=0,input logic HW=0,input logic OL=0,input logic OT=0,input COM=0);
        logic [15:0] current_message='d0;
        current_message[15] = status;
        if (status)  //0:数据信息，1：状态信息
            current_message[13:10]={HW,OL,OT,COM};
        else 
            current_message[13:0] = {OCD, current_value};

        if(right_crc) //校验正确
            current_message[14]=~^{ current_message[15] ,current_message[13:0]};
        else
            current_message[14]=^{ current_message[15] ,current_message[13:0]};
        
        spi_data_send(current_message);
    endtask
    //===========================================================================
    //spi数据传输
    //===========================================================================
    task automatic spi_data_send(input logic [15:0] current_message);
       @test_ifc.test_cb;
       test_ifc.test_cb.detect_enable <= 'b1;
       @test_ifc.test_cb;
       test_ifc.test_cb.detect_enable<='b0;
       repeat (16)
           begin
               @(posedge test_ifc.test_cb.spi_sclk_out);
               test_ifc.test_cb.spi_data_in<=current_message[15];
               current_message=current_message<<1;
           end
    endtask
endprogram

