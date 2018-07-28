`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/12
// Design Name:PMSM_DESIGN
// Module Name: electrical_rotation_phase_calculate_module.v
// Target Device:
// Tool versions:
// Description:���������������������������ȡ���ת�ӵĵ�Ƕ�
// Dependencies:
// Revision:
// Additional Comments:
//���յ�������ת�Ƕ���λԤ��ʹ��ʱ�����ݻ�����������״̬�����Ƕ�Ԥ��ֵ������������ģʽ�£�������ת
//����ʵʱ��ȡת�ӵ����Ƕȣ���������������λ�仯ʱ��У׼�����Ƕȣ����������Ӧ�ĵ����Ƕ�����Ϊ2*������
//*2048/��������������
//====================================================================================
`include "project_param.v"
module electrical_rotation_phase_calculate_module(
                                                  input    sys_clk,
                                                  input    reset_n,

                                                  input    electrical_rotation_phase_forecast_enable_in,            //������ת�Ƕ���λԤ��ʹ�ܣ������ϵ��λʱ��λԤ��

                                                  //������������Ϣ����
                                                  input    heds_9040_decoder_in,           //����������������������
                                                  input    rotate_direction_in,                  //��ת��������

                                                  //��������������
                                                  input    hall_u_in,
                                                  input    hall_v_in,
                                                  input    hall_w_in,

                                                  //�����Ƕ����
                                                  output  [`DATA_WIDTH-1:0]   electrical_rotation_phase_out,
                                                  output                                        electrical_rotation_phase_valid_out
                                                  );

//===========================================================================
//�ڲ������볣������
//===========================================================================
localparam   DELTA_PHASE=2*`PMSM_POLE_PAIRS*2048/`INCREMENTAL_CODER_CPR; //�������������������Ӧ�ĵ�Ƕ�ֵ
reg   hall_u_r,hall_v_r, hall_w_r;  //�������������뻺��
reg   heds_9040_decoder_r;//�����������������뻺��

reg[13:0]   electrical_rotation_phase_r,electrical_rotation_phase_r_ns;      //ת�ӵ����Ƕȼ���������һ״̬
reg               electrical_rotation_phase_valid_out_r;                                    //ת�ӵ����Ƕ���Чֵ
wire[2:0]     hall_current_value,hall_next_value;                                        //������������ǰ״̬������һ״̬

//===========================================================================
//�������������뻺��
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        {hall_u_r, hall_v_r, hall_w_r} <= 'd0;
    else
    {hall_u_r, hall_v_r, hall_w_r} <= {hall_u_in, hall_v_in, hall_w_in};
    end

assign hall_current_value = {hall_u_r, hall_v_r, hall_w_r};
assign hall_next_value=
    {
    hall_u_in,hall_v_in,hall_w_in
    };
//===========================================================================
//������������������������
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
        if(!reset_n)
            heds_9040_decoder_r<='d0;
        else
            heds_9040_decoder_r <= heds_9040_decoder_in;
    end


//===========================================================================
//ת�ӵ����Ƕȼ���
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        electrical_rotation_phase_r <= 'd0;
    else
        electrical_rotation_phase_r <= electrical_rotation_phase_r_ns;
    end
always @(*)
    begin
    if (electrical_rotation_phase_forecast_enable_in)        //�յ������Ƕ�Ԥ��ʱ��ת��λ��Ԥ��
        begin
        case (hall_current_value)
            3'b101:  electrical_rotation_phase_r_ns = 14'h555;           //30�ȵ�Ƕ�
            3'b100:  electrical_rotation_phase_r_ns = 14'h1000;          //90�ȵ�Ƕ�
            3'b110:  electrical_rotation_phase_r_ns = 14'h1aaa;          //150�ȵ�Ƕ�
            3'b010:  electrical_rotation_phase_r_ns = 14'h2555;           //210�ȵ�Ƕ�
            3'b011:  electrical_rotation_phase_r_ns = 14'h3000;           //270�ȵ�Ƕ�
            3'b001:  electrical_rotation_phase_r_ns = 14'h3aaa;           //330�ȵ�Ƕ�
            default:electrical_rotation_phase_r_ns = electrical_rotation_phase_r;
        endcase
        end 
        else if (hall_next_value != hall_current_value)    //�������������źŷ����仯ʱ���Ե�ǶȽ���У��
        begin
        if (rotate_direction_in) //��ת���
            case (hall_next_value)
                3'b101:  electrical_rotation_phase_r_ns = 14'h0aaa;           //60�ȵ�Ƕ�
                3'b100:  electrical_rotation_phase_r_ns = 14'h1555;          //120�ȵ�Ƕ�
                3'b110:  electrical_rotation_phase_r_ns = 14'h2000;          //180�ȵ�Ƕ�
                3'b010:  electrical_rotation_phase_r_ns = 14'h2aaa;           //240�ȵ�Ƕ�
                3'b011:  electrical_rotation_phase_r_ns = 14'h3555;           //300�ȵ�Ƕ�
                3'b001:  electrical_rotation_phase_r_ns = 14'h0000;           //0�ȵ�Ƕ�
                default:electrical_rotation_phase_r_ns = electrical_rotation_phase_r;
            endcase
        else //��ת���
            case (hall_next_value)
                3'b101:  electrical_rotation_phase_r_ns = 14'h0000;           //0�ȵ�Ƕ�
                3'b100:  electrical_rotation_phase_r_ns = 14'h0aaa;          //60�ȵ�Ƕ�
                3'b110:  electrical_rotation_phase_r_ns = 14'h1555;          //120�ȵ�Ƕ�
                3'b010:  electrical_rotation_phase_r_ns = 14'h2000;           //180�ȵ�Ƕ�
                3'b011:  electrical_rotation_phase_r_ns = 14'h2aaa;           //240�ȵ�Ƕ�
                3'b001:  electrical_rotation_phase_r_ns = 14'h3555;           //300�ȵ�Ƕ�
                default:electrical_rotation_phase_r_ns = electrical_rotation_phase_r;
            endcase
        end 
        else if (({heds_9040_decoder_r, heds_9040_decoder_in}==2'b01)||({heds_9040_decoder_r, heds_9040_decoder_in}==2'b10))
        begin
        if (rotate_direction_in) //��ת���
            electrical_rotation_phase_r_ns = electrical_rotation_phase_r - DELTA_PHASE;
        else //��ת���
            electrical_rotation_phase_r_ns = electrical_rotation_phase_r + DELTA_PHASE;
        end
        else
            electrical_rotation_phase_r_ns=electrical_rotation_phase_r;
    end
    //===========================================================================
    //�����Ч״̬��ֵ
    //===========================================================================
    always  @(posedge sys_clk or negedge reset_n)
        begin
            if(!reset_n)
                electrical_rotation_phase_valid_out_r<='d0;
            else
                electrical_rotation_phase_valid_out_r<=1'd1;
        end
        //===========================================================================
        //���״̬��ֵ
        //===========================================================================
        assign electrical_rotation_phase_out={electrical_rotation_phase_r[13],electrical_rotation_phase_r[13],electrical_rotation_phase_r};
        assign electrical_rotation_phase_valid_out=electrical_rotation_phase_valid_out_r;
endmodule
