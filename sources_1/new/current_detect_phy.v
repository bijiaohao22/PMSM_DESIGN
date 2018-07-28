`timescale 1ns / 1ps
//====================================================================================
// Company:
// Engineer: Li-xiaochuang
// Create Date: 2018/3/15
// Design Name:PMSM_DESIGN
// Module Name: current_detect_phy.v
// Target Device:
// Tool versions:
// Description: drive the current_sensor to get the actual current value
// Dependencies:
// Revision:
// Additional Comments:
//SPI CLK SPEED:5MHz(max)
//CS setup time:95ns;
//CS hold time 95ns
//data setup time：65ns
//Delay between CS rising edge and end of DOUT data:75ns;
//CS high time:300ns(min)
//====================================================================================
`include "project_param.v"
module current_detect_phy(
    input    sys_clk,                //system clock 
    input    reset_n,                //reset signal,low active

    input    detect_enable_in, //detect_enable signale
    input    [`DATA_WIDTH-1:0]  pmsm_imax_in,  //电机额定电流值(x10)

    input    spi_data_in,         //spi data in
    output  spi_sclk_out,       //spi sclk out
    output  spi_cs_n_out,      //chip select out ,low-active

    output signed [`DATA_WIDTH-1:0] current_out,         //current detect out

    output  [(`DATA_WIDTH/2)-1:0]   state_out,  //status of the sensor out
    output  detect_err_out,      //current detect error out

    output  detect_done_out   //current detect done out 
    );
    //===========================================================================
    //localparam declaration
    //===========================================================================
    localparam SCLK_PERIDO_CNT=1_000/(`CURRENT_SPI_SCLK_FREQ*`SYS_CLK_PERIOD);
    localparam TCSS_CNT  =`CURRENT_SPI_TCSS/`SYS_CLK_PERIOD;
    //localparam TCSH_CNT =`CURRENT_SPI_TCSH/`SYS_CLK_PERIOD;
    localparam TCSON_CNT=`CURRENT_SPI_CSON/`SYS_CLK_PERIOD;

    //state machine state declaration
    localparam FSM_IDLE='b1;
    localparam FSM_TCSS_WAIT='b1<<1;
    localparam FSM_DATA_READ='b1<<2;
    localparam FSM_PARITY_CHECK='b1<<3;
    localparam FSM_DATA_PROCESS='b1<<4;
    localparam FSM_TSCON_WAIT='b1<<5;


    //===========================================================================
    //Variable declaration
    //===========================================================================
    reg [$clog2(SCLK_PERIDO_CNT)-1:0]   SPI_PERIOD_CNT;  //one bit period count reg
    reg [$clog2(TCSS_CNT)-1:0]                    SPI_TCSS_CNT;      //tcss time count
    //reg [$clog2(TCSH_CNT)-1:0]                   SPI_TCSH_CNT;      //tcsh time count
    reg [$clog2(TCSON_CNT)-1:0]                SPI_TCSON_CNT;   //tcson time count
    
    //state machine declaration
    reg [5:0]   fsm_state_cs,fsm_state_ns;

    reg [1:0]  spi_data_r;    // Cache two clock cycles to avoid metastability
    reg           spi_sclk_r;
    reg           spi_cs_n_r;
    
    reg [15:0] spi_data_cache;
    reg  [3:0] spi_data_cnt; // a frame has 16 bits
    reg [3:0] detect_err_cnt;//error detect count,indicate a hardware failure while counting to 10;
    
    reg signed [`DATA_WIDTH-1:0]   current_r;
    reg[(`DATA_WIDTH/2)-1:0] state_r;
    reg   detect_err_r;
    reg   detect_done_r;

    reg overcurrent_flag;    //overcurrent flag

    //===========================================================================
    //overcurrent detection
    //===========================================================================
    always@(*)
        begin
            if(!spi_data_cache[15])
                begin
                    if(((spi_data_cache&'h1fff)<=((pmsm_imax_in<<4)+'d4096))&&((spi_data_cache&'h1fff)>=('d4096-(pmsm_imax_in<<4))))
                        overcurrent_flag=1'b0;
                    else
                        overcurrent_flag=1'b1;
                end
            else
                overcurrent_flag=1'b0;

        end
    //===========================================================================
    //State machine operation
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            fsm_state_cs <= FSM_IDLE;
        else
            fsm_state_cs <= fsm_state_ns;
        end
    always@(*)
        begin
        case (fsm_state_cs)
            FSM_IDLE: begin
                    if (detect_enable_in)   //enable the detect
                        fsm_state_ns = FSM_TCSS_WAIT;
                    else
                        fsm_state_ns = FSM_IDLE;
                end
            FSM_TCSS_WAIT: begin
                    if (SPI_TCSS_CNT == TCSS_CNT - 1)
                        fsm_state_ns = FSM_DATA_READ;
                    else
                        fsm_state_ns = FSM_TCSS_WAIT;
                end
            FSM_DATA_READ: begin //16 spi cycle
                    if ((spi_data_cnt == 'd15) && (SPI_PERIOD_CNT == SCLK_PERIDO_CNT - 1))
                        fsm_state_ns = FSM_PARITY_CHECK;
                    else
                        fsm_state_ns = FSM_DATA_READ;
                end
            FSM_PARITY_CHECK: begin
                if (((~(^spi_data_cache)) && detect_err_cnt != 'd10-1) || {spi_data_cache[15], spi_data_cache[13:10]} == 5'b10000) //parity check is error but less 10 times,or get a right status message frame;
                        fsm_state_ns = FSM_TSCON_WAIT;
                    else
                        fsm_state_ns = FSM_DATA_PROCESS;
                end
            FSM_DATA_PROCESS: begin
                    fsm_state_ns = FSM_IDLE;
                end
            FSM_TSCON_WAIT: 
              begin
                    if (SPI_TCSON_CNT == TCSON_CNT - 'b1)
                        fsm_state_ns = FSM_DATA_READ;
                    else
                        fsm_state_ns = FSM_TSCON_WAIT;
                end
            default :fsm_state_ns = FSM_IDLE;
        endcase
        end
    //===========================================================================
    //spi_cs_n signal operation
    //set the CS low while the state is in FSM_TCSS_WAIT and FSM_PARITY_CHECK and FSM_DATA_READ
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            spi_cs_n_r <= 'd1;
        else if (fsm_state_cs == FSM_TCSS_WAIT || fsm_state_cs == FSM_DATA_READ || fsm_state_cs == FSM_PARITY_CHECK)
            spi_cs_n_r <= 'd0;
        else
            spi_cs_n_r <= 'd1;
        end
    //===========================================================================
    //tcss delay count
    //===========================================================================
    always@(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            SPI_TCSS_CNT <= 'd0;
        else if (fsm_state_cs == FSM_TCSS_WAIT)
            SPI_TCSS_CNT <= SPI_TCSS_CNT + 'b1;
        else
            SPI_TCSS_CNT <= 'd0;
        end
    //===========================================================================
    //spi_sclk signal operation
    //duty:50%
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            spi_sclk_r <= 'b0;
        else if (fsm_state_ns == FSM_DATA_READ && SPI_PERIOD_CNT < SCLK_PERIDO_CNT / 2)
            spi_sclk_r <= 'b1;
        else
            spi_sclk_r <= 'b0;
        end
    //===========================================================================
    //spi sclk period count
    //===========================================================================
    always@(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            SPI_PERIOD_CNT <= 'd0;
        else if (fsm_state_cs == FSM_DATA_READ)
            begin
            if (SPI_PERIOD_CNT == SCLK_PERIDO_CNT - 1)
                SPI_PERIOD_CNT <= 'd0;
            else
                SPI_PERIOD_CNT <= SPI_PERIOD_CNT + 'b1;
            end
        end
    //===========================================================================
    //spi clock cycle count
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            spi_data_cnt <= 'd0;
        else if (fsm_state_cs == FSM_DATA_READ)
            begin
            if (SPI_PERIOD_CNT == SCLK_PERIDO_CNT-1)
                spi_data_cnt <= spi_data_cnt + 'b1;
            else
                spi_data_cnt <= spi_data_cnt;
            end else
            spi_data_cnt <= 'd0;
        end
    //===========================================================================
    //spi data register
    //===========================================================================
    //latency the sdo input tow clock cycles to avoid metastability
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            spi_data_r <= 'd0;
        else
            spi_data_r <= {spi_data_r[0], spi_data_in};
        end
    //get the actual data during data period
    always  @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            spi_data_cache <= 'd0;
        else if (fsm_state_cs == FSM_IDLE)
            spi_data_cache<='d0;
        else if (fsm_state_cs == FSM_DATA_READ && (SPI_PERIOD_CNT == SCLK_PERIDO_CNT / 2 + 'b1)) //dut to two clock latency
            spi_data_cache <= {spi_data_cache[14:0], spi_data_r[1]};
        else
            spi_data_cache <= spi_data_cache;
        end
    //===========================================================================
    //tcson time count
    //===========================================================================
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            SPI_TCSON_CNT <= 'd0;
        else if (fsm_state_cs == FSM_TSCON_WAIT)
            SPI_TCSON_CNT <= SPI_TCSON_CNT + 'b1;
        else
            SPI_TCSON_CNT <= 'd0;
        end
    //===========================================================================
    //count the failure time of the parity check ,once count to 10 times continuely, indicate thehardware disconnect
    //===========================================================================
    always@(posedge sys_clk or negedge reset_n)
        begin
            if (!reset_n)
                detect_err_cnt<='d0;
            else if(fsm_state_cs==FSM_DATA_PROCESS)
                detect_err_cnt<='d0;
            else if (fsm_state_cs == FSM_PARITY_CHECK&&(~(^spi_data_cache)))//parity check is detect
                        detect_err_cnt <= detect_err_cnt+'d1;
            else
                detect_err_cnt <= detect_err_cnt;
        end
    //===========================================================================
    //data_process
    //===========================================================================
    //detect_err_r operation
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            detect_err_r <= 'd0;
        else if (fsm_state_cs == FSM_DATA_PROCESS)
            begin
                if ({spi_data_cache[15], spi_data_cache[13]} == 2'b01 || spi_data_cache[15] || detect_err_cnt=='d10||overcurrent_flag)
                detect_err_r <= 'd1;
            else
                detect_err_r <= 'd0;
            end 
        else
            detect_err_r <= 'd0;
        end
    //state_r operation
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            state_r <= 'd0;
        else if (fsm_state_cs == FSM_DATA_PROCESS)
            begin
            if (detect_err_cnt=='d10)//disconnect error
                state_r<= {`DATA_WIDTH{1'b0}} | (1'b1 << 5);
            else if (({spi_data_cache[15], spi_data_cache[13]} == 2'b01)||overcurrent_flag)//OCD error
                state_r <= {`DATA_WIDTH{1'b0}} | (1'b1 << 4);
            else if ({spi_data_cache[15], spi_data_cache[13:10]}!= 5'b10000)//statue message
                state_r <= {`DATA_WIDTH{1'b0}} | spi_data_cache[13:10] ;  
            else if(detect_done_r)
                state_r<='d0;
            else
               state_r <=state_r;
            end
        end
    //current_r operation
    always @(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            current_r <= 'sd0;
        else if (fsm_state_cs == FSM_DATA_PROCESS && (~spi_data_cache[15]))
            current_r <= (spi_data_cache & 16'b0001_1111_1111_1111) - 'sd4096;
        else
            current_r <= current_r;
        end
    //===========================================================================
    //detect done signal
    //===========================================================================
    always@(posedge sys_clk or negedge reset_n)
        begin
        if (!reset_n)
            detect_done_r <= 'd0;
        else if (fsm_state_cs == FSM_DATA_PROCESS && ({spi_data_cache[15], spi_data_cache[13]} == 2'b00)&&( detect_err_cnt!='d10)&&(!overcurrent_flag)) 
            detect_done_r <= 'd1;
        else
            detect_done_r <= 'd0;
        end
    //===========================================================================
    //output port assignment
    //===========================================================================
    assign spi_sclk_out = spi_sclk_r;
    assign spi_cs_n_out = spi_cs_n_r;
    assign current_out = current_r;
    assign state_out = state_r;
    assign detect_err_out = detect_err_r;
    assign detect_done_out = detect_done_r;
endmodule
