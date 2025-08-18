`timescale 1ns / 1ps

module I2C_Slave (
    //global signals
    input        clk,
    input        reset,
    //internal signals
    input        SCL,
    inout        SDA,
    output [4:0] state_r,
    output       rx_done,
    output [7:0] outData1,
    output [7:0] outData2,
    input  [7:0] inData1,
    input  [7:0] inData2
);

    localparam IDLE=0, START1=1, START2=2, ADDR1=3, ADDR2=4, ADDR3=5, 
    ADDR_HOLD=6, ACK_START=7, ACK1=8, ACK2=9, ACK3=10, ADDR_ACK_END = 11, DATA_ACK_END=12, 
    RDATA1=13, RDATA2=14, RDATA3=15, WDATA1=16, WDATA2=17, WDATA3=18, WDATA_HOLD=19;
    localparam SLV_ADDR = 0;

    reg [4:0] state, state_next;
    reg  SDA_out;
    wire SDA_in;
    reg SDA_in_D, SDA_in_DD, SCL_D, SCL_DD;
    reg [7:0] temp_tx_data_next, temp_tx_data_reg;
    reg [7:0] temp_rx_data_next, temp_rx_data_reg;
    reg [8:0] clk_counter_next, clk_counter_reg;
    reg [2:0] bit_counter_next, bit_counter_reg;
    reg data_cnt_next, data_cnt_reg;
    reg rx_next, rx_reg;
    reg ack_next, ack_reg;
    reg send_reg, send_next;
    reg w_mode_reg, w_mode_next;
    reg done_next, done_reg;
    reg rx_done_next, rx_done_reg;
    reg [7:0]
        slv_reg, slv_reg_next, slv_reg2, slv_reg2_next, slv_reg3, slv_reg4;

    assign outData1 = slv_reg;
    assign outData2 = slv_reg2;
    assign rx_done  = rx_done_reg;

    assign state_r  = state;


    wire SDA_rising, SDA_falling;
    wire SCL_rising, SCL_falling;

    assign SDA         = send_reg ? SDA_out : 1'bz;
    assign SDA_in      = ~send_reg ? SDA : 1'b0;
    assign SDA_rising  = ~SDA_in_DD && SDA_in_D;
    assign SDA_falling = ~SDA_in_D && SDA_in_DD;
    assign SCL_rising  = ~SCL_DD && SCL_D;
    assign SCL_falling = ~SCL_D && SCL_DD;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            clk_counter_reg  <= 0;
            bit_counter_reg  <= 0;
            send_reg         <= 0;
            rx_reg           <= 0;
            slv_reg          <= 0;
            slv_reg2         <= 0;
            slv_reg3         <= 0;
            slv_reg4         <= 0;
            ack_reg          <= 0;
            w_mode_reg       <= 0;
            done_reg         <= 0;
            data_cnt_reg     <= 0;
            rx_done_reg      <= 0;
        end else begin
            state            <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            clk_counter_reg  <= clk_counter_next;
            bit_counter_reg  <= bit_counter_next;
            send_reg         <= send_next;
            rx_reg           <= rx_next;
            slv_reg          <= slv_reg_next;
            slv_reg2         <= slv_reg2_next;
            slv_reg3         <= inData1;
            slv_reg4         <= inData2;
            SDA_in_D         <= SDA_in;
            SDA_in_DD        <= SDA_in_D;
            SCL_D            <= SCL;
            SCL_DD           <= SCL_D;
            ack_reg          <= ack_next;
            w_mode_reg       <= w_mode_next;
            done_reg         <= done_next;
            data_cnt_reg     <= data_cnt_next;
            rx_done_reg      <= rx_done_next;
        end
    end

    always @(*) begin
        temp_tx_data_next = temp_tx_data_reg;
        temp_rx_data_next = temp_rx_data_reg;
        state_next        = state;
        clk_counter_next  = clk_counter_reg;
        bit_counter_next  = bit_counter_reg;
        send_next         = send_reg;
        rx_next           = rx_reg;
        slv_reg_next      = slv_reg;
        slv_reg2_next     = slv_reg2;
        SDA_out           = 0;
        ack_next          = ack_reg;
        w_mode_next       = w_mode_reg;
        done_next         = done_reg;
        data_cnt_next     = data_cnt_reg;
        rx_done_next      = rx_done_reg;
        case (state)
            IDLE: begin
                w_mode_next = 0;
                if (SCL && SDA_falling) begin
                    state_next = START1;
                    send_next  = 0;
                end
            end
            START1: begin
                if (SCL_falling) begin
                    clk_counter_next = 0;
                    state_next       = START2;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            START2: begin
                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    state_next       = ADDR1;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            ADDR1: begin
                if (SCL_rising) begin
                    state_next = ADDR2;
                    rx_next    = SDA_in;
                end
            end
            ADDR2: begin
                if (SCL_falling) begin
                    state_next = ADDR3;
                end
            end
            ADDR3: begin
                if (clk_counter_reg == 249) begin
                    clk_counter_next  = 0;
                    temp_rx_data_next = {temp_rx_data_reg, rx_reg};
                    if (bit_counter_reg == 7) begin  // ACK 수신 시작
                        state_next = ADDR_HOLD;
                        bit_counter_next = 0;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                        state_next = ADDR1;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            ADDR_HOLD: begin
                state_next = ACK_START;
                if (temp_rx_data_reg[0] == 0) begin
                    w_mode_next = 1;
                end else begin
                    w_mode_next = 0;
                end
                if (temp_rx_data_reg[7:1] == SLV_ADDR) begin
                    ack_next = 0;
                end else begin
                    ack_next = 1;
                end
            end
            ACK_START: begin
                SDA_out    = 0;
                rx_done_next = 0;
                state_next = ACK1;
                if (send_reg) begin  // write
                    send_next = 0;  // SDA input mode
                end else begin  // read
                    send_next = 1;  // SDA output mode
                end
            end
            ACK1: begin
                SDA_out = ack_reg;
                if (SCL_rising) begin
                    state_next = ACK2;
                    rx_next = SDA_in;
                end
            end
            ACK2: begin
                SDA_out = ack_reg;
                if (SCL_falling) begin
                    state_next = ACK3;
                end
            end
            ACK3: begin
                SDA_out = ack_reg;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    if (done_reg) begin
                        state_next = DATA_ACK_END;
                    end else begin
                        state_next = ADDR_ACK_END;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA_ACK_END: begin
                SDA_out   = ack_reg;
                done_next = 0;
                if (data_cnt_reg == 1) begin
                    send_next = 0;
                    data_cnt_next = 0;
                    state_next = IDLE;
                end else begin
                    if (w_mode_reg) begin
                        state_next = WDATA1;
                        send_next  = 0;
                    end else begin
                        state_next = RDATA1;
                        send_next = 1;
                        temp_tx_data_next = slv_reg4;
                    end
                    data_cnt_next = 1;
                end
            end
            ADDR_ACK_END: begin
                SDA_out = ack_reg;
                if (ack_reg == 1) begin
                    state_next = IDLE;
                end else begin
                    if (w_mode_reg) begin
                        state_next = WDATA1;
                        send_next  = 0;
                    end else begin
                        state_next = RDATA1;
                        send_next = 1;
                        temp_tx_data_next = slv_reg3;
                    end
                end
            end
            // read mode
            RDATA1: begin
                SDA_out = temp_tx_data_reg[7];
                if (SCL_rising) begin
                    state_next = RDATA2;
                end
            end
            RDATA2: begin
                SDA_out = temp_tx_data_reg[7];
                if (SCL_falling) begin
                    state_next = RDATA3;
                end
            end
            RDATA3: begin
                SDA_out = temp_tx_data_reg[7];
                if (clk_counter_reg == 249) begin
                    clk_counter_next  = 0;
                    temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                    if (bit_counter_reg == 7) begin  // ACK 수신 시작
                        state_next = ACK_START;
                        done_next = 1;
                        bit_counter_next = 0;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                        state_next = RDATA1;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            //write mode
            WDATA1: begin
                if (SCL_rising) begin
                    state_next = WDATA2;
                end
            end
            WDATA2: begin
                if (SCL_falling) begin
                    state_next = WDATA3;
                    rx_next = SDA_in;
                end
            end
            WDATA3: begin
                SDA_out = temp_tx_data_reg[7];
                if (clk_counter_reg == 249) begin
                    clk_counter_next  = 0;
                    temp_rx_data_next = {temp_rx_data_reg[6:0], rx_reg};
                    if (bit_counter_reg == 7) begin  // ACK 수신 시작
                        state_next = WDATA_HOLD;
                        bit_counter_next = 0;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                        state_next = WDATA1;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            WDATA_HOLD: begin
                done_next = 1;
                if (data_cnt_reg == 0) begin
                    slv_reg_next = temp_rx_data_reg;
                end else begin
                    slv_reg2_next = temp_rx_data_reg;
                    rx_done_next  = 1;
                end
                state_next = ACK_START;
            end
        endcase
    end
endmodule
