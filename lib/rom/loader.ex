defmodule Elixir6502.ROM.Loader do
  @moduledoc """
  ROM Loader for the 6502 emulator.
  
  Provides utilities for loading ROM files and binary data into memory.
  """
  
  @doc """
  Loads a binary file into memory at the specified address.
  """
  def load_file(cpu_pid, file_path, start_address \\ 0x8000) do
    case File.read(file_path) do
      {:ok, binary_data} ->
        bytes = :binary.bin_to_list(binary_data)
        Elixir6502.CPU.load_program(cpu_pid, bytes, start_address)
        {:ok, length(bytes)}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Loads a list of bytes representing assembly code into memory.
  """
  def load_bytes(cpu_pid, bytes, start_address \\ 0x0600) do
    Elixir6502.CPU.load_program(cpu_pid, bytes, start_address)
  end
  
  @doc """
  Creates a simple test program that demonstrates basic 6502 operations.
  """
  def load_test_program(cpu_pid) do
    # Simple test program:
    # LDA #$05     ; Load 5 into accumulator
    # STA $0200    ; Store accumulator at $0200
    # LDA #$03     ; Load 3 into accumulator
    # ADC #$02     ; Add 2 to accumulator (should be 5)
    # STA $0201    ; Store result at $0201
    # BRK          ; Break (halt)
    
    program = [
      0xA9, 0x05,        # LDA #$05
      0x8D, 0x00, 0x02,  # STA $0200
      0xA9, 0x03,        # LDA #$03
      0x69, 0x02,        # ADC #$02
      0x8D, 0x01, 0x02,  # STA $0201
      0x00               # BRK
    ]
    
    load_bytes(cpu_pid, program, 0x0600)
    
    # Set reset vector to point to our program
    Elixir6502.CPU.write_memory(cpu_pid, 0xFFFC, 0x00)
    Elixir6502.CPU.write_memory(cpu_pid, 0xFFFD, 0x06)
    
    {:ok, length(program)}
  end
  
  @doc """
  Creates a fibonacci sequence calculator program.
  """
  def load_fibonacci_program(cpu_pid) do
    # Fibonacci sequence calculator
    # Calculates fibonacci numbers and stores them starting at $0300
    
    program = [
      # Initialize: F(0) = 0, F(1) = 1
      0xA9, 0x00,        # LDA #$00     ; F(0) = 0
      0x8D, 0x00, 0x03,  # STA $0300    ; Store F(0)
      0xA9, 0x01,        # LDA #$01     ; F(1) = 1
      0x8D, 0x01, 0x03,  # STA $0301    ; Store F(1)
      
      # Main loop
      0xAD, 0x00, 0x03,  # LDA $0300    ; Load F(n-2)
      0x6D, 0x01, 0x03,  # ADC $0301    ; Add F(n-1)
      0x8D, 0x02, 0x03,  # STA $0302    ; Store F(n)
      
      # Shift values: F(n-1) -> F(n-2), F(n) -> F(n-1)
      0xAD, 0x01, 0x03,  # LDA $0301    ; Load F(n-1)
      0x8D, 0x00, 0x03,  # STA $0300    ; Store as new F(n-2)
      0xAD, 0x02, 0x03,  # LDA $0302    ; Load F(n)
      0x8D, 0x01, 0x03,  # STA $0301    ; Store as new F(n-1)
      
      # Check for overflow (if result > 100, stop)
      0xC9, 0x64,        # CMP #$64     ; Compare with 100
      0xB0, 0x02,        # BCS +2       ; Branch if carry set (A >= 100)
      0x4C, 0x0C, 0x06,  # JMP $060C    ; Jump back to main loop
      
      0x00               # BRK          ; Stop
    ]
    
    load_bytes(cpu_pid, program, 0x0600)
    
    # Set reset vector
    Elixir6502.CPU.write_memory(cpu_pid, 0xFFFC, 0x00)
    Elixir6502.CPU.write_memory(cpu_pid, 0xFFFD, 0x06)
    
    {:ok, length(program)}
  end
end