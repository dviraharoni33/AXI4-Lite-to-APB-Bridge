# AXI4-Lite to APB Bridge with Asynchronous CDC


## 1. Introduction

### What is this project?
This project implements a bridge between two industry-standard AMBA protocols: **AXI4-Lite** and **APB**.
Since these protocols often operate in different clock domains (fast processor vs. slow peripherals), the bridge incorporates robust **Clock Domain Crossing (CDC)** logic using Asynchronous FIFOs.
This design serves as a fundamental building block in System-on-Chip (SoC) architectures, enabling high-performance CPUs to communicate safely and reliably with low-speed peripherals like Timers, UARTs, and GPIO controllers.

### Key Features
* **Protocol Translation:** Converts AXI4-Lite transactions (Write/Read) into APB transfers.
* **Asynchronous CDC:** Uses dual-clock FIFOs with Gray-coded pointers to safely transfer data between the fast (`aclk`) and slow (`pclk`) domains.
* **Robust FSM:** An internal Finite State Machine (FSM) manages the APB protocol phases (SETUP, ACCESS) and handles `PREADY` handshakes.
* **Parameterized:** The FIFO depth and data width are fully configurable via Verilog parameters.


## 2. Architecture & Block Diagram

The system is built from three main modular components:

1.  **`axi_lite_to_apb_bridge` (Top Level):**
    * Acts as the AXI4-Lite Slave.
    * Instantiates the Command FIFO and Response FIFO.
    * Manages the `READY`/`VALID` handshake logic.

2.  **`async_fifo`:**
    * A dual-clock FIFO designed for safe CDC.
    * Uses **Gray Code** counters for pointer passing to prevent metastability.
    * Includes `sync_2ff` synchronizers (2-flip-flop chain) on all crossing signals.

3.  **`apb_master_fsm`:**
    * The "Brain" of the slow domain.
    * Reads commands from the FIFO and drives the APB Master interface.
    * Implements the APB state machine: `IDLE` -> `SETUP` -> `ACCESS`.
    * 
![דיאגרמת מלבנים](https://github.com/user-attachments/assets/952ab6f0-227d-461e-9d86-370c9662ea3e)

![FIFO](https://github.com/user-attachments/assets/73c7b141-0232-4725-9336-e0b68ae83b3b)




  ## 3. Design Details: CDC & FSM

### Clock Domain Crossing (CDC) Strategy
To prevent data loss or corruption when moving between clock domains:
* **Write Path:** AXI Write commands (Address + Data + Control) are packed into a 65-bit wide Asynchronous FIFO pushed by `aclk` and popped by `pclk`.
* **Read Path:** APB Read responses are pushed into a 32-bit Asynchronous FIFO by `pclk` and popped by `aclk`.
* **Gray Coding:** Pointer exchange between the FIFOs uses Gray coding to ensure that only one bit changes at a time, eliminating race conditions.

### APB Finite State Machine (FSM)
The APB Master is controlled by a 3-state FSM:
1.  **IDLE:** Waits for the Command FIFO to be non-empty.
2.  **SETUP:** Drives `PADDR`, `PWDATA`, and asserts `PSEL`.
3.  **ACCESS:** Asserts `PENABLE` and waits for the peripheral's `PREADY` signal to go high.


## 4. Verification

The project includes a self-checking **SystemVerilog Testbench** (`testbench.sv`) that simulates a complete system:
1.  Generates two asynchronous clocks (`aclk` = 10ns, `pclk` = 20ns).
2.  Simulates an AXI Master initiating Write and Read transactions.
3.  Simulates a dummy APB Slave that responds with `PREADY` and data (`0xDEADBEEF`).
4.  Verifies data integrity and protocol timing.

### Simulation Results
Below is the waveform showing a successful **Write** transaction (0x55) followed by a **Read** transaction (returning 0xDEADBEEF). Note the latency caused by the CDC crossing.

<img width="1830" height="307" alt="image" src="https://github.com/user-attachments/assets/95040254-376a-437e-a415-bec39825cdb3" />


## 5. File Descriptions

* **`axi_lite_to_apb_bridge.sv`**: The top-level module acting as the AXI slave and wrapper for the entire bridge system.
* **`async_fifo.sv`**: A generic, parameterized dual-clock FIFO that handles safe data transfer between asynchronous clock domains.
* **`sync_2ff.sv`**: A basic 2-stage synchronizer module used inside the FIFO to prevent metastability when passing pointers.
* **`apb_master_fsm.sv`**: The Finite State Machine that translates FIFO commands into the APB protocol sequence.
* **`testbench.sv`**: The verification environment that generates clocks, drives AXI transactions, and simulates an APB slave response.


## 6. Tools Used

* **Language:** SystemVerilog (IEEE 1800-2017)
* **Simulation:** Aldec Riviera-PRO (via EDA Playground)
* **Waveform Viewing:** EPWave
* **Diagram:** Notes
