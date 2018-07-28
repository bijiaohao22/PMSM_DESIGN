`include "E:\work_folder\PMSM_DESIGN\FPGA_DESIGN\PMSM_DESIGN\PMSM_DESIGN\PMSM_DESIGN.srcs\sources_1\new\project_param.v"
module electrical_phase_trig_calculation_sim();
//===========================================================================
//signals
//===========================================================================
reg sys_clk,
    reset_n;
reg heds_9040_ch_a_in,
    heds_9040_ch_b_in; //incremental_input_signals
reg electrical_rotation_phase_forecast_enable;  //phase predict enable
reg hall_u,
    hall_v,
    hall_w;

wire incremental_encoder_decode_w,
    rotate_direction_w;
wire[`DATA_WIDTH-1:0]    electrical_rotation_phase_sin_out;
wire[`DATA_WIDTH-1:0]    electrical_rotation_phase_cos_out;
wire  electrical_rotation_phase_trig_calculate_valid;
int cnt;

//===========================================================================
//DUT
//===========================================================================
incremental_encoder_decoder_module incremental_encoder_decoder_inst(
                                                                    .sys_clk(sys_clk),                //系统时钟
                                                                    .reset_n(reset_n),                //复位信号，低电平有效

                                                                    .heds_9040_ch_a_in(heds_9040_ch_a_in),    //增量编码器a通道输入
                                                                    .heds_9040_ch_b_in(heds_9040_ch_b_in),   //增量编码器b通道输入

                                                                    .heds_9040_decoder_out(incremental_encoder_decode_w),     //增量编码器解码输出
                                                                    .rotate_direction_out(rotate_direction_w)             //旋转方向输出，0：正转，1：反转
);

electrical_rotation_phase_trig_calculate_module electrical_rotation_phase_trig_calculate_inst(
                                                .sys_clk(sys_clk),             //系统时钟
                                                .reset_n(reset_n),             //复位信号，低电平有效

                                                .electrical_rotation_phase_forecast_enable(electrical_rotation_phase_forecast_enable),    //电气旋转角度相位预测使能，用于上电或复位时相位预判

                                                .incremental_encoder_decode_in(incremental_encoder_decode_w),                 //增量编码器正交编码输入
                                                .rotate_direction_in(rotate_direction_w),                                     //旋转方向输入

                                                //hall signal input
                                                .hall_u_in(hall_u),
                                                .hall_v_in(hall_v),
                                                .hall_w_in(hall_w),

                                                .electrical_rotation_phase_sin_out(electrical_rotation_phase_sin_out), //电气旋转角度正弦输出
                                                .electrical_rotation_phase_cos_out(electrical_rotation_phase_cos_out), //电气旋转角度余弦输出
                                                .electrical_rotation_phase_trig_calculate_valid(electrical_rotation_phase_trig_calculate_valid)                       //正余弦计算有效标志输出
                                                );
//===========================================================================
//signals initlization
//===========================================================================
initial
    begin
    sys_clk = 0;
    reset_n = 0;
    heds_9040_ch_a_in = 1;
    heds_9040_ch_b_in = 1;
    electrical_rotation_phase_forecast_enable = 0;
    hall_u = 0;
    hall_v = 0;
    hall_w = 0;
    @(negedge sys_clk)
        reset_n = 1;
        fork
            begin
            #20; @(negedge sys_clk) electrical_rotation_phase_forecast_enable <= 'b1;
            @(negedge sys_clk) electrical_rotation_phase_forecast_enable <= 'b0;
            end
        incremental_encoder_module(0);
        begin
             repeat(7)
                 hall_module(0);
        end       
        join
        fork
        incremental_encoder_module(0);
        begin
             repeat(7)
                 hall_module(0);
        end 
        join
        fork
        incremental_encoder_module(1);
        begin
             repeat(7)
                 hall_module(1);
        end 
        join
        fork
        incremental_encoder_module(1);
        begin
             repeat(7)
                 hall_module(1);
        end 
        join
    $stop;
    end


always #2 sys_clk = ~sys_clk;

task incremental_encoder_module(input logic rotation);
    if (rotation) //0:正转，1：反转
        begin
        repeat (2048)
            begin
            {heds_9040_ch_b_in, heds_9040_ch_a_in} = 'b10;
            #210;
            {heds_9040_ch_b_in, heds_9040_ch_a_in} = 'b11;
            #210;
            {heds_9040_ch_b_in, heds_9040_ch_a_in} = 'b01;
            #210;
            {heds_9040_ch_b_in, heds_9040_ch_a_in} = 'b00;
            #210;
            end
        end else
        begin
        repeat (2048)
            begin
            {heds_9040_ch_a_in, heds_9040_ch_b_in} = 'b10;
            #210;
            {heds_9040_ch_a_in, heds_9040_ch_b_in} = 'b11;
            #210;
            {heds_9040_ch_a_in, heds_9040_ch_b_in} = 'b01;
            #210;
            {heds_9040_ch_a_in, heds_9040_ch_b_in} = 'b00;
            #210;
            end
        end
endtask

task hall_module(input logic rotation);
    if (rotation) //0:正转，1：反转
        begin
        {hall_u, hall_v, hall_w} = 3'b001;
        #40960;
        {hall_u, hall_v, hall_w} = 3'b011;
        #40960;
        {hall_u, hall_v, hall_w} = 3'b010;
        #40960;
        {hall_u, hall_v, hall_w} = 3'b110;
        #40960;
        {hall_u, hall_v, hall_w} = 3'b100;
        #40960;
        {hall_u, hall_v, hall_w} = 3'b101;
        #40960;
        end else
        begin
        {hall_u, hall_v, hall_w} = 3'b101;
        #40960;
        {hall_u, hall_v, hall_w} = 3'b100;
        #40960;
        {hall_u, hall_v, hall_w} = 3'b110;
        #40960;
        {hall_u, hall_v, hall_w} = 3'b010;
        #40960;
        {hall_u, hall_v, hall_w} = 3'b011;
        #40960;
        {hall_u, hall_v, hall_w} = 3'b001;
        #40960;
        end
endtask

endmodule
