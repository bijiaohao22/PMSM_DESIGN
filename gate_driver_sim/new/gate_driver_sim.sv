//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/9
// Design Name:PMSM_DESIGN
// Module Name: gate_driver_sim.sv
// Target Device:
// Tool versions:
// Description:դ�����������ܷ���
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module gate_driver_sim;
//===========================================================================
//�ڲ���������
//===========================================================================
logic    sys_clk,reset_n;
logic    gate_init_driver_enable;
logic    gate_driver_init_done;
logic     gate_a_high_side_in;
logic     gate_a_low_side_in;
logic     gate_b_high_side_in;
logic     gate_b_low_side_in;
logic     gate_c_high_side_in;
logic     gate_c_low_side_in;
logic    gate_driver_enable;
logic    gate_driver_nscs;
logic    gate_driver_sclk;
logic    gate_driver_sdi;
logic    gate_driver_sdo;
logic    gate_driver_nfault;
logic gate_a_high_side_out;
logic gate_a_low_side_out;
logic gate_b_high_side_out;
logic gate_b_low_side_out;
logic gate_c_high_side_out;
logic gate_c_low_side_out;
logic [`DATA_WIDTH-1:0]    gate_driver_register_1;
logic [`DATA_WIDTH-1:0]    gate_driver_register_2;
logic gate_driver_error;

logic[15:0]  write_data;

//===========================================================================
//DUT
//===========================================================================
gate_driver_unit gate_driver_inst(
                                  .sys_clk(sys_clk),
                                  .reset_n(reset_n),

                                  .gate_driver_init_enable_in(gate_init_driver_enable),  //  դ���������ϵ��λ���ʼ��ʹ������
                                  .gate_driver_init_done_out(gate_driver_init_done),  //  դ����������ʼ����ɱ�־

                                  .gate_a_high_side_in(gate_a_high_side_out),                     //    a�����űڿ���
                                  .gate_a_low_side_in(gate_a_low_side_in),                      //    a�����űۿ���
                                  .gate_b_high_side_in(gate_b_high_side_in),                    //    b�����űۿ���
                                  .gate_b_low_side_in(gate_b_low_side_in),                     //    b�����űۿ���
                                  .gate_c_high_side_in(gate_c_high_side_in),                    //     c�����űۿ���
                                  .gate_c_low_side_in(gate_c_low_side_in),                      //     c�����űۿ���

                                  .gate_driver_enable_out(gate_driver_enable),
                                  .gate_driver_nscs_out(gate_driver_nscs),
                                  .gate_driver_sclk_out(gate_driver_sclk),
                                  .gate_driver_sdi_out(gate_driver_sdi),
                                  .gate_driver_sdo_in(gate_driver_sdo),
                                  .gate_driver_nfault_in(gate_driver_nfault),

                                  .gate_a_high_side_out(gate_a_high_side_out),                     //    a�����űڿ���
                                  .gate_a_low_side_out(gate_a_low_side_out),                      //    a�����űۿ���
                                  .gate_b_high_side_out(gate_b_high_side_out),                    //    b�����űۿ���
                                  .gate_b_low_side_out(gate_b_low_side_out),                     //    b�����űۿ���
                                  .gate_c_high_side_out(gate_c_high_side_out),                    //     c�����űۿ���
                                  .gate_c_low_side_out(gate_c_low_side_out),                      //     c�����űۿ���

                                  .gate_driver_register_1_out(gate_driver_register_1),  //  դ���Ĵ���״̬1�Ĵ������
                                  .gate_driver_register_2_out(gate_driver_register_2),  //  դ���Ĵ���״̬2�Ĵ������
                                  .gate_driver_error_out(gate_driver_error)   //դ���Ĵ������ϱ������
                                  );
//===========================================================================
//ʱ���븴λ�ź�
//===========================================================================
initial
    begin
    reset_n = 0;
    sys_clk = 0;
    #50;
    reset_n = 1;
    end
initial
    begin
    forever
        begin
        #1 sys_clk = ~sys_clk;
        end
    end
//===========================================================================
//�źŲ���
//===========================================================================
initial
    begin
    gate_driver_sdo = 1;
    #100;
    //դ��������ʹ��
    @(posedge sys_clk);
    gate_init_driver_enable <= 1;
    @(posedge sys_clk);
    gate_init_driver_enable <= 0;
    @(posedge gate_driver_init_done);
    #300;
    @(posedge sys_clk);
    gate_driver_nfault <= 0;
    #10000;
    @(posedge sys_clk);
    gate_driver_nfault <= 1;
    #700;
    @(posedge sys_clk);
    gate_driver_nfault <= 0;
    #10000;
    @(posedge sys_clk);
    gate_driver_nfault <= 1;
    #3000;
    $stop();
    end
//===========================================================================
//monitor
//===========================================================================
initial
    fork
        spi_data_return(16'b0_0000_111_1010_1010, 16'b1_0000_101_0101_1011);
        spi_data_monitor();
    join
initial
    begin
    forever
        begin
        @(posedge sys_clk)
            begin
            if (gate_driver_error)
                $display("time:%t\t,register0=%h,register1=%h", $time, gate_driver_register_1, gate_driver_register_2);
            end
        end
    end
//===========================================================================
//���ݲ���
//===========================================================================
//�ű۵�ͨ�������ݲ���
initial
    begin
    forever
        begin
        @(negedge sys_clk);
        gate_a_high_side_in = $urandom(3) % 2;
        gate_a_low_side_in = $urandom(4) % 2;
        gate_b_high_side_in = $urandom(8) % 2;
        gate_b_low_side_in = $urandom(78) % 2;
        gate_c_high_side_in = $urandom(29) % 2;
        gate_c_low_side_in = $urandom(29) % 2;
        end
    end
//===========================================================================
//SPI���ݷ���
//===========================================================================
task spi_data_return(logic[15:0] register0, register1);
    logic[15:0]   register_buffer;
    reg[3:0]   addr;
    while (1)
        begin
        @(negedge  gate_driver_nscs);
        @(negedge gate_driver_sclk);
        if (gate_driver_sdi)   //   ��bitΪ�ߴ��������
            begin
            $display("time=%t\tstate register0=%h\t,register1=%h", $time, (register0 | 16'b1111_1000_0000_0000), (register1 | 16'b1111_1000_0000_0000));
            repeat (4)
                begin
                @(negedge gate_driver_sclk)
                    addr = {addr[2:0], gate_driver_sdi};
                end
            if (addr == 'h0)
                register_buffer = register0;
            else if (addr == 'h1)
                register_buffer = register1;
            for (int i = 0; i <= 10; i++)
                begin
                @(posedge gate_driver_sclk)
                    gate_driver_sdo = register_buffer[10 - i];
                end
            end
        @(posedge  gate_driver_nscs) ;
        gate_driver_sdo = 1;
        end

endtask
//===========================================================================
//SPI���ݽ��ռ��
//===========================================================================
task spi_data_monitor;
    while (1)
        begin
        @(negedge  gate_driver_nscs);
        @(negedge gate_driver_sclk);
        if (~gate_driver_sdi)   //   ��bitΪ�ʹ���д����
            begin
            write_data = 'd0;
            repeat (15)
                begin
                @(negedge gate_driver_sclk);
                write_data = {write_data[14:0], gate_driver_sdi};
                end
            $display("time:%t\treceive data:\t %h", $time, write_data);
            end
        end
endtask
endmodule
