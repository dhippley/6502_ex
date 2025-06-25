defmodule Elixir6502 do
  @moduledoc """
  **A 6502 CPU emulator written in Elixir using GenServers**
  
  This module provides the main API for the MOS 6502 emulator.
  The emulator uses GenServers to manage CPU and memory state,
  allowing for concurrent execution and state management.
  
  ## Quick Start
  
  ```elixir
  # Start the emulator
  {:ok, cpu_pid} = Elixir6502.start()
  
  # Load and run a test program
  Elixir6502.load_test_program(cpu_pid)
  Elixir6502.reset(cpu_pid)
  Elixir6502.run(cpu_pid)
  
  # Check status
  Elixir6502.status(cpu_pid)
  ```
  
  ## Examples
  
      iex> {:ok, cpu} = Elixir6502.start()
      iex> Elixir6502.load_test_program(cpu)
      iex> Elixir6502.reset(cpu)
      iex> Elixir6502.step(cpu)
      :ok
  
  """
  
  alias Elixir6502.CPU
  alias Elixir6502.ROM.Loader
  
  @doc """
  Starts a new 6502 CPU emulator.
  
  ## Options
  
  - `:name` - Name for the GenServer (default: `Elixir6502.CPU`)
  - `:reset_vector` - Initial reset vector address (default: 0x0600)
  
  ## Examples
  
      iex> {:ok, pid} = Elixir6502.start()
      iex> is_pid(pid)
      true
  
  """
  def start(opts \\ []) do
    reset_vector = Keyword.get(opts, :reset_vector, 0x0600)
    opts = Keyword.put(opts, :reset_vector, reset_vector)
    CPU.start_link(opts)
  end
  
  @doc """
  Resets the CPU to initial state.
  """
  def reset(cpu_pid \\ CPU) do
    CPU.reset(cpu_pid)
  end
  
  @doc """
  Loads a test program that demonstrates basic operations.
  """
  def load_test_program(cpu_pid \\ CPU) do
    Loader.load_test_program(cpu_pid)
  end
  
  @doc """
  Loads a fibonacci sequence calculator.
  """
  def load_fibonacci_program(cpu_pid \\ CPU) do
    Loader.load_fibonacci_program(cpu_pid)
  end
  
  @doc """
  Loads a program from a list of bytes.
  """
  def load_program(cpu_pid \\ CPU, program, start_address \\ 0x0600) do
    CPU.load_program(cpu_pid, program, start_address)
  end
  
  @doc """
  Loads a program from a binary file.
  """
  def load_file(cpu_pid \\ CPU, file_path, start_address \\ 0x8000) do
    Loader.load_file(cpu_pid, file_path, start_address)
  end
  
  @doc """
  Executes a single instruction step.
  """
  def step(cpu_pid \\ CPU) do
    CPU.step(cpu_pid)
  end
  
  @doc """
  Starts continuous execution.
  """
  def run(cpu_pid \\ CPU) do
    CPU.run(cpu_pid)
  end
  
  @doc """
  Stops execution.
  """
  def stop(cpu_pid \\ CPU) do
    CPU.stop(cpu_pid)
  end
  
  @doc """
  Gets the current CPU status.
  """
  def status(cpu_pid \\ CPU) do
    CPU.status(cpu_pid)
  end
  
  @doc """
  Sets the program counter to a specific address.
  """
  def set_pc(cpu_pid \\ CPU, address) do
    CPU.set_pc(cpu_pid, address)
  end
  
  @doc """
  Reads a memory location.
  """
  def read_memory(cpu_pid \\ CPU, address) do
    CPU.read_memory(cpu_pid, address)
  end
  
  @doc """
  Writes to a memory location.
  """
  def write_memory(cpu_pid \\ CPU, address, value) do
    CPU.write_memory(cpu_pid, address, value)
  end
  
  @doc """
  Dumps a range of memory for debugging.
  """
  def dump_memory(cpu_pid \\ CPU, start_address, length) do
    # We need to access the memory GenServer through the CPU
    # This is a simplified version - in a real implementation,
    # you might want to add this functionality to the CPU module
    for address <- start_address..(start_address + length - 1) do
      value = read_memory(cpu_pid, address)
      {address, value}
    end
  end
  
  @doc """
  Pretty prints the CPU status.
  """
  def print_status(cpu_pid \\ CPU) do
    status = status(cpu_pid)
    
    IO.puts("""
    === 6502 CPU Status ===
    A:  $#{Integer.to_string(status.a, 16) |> String.pad_leading(2, "0")} (#{status.a})
    X:  $#{Integer.to_string(status.x, 16) |> String.pad_leading(2, "0")} (#{status.x})
    Y:  $#{Integer.to_string(status.y, 16) |> String.pad_leading(2, "0")} (#{status.y})
    SP: $#{Integer.to_string(status.sp, 16) |> String.pad_leading(2, "0")} (#{status.sp})
    PC: $#{Integer.to_string(status.pc, 16) |> String.pad_leading(4, "0")} (#{status.pc})
    P:  $#{Integer.to_string(status.flags, 16) |> String.pad_leading(2, "0")} (#{format_flags(status.flags)})
    Cycles: #{status.cycles}
    Running: #{status.running}
    Halted: #{status.halted}
    =====================
    """)
  end
  
  # Helper function to format flags
  defp format_flags(flags_byte) do
    flags = Elixir6502.CPU.Flags.from_byte(flags_byte)
    
    [
      if(flags.negative, do: "N", else: "n"),
      if(flags.overflow, do: "V", else: "v"),
      "-",
      if(flags.break, do: "B", else: "b"),
      if(flags.decimal, do: "D", else: "d"),
      if(flags.interrupt_disable, do: "I", else: "i"),
      if(flags.zero, do: "Z", else: "z"),
      if(flags.carry, do: "C", else: "c")
    ]
    |> Enum.join("")
  end
end
