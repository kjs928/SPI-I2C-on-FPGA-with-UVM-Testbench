class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    // TLM 수신 포트 정의
    uvm_analysis_imp #(spi_seq_item, spi_scoreboard) recv;

    // 통계용 카운터
    int total_cnt = 0;
    int pass_cnt  = 0;
    int fail_cnt  = 0;
    int local_fail = 0;

    function new(string name = "SCO", uvm_component parent);
        super.new(name, parent);
        recv = new("READ", this);
    endfunction

    // build_phase 생략 가능 (recv만 사용 중일 경우)

    virtual function void write(spi_seq_item item);
        total_cnt++;
        

        `uvm_info("SCOREBOARD", $sformatf("[SCO] addr = %0d | burst = %0d", item.address, item.burst), UVM_LOW)

        for (int i = 0; i < item.burst; i++) begin
            if (item.tx_data[i] !== item.rx_data[i]) begin
                `uvm_error("SCOREBOARD", $sformatf("❌ Mismatch at [%0d] : TX = 0x%0h, RX = 0x%0h", i, item.tx_data[i], item.rx_data[i]))
                local_fail++;
            end else begin
                `uvm_info("SCOREBOARD", $sformatf("✅ Match    at [%0d] : TX = 0x%0h == RX = 0x%0h", i, item.tx_data[i], item.rx_data[i]), UVM_LOW)
            end
        end

        if (local_fail == 0) begin
            pass_cnt++;
            `uvm_info("SCOREBOARD", "✅ BURST RESULT : PASS", UVM_LOW)
        end else begin
            fail_cnt++;
            `uvm_info("SCOREBOARD", $sformatf("❌ BURST RESULT : FAIL (%0d mismatches)", local_fail), UVM_NONE)
        end
    endfunction

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        `uvm_info("SCOREBOARD", "================== SPI BURST TEST SUMMARY ==================", UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("TOTAL: %0d | PASS: %0d | FAIL: %0d", total_cnt, pass_cnt, fail_cnt), UVM_NONE)
        `uvm_info("SCOREBOARD", "============================================================", UVM_NONE)
    endfunction
endclass
