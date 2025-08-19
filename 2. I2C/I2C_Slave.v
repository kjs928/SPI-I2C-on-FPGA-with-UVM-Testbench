`timescale 1ns / 1ps

module I2C_Slave2(
    input clk,
    input reset,
    input SCL,
    inout SDA,
    output [7:0] rx_data
);

    assign clk_out = clk;

    reg [7:0] addr_reg, addr_next;
    reg [7:0] rd_wr_next, rd_wr_reg;
    reg [2:0] bit_count_next, bit_count_reg;
    reg [7:0] temp_rx_data_reg, temp_rx_data_next;
    reg flag_next, flag_reg;
    reg stop_check_reg, stop_check_next;

    reg [3:0] state, state_next;
    localparam IDLE = 0, DATA = 1, ACK = 2;

    reg prev_scl_0, prev_scl_1;
    wire scl_rising = prev_scl_0 & ~prev_scl_1;
    wire scl_falling = ~prev_scl_0 & prev_scl_1;

    reg prev_sda;
    wire sda_rising = ~prev_sda & SDA;

    reg [7:0] led_reg, led_next;
    assign rx_data = led_reg;

    // SDA control
    reg sda_out;
    reg sda_oe_reg, sda_oe_next;
    assign SDA = sda_oe_reg ? sda_out : 1'bz;
    wire sda_in = SDA;

    // Sync & register update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_scl_0 <= 1;
            prev_scl_1 <= 1;
            sda_oe_reg <= 0;
            sda_out    <= 0;
            state <= IDLE;
            addr_reg <= 0;
            rd_wr_reg <= 0;
            bit_count_reg <= 0;
            temp_rx_data_reg <= 0;
            flag_reg <= 1;
            stop_check_reg <= 0;
            prev_sda <= 1;
            led_reg <= 0;
            // debug_led <=1;
        end else begin
            prev_scl_0 <= SCL;
            prev_scl_1 <= prev_scl_0;
            prev_sda   <= SDA;
            sda_oe_reg <= sda_oe_next;
            sda_out    <= 0;
            state <= state_next;
            addr_reg <= addr_next;
            rd_wr_reg <= rd_wr_next;
            bit_count_reg <= bit_count_next;
            temp_rx_data_reg <= temp_rx_data_next;
            flag_reg <= flag_next;
            stop_check_reg <= stop_check_next;
            led_reg <= led_next;
        end
    end

    // FSM
    always @(*) begin
        state_next = state;
        sda_oe_next = sda_oe_reg;  // 기본은 high-Z
        addr_next = addr_reg;
        rd_wr_next = rd_wr_reg;
        bit_count_next = bit_count_reg;
        temp_rx_data_next = temp_rx_data_reg;
        flag_next = flag_reg;
        stop_check_next = stop_check_reg;
        led_next = led_reg;

        case (state)
            IDLE: begin
                // debug_led = 4'd1;
                flag_next = 1;
                temp_rx_data_next = 0;
                stop_check_next = 0;
                if (scl_falling)
                    state_next = DATA;
            end

            DATA: begin
                // debug_led = 4'd2;
                if (stop_check_reg && sda_rising) begin
                    state_next = IDLE;
                    stop_check_next = 0;
                end

                if (scl_rising) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], sda_in};
                    stop_check_next = 1;
                end else if (scl_falling) begin
                    stop_check_next = 0;
                    if (bit_count_reg == 7) begin
                        bit_count_next = 0;
                        if (flag_reg) begin
                            flag_next = 0;
                            addr_next = temp_rx_data_reg;
                        end else begin
                            led_next = temp_rx_data_reg;
                        end
                        state_next = ACK;
                    end else begin
                        bit_count_next = bit_count_reg + 1;
                    end
                end
            end

            ACK: begin
                // debug_led = 4'd3;
                if (addr_reg == 8'h98) begin // slave address가 맞을때
                    if (scl_rising)
                        sda_oe_next = 1; // drive SDA low (ACK)
                        sda_out = 0;
                end

                if (scl_falling) begin
                    sda_oe_next = 0;
                    state_next = (addr_reg == 8'h98) ? DATA : IDLE;
                end
            end
        endcase
    end

endmodule
