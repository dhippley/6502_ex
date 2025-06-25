defmodule Elixir6502.CPU.Memory do
  @moduledoc """
  6502 Memory GenServer implementation.
  
  Manages 64KB of addressable memory space with the following layout:
  - $0000-$00FF: Zero Page
  - $0100-$01FF: Stack
  - $0200-$02FF: Reserved for OS and BASIC
  - $0300-$3FFF: Available RAM
  - $4000-$7FFF: Expansion RAM
  - $8000-$FFFF: ROM/Cartridge
  """
  
  use GenServer
  import Bitwise
  
  @memory_size 65536  # 64KB
  
  # Client API
  
  @doc """
  Starts the Memory GenServer.
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end
  
  @doc """
  Reads a byte from memory at the given address.
  """
  def read(memory_pid, address) when address >= 0 and address < @memory_size do
    GenServer.call(memory_pid, {:read, address})
  end
  
  @doc """
  Writes a byte to memory at the given address.
  """
  def write(memory_pid, address, value) 
      when address >= 0 and address < @memory_size and value >= 0 and value <= 255 do
    GenServer.call(memory_pid, {:write, address, value})
  end
  
  @doc """
  Reads a 16-bit word from memory at the given address (little-endian).
  """
  def read_word(memory_pid, address) when address >= 0 and address < (@memory_size - 1) do
    GenServer.call(memory_pid, {:read_word, address})
  end
  
  @doc """
  Writes a 16-bit word to memory at the given address (little-endian).
  """
  def write_word(memory_pid, address, value) 
      when address >= 0 and address < (@memory_size - 1) and value >= 0 and value <= 65535 do
    GenServer.call(memory_pid, {:write_word, address, value})
  end
  
  @doc """
  Loads a list of bytes into memory starting at the given address.
  """
  def load_bytes(memory_pid, start_address, bytes) when is_list(bytes) do
    GenServer.call(memory_pid, {:load_bytes, start_address, bytes})
  end
  
  @doc """
  Dumps a range of memory for debugging.
  """
  def dump(memory_pid, start_address, length) do
    GenServer.call(memory_pid, {:dump, start_address, length})
  end
  
  @doc """
  Clears all memory.
  """
  def clear(memory_pid) do
    GenServer.call(memory_pid, :clear)
  end
  
  @doc """
  Initializes memory with typical 6502 vectors.
  """
  def init_vectors(memory_pid, opts \\ []) do
    GenServer.call(memory_pid, {:init_vectors, opts})
  end
  
  # GenServer Callbacks
  
  @impl true
  def init(_opts) do
    # Initialize memory as an empty map
    # Using map instead of array for sparse memory representation
    {:ok, %{}}
  end
  
  @impl true
  def handle_call({:read, address}, _from, memory) do
    value = Map.get(memory, address, 0x00)
    {:reply, value, memory}
  end
  
  @impl true
  def handle_call({:write, address, value}, _from, memory) do
    new_memory = Map.put(memory, address, value)
    {:reply, :ok, new_memory}
  end
  
  @impl true
  def handle_call({:read_word, address}, _from, memory) do
    low_byte = Map.get(memory, address, 0x00)
    high_byte = Map.get(memory, address + 1, 0x00)
    word = (high_byte <<< 8) ||| low_byte
    {:reply, word, memory}
  end
  
  @impl true
  def handle_call({:write_word, address, value}, _from, memory) do
    low_byte = value &&& 0xFF
    high_byte = (value >>> 8) &&& 0xFF
    
    new_memory = memory
    |> Map.put(address, low_byte)
    |> Map.put(address + 1, high_byte)
    
    {:reply, :ok, new_memory}
  end
  
  @impl true
  def handle_call({:load_bytes, start_address, bytes}, _from, memory) do
    new_memory = bytes
    |> Enum.with_index()
    |> Enum.reduce(memory, fn {byte, index}, acc_memory ->
      address = start_address + index
      if address < @memory_size do
        Map.put(acc_memory, address, byte)
      else
        acc_memory
      end
    end)
    
    {:reply, :ok, new_memory}
  end
  
  @impl true
  def handle_call({:dump, start_address, length}, _from, memory) do
    dump_data = for address <- start_address..(start_address + length - 1) do
      {address, Map.get(memory, address, 0x00)}
    end
    {:reply, dump_data, memory}
  end
  
  @impl true
  def handle_call(:clear, _from, _memory) do
    {:reply, :ok, %{}}
  end
  
  @impl true
  def handle_call({:init_vectors, opts}, _from, memory) do
    nmi_vector = Keyword.get(opts, :nmi, 0x0000)
    reset_vector = Keyword.get(opts, :reset, 0x0600)
    irq_vector = Keyword.get(opts, :irq, 0x0000)
    
    new_memory = memory
    |> put_word(0xFFFA, nmi_vector)    # NMI vector
    |> put_word(0xFFFC, reset_vector)  # Reset vector
    |> put_word(0xFFFE, irq_vector)    # IRQ/BRK vector
    
    {:reply, :ok, new_memory}
  end
  
  # Private helper functions
  
  defp put_word(memory, address, value) do
    low_byte = value &&& 0xFF
    high_byte = (value >>> 8) &&& 0xFF
    
    memory
    |> Map.put(address, low_byte)
    |> Map.put(address + 1, high_byte)
  end
end