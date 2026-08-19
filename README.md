# Parameterized N-Bit Carry Lookahead Adder

A synthesizable parameterized N-bit Carry Lookahead Adder (CLA) implemented in SystemVerilog with a class-based verification environment.

The project demonstrates RTL design, constrained-random verification, SystemVerilog assertions, functional coverage, scoreboarding, interfaces, virtual interfaces, mailboxes, and modular testbench architecture.

---

## Overview

A Carry Lookahead Adder improves addition speed by reducing the dependency of each carry on the previous carry.

For each bit:

- **Generate:** `G[i] = A[i] & B[i]`
- **Propagate:** `P[i] = A[i] ^ B[i]`
- **Carry:** `C[i+1] = G[i] | (P[i] & C[i])`
- **Sum:** `SUM[i] = P[i] ^ C[i]`

The design is parameterized, allowing the same RTL structure to be configured for different operand widths.

---

## Features

### RTL

- Parameterized N-bit architecture
- SystemVerilog RTL
- Carry generate and propagate logic
- Configurable operand width
- Synthesizable design
- Separate carry-out and sum outputs

### Verification

The testbench includes:

- SystemVerilog interface
- Transaction class
- Constrained random stimulus
- Generator
- Driver
- Monitor
- Scoreboard
- Functional coverage
- SystemVerilog Assertions (SVA)
- Mailboxes
- Virtual interface
- Independent reference model
- Directed corner-case testing
- Random testing
- Waveform generation

---

## Project Structure

```text
parameterized-cla-adder/
│
├── rtl/
│   └── cla_adder.sv
│
├── tb/
│   └── testbench.sv
│
├── sim/
│   └── .gitkeep
│
├── Makefile
├── README.md
└── .gitignore
```

---

## Design Architecture

```text
                 ┌───────────────────────┐
                 │       CLA ADDER       │
                 │                       │
       A[N-1:0] ─►  Generate / Propagate │
       B[N-1:0] ─►       Logic           │
       CIN ──────►                       │
                 │                       │
                 │   Carry Lookahead     │
                 │       Network         │
                 │                       │
                 └──────────┬────────────┘
                            │
                  ┌─────────┴─────────┐
                  │                   │
                  ▼                   ▼
              SUM[N-1:0]            COUT
```

---

## Verification Architecture

```text
                    ┌─────────────────┐
                    │    Generator    │
                    │ Random Stimulus │
                    └────────┬────────┘
                             │  mailbox
                             ▼
                    ┌─────────────────┐
                    │     Driver      │
                    └────────┬────────┘
                             │  Virtual IF
                             ▼
                    ┌─────────────────┐
                    │      DUT        │
                    │   N-Bit CLA     │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │     Monitor     │
                    └────────┬────────┘
                             │  mailbox
                             ▼
                    ┌─────────────────┐
                    │   Scoreboard    │
                    │ Reference Model │
                    └─────────────────┘

                    ┌─────────────────┐
                    │    Coverage     │
                    └─────────────────┘

                    ┌─────────────────┐
                    │   Assertions    │
                    └─────────────────┘
```

---

## Testbench Components

### 1. Interface

`cla_if` encapsulates the DUT signals and provides a virtual interface connection between the testbench classes and the DUT.

**Signals:** `a`, `b`, `cin`, `sum`, `cout`, `clk`

### 2. Transaction

The transaction class contains:

- Randomized input operands
- Carry input
- Observed sum
- Observed carry output
- Reference-model calculation

### 3. Generator

The generator creates constrained-random transactions and sends them to the driver using a mailbox.

### 4. Driver

The driver receives transactions from the generator and drives `A`, `B`, and `CIN` onto the DUT interface.

### 5. Monitor

The monitor samples `A`, `B`, `CIN`, `SUM`, and `COUT`, and sends the observed transaction to the scoreboard.

### 6. Scoreboard

The scoreboard independently calculates:

```
Expected = A + B + CIN
```

and compares `{Expected_COUT, Expected_SUM}` against the DUT output.

### 7. Functional Coverage

Coverage tracks:

- Zero operands
- Maximum operands
- Low operand ranges
- High operand ranges
- Carry-in = 0
- Carry-in = 1
- Carry-out = 0
- Carry-out = 1
- Carry-in / Carry-out cross coverage

---

## Assertions

The testbench contains SystemVerilog assertions for:

| Check | Condition |
|---|---|
| Complete functional correctness | `{COUT, SUM} == A + B + CIN` |
| Zero addition | `0 + 0 + 0 = 0` |
| A plus zero | `A + 0 + 0 = A` |
| B plus zero | `0 + B + 0 = B` |
| Maximum value case | `MAX + MAX + 1` |

The maximum-value test verifies both the N-bit sum and final carry-out.

---

## Directed Tests

The testbench explicitly exercises:

- `0 + 0`
- `1 + 1`
- `MAX + 0`
- `0 + MAX`
- `MAX + MAX`
- `MAX + MAX + 1`
- Alternating-bit patterns
- Alternating-bit patterns with carry-in
- Carry-generating cases

---

## Constrained Random Verification

In addition to directed tests, the testbench generates random transactions.

**Default:** `Random transactions = 500`

The random inputs include `A`, `B`, and `CIN`. Each transaction is independently checked by the scoreboard.

---

## Simulation

### Requirements

Install:

- Icarus Verilog
- GTKWave (optional, for waveform viewing)
- GNU Make

Verify installation:

```bash
iverilog -V
gtkwave --version
```

### Run Simulation

From the project root:

```bash
make
```

or:

```bash
make test
```

### Compile Only

```bash
make compile
```

### Run Simulation

```bash
make run
```

### View Waveform

```bash
make wave
```

The simulation generates `sim/cla_adder.vcd`. The VCD file is intentionally ignored by Git.

### Clean Simulation Files

```bash
make clean
```

---

## Expected Result

A successful simulation should produce a scoreboard summary similar to:

```text
============================================================
                    SCOREBOARD REPORT
============================================================
PASS COUNT : 500
FAIL COUNT : 0
TOTAL      : 500
============================================================

============================================================
                    COVERAGE REPORT
============================================================
FUNCTIONAL COVERAGE : XX.XX%
============================================================

============================================================
                    TEST PASSED
============================================================
All 500 random transactions passed.
============================================================
```

The exact coverage percentage depends on the generated random stimulus and simulator coverage implementation.

---

## Verification Strategy

The verification environment follows a lightweight class-based architecture similar to the concepts used in UVM.

```text
Stimulus
   │
   ▼
Generator
   │
   ▼
Driver
   │
   ▼
DUT
   │
   ▼
Monitor
   │
   ▼
Scoreboard
   │
   ▼
PASS / FAIL
```

Assertions provide concurrent protocol-independent checking, while functional coverage measures whether important input/output scenarios have been exercised.

---

## Parameterization

The RTL supports configurable operand width through:

```systemverilog
parameter int N = 8;
```

The default configuration is `N = 8`. The architecture can be adapted for other operand widths by changing the parameter in the RTL/testbench configuration.

---

## Example

For:

```
A   = 8'hA5
B   = 8'h3C
CIN = 0
```

the expected operation is `A + B + CIN`, and the scoreboard independently calculates the expected `{COUT, SUM}` before comparing it against the DUT output.

---

## Skills Demonstrated

This project demonstrates practical experience with:

- Verilog/SystemVerilog
- RTL Design
- Parameterized RTL
- Carry Lookahead Adders
- Digital Arithmetic
- SystemVerilog Classes
- Object-Oriented Verification
- Constrained Randomization
- Mailboxes
- Interfaces
- Virtual Interfaces
- Drivers
- Monitors
- Scoreboards
- Functional Coverage
- SystemVerilog Assertions
- Reference Models
- Waveform Debugging
- Icarus Verilog
- GTKWave
- Makefiles
- Git/GitHub

---

## Future Improvements

Possible extensions include:

- Hierarchical 4-bit CLA blocks
- Group generate/propagate logic
- Configurable CLA block size
- Additional coverage points
- Functional coverage closure
- Assertion coverage
- Error injection testing
- Multiple test scenarios
- Clocking blocks
- Modports
- UVM-based verification environment
- Synthesis and timing analysis
- FPGA implementation

---

## Author

**MD Farhan Badar**
B.Tech Electronics, VLSI Design and Technology

---

## License

This project is released under the MIT License.