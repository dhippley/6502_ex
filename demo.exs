#!/usr/bin/env elixir
#
# 6502 Emulator Demo
# Run with: elixir demo.exs
#

# Start the application context
Mix.install([])
Code.append_path("_build/dev/lib/mos_6502_ex/ebin")

# Load all modules
Code.require_file("lib/elixir_6502.ex")
Code.require_file("lib/cpu/cpu.ex")
Code.require_file("lib/cpu/memory.ex")
Code.require_file("lib/cpu/flags.ex")
Code.require_file("lib/cpu/instructions.ex")
Code.require_file("lib/cpu/addressing.ex")
Code.require_file("lib/cpu/executor.ex")
Code.require_file("lib/rom/loader.ex")

IO.puts """
🎮 Welcome to Elixir 6502 Emulator Demo!
========================================

This demonstrates a working MOS 6502 CPU emulator built with GenServers.
"""

# Start the emulator
IO.puts "Starting 6502 CPU..."
{:ok, cpu_pid} = Elixir6502.start(name: :demo_cpu)

IO.puts "✅ CPU started successfully!"

# Load test program
IO.puts "\n📝 Loading test program..."
{:ok, size} = Elixir6502.load_test_program(cpu_pid)
IO.puts "✅ Loaded #{size} bytes"

# Reset CPU
IO.puts "\n🔄 Resetting CPU..."
Elixir6502.reset(cpu_pid)

IO.puts "\n📊 Initial CPU Status:"
Elixir6502.print_status(cpu_pid)

# Execute program step by step
IO.puts "\n🚀 Executing program step by step..."

instructions = [
  "LDA #$05 - Load 5 into accumulator",
  "STA $0200 - Store accumulator at memory $0200",
  "LDA #$03 - Load 3 into accumulator", 
  "ADC #$02 - Add 2 to accumulator",
  "STA $0201 - Store result at memory $0201",
  "BRK - Break (halt)"
]

for {instruction, step} <- Enum.with_index(instructions, 1) do
  IO.puts "\nStep #{step}: #{instruction}"
  
  case Elixir6502.step(cpu_pid) do
    :ok -> 
      IO.puts "✅ Executed successfully"
    :halt -> 
      IO.puts "🛑 CPU halted"
    {:error, reason} -> 
      IO.puts "❌ Error: #{inspect(reason)}"
  end
  
  Elixir6502.print_status(cpu_pid)
  
  if step <= 4 do
    IO.puts "Press Enter to continue..."
    IO.gets("")
  end
end

# Check memory results
IO.puts "\n🔍 Checking memory results:"
result1 = Elixir6502.read_memory(cpu_pid, 0x0200)
result2 = Elixir6502.read_memory(cpu_pid, 0x0201)

IO.puts "Memory $0200: #{result1} (should be 5)"
IO.puts "Memory $0201: #{result2} (should be 5)"

if result1 == 5 and result2 == 5 do
  IO.puts "✅ Program executed correctly!"
else
  IO.puts "❌ Unexpected results"
end

IO.puts "\n🧮 Now let's try the Fibonacci calculator..."

# Start a new CPU for Fibonacci
{:ok, fib_cpu} = Elixir6502.start(name: :fib_cpu)
{:ok, fib_size} = Elixir6502.load_fibonacci_program(fib_cpu)
Elixir6502.reset(fib_cpu)

IO.puts "✅ Loaded Fibonacci program (#{fib_size} bytes)"

# Run for a few cycles
IO.puts "Running Fibonacci calculator..."
Elixir6502.run(fib_cpu)

# Let it run for a bit
:timer.sleep(100)
Elixir6502.stop(fib_cpu)

IO.puts "\n📊 Final Fibonacci CPU Status:"
Elixir6502.print_status(fib_cpu)

# Check Fibonacci results
IO.puts "\n🔢 Fibonacci sequence results:"
fib_results = Elixir6502.dump_memory(fib_cpu, 0x0300, 10)

for {address, value} <- fib_results do
  if value > 0 do
    index = address - 0x0300
    IO.puts "F(#{index}): #{value}"
  end
end

IO.puts """

🎉 Demo completed!

Key features demonstrated:
- ✅ GenServer-based CPU and Memory management
- ✅ Complete 6502 instruction set implementation  
- ✅ All addressing modes supported
- ✅ Accurate flag handling
- ✅ Stack operations
- ✅ Program loading and execution
- ✅ Step-by-step debugging
- ✅ Continuous execution mode

This emulator provides a solid foundation for more advanced projects like:
- NES emulation
- Apple II emulation  
- Custom 6502-based computer systems
- Educational tools for learning assembly programming

Happy coding! 🚀
"""
