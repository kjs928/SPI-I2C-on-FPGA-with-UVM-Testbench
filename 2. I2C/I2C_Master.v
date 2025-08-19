module I2C_Master #(parameter Trans_Rates = 100_000) ( // 100kHz
    input clk,
    input reset,
    input [7:0] tx_data,
    output reg tx_done,
    output reg ready,
    input start,
    input i2c_en,
    input stop,
    output reg scl,
    inout sda
    );

    localparam  FCOUNT = (100_000_000/Trans_Rates); //100MHz / 100kHz = 1000

    localparam IDLE = 0, START1 = 1, START2 = 2, DATA1 =3, DATA2 =4, DATA3 = 5, DATA4 = 6,
    ACK1= 7, ACK2= 8, ACK3= 9, ACK4= 10, STOP1 =11 , STOP2 = 12, HOLD = 13, RESTART = 14;
    reg [3:0] state, state_next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [$clog2(FCOUNT/2)-1:0]  clk_counter_reg, clk_counter_next;
    reg [2:0] bit_counter_reg, bit_counter_next;

    // for sda control
    reg sda_out;  // SDA out value
    reg sda_oe;   // SDA Output Enable

    // tristate buffer
    assign sda = sda_oe ? sda_out : 1'bz;


    always @(posedge clk) begin
        if(reset) begin
            state <= IDLE;
            temp_tx_data_reg <= 0;
            clk_counter_reg <= 0;
            bit_counter_reg <= 0;
        end else begin
            state <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            clk_counter_reg <= clk_counter_next;
            bit_counter_reg <= bit_counter_next;
        end
    end

    always @(*) begin
        state_next = state;
        temp_tx_data_next = temp_tx_data_reg;
        clk_counter_next = clk_counter_reg;
        bit_counter_next = bit_counter_reg;
        scl = 1'b1;
        ready = 1'b1;
        tx_done = 1'b0;
        sda_out = 1'b1; // 기본적으로 high
        sda_oe = 1'b1; // 기본적으로 출력
        case (state)
            IDLE: begin
                ready = 1'b1;
                tx_done = 1'b0;
                sda_out = 1'b1; sda_oe = 1'b1;
                scl = 1'b1;
                if(!stop & start & i2c_en) begin
                    state_next = START1;
                end
            end
            // RESTART: begin
            //     ready = 1'b0;
            //     tx_done = 1'b0;
            //     sda_out = 1'b1; sda_oe = 1'b1;
            //     scl = 1'b1;
            //     state_next = START1;

            // end
            START1 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = 1'b0; sda_oe = 1'b1;
                scl = 1'b1;
                if(clk_counter_reg == (FCOUNT/2) -1) begin
                    state_next = START2;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            START2 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = 1'b0; sda_oe = 1'b1;
                scl = 1'b0;
                if(clk_counter_reg == (FCOUNT/2) -1) begin
                    state_next = HOLD;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            HOLD : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = 1'b0; sda_oe = 1'b1;
                scl = 1'b0;
                case ({stop,start,i2c_en})
                    3'b000: begin
                        state_next = HOLD;
                    end
                    3'b001: begin
                        temp_tx_data_next = tx_data;
                        state_next = DATA1;
                    end
                    3'b011: begin
                        temp_tx_data_next = tx_data;
                        state_next = DATA1;
                    end
                    3'b101: begin
                        state_next = STOP1;
                    end
                    default: state_next = HOLD;
                endcase
            end
            DATA1 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = temp_tx_data_reg[7]; sda_oe = 1'b1;
                scl = 1'b0;
                if(clk_counter_reg == (FCOUNT/4) -1) begin
                    state_next = DATA2;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA2 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = temp_tx_data_reg[7]; sda_oe = 1'b1;
                scl = 1'b1;
                if(clk_counter_reg == (FCOUNT/4) -1) begin
                    state_next = DATA3;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA3 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = temp_tx_data_reg[7]; sda_oe = 1'b1;
                scl = 1'b1;
                if(clk_counter_reg == (FCOUNT/4) -1) begin
                    state_next = DATA4;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            DATA4 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = temp_tx_data_reg[7]; sda_oe = 1'b1;
                scl = 1'b0;
                if(clk_counter_reg == (FCOUNT/4) -1) begin
                    if(bit_counter_reg == 7) begin
                        state_next = ACK1;
                        tx_done = 1'b1;
                        clk_counter_next = 0;
                        bit_counter_next =0;
                    end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0],1'b0};
                        state_next = DATA1;
                        clk_counter_next = 0;
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            ACK1 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = 1'b0; sda_oe = 1'b1;
                scl = 1'b0;
                if(clk_counter_reg == (FCOUNT/4) -1) begin
                    state_next = ACK2;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            ACK2 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = 1'b0; sda_oe = 1'b0;
                scl = 1'b1;
                if(clk_counter_reg == (FCOUNT/4) -1) begin
                    state_next = ACK3;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            ACK3 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = 1'b0; sda_oe = 1'b0;
                scl = 1'b1;
                if(clk_counter_reg == (FCOUNT/4) -1) begin
                    state_next = ACK4;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            ACK4 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = 1'b0; sda_oe = 1'b1;
                scl = 1'b0;
                if(clk_counter_reg == (FCOUNT/4) -1) begin
                    state_next = HOLD;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            STOP1 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = 1'b0; sda_oe = 1'b1;
                scl = 1'b1;
                if(clk_counter_reg == (FCOUNT/2) -1) begin
                    state_next = STOP2;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            STOP2 : begin
                ready = 1'b0;
                tx_done = 1'b0;
                sda_out = 1'b1; sda_oe = 1'b1;
                scl = 1'b1;
                if(clk_counter_reg == (FCOUNT/2) -1) begin
                    state_next = IDLE;
                    clk_counter_next = 0;
                    ready = 1'b1;
                    tx_done = 1'b0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
        endcase
    end
endmodule
