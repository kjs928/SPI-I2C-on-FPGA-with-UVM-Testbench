
interface spi_if();
    // global signals
    logic clk;
    logic reset;
    // internal signals
    logic cpol;
    logic cpha;
    logic start;
    logic [2:0] read_count;
    logic [2:0] write_count; 
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic done;
    logic ready;
endinterface //spi_if()
