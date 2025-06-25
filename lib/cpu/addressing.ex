defmodule Elixir6502.CPU.Addressing do
  @moduledoc """
  6502 CPU Addressing Modes.
  
  The 6502 supports various addressing modes:
  - Implicit/Accumulator
  - Immediate
  - Zero Page
  - Zero Page,X
  - Zero Page,Y
  - Absolute
  - Absolute,X
  - Absolute,Y
  - Indirect
  - Indexed Indirect (zp,X)
  - Indirect Indexed (zp),Y
  - Relative
  """
  
  import Bitwise
  alias Elixir6502.CPU.Memory
  
  @doc """
  Resolves an addressing mode and returns {operand, address, extra_cycles}.
  """
  def resolve(_cpu, :implicit) do
    {nil, nil, 0}
  end
  
  def resolve(cpu, :accumulator) do
    {cpu.a, nil, 0}
  end
  
  def resolve(cpu, :immediate) do
    operand = Memory.read(cpu.memory_pid, cpu.pc + 1)
    {operand, nil, 0}
  end
  
  def resolve(cpu, :zero_page) do
    address = Memory.read(cpu.memory_pid, cpu.pc + 1)
    operand = Memory.read(cpu.memory_pid, address)
    {operand, address, 0}
  end
  
  def resolve(cpu, :zero_page_x) do
    base_address = Memory.read(cpu.memory_pid, cpu.pc + 1)
    address = (base_address + cpu.x) &&& 0xFF  # Wrap around in zero page
    operand = Memory.read(cpu.memory_pid, address)
    {operand, address, 0}
  end
  
  def resolve(cpu, :zero_page_y) do
    base_address = Memory.read(cpu.memory_pid, cpu.pc + 1)
    address = (base_address + cpu.y) &&& 0xFF  # Wrap around in zero page
    operand = Memory.read(cpu.memory_pid, address)
    {operand, address, 0}
  end
  
  def resolve(cpu, :absolute) do
    address = Memory.read_word(cpu.memory_pid, cpu.pc + 1)
    operand = Memory.read(cpu.memory_pid, address)
    {operand, address, 0}
  end
  
  def resolve(cpu, :absolute_x) do
    base_address = Memory.read_word(cpu.memory_pid, cpu.pc + 1)
    address = (base_address + cpu.x) &&& 0xFFFF
    operand = Memory.read(cpu.memory_pid, address)
    
    # Check for page boundary crossing (adds extra cycle)
    page_crossed = (base_address &&& 0xFF00) != (address &&& 0xFF00)
    extra_cycles = if page_crossed, do: 1, else: 0
    
    {operand, address, extra_cycles}
  end
  
  def resolve(cpu, :absolute_y) do
    base_address = Memory.read_word(cpu.memory_pid, cpu.pc + 1)
    address = (base_address + cpu.y) &&& 0xFFFF
    operand = Memory.read(cpu.memory_pid, address)
    
    # Check for page boundary crossing (adds extra cycle)
    page_crossed = (base_address &&& 0xFF00) != (address &&& 0xFF00)
    extra_cycles = if page_crossed, do: 1, else: 0
    
    {operand, address, extra_cycles}
  end
  
  def resolve(cpu, :indirect) do
    indirect_address = Memory.read_word(cpu.memory_pid, cpu.pc + 1)
    
    # 6502 bug: if indirect address is on page boundary, 
    # high byte is read from wrong address
    if (indirect_address &&& 0xFF) == 0xFF do
      low_byte = Memory.read(cpu.memory_pid, indirect_address)
      high_byte = Memory.read(cpu.memory_pid, indirect_address &&& 0xFF00)
      address = (high_byte <<< 8) ||| low_byte
      {nil, address, 0}
    else
      address = Memory.read_word(cpu.memory_pid, indirect_address)
      {nil, address, 0}
    end
  end
  
  def resolve(cpu, :indexed_indirect) do
    base_address = Memory.read(cpu.memory_pid, cpu.pc + 1)
    indirect_address = (base_address + cpu.x) &&& 0xFF
    
    # Read 16-bit address from zero page (with wraparound)
    low_byte = Memory.read(cpu.memory_pid, indirect_address)
    high_byte = Memory.read(cpu.memory_pid, (indirect_address + 1) &&& 0xFF)
    address = (high_byte <<< 8) ||| low_byte
    
    operand = Memory.read(cpu.memory_pid, address)
    {operand, address, 0}
  end
  
  def resolve(cpu, :indirect_indexed) do
    base_address = Memory.read(cpu.memory_pid, cpu.pc + 1)
    
    # Read 16-bit address from zero page
    low_byte = Memory.read(cpu.memory_pid, base_address)
    high_byte = Memory.read(cpu.memory_pid, (base_address + 1) &&& 0xFF)
    base_indirect = (high_byte <<< 8) ||| low_byte
    
    address = (base_indirect + cpu.y) &&& 0xFFFF
    operand = Memory.read(cpu.memory_pid, address)
    
    # Check for page boundary crossing
    page_crossed = (base_indirect &&& 0xFF00) != (address &&& 0xFF00)
    extra_cycles = if page_crossed, do: 1, else: 0
    
    {operand, address, extra_cycles}
  end
  
  def resolve(cpu, :relative) do
    offset = Memory.read(cpu.memory_pid, cpu.pc + 1)
    # Convert to signed byte
    signed_offset = if offset > 127, do: offset - 256, else: offset
    target_address = (cpu.pc + 2 + signed_offset) &&& 0xFFFF
    {signed_offset, target_address, 0}
  end
  
  @doc """
  Gets the number of bytes this addressing mode consumes.
  """
  def instruction_length(:implicit), do: 1
  def instruction_length(:accumulator), do: 1
  def instruction_length(:immediate), do: 2
  def instruction_length(:zero_page), do: 2
  def instruction_length(:zero_page_x), do: 2
  def instruction_length(:zero_page_y), do: 2
  def instruction_length(:absolute), do: 3
  def instruction_length(:absolute_x), do: 3
  def instruction_length(:absolute_y), do: 3
  def instruction_length(:indirect), do: 3
  def instruction_length(:indexed_indirect), do: 2
  def instruction_length(:indirect_indexed), do: 2
  def instruction_length(:relative), do: 2
  def instruction_length(_), do: 1
end