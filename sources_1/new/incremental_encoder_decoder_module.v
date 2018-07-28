//====================================================================================
// Company:
// Engineer: LiXiaochuang
// Create Date: 2018/4/12
// Design Name:PMSM_DESIGN
// Module Name: incremental_encoder_decoder_module.v
// Target Device:
// Tool versions:
// Description:对增量编码器进行正交编码，获取旋转方向
//正交编码：通过异或进行获取
//旋转方向获取：若cha下降沿时chb为高，则旋转方向为正转，若cha下降沿时chb为低，则旋转方向为反转
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================


module incremental_encoder_decoder_module(
                                          input                sys_clk,                //系统时钟
                                          input                reset_n,                //复位信号，低电平有效

                                          input                heds_9040_ch_a_in,    //增量编码器a通道输入
                                          input                heds_9040_ch_b_in,   //增量编码器b通道输入

                                          output              heds_9040_decoder_out,     //增量编码器解码输出
                                          output              rotate_direction_out             //旋转方向输出，0：正转，1：反转
);

    //===========================================================================
    //内部变量声明
    //===========================================================================
    reg[2:0]       heds_9040_ch_a_r,  heds_9040_ch_b_r;     // 增量编码器输入缓存，用于避免亚稳态
    reg                 heds_9040_decoder_r;                               // 增量编码器正交处理输出
    reg                 rotate_direction_r;                                      // 旋转方向寄存器

    //===========================================================================
    //增量编码器输入缓存
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            {heds_9040_ch_a_r, heds_9040_ch_b_r} <= 6'b000_000;
        else
        {heds_9040_ch_a_r, heds_9040_ch_b_r} <= {heds_9040_ch_a_r[1:0], heds_9040_ch_a_in, heds_9040_ch_b_r[1:0], heds_9040_ch_b_in};
        end
    //===========================================================================
    //增量编码器正交输出
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            heds_9040_decoder_r <= 'd0;
        else
            heds_9040_decoder_r <= heds_9040_ch_a_r[1] ^ heds_9040_ch_b_r[1];
        end
    //===========================================================================
    //旋转方向判定
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            rotate_direction_r <= 'd0;   //默认旋转方向为正
        else if (heds_9040_ch_a_r[2:1] == 2'b10)
            rotate_direction_r <= ~heds_9040_ch_b_r[1];
        else
            rotate_direction_r <= rotate_direction_r;
        end
    //===========================================================================
    //输出变量赋值
    //===========================================================================
    assign heds_9040_decoder_out = heds_9040_decoder_r;
    assign rotate_direction_out = rotate_direction_r;
endmodule
