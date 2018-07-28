//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/5/15
// Design Name:PMSM_DESIGN
// Module Name: cmd_to_axi_lite_unit.v
// Target Device:
// Tool versions:
// Description:cmd��axi_lite�ӿ����ݽ�����������ݴ��������·�����ݽ���
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module cmd_to_axi_lite_unit(
                            input    sys_clk,
                            input    reset_n,

                            input    [7:0]   wr_addr_in,
                            input    [31:0] wr_data_in,
                            input              wr_enable_in,   //  дָ����Ч��־
                            output            wr_done_out,   //   д������ɱ�־
                            output            wr_busy_out,   //    д����æ��־

                            input   [7:0]    rd_addr_in,    //  ��������ַ����
                            input              rd_enable_in, //   ������ʹ�ܱ�־
                            output  [31:0] rd_data_out,  //  �������������
                            output  rd_done_out,
                            output  rd_busy_out,

                            output [7:0]  s_axi_awaddr_out,
                            output          s_axi_awvalid_out,
                            input            s_axi_awready_in,

                            output  [31:0]  s_axi_wdata_out,
                            output  [3:0]    s_axi_wstrb_out,
                            output              s_axi_wvalid_in,
                            input                s_axi_wready_in,
                            input    [1:0]    s_axi_bresp_in,
                            input                s_axi_bvalid_in,
                            output              s_axi_bready_out,

                            output  [7:0]    s_axi_araddr_out,
                            output             s_axi_arvalid_out,
                            input               s_axi_arready_in,
                            input   [31:0]   s_axi_rdata_in,
                            input   [1:0]     s_axi_rresp_in,
                            input               s_axi_rvalid_in,
                            output             s_axi_rready_out
                            );
//===========================================================================
//�ڲ���������
//===========================================================================
localparam FSM_WR_IDLE=1<<0;
localparam FSM_WR_ADDR=1<<1;
localparam FSM_WR_DATA=1<<2;
localparam FSM_WR_RESP=1<<3;
localparam FSM_WR_DONE=1<<4;

localparam FSM_RD_IDLE=1<<0;
localparam FSM_RD_ADDR=1<<1;
localparam FSM_RD_DATA=1<<2;
localparam FSM_RD_DONE=1<<3;
//===========================================================================
//�ڲ���������
//===========================================================================
reg[7:0]    axi_awaddr_r;   //axiд��ַ�Ĵ���
reg               axi_awvalid_r; //axiд��ַ��Ч��־�Ĵ���
reg[31:0]  axi_wdata_r;    //axiд���ݼĴ���
reg[3:0]    axi_wstrb_r;    //axiдѡͨ�Ĵ���
reg      axi_wvalid_r;          //axiд��Ч�Ĵ���
reg      axi_bready_r;          //д��Ӧ׼���ñ�־
reg      wr_done_r;             //д��ɱ�־
reg      wr_busy_r;             //дæµ��־
reg[4:0]   fsm_wr_cs,
    fsm_wr_ns;

reg[7:0]   axi_araddr_r;    //axi����ַ�Ĵ���
reg          axi_arvalid_r;    //axi����ַ��Ч�Ĵ���
reg          axi_rready_r;     //axi����Ӧ��Ч��־λ
reg[31:0] rd_data_r;
reg          rd_done_r;
reg           rd_busy_r;
reg[3:0]          fsm_rd_cs,
    fsm_rd_ns;

//===========================================================================
//axi-liteдʱ��״̬��ת��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        fsm_wr_cs <= FSM_WR_IDLE;
    else
        fsm_wr_cs <= fsm_wr_ns;
    end
always @(*)
    begin
    case (fsm_wr_cs)
        FSM_WR_IDLE: begin
                if (wr_enable_in) //���յ�дʹ������axiдʱ��
                    fsm_wr_ns = FSM_WR_ADDR;
                else
                    fsm_wr_ns = fsm_wr_cs;
            end
        FSM_WR_ADDR: begin  //�յ�s_axi_awready_in��ʾд��ַ��ɣ���������д�׶�
                if (s_axi_awready_in)
                    fsm_wr_ns = FSM_WR_RESP;//FSM_WR_DATA;
                else
                    fsm_wr_ns = fsm_wr_cs;
            end
//      FSM_WR_DATA: begin  //�յ�s_axi_wready_in��ʾд������ɣ��ɽ���д������Ӧ״̬
//              if (s_axi_wready_in)
//                  fsm_wr_ns = FSM_WR_RESP;
//              else
//                  fsm_wr_ns = fsm_wr_cs;
//            end
        FSM_WR_RESP : begin  //�ȴ�bvalid�ź���Ч��־���ж�bresp״̬
                if (s_axi_bvalid_in)
                    begin
                    if (s_axi_bresp_in == 'd0)  //��ʾ��Ϣд�ɹ�
                        fsm_wr_ns = FSM_WR_DONE;
                    else
                        fsm_wr_ns = FSM_WR_DATA;
                    end else
                    fsm_wr_ns = fsm_wr_cs;
            end
        FSM_WR_DONE:
            fsm_wr_ns = FSM_WR_IDLE;
        default :fsm_wr_ns = FSM_WR_IDLE;
    endcase
    end
//===========================================================================
//д��ַ�Ĵ�����д���ݼĴ�������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {axi_awaddr_r, axi_wdata_r} <= 'd0;
    else if ((fsm_wr_cs == FSM_WR_IDLE) && wr_enable_in)   //����״̬ ���յ�дʹ���ź�
        {axi_awaddr_r, axi_wdata_r} <= {wr_addr_in, wr_data_in};
    else
    {axi_awaddr_r, axi_wdata_r} <= {wr_addr_in, wr_data_in};
    end
//===========================================================================
//axiд��ַ��Ч��־�Ĵ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_awvalid_r <= 'd0;
    else if (s_axi_awready_in) //��⵽����д��ַ׼���ü���������Ч��־λ
        axi_awvalid_r <= 'b0;
    else if (fsm_wr_cs == FSM_RD_ADDR)
        axi_awvalid_r <= 'd1;
    else
        axi_awvalid_r <= 'd0;
    end
//===========================================================================
//axiд������Ч��־λ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_wvalid_r <= 'd0;
    else if (s_axi_wready_in) //��⵽��������д׼���ü���������Ч��־λ
        axi_wvalid_r <= 'd0;
    else if(fsm_wr_cs == FSM_WR_ADDR)//  (fsm_wr_cs == FSM_RD_DATA)
        axi_wvalid_r <= 'd1;
    else
        axi_wvalid_r <= 'd0;
    end
//===========================================================================
//axiд��������Ĵ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_wstrb_r <= 'd0;
    else
        axi_wstrb_r <= 'b1111;
    end
//===========================================================================
//д��Ӧ׼���üĴ�����־
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_bready_r <= 'd0;
    else if (s_axi_bvalid_in)
        axi_bready_r <= 'd0;
    else if (fsm_wr_cs == FSM_WR_ADDR)// (fsm_wr_cs == FSM_WR_RESP)
        axi_bready_r <= 'd1;
    else
        axi_bready_r <= 'd0;
    end
//===========================================================================
//д������ɱ�־,æ��־��ֵ
//===========================================================================
always @(posedge sys_clk or  negedge reset_n)
    begin
    if (!reset_n)
        wr_done_r <= 'd0;
    else if (fsm_wr_cs == FSM_WR_DONE)
        wr_done_r <= 'd1;
    else
        wr_done_r <= 'd0;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        wr_busy_r <= 'd0;
    else if ((fsm_wr_cs == FSM_WR_IDLE)&&(~wr_enable_in))
        wr_busy_r <= 'd0;
    else
        wr_busy_r <= 'd1;
    end

//===========================================================================
//����������״̬��״̬ת��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        fsm_rd_cs <= FSM_RD_IDLE;
    else
        fsm_rd_cs <= fsm_rd_ns;
    end
always @(*)
    begin
    case (fsm_rd_cs)
        FSM_RD_IDLE: begin
                if (rd_enable_in)  //�ڿ���״̬���յ���ʹ������ת�����޶���ַд�׶�
                    fsm_rd_ns = FSM_RD_ADDR;
                else
                    fsm_rd_ns = fsm_rd_cs;
            end
        FSM_RD_ADDR: begin
                if (s_axi_arready_in)    //�ӻ�׼���ý��ܵ�ַ�źź󼴿���ת�����ݶ��׶�
                    fsm_rd_ns = FSM_RD_DATA;
                else
                    fsm_rd_ns = fsm_rd_cs;
            end
        FSM_RD_DATA: begin
                if (s_axi_rvalid_in)  //���յ��ӻ�������Ч��־�󼴿���ɶ���
                    begin
                    if (s_axi_rresp_in == 'd0)
                        fsm_rd_ns = FSM_RD_DONE;
                    else
                        fsm_rd_ns = FSM_RD_ADDR;
                    end else
                    fsm_rd_ns = fsm_rd_cs;
            end
        FSM_RD_DONE:
            fsm_rd_ns = FSM_RD_IDLE;
        default:fsm_rd_ns = FSM_RD_IDLE;
    endcase
    end
//===========================================================================
//����ַ�Ĵ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_araddr_r <= 'd0;
    else if ((fsm_rd_cs == FSM_RD_IDLE) && rd_enable_in)
        axi_araddr_r <= rd_addr_in;
    else
        axi_araddr_r <= axi_araddr_r;
    end
//===========================================================================
//����ַ��Ч��־�Ĵ���
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_arvalid_r <= 'd0;
    else if (s_axi_arready_in)
        axi_arvalid_r <= 'd0;
    else if (fsm_rd_cs == FSM_RD_ADDR)
        axi_arvalid_r <= 'd1;
    else
        axi_arvalid_r <= 'd0;
    end
//===========================================================================
//��׼����־�Ĵ���
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        axi_rready_r <= 'd0;
    else if (s_axi_rvalid_in)
        axi_rready_r <= 'd0;
    else if (fsm_rd_cs == FSM_RD_ADDR)
        axi_rready_r <= 'd1;
    else
        axi_rready_r <= 'd0;
    end
//===========================================================================
//�����ݼĴ�����ֵ
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_data_r <= 'd0;
    else if (fsm_rd_cs == FSM_RD_DATA && (s_axi_rresp_in == 'd0) && (s_axi_rvalid_in))
        rd_data_r <= s_axi_rdata_in;
    else
        rd_data_r <= rd_data_r;
    end
//===========================================================================
//������æ��־����ɱ�־
//===========================================================================
always @(posedge sys_clk or  negedge reset_n)
    begin
    if (!reset_n)
        rd_done_r <= 'd0;
    else if (fsm_rd_cs == FSM_RD_DONE)
        rd_done_r <= 'd1;
    else
        rd_done_r <= 'd0;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        rd_busy_r <= 'd0;
    else if (fsm_rd_cs == FSM_RD_IDLE)
        rd_busy_r <= 'd0;
    else
        rd_busy_r <= 'd1;
    end
//===========================================================================
//����˿ڸ�ֵ
//===========================================================================
assign wr_done_out=wr_done_r;
assign wr_busy_out=wr_busy_r;
assign rd_data_out=rd_data_r;
assign rd_done_out=rd_done_r;
assign rd_busy_out=rd_busy_r;

assign s_axi_awaddr_out=axi_awaddr_r;
assign s_axi_awvalid_out=axi_awvalid_r;
assign s_axi_wdata_out=axi_wdata_r;
assign s_axi_wstrb_out=axi_wstrb_r;
assign s_axi_wvalid_in=axi_wvalid_r;
assign s_axi_bready_out=axi_bready_r;

assign s_axi_araddr_out=axi_araddr_r;
assign s_axi_arvalid_out=axi_arvalid_r;
assign s_axi_rready_out=axi_rready_r;
endmodule

