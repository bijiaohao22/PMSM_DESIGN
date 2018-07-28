//====================================================================================
// Company:
// Engineer: Li-xiaochuang
// Create Date: 2018/3/15
// Design Name:PMSM_DESIGN
// Module Name: project_param.v
// Target Device:
// Tool versions:
// Description: gloabal parameter definition
// Dependencies:
// Revision:
// Additional Comments:
//====================================================================================
`define DATA_WIDTH 16
`define SYS_CLK_PERIOD   20                        //unit:ns;

//current detect unit
`define CURRENT_SPI_SCLK_FREQ       4     //CURRENT SPI CLK FREQUENCY　   unit:MHz
`define CURRENT_SPI_TCSS   120                  //unit:ns  CS setup time
`define CURRENT_SPI_TCSH   120                 //unit:ns  CS hold time
`define CURRENT_SPI_CSON   400                 //unit:ns  CS high time

//electrical_rotation_phase_trig_calculate unit
`define PMSM_POLE_PAIRS    7                          //number of pole-pairs
`define INCREMENTAL_CODER_CPR    2048    //增量编码器线数

//clark and park transaction unit
`define PARK_MULT_LATENCY 4                      //  park变换乘法操作时钟延迟

//svpwm generate unit
`define DELTA_INC_VAL 16    // SVPWM增量值，时钟频率：50MHz， PWM频率12.207KHz

//drv8329s spi config unit
`define SPI_CLK_PERIOD 500  //unit:ns
`define SPI_FRAME_WIDTH 16    // frame width
`define DRIVER_CONTROL_REGISTER_VALUE 16'b0_0010_000_1000_0001  //  栅极驱动器控制寄存器设定值

//can节点配置
`define CAN_NODE_ID 11'b1010_1010_101
`define CAN_MODE_MASK  11'b1111_1111_111
//MCP2515指令集
`define RESET_CMD  8'b1100_0000
`define READ_CMD   8'b0000_0011
`define READ_STATE_CMD 8'b1010_0000
`define WRITE_CMD 8'b0000_0010
`define SEND_REQ0_CMD  8'b1000_0001
`define SEND_REQ1_CMD  8'b1000_0010
`define SEND_REQ2_CMD  8'b1000_0100
`define TX_BUFFER_WRITE0_CMD 8'b0100_0000  //写Tx缓冲器0，开始与TXB0SIDH
`define TX_BUFFER_WRITE1_CMD 8'b0100_0010  //写Tx缓冲器1，开始与TXB1SIDH
`define TX_BUFFER_WRITE2_CMD 8'b0100_0100  //写Tx缓冲器2，开始与TXB2SIDH
`define RX_BUFFER_READ0_CMD  8'b1001_0010  //接收缓冲器0，开始于RXB0D0
`define  RX_BUFFER_READ1_CMD  8'b1001_0100  //接收缓冲器1，开始于RXB1D0
//MCP2515SPI参数
`define MCP2515_SPI_PERIOD 200  //  unit:ns 5MHz
`define CS_SETUP_HOLD_TIME 100  //  unit:ns
`define SPI_TCSD   100  //unit:ns cs禁止时间
//位置模式配置
`define location_control_error  18'd50
`define ABSOLUTION_TOTAL_BIT 18
`define ABSOLUTION_PERIOD 1000        //unit:ns
//系统调度模块
`define BAND_BREAK_OPEN 8'h00
`define BAND_BREAK_CLOSE 8'hff
`define MOTOR_START_CMD 8'hff
`define MOTOR_STOP_CMD 8'h00
`define MOTOR_SPEED_MODE 4'h1
`define MOTOR_LOCATION_MODE 4'h0

