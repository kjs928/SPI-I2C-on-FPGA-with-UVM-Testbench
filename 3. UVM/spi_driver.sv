class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)

    function new(string name = "DRV", uvm_component parent);
        super.new(name, parent);
    endfunction

    spi_seq_item spi_item;
    virtual spi_if a_if;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        spi_item = spi_seq_item::type_id::create("spi_ITEM");

        if(!uvm_config_db#(virtual spi_if)::get(this, "*", "a_if", a_if))
            `uvm_fatal("DRV", "spi_if not found in uvm_config_db");
    endfunction

    // ✅ SPI Driver with Burst Support (Improved Version)

virtual task run_phase(uvm_phase phase);
    forever begin
        spi_seq_item spi_item;
        seq_item_port.get_next_item(spi_item);

        // --- Write Phase ---
        a_if.cpol <= 1'b0;
        a_if.cpha <= 1'b0;
        a_if.start <= 1'b0;
        a_if.write_count <= spi_item.burst;
        a_if.tx_data <= {1'b1, 5'b0, spi_item.address};

        @(posedge a_if.clk);
        a_if.start <= 1'b1;
        @(posedge a_if.clk);
        a_if.start <= 1'b0;

        wait (a_if.done);

        // Write burst loop
        for (int i = 0; i < spi_item.burst; i++) begin
            @(posedge a_if.clk);
            a_if.tx_data <= spi_item.tx_data[i];
            @(posedge a_if.clk);
            wait (a_if.done);
        end

        // --- Read Phase ---
        a_if.read_count <= spi_item.burst;
        @(posedge a_if.clk);
        a_if.tx_data <= {1'b0, 5'b0, spi_item.address};
        @(posedge a_if.clk);
        a_if.start <= 1'b1;
        @(posedge a_if.clk);
        a_if.start <= 1'b0;

        wait (a_if.done);

        for (int i = 0; i < spi_item.burst; i++) begin
            @(posedge a_if.clk);
            a_if.tx_data <= 8'hAA; // dummy data
            @(posedge a_if.clk);
            wait (a_if.done);
        end

        `uvm_info("DRV", "Burst read/write transaction complete", UVM_MEDIUM);
        @(posedge a_if.clk);
        seq_item_port.item_done();
    end
endtask

endclass
