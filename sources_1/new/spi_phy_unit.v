//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/7
// Design Name:PMSM_DESIGN
// Module Name: spi_phy_unit.v
// Target Device:
// Tool versions:
// Description:DRV8320S�����SPIЭ������
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module spi_phy_unit(
                    input    sys_clk,
                    input    reset_n,

                    input    [`SPI_FRAME_WIDTH-1:0]    wr_data_in,  //  ����д�˿�
                    input    wr_data_valid_in,                      //  ����д�˿���Ч��־

                    output    [`SPI_FRAME_WIDTH-1:0]    rd_data_out,  //   ���ݶ��˿�
                    input    rd_data_enable_in,     //  ���ݶ��˿�ʹ�ܱ�־
                    input    [`DATA_WIDTH-1:0]    rd_addr_in,   //  ����ַ����

                    output  spi_proc_done_out,   //    spi������ɱ�־
                    output  spi_proc_busy_out,   //    spiæ��־

                    output  spi_nscs_out,        //spiʹ�ܱ�־���
                    output  spi_sclk_out,           //spiʱ�Ӷ˿����
                    output  spi_sdo_out,           //   spi��������˿�
                    input    spi_sdi_in               //   spi��������˿�
                    );
//===========================================================================
//  �ڲ���������
//===========================================================================
localparam   SPI_PHY_500NS_NUM = `SPI_CLK_PERIOD / `SYS_CLK_PERIOD;  // 500ns����ֵ
localparam   SPI_CLK_HIGH_BEGIN_TIME=SPI_PHY_500NS_NUM*1/4;              //   clk�ߵ�ƽ��ʼʱ��
localparam   SPI_CLK_HIGH_END_TIME=SPI_PHY_500NS_NUM*3/4;                  //  clk�ߵ�ƽ����ʱ��

localparam   FSM_IDLE=1<<0;
localparam   FSM_DATA_WRITE=1<<1;
localparam   FSM_DATA_READ=1<<2;
localparam   FSM_SPI_DELAY=1<<3;  //  ʱ����ʱ��nscs����spi����֮������Ӧ��400ns��ʱ
localparam   FSM_SPI_PROC_DONE=1<<4;
//===========================================================================
//  �ڲ���������
//===========================================================================
reg[4:0]    fsm_cs,
    fsm_ns;     //  ����״̬����ǰ״̬������һ״̬
reg[$clog2(`SPI_FRAME_WIDTH)-1:0]  spi_clk_frame_cnt_r;   //  spi֡ʱ�Ӽ�����
reg[$clog2(SPI_PHY_500NS_NUM)-1:0] spi_500ns_cnt;         //  500ns������

reg[`SPI_FRAME_WIDTH-1:0]    wr_data_r;    //  ��д�����ݼĴ���
reg[`SPI_FRAME_WIDTH-1:0]    rd_data_r;     //  spi�����ݼĴ���
reg[`SPI_FRAME_WIDTH-1:0]    rd_data_buffer_r;    //  spi��������
reg   spi_proc_done_r; //  spi������ɼĴ���
reg   spi_proc_busy_r; //  spiæ��־

reg   spi_sclk_r;    //  spiʱ�ӼĴ���
reg   spi_sdo_r;    //  spi����Ĵ���
reg   spi_nscs_r;   //  spiƬѡʱ�ӼĴ���
reg[1:0]    spi_sdi_buffer;  //  spi�������뻺��Ĵ���

//===========================================================================
//  ����״̬��״̬ת��
//===========================================================================
always @(posedge   sys_clk or negedge reset_n)
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
                if (wr_data_valid_in)    //����дʹ��
                    fsm_ns = FSM_DATA_WRITE;
                else if (rd_data_enable_in)   //   ���ݶ�ʹ��
                    fsm_ns = FSM_DATA_READ;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_WRITE: begin
                if ((spi_clk_frame_cnt_r == `SPI_FRAME_WIDTH - 1) && (spi_500ns_cnt == SPI_PHY_500NS_NUM - 1))
                    fsm_ns = FSM_SPI_DELAY;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_DATA_READ: begin
                if ((spi_clk_frame_cnt_r == `SPI_FRAME_WIDTH - 1) && (spi_500ns_cnt == SPI_PHY_500NS_NUM - 1))
                    fsm_ns = FSM_SPI_DELAY;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_SPI_DELAY: begin
                if (spi_500ns_cnt == SPI_PHY_500NS_NUM - 1)  //�ӳ�500ns
                    fsm_ns = FSM_SPI_PROC_DONE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_SPI_PROC_DONE: begin
                fsm_ns = FSM_IDLE;
            end
        default: fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//Ƭѡ�ź�����
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_nscs_r <= 'd1;  //  ��ʼ̬Ϊ�ߵ�ƽ
    else if (fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_DATA_READ)
        spi_nscs_r <= 'd0;
    else
        spi_nscs_r <= 'd1;
    end
//===========================================================================
//spiʱ���ź�����
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_sclk_r <= 'd0;  //  ��ʼ״̬Ϊ�͵�ƽ
    else if (fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_DATA_READ)
        begin
        if (spi_500ns_cnt == SPI_CLK_HIGH_BEGIN_TIME - 1)
            spi_sclk_r <= 'd1;
        else if (spi_500ns_cnt == SPI_CLK_HIGH_END_TIME - 1)
            spi_sclk_r <= 'd0;
        else
            spi_sclk_r <= spi_sclk_r;
        end else
        spi_sclk_r <= 'd0;
    end
//===========================================================================
//500ns��������ֵ
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_500ns_cnt <= 'd0;
    else if (fsm_cs == FSM_DATA_READ || fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_SPI_DELAY)
        begin
        if (spi_500ns_cnt == SPI_PHY_500NS_NUM - 1)
            spi_500ns_cnt <= 'd0;
        else
            spi_500ns_cnt <= spi_500ns_cnt + 1'b1;
        end            else
        spi_500ns_cnt <= 'd0;
    end
//===========================================================================
//֡��������ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_clk_frame_cnt_r <= 'd0;
    else if (fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_DATA_READ)
        begin
        if (spi_500ns_cnt == SPI_PHY_500NS_NUM - 1)
            spi_clk_frame_cnt_r <= spi_clk_frame_cnt_r + 1'b1;
        else
            spi_clk_frame_cnt_r <= spi_clk_frame_cnt_r;
        end else
        spi_clk_frame_cnt_r <= 'd0;
    end

//===========================================================================
//��д�����ݼĴ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_data_r <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        begin
        if (wr_data_valid_in)    //дʹ��
            wr_data_r <= wr_data_in;
        else if (rd_data_enable_in)   // ��ʹ��
            wr_data_r <= {1'b1, rd_addr_in[3:0], 11'd0};
        else
            wr_data_r <= 'd0;
        end else if ((fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_DATA_READ) && (spi_500ns_cnt == SPI_CLK_HIGH_BEGIN_TIME - 1)) //�ڷ��ͻ���������ش���������һλ����
        wr_data_r <= (wr_data_r << 1'b1);
    else
        wr_data_r <= wr_data_r;
    end
//===========================================================================
//����Ĵ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_sdo_r <= 'd1;
    else if (fsm_cs == FSM_DATA_WRITE || fsm_cs == FSM_DATA_READ)
        begin
        if (spi_500ns_cnt == SPI_CLK_HIGH_BEGIN_TIME - 1)
            spi_sdo_r <= wr_data_r[`SPI_FRAME_WIDTH - 1];
        else
            spi_sdo_r <= spi_sdo_r;
        end else
        spi_sdo_r <= 'd1;
    end
//===========================================================================
//spi ���뻺��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_sdi_buffer <= 'd0;
    else
        spi_sdi_buffer <= {spi_sdi_buffer[0], spi_sdi_in};
    end
//===========================================================================
//spi�������ݶ�ȡ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_data_buffer_r <= 'd0;
    else if ((fsm_cs == FSM_DATA_READ) && (spi_500ns_cnt == SPI_CLK_HIGH_END_TIME + 1))
        rd_data_buffer_r <= {rd_data_buffer_r[(`SPI_FRAME_WIDTH - 2) : 0], spi_sdi_buffer[1]};
    else
        rd_data_buffer_r <= rd_data_buffer_r;
    end
//===========================================================================
//spi���Ĵ����������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_data_r <= 'd0;
    else if (fsm_cs == FSM_SPI_PROC_DONE)
        rd_data_r <= rd_data_buffer_r;
    else
        rd_data_r <= rd_data_r;
    end
//===========================================================================
//������ɱ�־����
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_proc_done_r <= 1'b0;
    else if (fsm_cs == FSM_SPI_PROC_DONE)
        spi_proc_done_r <= 'b1;
    else
        spi_proc_done_r <= 'b0;
    end
//===========================================================================
//spiæ��־��ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        spi_proc_busy_r <= 'd0;
    else if (fsm_cs == FSM_IDLE && (rd_data_enable_in || wr_data_valid_in))
        spi_proc_busy_r <= 'b1;
    else if (fsm_cs == FSM_SPI_PROC_DONE)
        spi_proc_busy_r <= 1'b0;
    else
        spi_proc_busy_r <= spi_proc_busy_r;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign rd_data_out=rd_data_r;
assign spi_proc_done_out=spi_proc_done_r;
assign spi_proc_busy_out=spi_proc_busy_r;
assign spi_nscs_out=spi_nscs_r;
assign spi_sclk_out=spi_sclk_r;
assign spi_sdo_out=spi_sdo_r;
endmodule
