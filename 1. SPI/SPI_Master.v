`timescale 1ns / 1ps

module SPI_Master (
    // global signals
    input            clk,
    input            reset,
    input            start,
    input      [7:0] tx_data,
    output     [7:0] rx_data,
    output reg       done,
    output reg       ready,
    // SPI signals
    input            cpol,     // clock polarity
    input            cpha,     // clock phase
    // external port
    output           SCLK,
    output           MOSI,
    input            MISO,
    output reg       SS,
    input [2:0] read_count,
    input [2:0] write_count
);
    reg [2:0] rd_cnt_reg, rd_cnt_next; // 현재 read 한 개수
    reg [2:0] read_count_reg,read_count_next; // 인풋값 받아서 캡처
    reg [2:0] wr_cnt_reg, wr_cnt_next;
    reg [2:0] write_count_reg, write_count_next;

    reg rd_wr_reg, rd_wr_next;

    localparam IDLE = 0, CP_DELAY = 1, CP0= 2, CP1 = 3, BURST = 4;

    //reg r_sclk;
    wire r_sclk;
    reg [3:0] state, state_next;
    reg [5:0] sclk_counter_reg, sclk_counter_next;  //6bit
    reg [2:0] bit_counter_reg, bit_counter_next;  //3bit
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [7:0] temp_rx_data_reg, temp_rx_data_next;

    assign MOSI = temp_tx_data_reg[7];
    assign rx_data = temp_rx_data_reg;
    assign r_sclk = ((state_next == CP1 &&~cpha) || (state_next == CP0 && cpha));
    // cpha = 1 이면 CP0에서 SCLK가 올라가고, cpha = 0 이면 CP1에서 SCLK가 올라감
    assign SCLK = cpol ? ~r_sclk : r_sclk; 
    // cpol = 1 이면 SCLK가 반전, cpol = 0 이면 SCLK가 그대로



    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            sclk_counter_reg <= 0;
            bit_counter_reg  <= 0;
            rd_cnt_reg<=0;
            read_count_reg<=0;
            rd_wr_reg<=0;
            wr_cnt_reg<=0;
            write_count_reg<=0;
        end else begin
            state            <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_counter_reg  <= bit_counter_next;
            rd_cnt_reg <= rd_cnt_next;
            read_count_reg<=read_count_next;
            rd_wr_reg <=rd_wr_next;
            write_count_reg <= write_count_next;
            wr_cnt_reg <= wr_cnt_next;
        end
    end

    always @(*) begin
        state_next        = state;
        done              = 1'b0;
        ready             = 1'b0;
        // r_sclk            = 1'b0;
        temp_rx_data_next = temp_rx_data_reg;
        temp_tx_data_next = temp_tx_data_reg;
        sclk_counter_next = sclk_counter_reg;
        bit_counter_next  = bit_counter_reg;
        rd_cnt_next = rd_cnt_reg;
        read_count_next = read_count_reg;
        rd_wr_next = rd_wr_reg;
        write_count_next = write_count_reg;
        wr_cnt_next = wr_cnt_reg;
        case (state)
            IDLE: begin
                SS = 1;
                temp_tx_data_next = 0;
                done              = 1'b0;
                ready             = 1'b1;
                rd_cnt_next = 0;
                wr_cnt_next = 0;
                read_count_next=0;
                write_count_next=0;
                if (start) begin
                    state_next        = cpha ? CP_DELAY : CP0;  // cpha = 1 이면 CP_DELAY, cpha = 0 이면 CP0 
                    temp_tx_data_next = tx_data;
                    rd_wr_next = tx_data[7];
                    ready             = 1'b0;
                    sclk_counter_next = 1'b0;
                    bit_counter_next  = 1'b0;
                    read_count_next = read_count;
                    write_count_next = write_count;
                end
            end
            CP_DELAY: begin
                SS = 0;
                if (sclk_counter_reg == 49) begin
                    sclk_counter_next = 1'b0;
                    state_next        = CP0;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP0: begin
                SS = 0;
               // r_sclk = 1'b0;
                if (sclk_counter_reg == 49) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], MISO};
                    sclk_counter_next = 1'b0;
                    state_next        = CP1;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP1: begin
                SS = 0;
                // r_sclk = 1'b1;
                if (sclk_counter_reg == 49) begin
                    if (bit_counter_reg == 7) begin
                        done       = 1'b1;
                        sclk_counter_next = 1'b0;
                        state_next = BURST;
                    end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        sclk_counter_next = 1'b0;
                        bit_counter_next  = bit_counter_reg + 1;
                        state_next        = CP0;
                    end
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end

            BURST : begin
                 if (!rd_wr_reg) begin // read burst
                            if (read_count_reg == rd_cnt_reg) begin
                                state_next = IDLE;
                            end else begin
                                rd_cnt_next = rd_cnt_reg+1;
                                temp_tx_data_next = 8'h00;
                                state_next = CP0;
                                bit_counter_next = 0;
                            end
                        end else begin // write burst
                            if (write_count_reg == wr_cnt_reg) begin
                                state_next = IDLE;
                            end else begin
                                wr_cnt_next = wr_cnt_reg+1;
                                temp_tx_data_next = tx_data;
                                state_next = CP0;
                                bit_counter_next=0;
                            end
                        end


            end
        endcase
    end
endmodule
