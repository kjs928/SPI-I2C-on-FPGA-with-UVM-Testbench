class spi_environment extends uvm_env;
    `uvm_component_utils(spi_environment) // Factory에 등록

    function new(string name = "ENV", uvm_component parent);
        super.new(name, parent);
    endfunction

    spi_scoreboard spi_sco;
    spi_agent spi_agt;
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        spi_sco = spi_scoreboard::type_id::create("SCO", this);
        spi_agt = spi_agent::type_id::create("AGT", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase); // agt안의 mon과 scb 사이 연결 통로를 만들어줘야 함
        super.connect_phase(phase);
        spi_agt.spi_mon.send.connect(spi_sco.recv); // TLM Port 연결 transaction level modeling
    endfunction

endclass
