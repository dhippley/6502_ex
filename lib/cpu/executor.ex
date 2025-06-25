defmodule Elixir6502.CPU.Executor do
  @moduledoc """
  6502 CPU Instruction Executor.
  
  This module handles the execution of individual 6502 instructions.
  Each instruction implementation modifies the CPU state appropriately.
  """
  
  import Bitwise
  alias Elixir6502.CPU.{Memory, Flags, Addressing}
  
  @doc """
  Executes an instruction and returns the updated CPU state.
  """
  def execute(cpu, instruction, addressing_mode, base_cycles) do
    # Resolve addressing mode
    {operand, address, extra_cycles} = Addressing.resolve(cpu, addressing_mode)
    
    # Update program counter based on instruction length
    instruction_length = Addressing.instruction_length(addressing_mode)
    cpu = %{cpu | pc: cpu.pc + instruction_length}
    
    # Execute the instruction
    case execute_instruction(cpu, instruction, operand, address) do
      {:ok, new_cpu} ->
        total_cycles = base_cycles + extra_cycles
        final_cpu = %{new_cpu | cycles: new_cpu.cycles + total_cycles}
        {:ok, final_cpu}
      
      {:halt, new_cpu} ->
        total_cycles = base_cycles + extra_cycles
        final_cpu = %{new_cpu | cycles: new_cpu.cycles + total_cycles}
        {:halt, final_cpu}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Instruction implementations
  
  # Load/Store Operations
  defp execute_instruction(cpu, :lda, operand, _address) do
    new_cpu = %{cpu | a: operand, flags: Flags.set_nz(cpu.flags, operand)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :ldx, operand, _address) do
    new_cpu = %{cpu | x: operand, flags: Flags.set_nz(cpu.flags, operand)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :ldy, operand, _address) do
    new_cpu = %{cpu | y: operand, flags: Flags.set_nz(cpu.flags, operand)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :sta, _operand, address) do
    Memory.write(cpu.memory_pid, address, cpu.a)
    {:ok, cpu}
  end
  
  defp execute_instruction(cpu, :stx, _operand, address) do
    Memory.write(cpu.memory_pid, address, cpu.x)
    {:ok, cpu}
  end
  
  defp execute_instruction(cpu, :sty, _operand, address) do
    Memory.write(cpu.memory_pid, address, cpu.y)
    {:ok, cpu}
  end
  
  # Transfer Operations
  defp execute_instruction(cpu, :tax, _operand, _address) do
    new_cpu = %{cpu | x: cpu.a, flags: Flags.set_nz(cpu.flags, cpu.a)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :tay, _operand, _address) do
    new_cpu = %{cpu | y: cpu.a, flags: Flags.set_nz(cpu.flags, cpu.a)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :txa, _operand, _address) do
    new_cpu = %{cpu | a: cpu.x, flags: Flags.set_nz(cpu.flags, cpu.x)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :tya, _operand, _address) do
    new_cpu = %{cpu | a: cpu.y, flags: Flags.set_nz(cpu.flags, cpu.y)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :tsx, _operand, _address) do
    new_cpu = %{cpu | x: cpu.sp, flags: Flags.set_nz(cpu.flags, cpu.sp)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :txs, _operand, _address) do
    new_cpu = %{cpu | sp: cpu.x}
    {:ok, new_cpu}
  end
  
  # Arithmetic Operations
  defp execute_instruction(cpu, :adc, operand, _address) do
    carry = if cpu.flags.carry, do: 1, else: 0
    result = cpu.a + operand + carry
    
    # Check for overflow (signed arithmetic)
    overflow = ((bxor(cpu.a, result)) &&& (bxor(operand, result)) &&& 0x80) != 0
    
    final_result = result &&& 0xFF
    new_flags = cpu.flags
    |> Flags.set_nz(final_result)
    |> Flags.set_carry(result > 255)
    |> Flags.set_overflow(overflow)
    
    new_cpu = %{cpu | a: final_result, flags: new_flags}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :sbc, operand, _address) do
    carry = if cpu.flags.carry, do: 1, else: 0
    result = cpu.a - operand - (1 - carry)
    
    # Check for overflow (signed arithmetic)
    overflow = ((bxor(cpu.a, result)) &&& ((bxor(cpu.a, operand)) &&& 0x80)) != 0
    
    final_result = result &&& 0xFF
    new_flags = cpu.flags
    |> Flags.set_nz(final_result)
    |> Flags.set_carry(result >= 0)
    |> Flags.set_overflow(overflow)
    
    new_cpu = %{cpu | a: final_result, flags: new_flags}
    {:ok, new_cpu}
  end
  
  # Logical Operations
  defp execute_instruction(cpu, :and, operand, _address) do
    result = cpu.a &&& operand
    new_cpu = %{cpu | a: result, flags: Flags.set_nz(cpu.flags, result)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :ora, operand, _address) do
    result = cpu.a ||| operand
    new_cpu = %{cpu | a: result, flags: Flags.set_nz(cpu.flags, result)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :eor, operand, _address) do
    result = bxor(cpu.a, operand)
    new_cpu = %{cpu | a: result, flags: Flags.set_nz(cpu.flags, result)}
    {:ok, new_cpu}
  end
  
  # Shift Operations
  defp execute_instruction(cpu, :asl, operand, address) do
    carry = (operand &&& 0x80) != 0
    result = (operand <<< 1) &&& 0xFF
    
    new_flags = cpu.flags
    |> Flags.set_nz(result)
    |> Flags.set_carry(carry)
    
    new_cpu = %{cpu | flags: new_flags}
    
    case address do
      nil -> {:ok, %{new_cpu | a: result}}  # Accumulator mode
      _ -> 
        Memory.write(cpu.memory_pid, address, result)
        {:ok, new_cpu}
    end
  end
  
  defp execute_instruction(cpu, :lsr, operand, address) do
    carry = (operand &&& 0x01) != 0
    result = operand >>> 1
    
    new_flags = cpu.flags
    |> Flags.set_nz(result)
    |> Flags.set_carry(carry)
    
    new_cpu = %{cpu | flags: new_flags}
    
    case address do
      nil -> {:ok, %{new_cpu | a: result}}  # Accumulator mode
      _ -> 
        Memory.write(cpu.memory_pid, address, result)
        {:ok, new_cpu}
    end
  end
  
  # Increment/Decrement Operations
  defp execute_instruction(cpu, :inc, operand, address) do
    result = (operand + 1) &&& 0xFF
    Memory.write(cpu.memory_pid, address, result)
    new_cpu = %{cpu | flags: Flags.set_nz(cpu.flags, result)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :dec, operand, address) do
    result = (operand - 1) &&& 0xFF
    Memory.write(cpu.memory_pid, address, result)
    new_cpu = %{cpu | flags: Flags.set_nz(cpu.flags, result)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :inx, _operand, _address) do
    result = (cpu.x + 1) &&& 0xFF
    new_cpu = %{cpu | x: result, flags: Flags.set_nz(cpu.flags, result)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :iny, _operand, _address) do
    result = (cpu.y + 1) &&& 0xFF
    new_cpu = %{cpu | y: result, flags: Flags.set_nz(cpu.flags, result)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :dex, _operand, _address) do
    result = (cpu.x - 1) &&& 0xFF
    new_cpu = %{cpu | x: result, flags: Flags.set_nz(cpu.flags, result)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :dey, _operand, _address) do
    result = (cpu.y - 1) &&& 0xFF
    new_cpu = %{cpu | y: result, flags: Flags.set_nz(cpu.flags, result)}
    {:ok, new_cpu}
  end
  
  # Compare Operations
  defp execute_instruction(cpu, :cmp, operand, _address) do
    result = cpu.a - operand
    new_flags = cpu.flags
    |> Flags.set_nz(result &&& 0xFF)
    |> Flags.set_carry(cpu.a >= operand)
    
    new_cpu = %{cpu | flags: new_flags}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :cpx, operand, _address) do
    result = cpu.x - operand
    new_flags = cpu.flags
    |> Flags.set_nz(result &&& 0xFF)
    |> Flags.set_carry(cpu.x >= operand)
    
    new_cpu = %{cpu | flags: new_flags}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :cpy, operand, _address) do
    result = cpu.y - operand
    new_flags = cpu.flags
    |> Flags.set_nz(result &&& 0xFF)
    |> Flags.set_carry(cpu.y >= operand)
    
    new_cpu = %{cpu | flags: new_flags}
    {:ok, new_cpu}
  end
  
  # Branch Operations
  defp execute_instruction(cpu, :bcc, _operand, target_address) do
    if not cpu.flags.carry do
      {:ok, %{cpu | pc: target_address}}
    else
      {:ok, cpu}
    end
  end
  
  defp execute_instruction(cpu, :bcs, _operand, target_address) do
    if cpu.flags.carry do
      {:ok, %{cpu | pc: target_address}}
    else
      {:ok, cpu}
    end
  end
  
  defp execute_instruction(cpu, :beq, _operand, target_address) do
    if cpu.flags.zero do
      {:ok, %{cpu | pc: target_address}}
    else
      {:ok, cpu}
    end
  end
  
  defp execute_instruction(cpu, :bne, _operand, target_address) do
    if not cpu.flags.zero do
      {:ok, %{cpu | pc: target_address}}
    else
      {:ok, cpu}
    end
  end
  
  defp execute_instruction(cpu, :bmi, _operand, target_address) do
    if cpu.flags.negative do
      {:ok, %{cpu | pc: target_address}}
    else
      {:ok, cpu}
    end
  end
  
  defp execute_instruction(cpu, :bpl, _operand, target_address) do
    if not cpu.flags.negative do
      {:ok, %{cpu | pc: target_address}}
    else
      {:ok, cpu}
    end
  end
  
  defp execute_instruction(cpu, :bvc, _operand, target_address) do
    if not cpu.flags.overflow do
      {:ok, %{cpu | pc: target_address}}
    else
      {:ok, cpu}
    end
  end
  
  defp execute_instruction(cpu, :bvs, _operand, target_address) do
    if cpu.flags.overflow do
      {:ok, %{cpu | pc: target_address}}
    else
      {:ok, cpu}
    end
  end
  
  # Jump Operations
  defp execute_instruction(cpu, :jmp, _operand, target_address) do
    {:ok, %{cpu | pc: target_address}}
  end
  
  defp execute_instruction(cpu, :jsr, _operand, target_address) do
    # Push return address - 1 to stack
    return_address = cpu.pc - 1
    push_word(cpu, return_address)
    {:ok, %{cpu | pc: target_address}}
  end
  
  defp execute_instruction(cpu, :rts, _operand, _address) do
    {cpu, return_address} = pop_word(cpu)
    {:ok, %{cpu | pc: return_address + 1}}
  end
  
  # Flag Operations
  defp execute_instruction(cpu, :clc, _operand, _address) do
    new_cpu = %{cpu | flags: Flags.set_carry(cpu.flags, false)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :sec, _operand, _address) do
    new_cpu = %{cpu | flags: Flags.set_carry(cpu.flags, true)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :cli, _operand, _address) do
    new_cpu = %{cpu | flags: Flags.set_interrupt_disable(cpu.flags, false)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :sei, _operand, _address) do
    new_cpu = %{cpu | flags: Flags.set_interrupt_disable(cpu.flags, true)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :cld, _operand, _address) do
    new_cpu = %{cpu | flags: Flags.set_decimal(cpu.flags, false)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :sed, _operand, _address) do
    new_cpu = %{cpu | flags: Flags.set_decimal(cpu.flags, true)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :clv, _operand, _address) do
    new_cpu = %{cpu | flags: Flags.set_overflow(cpu.flags, false)}
    {:ok, new_cpu}
  end
  
  # Stack Operations
  defp execute_instruction(cpu, :pha, _operand, _address) do
    push_byte(cpu, cpu.a)
    {:ok, cpu}
  end
  
  defp execute_instruction(cpu, :pla, _operand, _address) do
    {cpu, value} = pop_byte(cpu)
    new_cpu = %{cpu | a: value, flags: Flags.set_nz(cpu.flags, value)}
    {:ok, new_cpu}
  end
  
  defp execute_instruction(cpu, :php, _operand, _address) do
    flags_byte = Flags.to_byte(cpu.flags) ||| 0x10  # Set B flag for PHP
    push_byte(cpu, flags_byte)
    {:ok, cpu}
  end
  
  defp execute_instruction(cpu, :plp, _operand, _address) do
    {cpu, flags_byte} = pop_byte(cpu)
    new_flags = Flags.from_byte(flags_byte)
    new_cpu = %{cpu | flags: new_flags}
    {:ok, new_cpu}
  end
  
  # System Operations
  defp execute_instruction(cpu, :nop, _operand, _address) do
    {:ok, cpu}
  end
  
  defp execute_instruction(cpu, :brk, _operand, _address) do
    # BRK causes a software interrupt
    # Push PC + 2 and status register to stack
    push_word(cpu, cpu.pc + 1)
    flags_byte = Flags.to_byte(cpu.flags) ||| 0x10  # Set B flag
    push_byte(cpu, flags_byte)
    
    # Set interrupt disable flag and jump to IRQ vector
    irq_vector = Memory.read_word(cpu.memory_pid, 0xFFFE)
    new_flags = Flags.set_interrupt_disable(cpu.flags, true)
    new_cpu = %{cpu | flags: new_flags, pc: irq_vector}
    
    {:halt, new_cpu}
  end
  
  # Unknown instruction
  defp execute_instruction(_cpu, instruction, _operand, _address) do
    {:error, {:unknown_instruction, instruction}}
  end
  
  # Stack helper functions
  defp push_byte(cpu, value) do
    stack_address = 0x0100 + cpu.sp
    Memory.write(cpu.memory_pid, stack_address, value)
    %{cpu | sp: (cpu.sp - 1) &&& 0xFF}
  end
  
  defp pop_byte(cpu) do
    new_sp = (cpu.sp + 1) &&& 0xFF
    stack_address = 0x0100 + new_sp
    value = Memory.read(cpu.memory_pid, stack_address)
    {%{cpu | sp: new_sp}, value}
  end
  
  defp push_word(cpu, value) do
    cpu = push_byte(cpu, (value >>> 8) &&& 0xFF)  # High byte first
    push_byte(cpu, value &&& 0xFF)                # Then low byte
  end
  
  defp pop_word(cpu) do
    {cpu, low_byte} = pop_byte(cpu)   # Low byte first
    {cpu, high_byte} = pop_byte(cpu)  # Then high byte
    word = (high_byte <<< 8) ||| low_byte
    {cpu, word}
  end
end