//====================================================================================
// Company:
// Engineer: feng
// Create Date: 2018/3/29
// Design Name:PMSM_DESIGN
// Module Name: current_per_unit_module.v
// Target Device:
// Tool versions:
// Description:标幺化电流检测值，位宽16位
// Dependencies:
// Revision:
// Additional Comments:
//电流转换关系：标幺化电流值=电流采样值*(2^15-1)*10/(160*Imax)   Imax为电机额定工作最大电流值
//160=(2^7+2^5);
//(2^15-1)*10=2^18+2^16-2^3-2^1
//====================================================================================
`include "project_param.v"
module current_per_unit_module(
                               input            sys_clk,
                               input            reset_n,

                               input              current_value_valid_in,                                             //电流有效标志
                               input signed   [`DATA_WIDTH-1:0] current_value_in,                  //电流检测值

                               input              [`DATA_WIDTH-1:0] pmsm_imax_in,                    //电机额定电流值

                               output signed [`DATA_WIDTH-1:0] current_standardization_out,  //电流标幺化输出值
                               output            current_porce_done_out                                              //电流标幺化完成标志
                               );
//===========================================================================
//内部变量声明
//===========================================================================
wire   [`DATA_WIDTH+16-1:0]         dividend_wire;                 //除法器被除数
wire   [`DATA_WIDTH-1:0]               divisor_wire;                   //除法器除数
wire                                                    m_axis_dout_tvalid;        //除法器输出有效信号
wire  [`DATA_WIDTH*2+16-1:0]         m_axis_dout_tdata;          //除法器输出结果
reg                                                     current_porce_done_r;      //标幺化完成标志
reg signed[`DATA_WIDTH-1:0]       current_standardization_r;  //电流标幺值

//===========================================================================
//触发器IP核例化
//===========================================================================
current_per_unit_divider current_standardization_module(
                                                        .aclk(sys_clk),                                      // input wire aclk
                                                        .aresetn(reset_n),                                // input wire aresetn
                                                        .s_axis_divisor_tvalid(1'b1),    // input wire s_axis_divisor_tvalid
                                                        .s_axis_divisor_tready(),    // output wire s_axis_divisor_tready
                                                        .s_axis_divisor_tdata(divisor_wire),      // input wire [15 : 0] s_axis_divisor_tdata
                                                        .s_axis_dividend_tvalid(current_value_valid_in),  // input wire s_axis_dividend_tvalid
                                                        .s_axis_dividend_tready(),  // output wire s_axis_dividend_tready
                                                        .s_axis_dividend_tdata(dividend_wire),    // input wire [31 : 0] s_axis_dividend_tdata
                                                        .m_axis_dout_tvalid(m_axis_dout_tvalid),          // output wire m_axis_dout_tvalid
                                                        .m_axis_dout_tdata(m_axis_dout_tdata)            // output wire [47 : 0] m_axis_dout_tdata
);
//===========================================================================
//除法器除数位宽扩展
//===========================================================================
assign   dividend_wire = (current_value_in<<<'d18)+(current_value_in<<<'d16)-(current_value_in<<<'d3)   - current_value_in;
assign   divisor_wire = (pmsm_imax_in <<<7) + (pmsm_imax_in <<<5);
//===========================================================================
//除法器输出值截取
//===========================================================================
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_porce_done_r <= 'd0;
    else
        current_porce_done_r <= m_axis_dout_tvalid;
    end
always @(posedge sys_clk or negedge reset_n)
    begin
    if (!reset_n)
        current_standardization_r <= 'sd0;
    else if (m_axis_dout_tvalid)
        current_standardization_r <= {m_axis_dout_tdata[`DATA_WIDTH + 16 - 1], m_axis_dout_tdata[30:16]};
    else
        current_standardization_r <= current_standardization_r;
    end
//===========================================================================
//输出端口赋值
//===========================================================================
assign   current_standardization_out = current_standardization_r;
assign   current_porce_done_out = current_porce_done_r;
endmodule
