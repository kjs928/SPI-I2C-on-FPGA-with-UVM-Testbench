class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    uvm_analysis_port #(spi_seq_item) send;
    virtual spi_if a_if;

    function new(string name = "MON", uvm_component parent);
        super.new(name, parent);
        send = new("WRITE", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "a_if", a_if))
            `uvm_fatal("MON", "spi_if not found in uvm_config_db");
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            spi_seq_item spi_item = spi_seq_item::type_id::create("mon_item");

            // ===== WRITE PHASE =====
            @(posedge a_if.done);  // write address 전송 완료
            spi_item.address = a_if.tx_data[1:0];
            spi_item.burst   = a_if.write_count;

            for (int i = 0; i < spi_item.burst; i++) begin
                @(posedge a_if.done);
                spi_item.tx_data[i] = a_if.tx_data;
            end

            // ===== READ PHASE =====
            @(posedge a_if.done);  // read address 전송 완료
            @(posedge a_if.clk);
            @(posedge a_if.clk);
            spi_item.burst = a_if.read_count;

            for (int i = 0; i < spi_item.burst; i++) begin
                @(posedge a_if.done);
                @(posedge a_if.clk);
                @(posedge a_if.clk);
                spi_item.rx_data[i] = a_if.rx_data;
            end

            // ===== 로그 및 전달 =====
            `uvm_info("MON", $sformatf("[MON] addr=%0d, burst=%0d", spi_item.address, spi_item.burst), UVM_LOW)
            for (int i = 0; i < spi_item.burst; i++) begin
                `uvm_info("MON", $sformatf("  TX[%0d]=0x%0h  RX[%0d]=0x%0h", i, spi_item.tx_data[i], i, spi_item.rx_data[i]), UVM_LOW)
            end

            send.write(spi_item); // scoreboard로 전달
        end
    endtask
endclass
