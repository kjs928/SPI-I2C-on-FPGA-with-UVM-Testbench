`timescale 1ns / 1ps
module I2C_Master (
    //global signals
    input            clk,
    input            reset,
    //internal signals
    input      [7:0] tx_data,
    output reg [7:0] rx_data,
    input            start,
    output           tx_done,
    output           ready,
    input            i2c_en,
    //external signals
    inout            SDA,
    output reg       SCL,
    output     [3:0] state_r,
    output           SDA_o
);

    localparam IDLE=0, START1=1, START2=2, DATA1=3, DATA2=4, DATA3=5, DATA4=6, 
                ACK_START=7, ACK_END=8, ADDRESS_HOLD=9, DATA_HOLD=10, STOP1=11, STOP2=12;

    reg [3:0] state, state_next;
    reg [7:0] temp_tx_data_next, temp_tx_data_reg;
    reg [7:0] temp_rx_data_next, temp_rx_data_reg;
    reg [8:0] clk_counter_next, clk_counter_reg;
    reg [3:0] bit_counter_next, bit_counter_reg;
    reg data_cnt_next, data_cnt_reg;
    reg s_ack_next, s_ack_reg, ack_next, ack_reg;
    reg
        ready_next,
        ready_reg,
        tx_done_next,
        tx_done_reg,
        rx_done_next,
        rx_done_reg;
    reg start_next, start_reg;
    reg rx_next, rx_reg;

    reg write_next, write_reg, SDA_out;
    wire SDA_in;

    assign SDA     = write_reg ? SDA_out : 1'bz;
    assign SDA_in  = ~write_reg ? SDA : 1'bz;
    assign SDA_o   = write_reg ? SDA_out : SDA;

    assign ready   = ready_reg;
    assign tx_done = tx_done_reg;
    assign state_r = state;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            clk_counter_reg  <= 0;
            bit_counter_reg  <= 0;
            s_ack_reg        <= 0;
            ack_reg          <= 0;
            write_reg        <= 0;
            ready_reg        <= 0;
            tx_done_reg      <= 0;
            rx_done_reg      <= 0;
            start_reg        <= 0;
            rx_reg           <= 0;
            rx_data          <= 0;
            data_cnt_reg     <= 0;
        end else begin
            state            <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            clk_counter_reg  <= clk_counter_next;
            bit_counter_reg  <= bit_counter_next;
            s_ack_reg        <= s_ack_next;
            ack_reg          <= ack_next;
            write_reg        <= write_next;
            ready_reg        <= ready_next;
            tx_done_reg      <= tx_done_next;
            rx_done_reg      <= rx_done_next;
            start_reg        <= start_next;
            rx_reg           <= rx_next;
            data_cnt_reg     <= data_cnt_next;
            if (rx_done_reg) rx_data <= temp_rx_data_reg;
        end
    end

    always @(*) begin
        temp_tx_data_next = temp_tx_data_reg;
        temp_rx_data_next = temp_rx_data_reg;
        state_next        = state;
        clk_counter_next  = clk_counter_reg;
        bit_counter_next  = bit_counter_reg;
        s_ack_next        = s_ack_reg;
        ack_next          = ack_reg;
        write_next        = write_reg;
        ready_next        = ready_reg;
        tx_done_next      = tx_done_reg;
        rx_done_next      = rx_done_reg;
        start_next        = start_reg;
        rx_next           = rx_reg;
        data_cnt_next     = data_cnt_reg;
        SDA_out           = 1;
        SCL               = 1;
        case (state)
            IDLE: begin
                SDA_out    = 1;
                SCL        = 1;
                ready_next = 1;
                write_next = 1;
                if (i2c_en && start) begin
                    state_next        = START1;
                    temp_tx_data_next = tx_data;
                    write_next        = 1;
                    ready_next        = 0;
                    start_next        = 1;
                end
            end
            START1: begin
                SDA_out = 0;
                SCL = 1;
                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    state_next       = START2;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            START2: begin
                SDA_out = 0;
                SCL = 0;
                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    state_next       = DATA1;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA1: begin
                tx_done_next = 0;
                rx_done_next = 0;
                SDA_out = temp_tx_data_reg[7];
                SCL = 0;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    state_next       = DATA2;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA2: begin
                SDA_out = temp_tx_data_reg[7];
                SCL = 1;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    state_next       = DATA3;
                    rx_next          = SDA_in;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA3: begin
                SDA_out = temp_tx_data_reg[7];
                SCL = 1;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    state_next       = DATA4;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA4: begin
                SDA_out = temp_tx_data_reg[7];
                SCL = 0;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    if (bit_counter_reg == 7) begin  // ACK 수신 시작
                        state_next = ACK_START;
                    end else if (s_ack_reg) begin  // ACK 수신 완료
                        state_next = ACK_END;
                    end else begin
                        bit_counter_next  = bit_counter_reg + 1;
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        temp_rx_data_next = {temp_rx_data_reg[6:0], rx_reg};
                        state_next        = DATA1;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            ACK_START: begin
                SDA_out           = 0;
                SCL               = 0;
                temp_rx_data_next = {temp_rx_data_reg[6:0], rx_reg};
                bit_counter_next  = 0;
                s_ack_next        = 1;
                state_next        = DATA1;
                if (write_reg) begin  // write
                    write_next = 0;  // SDA input mode
                end else begin  // read
                    write_next = 1;  // SDA output mode
                    if (data_cnt_reg == 0) begin
                        temp_tx_data_next[7] = 0;  // ACK
                    end else begin
                        temp_tx_data_next[7] = 1;  // NACK
                    end
                end
            end
            ACK_END: begin
                SDA_out = 0;
                SCL = 0;
                s_ack_next = 0;
                if (start_reg) begin
                    state_next = ADDRESS_HOLD;
                end else begin
                    state_next = DATA_HOLD;

                end
            end
            ADDRESS_HOLD: begin
                SDA_out           = 0;
                SCL               = 0;
                temp_tx_data_next = tx_data;
                tx_done_next      = 1;
                start_next        = 0;
                state_next        = DATA1;
                if (temp_tx_data_reg[7]) begin  // read
                    write_next = 0;  // SDA input mode
                end else begin  // write
                    write_next = 1;  // SDA output mode
                end
            end
            DATA_HOLD: begin
                SDA_out           = 0;
                SCL               = 0;
                temp_tx_data_next = tx_data;
                write_next        = 1;
                if (write_reg) begin  // read
                    rx_done_next = 1;
                end else begin  // write
                    tx_done_next = 1;
                end
                if (data_cnt_reg == 1) begin
                    state_next    = STOP1;
                    write_next    = 1;
                    data_cnt_next = 0;
                end else begin
                    state_next    = DATA1;
                    data_cnt_next = data_cnt_reg + 1;
                    if (write_reg) begin  // read
                        write_next = 0;
                    end else begin  // write
                        write_next = 1;
                    end
                end
            end
            STOP1: begin
                tx_done_next = 0;
                rx_done_next = 0;
                SDA_out      = 0;
                SCL          = 1;
                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    state_next       = STOP2;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            STOP2: begin
                SDA_out = 1;
                SCL = 1;
                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    state_next       = IDLE;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
        endcase
    end
endmodule
