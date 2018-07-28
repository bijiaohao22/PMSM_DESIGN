//====================================================================================
// Company:
// Engineer: LiXIaochuang
// Create Date: 2018/5/16
// Design Name:PMSM_DESIGN
// Module Name: can_data_trans_unit.v
// Target Device:
// Tool versions:
// Description:can���ݴ���㣬����Ӧ�ò㴫�����ݣ��ϴ���·����յ������ݣ���д�ٲ�
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module can_data_trans_unit(
                           input    sys_clk,
                           input    reset_n,

                           input    [31:0]  tx_dw1r_in,       //   ���ݷ�����1��
                           input    [31:0]  tx_dw2r_in,       //   ���ݷ�����2��
                           input               tx_valid_in,       //   ���ݷ�����Ч��־λ
                           output             tx_ready_out,    //  ���ݷ���׼���ñ�־

                           output  [31:0] rx_dw1r_out,    //  ����������1
                           output  [31:0] rx_dw2r_out,    //  ����������2
                           output            rx_valid_out,     //  ����������Ч��־
                           input              rx_ready_in,      //  ����׼���ñ�־����

                           output  [7:0]   wr_addr_out,
                           output  [31:0] wr_data_out,
                           output            wr_enable_out,
                           input              wr_done_in,
                           input              wr_busy_in,

                           output  [7:0]  rd_addr_out,
                           output           rd_enable_out,
                           input [31:0]  rd_data_in,
                           input            rd_done_in,
                           input            rd_busy_in,

                           input            ip2bus_intrevent_in

                           );
//===========================================================================
//�ڲ���������
//===========================================================================
localparam FSM_IDLE=1<<0;
localparam FSM_ISR_READ=1<<1;
localparam FSM_ISR_ADJUST=1<<2;  //�ж������б�
localparam FSM_DATA_ID_REC=1<<3;
localparam FSM_DATA_DLC_REC=1<<4;
localparam FSM_DATA_DW1_REC=1<<5;
localparam FSM_DATA_DW2_REC=1<<6;
localparam FSM_DATA_REC_UPDATE=1<<7;
localparam FSM_ISR_CLEAR=1<<8;
localparam FSM_TX_ID=1<<9;
localparam FSM_TX_DLC=1<<10;
localparam FSM_TX_DW1=1<<11;
localparam FSM_TX_DW2=1<<12;
localparam FSM_TX_FULL_DETECT=1<<13;

localparam SR_ADDR=8'h18;
localparam ISR_ADDR=8'h1C;
localparam ICR_ADDR=8'h24;
localparam TX_ID_ADDR=8'h30;
localparam TX_DLC_ADDR=8'h34;
localparam TX_DW1_ADDR=8'h38;
localparam TX_DW2_ADDR=8'h3c;
localparam RX_ID_ADDR=8'h50;
localparam RX_DLC_ADDR=8'h54;
localparam RX_DW1_ADDR=8'h58;
localparam RX_DW2_ADDR=8'h5c;

localparam CAN_ID_VALUE=
    {
    `CAN_NODE_ID,1'b0,1'b0,18'b0,1'b0
    };
localparam CAN_DLC_VALUE=
    {
    4'd8,28'd0
    };
//===========================================================================
//�ڲ���������
//===========================================================================
reg[13:0]  fsm_cs,
    fsm_ns; //  ����״̬���Ĵ���

reg[31:0]  can_isr_r;          //  �ж�״̬�Ĵ���
reg   tx_fifo_full_flag;       //  ���ͻ���������־

reg[31:0] tx_dw1r_cache; //���������ݻ���
reg[31:0] tx_dw2r_cache;

reg   tx_ready_r;              //  ׼�����ձ�־
reg[31:0]  rx_dw1r_r;   //����������1�Ĵ���
reg[31:0]  rx_dw2r_r;   //����������2�Ĵ���
reg              rx_valid_r;    //  ����������Ч��־
reg[7:0]   wr_addr_r;     //  �������ݵ�ַ
reg[31:0]  wr_data_r;    //  �������ݼĴ���
reg               wr_enable_r;    //  ����ʹ�ܼĴ���
reg[7:0]   rd_addr_r;      //  ����ַ�Ĵ���
reg   rd_enable_r;             //  ��ʹ�ܼĴ���

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
        FSM_IDLE: begin
                if (ip2bus_intrevent_in)    //���ж�ָʾΪ��ʱ�������н��յ����ݻ�д���жϣ���ʱ�����жϴ����ж������н��յ�������������ݴ�������д���ж�ֱ�����жϼ��ɣ���������������ٴδ����ж�ѭ������ֱ���������ɽ����������ݷ��ͣ�
                    fsm_ns = FSM_ISR_READ;
                else if (tx_valid_in)   //  �����յ�������Ч��־��������ݷ��ʹ���
                    begin
                        if (tx_fifo_full_flag)
                            fsm_ns = FSM_TX_FULL_DETECT;
                        else
                            fsm_ns = FSM_TX_ID;
                    end            
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ISR_READ: begin   //  ��ȡISR�Ĵ�����ȡ�ж�״̬
                if (rd_done_in)   //   ��ȡ���������ж������ж�״̬
                    fsm_ns = FSM_ISR_ADJUST;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ISR_ADJUST: begin
                if (can_isr_r[4]) //  ���ǽ��յ����ݣ���������ݶ�ȡ����
                    fsm_ns = FSM_DATA_ID_REC;
                else   //  �����յ�TX���жϣ���ֱ�ӽ����ж������������
                    fsm_ns = FSM_ISR_CLEAR;
            end
        FSM_DATA_ID_REC: begin
                if (rd_done_in)    //   ��ȡ��ɺ����dlc��ȡ״̬
                    fsm_ns = FSM_DATA_DLC_REC;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_DLC_REC: begin
                if (rd_done_in)    //   ��ȡ��ɺ����dw1��ȡ״̬
                    fsm_ns = FSM_DATA_DW1_REC;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_DW1_REC: begin
                if (rd_done_in)    //   ��ȡ��ɺ����dw2��ȡ״̬
                    fsm_ns = FSM_DATA_DW2_REC;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_DW2_REC: begin
                if (rd_done_in)    //   ��ȡ��ɺ�������ݸ���״̬
                    fsm_ns = FSM_DATA_REC_UPDATE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_REC_UPDATE: begin
                if (rx_ready_in) //   ��Ӧ�ò����ý���׼���󼴿ɽ����ж����״̬
                    fsm_ns = FSM_ISR_CLEAR;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ISR_CLEAR: begin
                if (wr_done_in)    //д������ɺ󼴿ɷ��س�ʼ״̬
                    fsm_ns = FSM_IDLE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_TX_ID: begin
                if (wr_done_in)    //д������ɺ󼴿ɽ���DLCд����
                    fsm_ns = FSM_TX_DLC;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_TX_DLC: begin
                if (wr_done_in)    //д������ɺ󼴿ɽ���DW1д����
                    fsm_ns = FSM_TX_DW1;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_TX_DW1: begin
                if (wr_done_in)    //д������ɺ󼴿ɽ���DW2д����
                    fsm_ns = FSM_TX_DW2;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_TX_DW2: begin
                if (wr_done_in)    //д������ɺ��ѯ���ͻ������Ƿ�д��//���ɽ����ʼ״̬
                  fsm_ns = FSM_TX_FULL_DETECT ;//FSM_IDLE;
                else
                    fsm_ns = fsm_cs;
        end
        FSM_TX_FULL_DETECT:
        begin
            if(rd_done_in)
                fsm_ns= FSM_IDLE;
            else
                fsm_ns=fsm_cs;
        end
        default :fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//�ж�״̬�Ĵ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        can_isr_r <= 'd0;
    else if ((fsm_cs == FSM_ISR_READ) && rd_done_in)
        can_isr_r <= rd_data_in;
    else
        can_isr_r <= can_isr_r;
    end
//===========================================================================
//����״̬����־��ѯ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        tx_fifo_full_flag <= 'd0;
    else if ((fsm_cs == FSM_TX_FULL_DETECT) && rd_done_in)
        tx_fifo_full_flag <= rd_data_in[10];
    else
        tx_fifo_full_flag <= tx_fifo_full_flag;
    end
//===========================================================================
//���ݷ���׼���ñ�־
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        tx_ready_r <= 'd0;
        else if ((fsm_cs == FSM_IDLE) && (~ip2bus_intrevent_in) && (~tx_fifo_full_flag))
        tx_ready_r <= 'd1;
    else
        tx_ready_r <= 'd0;
    end
//===========================================================================
//���������ֽ�1��ֵ
//===========================================================================
always @(posedge sys_clk or  negedge reset_n)
    begin
    if (!reset_n)
        rx_dw1r_r <= 'd0;
    else if ((fsm_cs == FSM_DATA_DW1_REC) && rd_done_in)
        rx_dw1r_r <= rd_data_in;
    else
        rx_dw1r_r <= rx_dw1r_r;
    end
//===========================================================================
//���������ֽ�2��ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_dw2r_r <= 'd0;
    else if ((fsm_cs == FSM_DATA_DW2_REC) && rd_done_in)
        rx_dw2r_r <= rd_data_in;
    else
        rx_dw2r_r <= rx_dw2r_r;
    end
//===========================================================================
//����������Ч��־��ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rx_valid_r <= 'd0;
    else if (fsm_cs == FSM_DATA_REC_UPDATE)
        rx_valid_r <= 'd1;
    else
        rx_valid_r <= 'd0;
    end
//===========================================================================
//�������ݵ�ַ��ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_addr_r <= 'd0;
    else
        begin
        case (fsm_cs)
            FSM_ISR_CLEAR:    wr_addr_r <= ICR_ADDR;
            FSM_TX_ID:              wr_addr_r <= TX_ID_ADDR;
            FSM_TX_DLC:          wr_addr_r <= TX_DLC_ADDR;
            FSM_TX_DW1:          wr_addr_r <= TX_DW1_ADDR;
            FSM_TX_DW2:          wr_addr_r <= TX_DW2_ADDR;
            default :wr_addr_r <= wr_addr_r;
        endcase
        end
    end
//===========================================================================
//�������ݼĴ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_data_r <= 'd0;
    else
        begin
        case (fsm_cs)
            FSM_ISR_CLEAR:    wr_data_r <= {20'd0, 12'h014};
            FSM_TX_ID:              wr_data_r <= CAN_ID_VALUE;
            FSM_TX_DLC:          wr_data_r <= CAN_DLC_VALUE;
            FSM_TX_DW1:          wr_data_r <= tx_dw1r_cache;
            FSM_TX_DW2:          wr_data_r <= tx_dw2r_cache;
            default :wr_data_r <= wr_data_r;
        endcase
        end
    end
//===========================================================================
//���������ݻ���
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        begin
        tx_dw1r_cache <= 'd0;
        tx_dw2r_cache <= 'd0;
        end else if ((fsm_cs == FSM_IDLE) && (~ip2bus_intrevent_in) && (tx_valid_in))
        begin
        tx_dw1r_cache <= tx_dw1r_in;
        tx_dw2r_cache <= tx_dw2r_in;
        end else
        begin
        tx_dw1r_cache <= tx_dw1r_cache;
        tx_dw2r_cache <= tx_dw2r_cache;
        end
    end
//===========================================================================
//���ݷ���ʹ��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_enable_r <= 'd0;
    else if (((fsm_cs == FSM_ISR_CLEAR) || (fsm_cs == FSM_TX_ID) || (fsm_cs == FSM_TX_DLC) || (fsm_cs == FSM_TX_DW1) || (fsm_cs == FSM_TX_DW2)) && ((~wr_busy_in) && (~wr_done_in)))
        wr_enable_r <= 'd1;
    else
        wr_enable_r <= 'd0;
    end
//===========================================================================
//����ַ�Ĵ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_addr_r <= 'd0;
    else
        begin
        case (fsm_cs)
            FSM_ISR_READ:   rd_addr_r <= ISR_ADDR;
            FSM_DATA_ID_REC:   rd_addr_r <= RX_ID_ADDR;
            FSM_DATA_DLC_REC:   rd_addr_r <= RX_DLC_ADDR;
            FSM_DATA_DW1_REC:  rd_addr_r <= RX_DW1_ADDR;
            FSM_DATA_DW2_REC:  rd_addr_r <= RX_DW2_ADDR;
            FSM_TX_FULL_DETECT:rd_addr_r<=SR_ADDR;
            default:rd_addr_r <= rd_addr_r;
        endcase
        end
    end
//===========================================================================
//��ʹ�ܼĴ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_enable_r <= 'd0;
        else if (((fsm_cs == FSM_ISR_READ) || (fsm_cs == FSM_DATA_ID_REC) || (fsm_cs == FSM_DATA_DLC_REC) || (fsm_cs == FSM_DATA_DW1_REC) || (fsm_cs == FSM_DATA_DW2_REC) || (fsm_cs == FSM_TX_FULL_DETECT)) && ((~rd_done_in) && (~rd_busy_in)))
        rd_enable_r <= 'd1;
    else
        rd_enable_r <= 'd0;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign tx_ready_out = tx_ready_r;
assign rx_dw1r_out = rx_dw1r_r;
assign rx_dw2r_out = rx_dw2r_r;
assign rx_valid_out = rx_valid_r;
assign wr_addr_out = wr_addr_r;
assign wr_data_out = wr_data_r;
assign wr_enable_out = wr_enable_r;
assign rd_addr_out = rd_addr_r;
assign rd_enable_out = rd_enable_r;
endmodule

