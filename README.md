# SPI-I2C-on-FPGA-with-UVM-Testbench

# FPGA 기반 SPI/I2C 통신 시스템 설계 & UVM 기반 기능 검증
---

## 📌 프로젝트 요약

| 항목 | 내용 |
| --- | --- |
| 프로젝트 명 | FPGA 기반 SPI/I2C 통신 시스템 설계 & UVM 기반 기능 검증 |
| 수행 목표 | SPI/I2C 통신 모듈 설계 및 UVM 검증 과정 진행 |
| 수행 기간 | 2025.05.19 ~ 2025.05.27 |
| 담당 역할 | SPI/I2C Master·Slave 모듈 설계, SPI 모듈 UVM 검증 |
| 사용 기술 | Vivado/Vitis, Verilog/SystemVerilog, Synopsys VCS/Verdi |

---

## 🔑 주요 구현 내용

### 1. SPI 통신 모듈
- **Master/Slave 모듈 설계** : CPOL/CPHA 설정 기반 4모드 지원
- **Burst 전송 지원** : FSM으로 다중 데이터 전송 구현
- **Master 기능** : SCLK 생성, SS 제어, MOSI/MISO 데이터 송수신
- **Slave 기능** : 내부 레지스터 맵 설계(4×8bit), Read/Write 처리

---

### 2. I2C 통신 모듈
- **Master/Slave 모듈 설계** : SDA/SCL 기반 직렬 통신 구현
- **Master 기능** : Start/Stop 조건 생성, 7bit 주소 전송 및 ACK 처리
- **Slave 기능** : 주소 매칭, Read/Write 동작, 내부 레지스터 접근
- **FSM 기반 설계** : 주소 비교, 데이터 전송, ACK 응답 제어

---

### 3. UVM 기반 SPI 검증 환경
- **UVM Testbench 구성** : Sequencer, Driver, Monitor, Scoreboard 포함
- **Self-checking** : 자동 트랜잭션 생성 및 DUT 응답 비교
- **Burst 검증 시나리오** : 다양한 데이터 전송 케이스 검증
- **결과** : TX/RX 데이터 일치 → ✅ PASS

---

