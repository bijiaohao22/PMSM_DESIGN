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
`define CURRENT_SPI_SCLK_FREQ       4     //CURRENT SPI CLK FREQUENCY��   unit:MHz
`define CURRENT_SPI_TCSS   120                  //unit:ns  CS setup time
`define CURRENT_SPI_TCSH   120                 //unit:ns  CS hold time
`define CURRENT_SPI_CSON   400                 //unit:ns  CS high time

//electrical_rotation_phase_trig_calculate unit
`define PMSM_POLE_PAIRS    7                          //number of pole-pairs
`define INCREMENTAL_CODER_CPR    2048    //��������������

//clark and park transaction unit
`define PARK_MULT_LATENCY 4                      //  park�任�˷�����ʱ���ӳ�

//svpwm generate unit
`define DELTA_INC_VAL 16    // SVPWM����ֵ��ʱ��Ƶ�ʣ�50MHz�� PWMƵ��12.207KHz

//drv8329s spi config unit
`define SPI_CLK_PERIOD 500  //unit:ns
`define SPI_FRAME_WIDTH 16    // frame width
`define DRIVER_CONTROL_REGISTER_VALUE 16'b0_0010_000_1000_0001  //  դ�����������ƼĴ����趨ֵ

//can�ڵ�����
`define CAN_NODE_ID 11'b1010_1010_101
`define CAN_MODE_MASK  11'b1111_1111_111
//MCP2515ָ�
`define RESET_CMD  8'b1100_0000
`define READ_CMD   8'b0000_0011
`define READ_STATE_CMD 8'b1010_0000
`define WRITE_CMD 8'b0000_0010
`define SEND_REQ0_CMD  8'b1000_0001
`define SEND_REQ1_CMD  8'b1000_0010
`define SEND_REQ2_CMD  8'b1000_0100
`define TX_BUFFER_WRITE0_CMD 8'b0100_0000  //дTx������0����ʼ��TXB0SIDH
`define TX_BUFFER_WRITE1_CMD 8'b0100_0010  //дTx������1����ʼ��TXB1SIDH
`define TX_BUFFER_WRITE2_CMD 8'b0100_0100  //дTx������2����ʼ��TXB2SIDH
`define RX_BUFFER_READ0_CMD  8'b1001_0010  //���ջ�����0����ʼ��RXB0D0
`define  RX_BUFFER_READ1_CMD  8'b1001_0100  //���ջ�����1����ʼ��RXB1D0
//MCP2515SPI����
`define MCP2515_SPI_PERIOD 200  //  unit:ns 5MHz
`define CS_SETUP_HOLD_TIME 100  //  unit:ns
`define SPI_TCSD   100  //unit:ns cs��ֹʱ��
//λ��ģʽ����
`define location_control_error  18'd50
`define ABSOLUTION_TOTAL_BIT 18
`define ABSOLUTION_PERIOD 1000        //unit:ns
//ϵͳ����ģ��
`define BAND_BREAK_OPEN 8'h00
`define BAND_BREAK_CLOSE 8'hff
`define MOTOR_START_CMD 8'hff
`define MOTOR_STOP_CMD 8'h00
`define MOTOR_SPEED_MODE 4'h1
`define MOTOR_LOCATION_MODE 4'h0

