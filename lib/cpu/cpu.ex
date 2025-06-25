defmodule Elixir6502.CPU do
  @moduledoc """
  MOS 6502 CPU GenServer implementation.
  
  This GenServer manages the complete state of a 6502 processor including:
  - 8-bit accumulator (A)
  - 8-bit index registers (X, Y)
  - 8-bit stack pointer (SP)
  - 16-bit program counter (PC)
  - 8-bit status register (P) with flags: N V - B D I Z C
  - 64KB memory space
  - Execution cycles
  """
  
  use GenServer
  
  alias Elixir6502.CPU.{Memory, Flags, Instructions, Executor}
  
  defstruct [
    # Registers
    a: 0x00,          # Accumulator
    x: 0x00,          # X index register
    y: 0x00,          # Y index register
    sp: 0xFF,         # Stack pointer (starts at 0xFF)
    pc: 0x0000,       # Program counter
    
    # Status flags
    flags: %{},       # Will be initialized as Flags struct
    
    # Memory GenServer PID
    memory_pid: nil,
    
    # Execution state
    cycles: 0,
    running: false,
    halted: false
  ]
  
  @type t :: %__MODULE__{
    a: 0..255,
    x: 0..255,
    y: 0..255,
    sp: 0..255,
    pc: 0..65535,
    flags: map(),
    memory_pid: pid(),
    cycles: non_neg_integer(),
    running: boolean(),
    halted: boolean()
  }
  
  # Client API
  
  @doc """
  Starts the CPU GenServer.
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end
  
  @doc """
  Resets the CPU to initial state.
  """
  def reset(cpu_pid \\ __MODULE__) do
    GenServer.call(cpu_pid, :reset)
  end
  
  @doc """
  Loads a program into memory starting at the given address.
  """
  def load_program(cpu_pid \\ __MODULE__, program, start_address \\ 0x0600) do
    GenServer.call(cpu_pid, {:load_program, program, start_address})
  end
  
  @doc """
  Executes a single instruction step.
  """
  def step(cpu_pid \\ __MODULE__) do
    GenServer.call(cpu_pid, :step)
  end
  
  @doc """
  Starts continuous execution.
  """
  def run(cpu_pid \\ __MODULE__) do
    GenServer.call(cpu_pid, :run)
  end
  
  @doc """
  Stops execution.
  """
  def stop(cpu_pid \\ __MODULE__) do
    GenServer.call(cpu_pid, :stop)
  end
  
  @doc """
  Gets the current CPU status.
  """
  def status(cpu_pid \\ __MODULE__) do
    GenServer.call(cpu_pid, :status)
  end
  
  @doc """
  Sets the program counter.
  """
  def set_pc(cpu_pid \\ __MODULE__, address) do
    GenServer.call(cpu_pid, {:set_pc, address})
  end
  
  @doc """
  Reads a memory location.
  """
  def read_memory(cpu_pid \\ __MODULE__, address) do
    GenServer.call(cpu_pid, {:read_memory, address})
  end
  
  @doc """
  Writes to a memory location.
  """
  def write_memory(cpu_pid \\ __MODULE__, address, value) do
    GenServer.call(cpu_pid, {:write_memory, address, value})
  end
  
  # GenServer Callbacks
  
  @impl true
  def init(opts) do
    pc = Keyword.get(opts, :pc, 0x0000)
    
    # Start memory GenServer
    {:ok, memory_pid} = Memory.start_link()
    
    # Initialize CPU state
    state = %__MODULE__{
      pc: pc,
      memory_pid: memory_pid,
      flags: Flags.new()
    }
    
    # Set up reset vector if provided
    if reset_vector = Keyword.get(opts, :reset_vector) do
      Memory.write_word(memory_pid, 0xFFFC, reset_vector)
    end
    
    {:ok, state}
  end
  
  @impl true
  def handle_call(:reset, _from, state) do
    # Read reset vector from memory
    reset_vector = Memory.read_word(state.memory_pid, 0xFFFC)
    
    new_state = %{state |
      a: 0x00,
      x: 0x00,
      y: 0x00,
      sp: 0xFF,
      pc: reset_vector,
      flags: Flags.new() |> Flags.set_interrupt_disable(true),
      cycles: 0,
      running: false,
      halted: false
    }
    
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call({:load_program, program, start_address}, _from, state) do
    Memory.load_bytes(state.memory_pid, start_address, program)
    new_state = %{state | pc: start_address}
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call(:step, _from, state) do
    if state.halted do
      {:reply, {:error, :halted}, state}
    else
      case execute_instruction(state) do
        {:ok, new_state} -> {:reply, :ok, new_state}
        {:halt, new_state} -> {:reply, :halt, %{new_state | halted: true}}
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    end
  end
  
  @impl true
  def handle_call(:run, _from, state) do
    new_state = %{state | running: true}
    send(self(), :execute_cycle)
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call(:stop, _from, state) do
    new_state = %{state | running: false}
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call(:status, _from, state) do
    status = %{
      a: state.a,
      x: state.x,
      y: state.y,
      sp: state.sp,
      pc: state.pc,
      flags: Flags.to_byte(state.flags),
      cycles: state.cycles,
      running: state.running,
      halted: state.halted
    }
    {:reply, status, state}
  end
  
  @impl true
  def handle_call({:set_pc, address}, _from, state) when address >= 0 and address <= 0xFFFF do
    new_state = %{state | pc: address}
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call({:read_memory, address}, _from, state) do
    value = Memory.read(state.memory_pid, address)
    {:reply, value, state}
  end
  
  @impl true
  def handle_call({:write_memory, address, value}, _from, state) do
    Memory.write(state.memory_pid, address, value)
    {:reply, :ok, state}
  end
  
  @impl true
  def handle_info(:execute_cycle, state) do
    if state.running and not state.halted do
      case execute_instruction(state) do
        {:ok, new_state} ->
          # Schedule next cycle with a small delay to prevent overwhelming
          Process.send_after(self(), :execute_cycle, 1)
          {:noreply, new_state}
        {:halt, new_state} ->
          {:noreply, %{new_state | running: false, halted: true}}
        {:error, _reason} ->
          {:noreply, %{state | running: false}}
      end
    else
      {:noreply, state}
    end
  end
  
  # Private helper functions
  
  defp execute_instruction(state) do
    opcode = Memory.read(state.memory_pid, state.pc)
    
    case Instructions.get_instruction(opcode) do
      {:unknown, _, _} ->
        {:error, {:unknown_opcode, opcode}}
      
      {instruction, addressing_mode, base_cycles} ->
        # Execute the instruction
        case Executor.execute(state, instruction, addressing_mode, base_cycles) do
          {:ok, new_state} -> {:ok, new_state}
          {:halt, new_state} -> {:halt, new_state}
          {:error, reason} -> {:error, reason}
        end
    end
  end
end