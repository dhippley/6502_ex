# 💾 Elixir 6502

**A 6502 CPU emulator written in Elixir**
This is project created out of my love of both Elixir and the legendary MOS 6502



---

## 🧠 What’s the 6502?

The **MOS Technology 6502** is an 8-bit microprocessor released in **1975**, known for being **fast, cheap, and wildly influential**.

Despite costing just $25 at launch, it powered an entire generation of computing and gaming history.

Some of the legendary systems that ran on the 6502 or its variants:
- 🧠 Apple I and Apple II
- 🕹️ Nintendo Entertainment System (NES)
- 🎨 Commodore 64
- 🧮 Atari 2600
- 🐍 BBC Micro (yes, Python’s birthplace)

It had:
- A 16-bit address space (64KB memory)
- Just a handful of registers (`A`, `X`, `Y`, `SP`, `PC`, `P`)
- 151 instructions and 13 addressing modes
- A cult following that continues to this day

---

## 🚀 Goals

- Emulate core 6502 functionality in idiomatic Elixir
- Prioritize clarity, readability, and testability
- Create a foundation for fun extensions — like a LiveView debugger or NES peripheral simulation

---

## ✨ Features

- [x] **GenServer-based Architecture** - CPU and Memory as concurrent processes
- [x] **Complete CPU State Management** - All registers, flags, and timing
- [x] **Full Memory Map** - 64KB addressable space with proper banking
- [x] **Complete Instruction Set** - All 151 official 6502 instructions
- [x] **All Addressing Modes** - 13 different addressing modes implemented
- [x] **Accurate Flag Handling** - Proper status register behavior
- [x] **Stack Operations** - Push/pop operations with proper stack pointer management
- [x] **Cycle Timing** - Accurate instruction timing and page crossing penalties
- [x] **ROM Loading** - Load programs from files or byte arrays
- [x] **Debugging Tools** - Step execution, memory dumps, status inspection
- [x] **Test Programs** - Built-in test programs and examples

---

## 📦 Installation & Usage

```bash
git clone https://github.com/dhippley/elixir_6502.git
cd elixir_6502
mix deps.get
mix test
```

### Quick Start

```elixir
# Start the emulator
{:ok, cpu} = Elixir6502.start()

# Load a test program
Elixir6502.load_test_program(cpu)
Elixir6502.reset(cpu)

# Execute step by step
Elixir6502.step(cpu)
Elixir6502.print_status(cpu)

# Or run continuously
Elixir6502.run(cpu)
```

### Interactive Demo

Run the included demo script:

```bash
elixir demo.exs
```

This will demonstrate:
- Loading and executing a simple program
- Step-by-step debugging
- Memory operations
- Fibonacci sequence calculator
- Complete CPU status monitoring

### Testing

```bash
mix test
```

### Features Overview

```elixir
# CPU Management
{:ok, cpu} = Elixir6502.start()
Elixir6502.reset(cpu)
Elixir6502.step(cpu)     # Execute one instruction
Elixir6502.run(cpu)      # Start continuous execution
Elixir6502.stop(cpu)     # Stop execution

# Program Loading
Elixir6502.load_program(cpu, [0xA9, 0x42, 0x00])  # Load bytes
Elixir6502.load_file(cpu, "program.bin")           # Load from file
Elixir6502.load_test_program(cpu)                  # Built-in test

# Memory Operations
Elixir6502.read_memory(cpu, 0x1000)
Elixir6502.write_memory(cpu, 0x1000, 42)
Elixir6502.dump_memory(cpu, 0x1000, 16)

# Debugging
Elixir6502.status(cpu)        # Get CPU state
Elixir6502.print_status(cpu)  # Pretty print status
Elixir6502.set_pc(cpu, 0x600) # Set program counter
```
