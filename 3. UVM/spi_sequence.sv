class spi_sequence extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_sequence)

    function new(string name = "SEQ");
        super.new(name);
    endfunction

    virtual task body();
        repeat (100) begin
            spi_seq_item spi_item = spi_seq_item::type_id::create("seq_item");
            `uvm_info(get_type_name(), "Starting SPI sequence", UVM_MEDIUM)

            start_item(spi_item);
            if (!spi_item.randomize()) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end
            finish_item(spi_item);

            `uvm_info(get_type_name(),
                $sformatf("Generated addr = %0d, burst = %0d, tx_data = %p",
                          spi_item.address, spi_item.burst, spi_item.tx_data),
                UVM_LOW)
        end
    endtask
endclass
