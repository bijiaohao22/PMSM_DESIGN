// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/6/4
// Design Name:PMSM_DESIGN
// Module Name: uart_rx_phy.v
// Target Device:
// Tool versions:
// Description:�������ݽ���
//������:230400
//У�鷽ʽ:żУ��
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module uart_rx_phy #(
                     parameter band_rate = 230400
                     ) (
                        input    sys_clk,
                        input    reset_n,

                        input    uart_rx_in,

                        output[31:0]  rx_data1_out,
                        output[31:0]   rx_data2_out,
                        output              rx_valid_out,
                        input                rx_ready_in
                        );
//===========================================================================
//�ڲ���������
//===========================================================================
localparam band_bit_time_num = (10 ** 9 / 230400) / `SYS_CLK_PERIOD;
localparam FSM_IDLE = 1 << 0;
localparam FSM_RX_START_DETECT = 1 << 1;
localparam FSM_RX_DATA_REC = 1 << 2;
localparam FSM_RX_DATA_CHECK = 1 << 3;
localparam FSM_RX_REC_DONE = 1 << 4;
//===========================================================================
//�ڲ���������
//===========================================================================
reg[7:0] rx_data_buffer_r;       //  ���ջ�����
reg[$clog2(band_bit_time_num)-1:0]  band_bit_time_cnt_r;   //  ����λ��ʱ��
reg[3:0]  rx_bit_cnt_r;      //    ����bit������
reg[3:0]  rx_byte_cnt_r;     //  �����ֽڼ����Ĵ���
reg          rx_datacheck_err_r;   //  ����Ч������־�Ĵ���
reg[4:0]  fsm_cs,
    fsm_ns;
reg[2:0]  rx_port_buffer_r;   //rx���Ž�����
reg[7:0] rx_data0_r;
reg[7:0] rx_data1_r;
reg[7:0] rx_data2_r;
reg[7:0] rx_data3_r;
reg[7:0] rx_data4_r;
reg[7:0] rx_data5_r;
reg[7:0] rx_data6_r;
reg[7:0] rx_data7_r;
reg        rx_valid_r;
//===========================================================================
//����״̬��״̬ת��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        fsm_cs <= FSM_IDLE;
    else
        fsm_cs <= fsm_ns;
    end
always @(*)
    begin
    case (fsm_cs)
        FSM_IDLE,
                FSM_RX_START_DETECT: begin
                if (rx_port_buffer_r[2:1] == 2'b10) //��⵽�½�����ʼλ
                    fsm_ns = FSM_RX_DATA_REC;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_RX_DATA_REC: begin
                if ((band_bit_time_cnt_r == band_bit_time_num - 'b1) && (rx_bit_cnt_r == 'd8))  //������ʼλ������λ
                    fsm_ns = FSM_RX_DATA_CHECK;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_RX_DATA_CHECK: begin
                if (band_bit_time_cnt_r == band_bit_time_num - 'b1)
                    begin
                    if (rx_byte_cnt_r == 'd7)
                        fsm_ns = FSM_RX_REC_DONE;
                    else
                        fsm_ns = FSM_RX_START_DETECT;
                    end else
                    fsm_ns = fsm_cs;
            end
        FSM_RX_REC_DONE: begin
                fsm_ns = FSM_IDLE;
            end
        default:fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//uart rx���뻺��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_port_buffer_r <= 'b111;
    else
        rx_port_buffer_r <= {rx_port_buffer_r[1:0], uart_rx_in};
    end
//===========================================================================
//����bit������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_bit_cnt_r <= 'd0;
    else if (fsm_cs == FSM_RX_DATA_REC)
        begin
        if (band_bit_time_cnt_r == band_bit_time_num - 'b1)
            rx_bit_cnt_r <= rx_bit_cnt_r + 'b1;
        else
            rx_bit_cnt_r <= rx_bit_cnt_r;
        end else
        rx_bit_cnt_r <= 'd0;
    end
//===========================================================================
//λʱ�����
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        band_bit_time_cnt_r <= 'd0;
    else if (fsm_cs == FSM_RX_DATA_REC || fsm_cs == FSM_RX_DATA_CHECK)
        begin
        if (band_bit_time_cnt_r == band_bit_time_num - 1'b1)
            band_bit_time_cnt_r <= 'd0;
        else
            band_bit_time_cnt_r <= band_bit_time_cnt_r + 1'b1;
        end else
        band_bit_time_cnt_r <= 'd0;
    end
//===========================================================================
//�����ֽڼ���
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_byte_cnt_r <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        rx_byte_cnt_r <= 'd0;
    else if ((band_bit_time_cnt_r == band_bit_time_num - 1'b1) && (fsm_cs == FSM_RX_DATA_CHECK))
        rx_byte_cnt_r <= rx_byte_cnt_r + 1'b1;
    else
        rx_byte_cnt_r <= rx_byte_cnt_r;
    end
//===========================================================================
//���ݽ��ջ���������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_data_buffer_r <= 'hff;
    else if ((fsm_cs == FSM_RX_DATA_REC) && (band_bit_time_cnt_r == band_bit_time_num / 2))
        rx_data_buffer_r <= {rx_port_buffer_r[2], rx_data_buffer_r[7:1]};
    else
        rx_data_buffer_r <= rx_data_buffer_r;
    end
//===========================================================================
//��żЧ��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_datacheck_err_r <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        rx_datacheck_err_r <= 'd0;
    else if ((fsm_cs == FSM_RX_DATA_CHECK) && (band_bit_time_cnt_r == band_bit_time_num / 2) && (^{rx_data_buffer_r, rx_port_buffer_r[2]}))
        rx_datacheck_err_r <= 'd1;
    else
        rx_datacheck_err_r <= rx_datacheck_err_r;
    end
//===========================================================================
//���ռĴ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_data0_r <= 'd0;
    else if ((fsm_cs == FSM_RX_DATA_CHECK) && (rx_byte_cnt_r == 'd0))
        rx_data0_r <= rx_data_buffer_r;
    else
        rx_data0_r <= rx_data0_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_data1_r <= 'd0;
    else if ((fsm_cs == FSM_RX_DATA_CHECK) && (rx_byte_cnt_r == 'd1))
        rx_data1_r <= rx_data_buffer_r;
    else
        rx_data1_r <= rx_data1_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_data2_r <= 'd0;
    else if ((fsm_cs == FSM_RX_DATA_CHECK) && (rx_byte_cnt_r == 'd2))
        rx_data2_r <= rx_data_buffer_r;
    else
        rx_data2_r <= rx_data2_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_data3_r <= 'd0;
    else if ((fsm_cs == FSM_RX_DATA_CHECK) && (rx_byte_cnt_r == 'd3))
        rx_data3_r <= rx_data_buffer_r;
    else
        rx_data3_r <= rx_data3_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_data4_r <= 'd0;
    else if ((fsm_cs == FSM_RX_DATA_CHECK) && (rx_byte_cnt_r == 'd4))
        rx_data4_r <= rx_data_buffer_r;
    else
        rx_data4_r <= rx_data4_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_data5_r <= 'd0;
    else if ((fsm_cs == FSM_RX_DATA_CHECK) && (rx_byte_cnt_r == 'd5))
        rx_data5_r <= rx_data_buffer_r;
    else
        rx_data5_r <= rx_data5_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_data6_r <= 'd0;
    else if ((fsm_cs == FSM_RX_DATA_CHECK) && (rx_byte_cnt_r == 'd6))
        rx_data6_r <= rx_data_buffer_r;
    else
        rx_data6_r <= rx_data6_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_data7_r <= 'd0;
    else if ((fsm_cs == FSM_RX_DATA_CHECK) && (rx_byte_cnt_r == 'd7))
        rx_data7_r <= rx_data_buffer_r;
    else
        rx_data7_r <= rx_data7_r;
    end
//===========================================================================
//������Ч��־��ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_valid_r <= 'd0;
    else if (rx_valid_r && rx_ready_in)
        rx_valid_r <= 'd0;
    else if ((fsm_cs == FSM_RX_REC_DONE) && (!rx_datacheck_err_r))
        rx_valid_r <= 'd1;
    else
        rx_valid_r <= rx_valid_r;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign rx_data1_out = {rx_data0_r, rx_data1_r, rx_data2_r, rx_data3_r};
assign rx_data2_out = {rx_data4_r, rx_data5_r, rx_data6_r, rx_data7_r};
assign rx_valid_out = rx_valid_r;
endmodule
    