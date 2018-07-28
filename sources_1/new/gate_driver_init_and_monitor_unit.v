//====================================================================================
// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/5/8
// Design Name:PMSM_DESIGN
// Module Name: gate_driver_init_and_monitor_unit.v
// Target Device:
// Tool versions:
// Description:դ����������ʼ����״̬���
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module gate_driver_init_and_monitor_unit(
                                         input    sys_clk,
                                         input    reset_n,

                                         input    gate_driver_init_enable_in,  //  դ���������ϵ��λ���ʼ��ʹ������
                                         output  gate_driver_init_done_out,  //  դ����������ʼ����ɱ�־

                                         input  gate_driver_nfault_in,           //   դ�����������������룬�͵�ƽ��Ч
                                         output  gate_driver_enable_out,      //   դ��������ʹ��������ߵ�ƽ��Ч

                                         output[`SPI_FRAME_WIDTH-1:0]  wr_data_out,    //  spiд����
                                         output  wr_data_enable_out,    //  spiдʹ��
                                         output[`DATA_WIDTH-1:0]    rd_addr_out, //  spi���Ĵ�����ַ
                                         output  rd_data_enable_out, //  spi��ʹ��
                                         input [`SPI_FRAME_WIDTH-1:0]    rd_data_in,   //spi������

                                         input    spi_phy_proc_done_in,   //  spi����㴦����ɱ�־
                                         input    spi_phy_proc_busy_in,   //  spi�����æ��־

                                         output[`DATA_WIDTH-1:0]    gate_driver_register_1_out,  //  դ���Ĵ���״̬1�Ĵ������
                                         output[`DATA_WIDTH-1:0]    gate_driver_register_2_out,  //  դ���Ĵ���״̬2�Ĵ������
                                         output  gate_driver_error_out   //դ���Ĵ������ϱ������
                                         );
//===========================================================================
//      �ڲ���������
//===========================================================================
localparam   FSM_IDLE=1<<0;
localparam   FSM_ENABLE_DELAY=1<<1;
localparam   FSM_GATE_DRIVER_INIT=1<<2;   //  ����դ���������Ŀ��ƼĴ�������߸�λ����
localparam   FSM_GATE_DRIVER_MONITOR=1<<3;    //  դ��������״̬����
localparam   FSM_GATE_DRIVER_READ_0=1<<4;       //   դ��������״̬�Ĵ���0��ȡ
localparam   FSM_GATE_DRIVER_READ_1=1<<5;       //   դ��������״̬�Ĵ���1��ȡ
localparam   FSM_GATE_DRIVER_REC_WAIT = 1 << 6;  //   դ��������״̬�ָ��ȴ�״̬

localparam   TIME_2MS_NUM = 'd2_000_000 / `SYS_CLK_PERIOD;
//===========================================================================
//�ڲ���������
//===========================================================================
reg[6:0]    fsm_cs,
    fsm_ns;     //  state machine and the nest state
reg[$clog2(TIME_2MS_NUM)-1:0]   time_2ms_cnt_r;   //  2ms������

reg[1:0]  gate_driver_nfault_buffer_r; //   դ�����������������뻺��

reg  gate_driver_init_done_r;  //  դ����������ʼ����ɱ�־
reg  gate_driver_enable_r;    //  դ��������ʹ�ܼĴ���
reg[`SPI_FRAME_WIDTH-1:0]  wr_data_r;    //  spiд���ݼĴ���
reg  wr_data_enable_r; //spiдʹ�ܼĴ���
reg[`DATA_WIDTH-1:0]    rd_addr_r;  //  spi���Ĵ�����ַ�Ĵ���
reg   rd_data_enable_r; //  spi��ʹ�ܼĴ���
reg[`DATA_WIDTH-1:0]    gate_driver_register_1_r;  //  դ���Ĵ���״̬1�Ĵ������
reg[`DATA_WIDTH-1:0]    gate_driver_register_2_r;  //  դ���Ĵ���״̬2�Ĵ������
reg   gate_driver_error_r;   //դ���Ĵ������ϱ�������Ĵ���

//===========================================================================
//����״̬��״̬��ת
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
                if (gate_driver_init_enable_in)  //  �յ�դ���Ĵ���ʹ�ܱ�־��ת��ʹ���ӳ�״̬
                    fsm_ns = FSM_ENABLE_DELAY;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ENABLE_DELAY: begin   //  դ���Ĵ���ʹ�ܺ����ٵȴ�1ms���ܽ���SPI��д�����ӳ�2ms
                if (time_2ms_cnt_r == (TIME_2MS_NUM - 1)) //    2ms�ӳٽ�������ת����ʼ��״̬
                    fsm_ns = FSM_GATE_DRIVER_INIT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_GATE_DRIVER_INIT: begin
                if (spi_phy_proc_done_in)   //��ʼ������λ��������ɺ����״̬���״̬
                    fsm_ns = FSM_GATE_DRIVER_MONITOR;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_GATE_DRIVER_MONITOR: begin  //����⵽nFaultΪ��ʱ����״̬�Ĵ�����ȡ״̬
                if (!gate_driver_nfault_buffer_r[1])
                    fsm_ns = FSM_GATE_DRIVER_READ_0;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_GATE_DRIVER_READ_0: begin
                if (spi_phy_proc_done_in)  //   �յ�spi��ȡ��ɱ�־�����״̬�Ĵ���1��ȡ״̬
                    fsm_ns = FSM_GATE_DRIVER_READ_1;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_GATE_DRIVER_READ_1: begin
                if (spi_phy_proc_done_in)  //   �յ�spi��ȡ��ɱ�־��������ָ��ȴ�״̬
                    fsm_ns = FSM_GATE_DRIVER_REC_WAIT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_GATE_DRIVER_REC_WAIT: begin
                if (gate_driver_nfault_buffer_r[1])   //   ��⵽nFault��Ϊ�ߵ�ƽ������ת����λ��ʼ��״̬��������־λ
                    fsm_ns = FSM_GATE_DRIVER_INIT;
                else
                    fsm_ns = fsm_cs;
            end
        default: fsm_ns = FSM_GATE_DRIVER_MONITOR;
    endcase
    end
//===========================================================================
//  2ms��ʱ����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        time_2ms_cnt_r <= 'd0;
    else if (fsm_cs == FSM_ENABLE_DELAY)
        time_2ms_cnt_r <= time_2ms_cnt_r + 1'b1;
    else
        time_2ms_cnt_r <= 'd0;
    end
//===========================================================================
//  դ�����������������뻺��
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_nfault_buffer_r <= 'b11;
    else
        gate_driver_nfault_buffer_r <= {gate_driver_nfault_buffer_r[0], gate_driver_nfault_in};
    end
//===========================================================================
//դ����������ʼ����ɱ�־
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_init_done_r <= 'b0;
    else if ((fsm_cs == FSM_GATE_DRIVER_INIT) && (spi_phy_proc_done_in))  //��ʼ�����
        gate_driver_init_done_r <= 'b1;
    else
        gate_driver_init_done_r <= gate_driver_init_done_r;
    end
//===========================================================================
//  դ��������ʹ�ܸ�ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_enable_r <= 'b0;
    else if ((fsm_cs == FSM_IDLE) && gate_driver_init_enable_in)   //�յ�ʹ�ܱ�־ʹ��դ��������
        gate_driver_enable_r <= 'b1;
    else
        gate_driver_enable_r <= gate_driver_enable_r;
    end
//===========================================================================
//spiд���ݼĴ���
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_data_r <= 'd0;
    else
    wr_data_r <= `DRIVER_CONTROL_REGISTER_VALUE;
    end
//===========================================================================
//spiд����ʹ��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_data_enable_r <= 'b0;
    else if (wr_data_enable_r)    //ȷ��wr_data_enable_r��ռһ��ʱ������
        wr_data_enable_r <= 'b0;
    else if ((fsm_cs == FSM_GATE_DRIVER_INIT) && (!spi_phy_proc_busy_in) && (~spi_phy_proc_done_in))
        wr_data_enable_r <= 'b1;
    else
        wr_data_enable_r <= 'b0;
    end
//===========================================================================
//����ַ�Ĵ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_addr_r <= 'd0;
    else if (fsm_cs == FSM_GATE_DRIVER_READ_0)
        rd_addr_r <= 'd0;
    else if (fsm_cs == FSM_GATE_DRIVER_READ_1)
        rd_addr_r <= 'd1;
    else
        rd_addr_r <= 'd0;
    end
//===========================================================================
//��ʹ�ܼĴ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_data_enable_r <= 'b0;
    else if (rd_data_enable_r)  //ȷ��rd_data_enable_r��ռ��һ��ʱ������
        rd_data_enable_r <= 'd0;
    else if ((fsm_cs == FSM_GATE_DRIVER_READ_0 || fsm_cs == FSM_GATE_DRIVER_READ_1) && (!spi_phy_proc_busy_in) && (!spi_phy_proc_done_in))
        rd_data_enable_r <= 'b1;
    else
        rd_data_enable_r <= 'b0;
    end
//===========================================================================
// դ���Ĵ���״̬1��2�Ĵ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_register_1_r <= 'd0;
    else if (fsm_cs == FSM_GATE_DRIVER_READ_0 && spi_phy_proc_done_in)
        gate_driver_register_1_r <= rd_data_in;
    else
        gate_driver_register_1_r <= gate_driver_register_1_r;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_register_2_r <= 'd0;
    else if (fsm_cs == FSM_GATE_DRIVER_READ_1 && spi_phy_proc_done_in)
        gate_driver_register_2_r <= rd_data_in;
    else
        gate_driver_register_2_r <= gate_driver_register_2_r;
    end
//===========================================================================
//դ�����������󱨾����
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        gate_driver_error_r <= 'd0;
    else if (fsm_cs == FSM_GATE_DRIVER_READ_1 && spi_phy_proc_done_in)   //״̬�Ĵ���1��2������Ϻ���λ���󱨾����
        gate_driver_error_r = 1'b1;
    else if ((fsm_cs == FSM_GATE_DRIVER_REC_WAIT) && gate_driver_nfault_buffer_r[1])
        gate_driver_error_r = 1'b0;
    else
        gate_driver_error_r <= gate_driver_error_r;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign gate_driver_init_done_out=gate_driver_init_done_r;
assign gate_driver_enable_out=gate_driver_enable_r;
assign wr_data_out=wr_data_r;
assign wr_data_enable_out=wr_data_enable_r;
assign rd_addr_out=rd_addr_r;
assign rd_data_enable_out=rd_data_enable_r;
assign gate_driver_register_1_out=gate_driver_register_1_r;
assign gate_driver_register_2_out=gate_driver_register_2_r;
assign gate_driver_error_out=gate_driver_error_r;
endmodule

