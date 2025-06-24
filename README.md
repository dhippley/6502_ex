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

## ✨ Features (Planned & WIP)

- [x] CPU state and register modeling
- [x] Basic memory map and access
- [ ] Instruction decoding
- [ ] Instruction execution
- [ ] Addressing mode resolution
- [ ] Cycle tracking
- [ ] ROM loading support
- [ ] Debugging tools (step/run, log, etc.)
- [ ] Integration with Livebook / LiveView

---

## 📦 Installation

This is a work-in-progress project. To run locally:

```bash
git clone https://github.com/YOUR_USERNAME/elixir_6502.git
cd elixir_6502
mix deps.get
iex -S mix
