//====================================================================================
// Company:
// Engineer: LiXiaochaung
// Create Date: 2018/5/15
// Design Name:PMSM_DESIGN
// Module Name: can_init_unit.v
// Target Device:
// Tool versions:
// Description:���CAN IP�˵ĳ�ʼ��
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`include "project_param.v"
module can_init_unit(
                     input    sys_clk,
                     input    reset_n,

                     input    can_init_enable_in,    //   can��ʼ��ʹ�ܱ�־
                     output  can_init_done_out,    //    can��ʼ����ɱ�־

                     output  [7:0]    wr_addr_out, //can����д��ַ
                     output  [31:0]  wr_data_out, //can����д����
                     output             wr_enable_out, //can����дʹ��
                     input    wr_done_in,    //canд�����������
                     input    wr_busy_in,    //can����д����æ��־

                     output  [7:0]    rd_addr_out, //can���߶���ַ
                     output             rd_enable_out, //can���߶�ʹ��
                     input               rd_done_in,   //can���߶��������
                     input   [31:0]  rd_data_in     //can���߶���������
                     );
//===========================================================================
//�ڲ���������
//===========================================================================
localparam MSR_ADDR=8'h04;
localparam MSR_VALUE=32'd2;   //32'd2:loopback model,32'd0:normal_model
localparam BRPR_ADDR=8'h08;
localparam BRPR_VALUE=32'd1;
localparam BTR_ADDR=8'h0c;
localparam BTR_VALUE=32'd184;
localparam AFR_ADDR=8'h60;
localparam SR_ADDR=8'h18;
localparam AFMR1_ADDR=8'h64;
localparam AFMR1_VALUE=
    {
    `CAN_MODE_MASK,1'b0,1'b0,18'b0,1'b0
    };
localparam AFIR1_ADDR=8'h68;
localparam AFIR1_VALUE=
    {
    `CAN_NODE_ID,1'b0,1'b0,19'd0
    };
localparam IER_ADDDR=8'h20;
localparam IER_VALUE=  //  ʹ�ܽ����ж���TX_FIFO���ж�
    {
    20'b0,12'd16
    };
localparam SRR_ADDR=8'h00;
localparam SRR_VALUE=23'd2;

localparam FSM_IDLE=1<<0;
localparam FSM_INIT1=1<<1;
localparam FSM_SR_POLL=1<<2;
localparam FSM_ACFBSY_WAIT=1<<3;
localparam FSM_INIT2=1<<4;
localparam FSM_INIT_DONE=1<<5;
//===========================================================================
//�ڲ���������
//===========================================================================
reg[5:0]    fsm_cs,
    fsm_ns;
reg[3:0]    can_config_index_r;    //can���ô������
reg[31:0]  can_rd_data_r;             //can���߶����ݼĴ���
reg[7:0]    can_rd_addr_r;            //can���߶���ַ
reg           can_rd_enable_r;        //can���߶�ʹ�ܼĴ���
wire         sr_acfbsy_w;

reg[7:0]    can_wr_addr_r;         //can����д��ַ�Ĵ���
reg[31:0]  can_wr_data_r;         //can����д���ݼĴ���
reg           can_wr_enable_r;      //can����дʹ�ܼĴ���

reg   can_init_done_r;               //can����������ɱ�־

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
                if (can_init_enable_in)  //��ʼ��ʹ��
                    fsm_ns = FSM_INIT1;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_INIT1: begin    //�������MSR��BRPR,BTR��AFR�Ĵ��������SR��ѯ״̬
                if (can_config_index_r == 4'd3 && wr_done_in) //�ɹ�����Ĵ�����
                    fsm_ns = FSM_SR_POLL;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_SR_POLL: begin
                if (rd_done_in)  //���һ��SR�Ĵ�����ȡ
                    fsm_ns = FSM_ACFBSY_WAIT;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_ACFBSY_WAIT: begin
                if (~sr_acfbsy_w) //�ȴ�sr�Ĵ�����acfbsyΪ0
                    fsm_ns = FSM_INIT2;
                else
                    fsm_ns = FSM_SR_POLL;
            end
        FSM_INIT2: begin
                if (can_config_index_r == 4'd8 && wr_done_in) //�ɹ����������������
                    fsm_ns = FSM_INIT_DONE;
                else
                    fsm_ns = fsm_cs;
            end
        FSM_INIT_DONE:
            fsm_ns = FSM_IDLE;
        default:fsm_ns = FSM_IDLE;
    endcase
    end
//===========================================================================
//can���ô��������Ĵ���
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        can_config_index_r <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        can_config_index_r <= 'd0;
    else if (wr_done_in)  //���һ��д��������һ�μ�����1
        can_config_index_r <= can_config_index_r + 1'b1;
    else
        can_config_index_r <= can_config_index_r;
    end
//===========================================================================
//canд��ַ��д���ݼĴ�������
//===========================================================================
always@(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {can_wr_addr_r, can_wr_data_r} <= 'd0;
    else if (fsm_cs == FSM_IDLE)
        {can_wr_addr_r, can_wr_data_r} <= 'd0;
    else
        begin
        case (can_config_index_r)
            'd0:{can_wr_addr_r, can_wr_data_r} <= {MSR_ADDR, MSR_VALUE};  //MSR�Ĵ�������
                'd1:{can_wr_addr_r, can_wr_data_r} <= {BRPR_ADDR, BRPR_VALUE}; //BRPR�Ĵ�������
                'd2:{can_wr_addr_r, can_wr_data_r} <= {BTR_ADDR, BTR_VALUE}; //BTR�Ĵ�������
                'd3:{can_wr_addr_r, can_wr_data_r} <= {AFR_ADDR, 32'd0};   //AFR�Ĵ�������
                'd4:{can_wr_addr_r, can_wr_data_r} <= {AFMR1_ADDR, AFMR1_VALUE};  //AFMR1�Ĵ�������
                'd5:{can_wr_addr_r, can_wr_data_r} <= {AFIR1_ADDR, AFIR1_VALUE};  //AFIR�Ĵ�������
                'd6:{can_wr_addr_r, can_wr_data_r} <= {AFR_ADDR, 32'd1};   //AFR�Ĵ�������
                'd7:{can_wr_addr_r, can_wr_data_r} <= {IER_ADDDR, IER_VALUE}; //IER�Ĵ�������
                'd8:{can_wr_addr_r, can_wr_data_r} <= {SRR_ADDR, SRR_VALUE}; //SRR�Ĵ�������
                default:{can_wr_addr_r, can_wr_data_r} <= {can_wr_addr_r, can_wr_data_r};
                endcase
        end
        end

        //===========================================================================
        //дʹ��
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            can_wr_enable_r <= 'd0;
        else if (fsm_cs == FSM_INIT1 || fsm_cs == FSM_INIT2)
            begin
            if (can_wr_enable_r)
                can_wr_enable_r <= 'd0;
            else if ((~wr_busy_in) && (~wr_done_in))
                can_wr_enable_r <= 'd1;
            end else
            can_wr_enable_r <= 'd0;
    end
        //===========================================================================
        //��ʹ��
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            can_rd_enable_r <= 'd0;
        else if ((fsm_cs == FSM_INIT1 || fsm_cs == FSM_ACFBSY_WAIT) && (fsm_cs != fsm_ns))
            can_rd_enable_r <= 'd1;
        else
            can_rd_enable_r <= 'd0;
    end
        //===========================================================================
        //�����ݼĴ���
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            can_rd_data_r <= 'd0;
        else if (rd_done_in)
            can_rd_data_r <= rd_data_in;
        else
            can_rd_data_r <= 'd0;
    end
        assign sr_acfbsy_w = can_rd_data_r[11];
        //===========================================================================
        //����ַ�Ĵ�����ֵ
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            can_rd_addr_r <= 'd0;
        else
            can_rd_addr_r <= SR_ADDR;
    end
        //===========================================================================
        //��ʼ����ɱ�־
        //===========================================================================
        always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n)
            can_init_done_r <= 'd0;
        else if (fsm_cs == FSM_INIT_DONE)
            can_init_done_r <= 'd1;
        else
            can_init_done_r <= 'd0;
    end
        //===========================================================================
        //����ӿڸ�ֵ
        //==========================================================================
        assign can_init_done_out = can_init_done_r;
        assign wr_addr_out = can_wr_addr_r;
        assign wr_data_out = can_wr_data_r;
        assign wr_enable_out = can_wr_enable_r;
        assign rd_addr_out = can_rd_addr_r;
        assign rd_enable_out = can_rd_enable_r;
        endmodule
