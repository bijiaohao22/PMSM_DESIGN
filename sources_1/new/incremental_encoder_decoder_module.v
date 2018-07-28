//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/12
// Design Name:PMSM_DESIGN
// Module Name: incremental_encoder_decoder_module.v
// Target Device:
// Tool versions:
// Description:�����������������������룬��ȡ��ת����
//�������룺ͨ�������л�ȡ
//��ת�����ȡ����cha�½���ʱchbΪ�ߣ�����ת����Ϊ��ת����cha�½���ʱchbΪ�ͣ�����ת����Ϊ��ת
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================


module incremental_encoder_decoder_module(
                                          input                sys_clk,                //ϵͳʱ��
                                          input                reset_n,                //��λ�źţ��͵�ƽ��Ч

                                          input                heds_9040_ch_a_in,    //����������aͨ������
                                          input                heds_9040_ch_b_in,   //����������bͨ������

                                          output              heds_9040_decoder_out,     //�����������������
                                          output              rotate_direction_out             //��ת���������0����ת��1����ת
);

    //===========================================================================
    //�ڲ���������
    //===========================================================================
    reg[2:0]       heds_9040_ch_a_r,  heds_9040_ch_b_r;     // �������������뻺�棬���ڱ�������̬
    reg                 heds_9040_decoder_r;                               // ���������������������
    reg                 rotate_direction_r;                                      // ��ת����Ĵ���

    //===========================================================================
    //�������������뻺��
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            {heds_9040_ch_a_r, heds_9040_ch_b_r} <= 6'b000_000;
        else
        {heds_9040_ch_a_r, heds_9040_ch_b_r} <= {heds_9040_ch_a_r[1:0], heds_9040_ch_a_in, heds_9040_ch_b_r[1:0], heds_9040_ch_b_in};
        end
    //===========================================================================
    //�����������������
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            heds_9040_decoder_r <= 'd0;
        else
            heds_9040_decoder_r <= heds_9040_ch_a_r[1] ^ heds_9040_ch_b_r[1];
        end
    //===========================================================================
    //��ת�����ж�
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            rotate_direction_r <= 'd0;   //Ĭ����ת����Ϊ��
        else if (heds_9040_ch_a_r[2:1] == 2'b10)
            rotate_direction_r <= ~heds_9040_ch_b_r[1];
        else
            rotate_direction_r <= rotate_direction_r;
        end
    //===========================================================================
    //���������ֵ
    //===========================================================================
    assign heds_9040_decoder_out = heds_9040_decoder_r;
    assign rotate_direction_out = rotate_direction_r;
endmodule
