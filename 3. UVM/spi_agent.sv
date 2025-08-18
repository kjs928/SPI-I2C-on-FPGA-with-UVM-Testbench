class spi_agent extends uvm_agent;
    `uvm_component_utils(spi_agent)
    function new(string name = "AGT", uvm_component parent);
        super.new(name, parent);
    endfunction

    spi_monitor spi_mon; // handler 생성
    spi_driver spi_drv;
    uvm_sequencer #(spi_seq_item) spi_sqr;

    virtual function void build_phase(uvm_phase phase); // 핸들러 만든거에 인스턴스 한 값을 넣어주기
        super.build_phase(phase);
        spi_mon = spi_monitor::type_id::create("MON", this);
        spi_drv = spi_driver::type_id::create("DRV", this);
        spi_sqr = uvm_sequencer#(spi_seq_item)::type_id::create("SQR", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        spi_drv.seq_item_port.connect(spi_sqr.seq_item_export);
        //spi_mon.send.connect(env.scoreboard.recv);
    endfunction

endclass
