class spi_seq_item extends uvm_sequence_item;
    // 설정 값
    rand bit [2:0] burst;             // burst length (1~4)
    rand bit [1:0] address;           // target address

    // 전송/수신 데이터 배열
    rand bit [7:0] tx_data[4];        // 최대 4바이트 전송
         bit [7:0] rx_data[4];        // 수신값 저장용

    // 제약 조건
    constraint burst_c { burst inside {[1:4]}; }
    constraint tx_data_c {
        foreach (tx_data[i])
            i < burst -> tx_data[i] inside {[0:255]};
    }

    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(burst, UVM_DEFAULT)
        `uvm_field_int(address, UVM_DEFAULT)
        `uvm_field_sarray_int(tx_data, UVM_DEFAULT)
        `uvm_field_sarray_int(rx_data, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction
endclass
