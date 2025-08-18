class test extends uvm_test; // uvm_test 라이브러리 상속 받기
    `uvm_component_utils(test) // Factory에 등록 매크로

    function new(string name = "TEST", uvm_component parent);
        super.new(name, parent);
    endfunction

    spi_sequence spi_seq;
    spi_environment spi_env;

    virtual function void build_phase(uvm_phase phase); // overriding -> 부모 클래스가 함수 이름만 가지고
        super.build_phase(phase);
        spi_seq = spi_sequence::type_id::create("SEQ", this); // spi_seq = new(); 이거랑 비슷한 거임
        spi_env = spi_environment::type_id::create("ENV", this); // -> "Factory에서 실행됐다"
    endfunction

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        uvm_root::get().print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase); // overriding 자식이 그 함수 구현을 하는 것
        phase.raise_objection(this); // drop 전까지 시뮬 멈추지 않게
        spi_seq.start(spi_env.spi_agt.spi_sqr); // seq -> sequence / sqr -> sequnecer 둘이 다른 거임
        phase.drop_objection(this);  // objection 해제, run phase 종료
    endtask
endclass
