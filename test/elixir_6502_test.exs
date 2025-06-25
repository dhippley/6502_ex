defmodule Elixir6502Test do
  use ExUnit.Case
  doctest Elixir6502

  test "CPU can be started and reset" do
    {:ok, cpu_pid} = Elixir6502.start(name: :test_cpu)
    assert :ok = Elixir6502.reset(cpu_pid)
    
    status = Elixir6502.status(cpu_pid)
    assert status.a == 0
    assert status.x == 0
    assert status.y == 0
    assert status.sp == 255
    assert status.pc == 0x0600  # Default reset vector
  end

  test "can load and execute simple program" do
    {:ok, cpu_pid} = Elixir6502.start(name: :test_cpu_2)
    
    # Load test program
    {:ok, _size} = Elixir6502.load_test_program(cpu_pid)
    Elixir6502.reset(cpu_pid)
    
    # Execute first instruction: LDA #$05
    :ok = Elixir6502.step(cpu_pid)
    status = Elixir6502.status(cpu_pid)
    assert status.a == 5
    
    # Execute second instruction: STA $0200
    :ok = Elixir6502.step(cpu_pid)
    memory_value = Elixir6502.read_memory(cpu_pid, 0x0200)
    assert memory_value == 5
  end

  test "can execute complete test program" do
    {:ok, cpu_pid} = Elixir6502.start(name: :test_cpu_3)
    
    # Load and run test program
    {:ok, _size} = Elixir6502.load_test_program(cpu_pid)
    Elixir6502.reset(cpu_pid)
    
    # Execute all instructions until BRK
    for _step <- 1..6 do
      case Elixir6502.step(cpu_pid) do
        :ok -> :continue
        :halt -> :halt
        {:error, _} -> :error
      end
    end
    
    # Check results
    result1 = Elixir6502.read_memory(cpu_pid, 0x0200)  # Should be 5
    result2 = Elixir6502.read_memory(cpu_pid, 0x0201)  # Should be 5 (3+2)
    
    assert result1 == 5
    assert result2 == 5
  end

  test "memory operations work correctly" do
    {:ok, cpu_pid} = Elixir6502.start(name: :test_cpu_4)
    
    # Test write and read
    :ok = Elixir6502.write_memory(cpu_pid, 0x1000, 42)
    value = Elixir6502.read_memory(cpu_pid, 0x1000)
    assert value == 42
    
    # Test program loading
    program = [0xA9, 0x42, 0x00]  # LDA #$42, BRK
    :ok = Elixir6502.load_program(cpu_pid, program, 0x2000)
    
    opcode = Elixir6502.read_memory(cpu_pid, 0x2000)
    operand = Elixir6502.read_memory(cpu_pid, 0x2001)
    
    assert opcode == 0xA9
    assert operand == 0x42
  end
end
