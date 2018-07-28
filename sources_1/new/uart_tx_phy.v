// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/6/4
// Design Name:PMSM_DESIGN
// Module Name: uart_tx_phy.v
// Target Device:
// Tool versions:
// Description:�������ݷ���
//������:230400
//У�鷽ʽ:żУ��
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module uart_tx_phy #(
                     parameter band_rate=230400
                     )(
                       input    sys_clk,
                       input    reset_n,

                       input [31:0] wr_data1_in,
                       input [31:0] wr_data2_in,
                       input            wr_data_valid_in,
                       output          wr_data_ready_out,

                       output          uart_tx_out
                       );
//===========================================================================
//�ڲ���������
//===========================================================================
localparam band_bit_time_num=(10**9/230400)/`SYS_CLK_PERIOD;
localparam FSM_IDLE=1<<0;
localparam FSM_TX_SEND=1<<1;
//===========================================================================
//�ڲ���������
//===========================================================================
reg[11*8-1:0] tx_buffer_r;      //  ���ͻ�����
wire[11*8-1:0] tx_buffer_r_w;
reg[$clog2(band_bit_time_num)-1:0]  band_bit_time_cnt_r;   //  ����λ��ʱ��
reg[$clog2(11*8)-1:0] bit_num_cnt_r; //  ��������ʱ��
reg[1:0]   fsm_cs;
reg[1:0]    fsm_ns;
reg           wr_data_ready_r; //׼���÷��ͱ�־�Ĵ���

//===========================================================================
//����״̬��״̬����
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
        FSM_IDLE: begin
                if (wr_data_valid_in && wr_data_ready_r)
                    fsm_ns = FSM_TX_SEND;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_TX_SEND: begin
                if ((bit_num_cnt_r == 'd87) && (band_bit_time_cnt_r == band_bit_time_num - 1))
                    fsm_ns = FSM_IDLE;
                else
                    fsm_ns = fsm_cs;
            end
        default:fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//���ͻ�������ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        tx_buffer_r <= {88{1'b1}};
    else if (wr_data_valid_in && wr_data_ready_r)
        tx_buffer_r <= tx_buffer_r_w;
    else if (band_bit_time_cnt_r == band_bit_time_num - 1)
        tx_buffer_r <= {1'b1, tx_buffer_r[11 * 8 - 1:1]};
    else
        tx_buffer_r <= tx_buffer_r;
    end
//��ֵװ��
assign tx_buffer_r_w[0] = 'd0; //��ʼλ
assign tx_buffer_r_w[8:1] = wr_data1_in[31:24];    //  ����λ
assign tx_buffer_r_w[9] = ^wr_data1_in[31:24];     //  Ч��λ
assign tx_buffer_r_w[10] = 'd1;   //  ֹͣλ

assign tx_buffer_r_w[11] = 'd0; //��ʼλ
assign tx_buffer_r_w[19:12] = wr_data1_in[23:16];    //  ����λ
assign tx_buffer_r_w[20] = ^wr_data1_in[23:16];     //  Ч��λ
assign tx_buffer_r_w[21] = 'd1;   //  ֹͣλ

assign tx_buffer_r_w[22] = 'd0; //��ʼλ
assign tx_buffer_r_w[30:23] = wr_data1_in[15:8];    //  ����λ
assign tx_buffer_r_w[31] = ^wr_data1_in[15:8];     //  Ч��λ
assign tx_buffer_r_w[32] = 'd1;   //  ֹͣλ

assign tx_buffer_r_w[33] = 'd0; //��ʼλ
assign tx_buffer_r_w[41:34] = wr_data1_in[7:0];    //  ����λ
assign tx_buffer_r_w[42] = ^wr_data1_in[7:0];     //  Ч��λ
assign tx_buffer_r_w[43] = 'd1;   //  ֹͣλ

assign tx_buffer_r_w[44] = 'd0; //��ʼλ
assign tx_buffer_r_w[52:45] = wr_data2_in[31:24];    //  ����λ
assign tx_buffer_r_w[53] = ^wr_data2_in[31:24];     //  Ч��λ
assign tx_buffer_r_w[54] = 'd1;   //  ֹͣλ

assign tx_buffer_r_w[55] = 'd0; //��ʼλ
assign tx_buffer_r_w[63:56] = wr_data2_in[23:16];    //  ����λ
assign tx_buffer_r_w[64] = ^wr_data2_in[23:16];     //  Ч��λ
assign tx_buffer_r_w[65] = 'd1;   //  ֹͣλ

assign tx_buffer_r_w[66] = 'd0; //��ʼλ
assign tx_buffer_r_w[74:67] = wr_data2_in[15:8];    //  ����λ
assign tx_buffer_r_w[75] = ^wr_data2_in[15:8];     //  Ч��λ
assign tx_buffer_r_w[76] = 'd1;   //  ֹͣλ

assign tx_buffer_r_w[77] = 'd0; //��ʼλ
assign tx_buffer_r_w[85:78] = wr_data2_in[7:0];    //  ����λ
assign tx_buffer_r_w[86] = ^wr_data2_in[7:0];     //  Ч��λ
assign tx_buffer_r_w[87] = 'd1;   //  ֹͣλ

//===========================================================================
//����λ��ʱ��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        band_bit_time_cnt_r <= 'd0;
    else if (fsm_cs == FSM_TX_SEND)
        begin
        if (band_bit_time_cnt_r == band_bit_time_num - 1)
            band_bit_time_cnt_r <= 'd0;
        else
            band_bit_time_cnt_r <= band_bit_time_cnt_r + 1'b1;
        end else
        band_bit_time_cnt_r <= 'd0;
    end
//===========================================================================
//����λ������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        bit_num_cnt_r <= 'd0;
    else if (fsm_cs == FSM_TX_SEND)
        begin
        if (band_bit_time_cnt_r == band_bit_time_num - 'b1)
            bit_num_cnt_r <= bit_num_cnt_r + 'b1;
        else
            bit_num_cnt_r <= bit_num_cnt_r;
        end else
        bit_num_cnt_r <= 'd0;
    end
//===========================================================================
//����׼���ñ�־�Ĵ���
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_data_ready_r <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        begin
        if (wr_data_ready_r && wr_data_valid_in)
            wr_data_ready_r <= 'd0;
        else
            wr_data_ready_r <= 'd1;
        end else
        wr_data_ready_r <= 'd0;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign wr_data_ready_out=wr_data_ready_r;
assign uart_tx_out=tx_buffer_r[0];
endmodule
