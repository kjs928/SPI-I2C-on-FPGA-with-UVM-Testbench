`timescale 1ns / 1ps

module tb_SPI_Master ();


    // global signals
    logic       clk;
    logic       reset;

    logic       cpol;
    logic       cpha;
    logic       start;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       done;
    logic       ready;

    logic       SCLK;
    logic       MOSI;
    logic       MISO;
    logic       SS;
    logic       [2:0]read_count;
    logic       [2:0]write_count;


    SPI_Master U_DUT (.*);
    
    SPI_Slave slave_DUT (.*);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10 reset = 0;
       
        repeat (3) @(posedge clk);
        // address byte
        // SS = 1;
        @(posedge clk);
        tx_data = 8'b10000000; start = 1; cpol = 0; cpha = 0; read_count = 0; write_count = 4;
        // SS = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
    

        // write data byte on 0x00 address
        @(posedge clk);
        tx_data = 8'h10;  cpol = 0; cpha = 0;  // msb =1, write
        // SS = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
      

        // write data byte on 0x01 address
        @(posedge clk);
        tx_data = 8'h20;  cpol = 0; cpha = 0;
        // SS = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
      

        // write data byte on 0x02 address
        @(posedge clk);
        tx_data = 8'h30; cpol = 0; cpha = 0;
        // SS = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        
        tx_data = 8'h40;  cpol = 0; cpha = 0;
        // SS = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        // SS = 1;
         wait (done == 1);

        repeat(5) @(posedge clk);
        // SS = 0;
        @(posedge clk);
        tx_data = 8'b0; start = 1; cpol = 0; cpha = 0; read_count=4;   // msb =0, read
        @(posedge clk);
        start = 0;
       



   


        #300;
        $finish;
    end

endmodule
