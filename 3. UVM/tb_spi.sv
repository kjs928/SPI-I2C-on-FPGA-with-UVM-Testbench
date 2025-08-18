module tb_spi;
    //test spi_test;
    spi_if a_if();

    spi dut(
        .clk(a_if.clk),
        .reset(a_if.reset),
        .cpol(a_if.cpol),
        .cpha(a_if.cpha),
        .start(a_if.start),
        .read_count(a_if.read_count),
        .write_count(a_if.write_count),
        //.SS(a_if.SS),
        .tx_data(a_if.tx_data),
        .rx_data(a_if.rx_data),
        .done(a_if.done),
        .ready(a_if.ready)
    );
    always #5 a_if.clk = ~a_if.clk;

    initial begin       
        $fsdbDumpvars(0);
        $fsdbDumpfile("wave.fsdb");
        a_if.clk = 0;
        uvm_config_db#(virtual spi_if)::set(null, "*", "a_if", a_if);
        run_test(); 
        #1000;
        $finish;
       
    end

    initial begin
        a_if.reset = 1;
        #5;
        a_if.reset = 0;
    end

endmodule
