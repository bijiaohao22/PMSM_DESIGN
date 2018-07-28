//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/18
// Design Name:PMSM_DESIGN
// Module Name: speed_detection_sim.sv
// Target Device:
// Tool versions:
// Description: motor speed detection simulation
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
module speed_detection_sim;

    //===========================================================================
    //�ڲ���������
    //===========================================================================
    reg   sys_clk,
        reset_n;
    reg   incremental_encode_ch_a_in,
        incremental_encode_ch_b_in;
    reg[15:0]  rated_speed_in;
    wire incremental_decoder_w,
        rotate_direction_w;
    reg[15:0]  standardization_speed_out;
    reg signed [15:0]  standardization_speed_reference;

    //===========================================================================
    //ģ������
    //===========================================================================
    incremental_encoder_decoder_module incremental_encoder_decoder_inst(
                                                                        .sys_clk(sys_clk),                //ϵͳʱ��
                                                                        .reset_n(reset_n),                //��λ�źţ��͵�ƽ��Ч

                                                                        .heds_9040_ch_a_in(incremental_encode_ch_a_in),    //����������aͨ������
                                                                        .heds_9040_ch_b_in(incremental_encode_ch_b_in),   //����������bͨ������

                                                                        .heds_9040_decoder_out(incremental_decoder_w),     //�����������������
                                                                        .rotate_direction_out(rotate_direction_w)             //��ת���������0����ת��1����ת
    );

    speed_detection_module speed_detection_inst(
                                                .sys_clk(sys_clk),
                                                .reset_n(reset_n),

                                                .incremental_decoder_in(incremental_decoder_w),
                                                .rotation_direction_in(rotate_direction_w),

                                                .rated_speed_in(rated_speed_in),       //�ת������

                                                .standardization_speed_out(standardization_speed_out)  //���ۻ��ٶ�ֵ���
    );
    //===========================================================================
    //ʱ�Ӹ�ֵ
    //===========================================================================
    always #1 sys_clk = ~sys_clk;
    //===========================================================================
    //��������
    //===========================================================================
    initial
        begin
        reset_n = 0;
        sys_clk = 0;
        incremental_encode_ch_a_in = 1;
        incremental_encode_ch_b_in = 1;
        rated_speed_in='d4000;
        $display("rated_speed is 4000m r/min");
        #100;
        reset_n = 1;
        #1000;
        $display("speed set is 3662rad/min");
        standardization_speed_reference=3662*(2**15-1)/4000;
        incremental_enmdoer_run(100,0,128);
        $display("speed set is -3662rad/min");
        standardization_speed_reference=-'sd3662*(2**15-1)/4000;
        incremental_enmdoer_run(100,1,128);

        $display("speed set is 1000rad/min");
        incremental_enmdoer_run(366,0,64);
        standardization_speed_reference='sd1000*(2**15-1)/4000;
        $display("speed set is -1000rad/min");
         standardization_speed_reference=-'sd1000*(2**15-1)/4000;
        incremental_enmdoer_run(366,1,64);

        $display("speed set is 500rad/min");
        incremental_enmdoer_run(732,0,32);
        standardization_speed_reference='sd500*(2**15-1)/4000;
        $display("speed set is -500rad/min");
        standardization_speed_reference=-'sd500*(2**15-1)/4000;
        incremental_enmdoer_run(732,1,32);

        $display("speed set is 50rad/min");
        standardization_speed_reference='sd50*(2**15-1)/4000;
        incremental_enmdoer_run(7324,0,16);
        $display("speed set is -50rad/min");
        standardization_speed_reference=-'sd50*(2**15-1)/4000;
        incremental_enmdoer_run(7324,1,16);

        $display("speed set is 5rad/min");
        standardization_speed_reference='sd5*(2**15-1)/4000;
        incremental_enmdoer_run(73242,0,16);
        $display("speed set is -5rad/min");
        standardization_speed_reference=-'sd5*(2**15-1)/4000;
        incremental_enmdoer_run(73242,1,16);

        $display("speed set is 0.1rad/min");
        standardization_speed_reference='sd1*(2**15-1)/40000;
        incremental_enmdoer_run(3662112,0,4);
        $display("speed set is -0.1rad/min");
        standardization_speed_reference=-'sd1*(2**15-1)/40000;
        incremental_enmdoer_run(3662112,1,4);

        $display("speed set is 0rad/min",4);
        standardization_speed_reference='d0;
        incremental_enmdoer_run(67108868,0,2);
        $display("speed set is -0rad/min",4);
        incremental_enmdoer_run(67108868,1,2);
        $stop;
        end

    //===========================================================================
    //�������������
    //===========================================================================
    task incremental_enmdoer_run(input int  period,input logic direction,input int times);
         if (direction) //0:��ת��1����ת
        begin
        repeat (times)
            begin
            {incremental_encode_ch_b_in, incremental_encode_ch_a_in} = 'b10;
            #(period*2);
            {incremental_encode_ch_b_in, incremental_encode_ch_a_in} = 'b11;
            #(period*2);
            {incremental_encode_ch_b_in, incremental_encode_ch_a_in} = 'b01;
            #(period*2);
            {incremental_encode_ch_b_in, incremental_encode_ch_a_in} = 'b00;
            #(period*2);
            end
        end else
        begin
        repeat (times)
            begin
            {incremental_encode_ch_a_in, incremental_encode_ch_b_in} = 'b10;
            #(period*2);
            {incremental_encode_ch_a_in, incremental_encode_ch_b_in} = 'b11;
            #(period*2);
            {incremental_encode_ch_a_in, incremental_encode_ch_b_in} = 'b01;
            #(period*2);
            {incremental_encode_ch_a_in, incremental_encode_ch_b_in} = 'b00;
            #(period*2);
            end
        end
    endtask
endmodule
