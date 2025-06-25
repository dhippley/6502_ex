defmodule Elixir6502.CPU.Instructions do
  @moduledoc """
  6502 CPU Instruction Set.
  
  This module defines all the 6502 instructions and their opcodes.
  Each instruction is mapped to its addressing mode and cycle count.
  """
  
  # Instruction definitions with opcodes, addressing modes, and cycle counts
  @instructions %{
    # ADC - Add with Carry
    0x69 => {:adc, :immediate, 2},
    0x65 => {:adc, :zero_page, 3},
    0x75 => {:adc, :zero_page_x, 4},
    0x6D => {:adc, :absolute, 4},
    0x7D => {:adc, :absolute_x, 4}, # +1 if page crossed
    0x79 => {:adc, :absolute_y, 4}, # +1 if page crossed
    0x61 => {:adc, :indexed_indirect, 6},
    0x71 => {:adc, :indirect_indexed, 5}, # +1 if page crossed
    
    # AND - Logical AND
    0x29 => {:and, :immediate, 2},
    0x25 => {:and, :zero_page, 3},
    0x35 => {:and, :zero_page_x, 4},
    0x2D => {:and, :absolute, 4},
    0x3D => {:and, :absolute_x, 4}, # +1 if page crossed
    0x39 => {:and, :absolute_y, 4}, # +1 if page crossed
    0x21 => {:and, :indexed_indirect, 6},
    0x31 => {:and, :indirect_indexed, 5}, # +1 if page crossed
    
    # ASL - Arithmetic Shift Left
    0x0A => {:asl, :accumulator, 2},
    0x06 => {:asl, :zero_page, 5},
    0x16 => {:asl, :zero_page_x, 6},
    0x0E => {:asl, :absolute, 6},
    0x1E => {:asl, :absolute_x, 7},
    
    # BCC - Branch if Carry Clear
    0x90 => {:bcc, :relative, 2}, # +1 if branch taken, +2 if page crossed
    
    # BCS - Branch if Carry Set
    0xB0 => {:bcs, :relative, 2},
    
    # BEQ - Branch if Equal (Zero Set)
    0xF0 => {:beq, :relative, 2},
    
    # BIT - Bit Test
    0x24 => {:bit, :zero_page, 3},
    0x2C => {:bit, :absolute, 4},
    
    # BMI - Branch if Minus (Negative Set)
    0x30 => {:bmi, :relative, 2},
    
    # BNE - Branch if Not Equal (Zero Clear)
    0xD0 => {:bne, :relative, 2},
    
    # BPL - Branch if Plus (Negative Clear)
    0x10 => {:bpl, :relative, 2},
    
    # BRK - Break
    0x00 => {:brk, :implicit, 7},
    
    # BVC - Branch if Overflow Clear
    0x50 => {:bvc, :relative, 2},
    
    # BVS - Branch if Overflow Set
    0x70 => {:bvs, :relative, 2},
    
    # CLC - Clear Carry Flag
    0x18 => {:clc, :implicit, 2},
    
    # CLD - Clear Decimal Mode
    0xD8 => {:cld, :implicit, 2},
    
    # CLI - Clear Interrupt Disable
    0x58 => {:cli, :implicit, 2},
    
    # CLV - Clear Overflow Flag
    0xB8 => {:clv, :implicit, 2},
    
    # CMP - Compare Accumulator
    0xC9 => {:cmp, :immediate, 2},
    0xC5 => {:cmp, :zero_page, 3},
    0xD5 => {:cmp, :zero_page_x, 4},
    0xCD => {:cmp, :absolute, 4},
    0xDD => {:cmp, :absolute_x, 4}, # +1 if page crossed
    0xD9 => {:cmp, :absolute_y, 4}, # +1 if page crossed
    0xC1 => {:cmp, :indexed_indirect, 6},
    0xD1 => {:cmp, :indirect_indexed, 5}, # +1 if page crossed
    
    # CPX - Compare X Register
    0xE0 => {:cpx, :immediate, 2},
    0xE4 => {:cpx, :zero_page, 3},
    0xEC => {:cpx, :absolute, 4},
    
    # CPY - Compare Y Register
    0xC0 => {:cpy, :immediate, 2},
    0xC4 => {:cpy, :zero_page, 3},
    0xCC => {:cpy, :absolute, 4},
    
    # DEC - Decrement Memory
    0xC6 => {:dec, :zero_page, 5},
    0xD6 => {:dec, :zero_page_x, 6},
    0xCE => {:dec, :absolute, 6},
    0xDE => {:dec, :absolute_x, 7},
    
    # DEX - Decrement X Register
    0xCA => {:dex, :implicit, 2},
    
    # DEY - Decrement Y Register
    0x88 => {:dey, :implicit, 2},
    
    # EOR - Exclusive OR
    0x49 => {:eor, :immediate, 2},
    0x45 => {:eor, :zero_page, 3},
    0x55 => {:eor, :zero_page_x, 4},
    0x4D => {:eor, :absolute, 4},
    0x5D => {:eor, :absolute_x, 4}, # +1 if page crossed
    0x59 => {:eor, :absolute_y, 4}, # +1 if page crossed
    0x41 => {:eor, :indexed_indirect, 6},
    0x51 => {:eor, :indirect_indexed, 5}, # +1 if page crossed
    
    # INC - Increment Memory
    0xE6 => {:inc, :zero_page, 5},
    0xF6 => {:inc, :zero_page_x, 6},
    0xEE => {:inc, :absolute, 6},
    0xFE => {:inc, :absolute_x, 7},
    
    # INX - Increment X Register
    0xE8 => {:inx, :implicit, 2},
    
    # INY - Increment Y Register
    0xC8 => {:iny, :implicit, 2},
    
    # JMP - Jump
    0x4C => {:jmp, :absolute, 3},
    0x6C => {:jmp, :indirect, 5},
    
    # JSR - Jump to Subroutine
    0x20 => {:jsr, :absolute, 6},
    
    # LDA - Load Accumulator
    0xA9 => {:lda, :immediate, 2},
    0xA5 => {:lda, :zero_page, 3},
    0xB5 => {:lda, :zero_page_x, 4},
    0xAD => {:lda, :absolute, 4},
    0xBD => {:lda, :absolute_x, 4}, # +1 if page crossed
    0xB9 => {:lda, :absolute_y, 4}, # +1 if page crossed
    0xA1 => {:lda, :indexed_indirect, 6},
    0xB1 => {:lda, :indirect_indexed, 5}, # +1 if page crossed
    
    # LDX - Load X Register
    0xA2 => {:ldx, :immediate, 2},
    0xA6 => {:ldx, :zero_page, 3},
    0xB6 => {:ldx, :zero_page_y, 4},
    0xAE => {:ldx, :absolute, 4},
    0xBE => {:ldx, :absolute_y, 4}, # +1 if page crossed
    
    # LDY - Load Y Register
    0xA0 => {:ldy, :immediate, 2},
    0xA4 => {:ldy, :zero_page, 3},
    0xB4 => {:ldy, :zero_page_x, 4},
    0xAC => {:ldy, :absolute, 4},
    0xBC => {:ldy, :absolute_x, 4}, # +1 if page crossed
    
    # LSR - Logical Shift Right
    0x4A => {:lsr, :accumulator, 2},
    0x46 => {:lsr, :zero_page, 5},
    0x56 => {:lsr, :zero_page_x, 6},
    0x4E => {:lsr, :absolute, 6},
    0x5E => {:lsr, :absolute_x, 7},
    
    # NOP - No Operation
    0xEA => {:nop, :implicit, 2},
    
    # ORA - Logical Inclusive OR
    0x09 => {:ora, :immediate, 2},
    0x05 => {:ora, :zero_page, 3},
    0x15 => {:ora, :zero_page_x, 4},
    0x0D => {:ora, :absolute, 4},
    0x1D => {:ora, :absolute_x, 4}, # +1 if page crossed
    0x19 => {:ora, :absolute_y, 4}, # +1 if page crossed
    0x01 => {:ora, :indexed_indirect, 6},
    0x11 => {:ora, :indirect_indexed, 5}, # +1 if page crossed
    
    # PHA - Push Accumulator
    0x48 => {:pha, :implicit, 3},
    
    # PHP - Push Processor Status
    0x08 => {:php, :implicit, 3},
    
    # PLA - Pull Accumulator
    0x68 => {:pla, :implicit, 4},
    
    # PLP - Pull Processor Status
    0x28 => {:plp, :implicit, 4},
    
    # ROL - Rotate Left
    0x2A => {:rol, :accumulator, 2},
    0x26 => {:rol, :zero_page, 5},
    0x36 => {:rol, :zero_page_x, 6},
    0x2E => {:rol, :absolute, 6},
    0x3E => {:rol, :absolute_x, 7},
    
    # ROR - Rotate Right
    0x6A => {:ror, :accumulator, 2},
    0x66 => {:ror, :zero_page, 5},
    0x76 => {:ror, :zero_page_x, 6},
    0x6E => {:ror, :absolute, 6},
    0x7E => {:ror, :absolute_x, 7},
    
    # RTI - Return from Interrupt
    0x40 => {:rti, :implicit, 6},
    
    # RTS - Return from Subroutine
    0x60 => {:rts, :implicit, 6},
    
    # SBC - Subtract with Carry
    0xE9 => {:sbc, :immediate, 2},
    0xE5 => {:sbc, :zero_page, 3},
    0xF5 => {:sbc, :zero_page_x, 4},
    0xED => {:sbc, :absolute, 4},
    0xFD => {:sbc, :absolute_x, 4}, # +1 if page crossed
    0xF9 => {:sbc, :absolute_y, 4}, # +1 if page crossed
    0xE1 => {:sbc, :indexed_indirect, 6},
    0xF1 => {:sbc, :indirect_indexed, 5}, # +1 if page crossed
    
    # SEC - Set Carry Flag
    0x38 => {:sec, :implicit, 2},
    
    # SED - Set Decimal Flag
    0xF8 => {:sed, :implicit, 2},
    
    # SEI - Set Interrupt Disable
    0x78 => {:sei, :implicit, 2},
    
    # STA - Store Accumulator
    0x85 => {:sta, :zero_page, 3},
    0x95 => {:sta, :zero_page_x, 4},
    0x8D => {:sta, :absolute, 4},
    0x9D => {:sta, :absolute_x, 5},
    0x99 => {:sta, :absolute_y, 5},
    0x81 => {:sta, :indexed_indirect, 6},
    0x91 => {:sta, :indirect_indexed, 6},
    
    # STX - Store X Register
    0x86 => {:stx, :zero_page, 3},
    0x96 => {:stx, :zero_page_y, 4},
    0x8E => {:stx, :absolute, 4},
    
    # STY - Store Y Register
    0x84 => {:sty, :zero_page, 3},
    0x94 => {:sty, :zero_page_x, 4},
    0x8C => {:sty, :absolute, 4},
    
    # TAX - Transfer Accumulator to X
    0xAA => {:tax, :implicit, 2},
    
    # TAY - Transfer Accumulator to Y
    0xA8 => {:tay, :implicit, 2},
    
    # TSX - Transfer Stack Pointer to X
    0xBA => {:tsx, :implicit, 2},
    
    # TXA - Transfer X to Accumulator
    0x8A => {:txa, :implicit, 2},
    
    # TXS - Transfer X to Stack Pointer
    0x9A => {:txs, :implicit, 2},
    
    # TYA - Transfer Y to Accumulator
    0x98 => {:tya, :implicit, 2}
  }
  
  @doc """
  Gets instruction information for an opcode.
  """
  def get_instruction(opcode) do
    Map.get(@instructions, opcode, {:unknown, :implicit, 2})
  end
  
  @doc """
  Gets all valid opcodes.
  """
  def valid_opcodes do
    Map.keys(@instructions)
  end
  
  @doc """
  Checks if an opcode is valid.
  """
  def valid_opcode?(opcode) do
    Map.has_key?(@instructions, opcode)
  end
  
  @doc """
  Gets instruction name from opcode.
  """
  def instruction_name(opcode) do
    case get_instruction(opcode) do
      {name, _, _} -> name
      _ -> :unknown
    end
  end
  
  @doc """
  Gets addressing mode from opcode.
  """
  def addressing_mode(opcode) do
    case get_instruction(opcode) do
      {_, mode, _} -> mode
      _ -> :implicit
    end
  end
  
  @doc """
  Gets base cycle count from opcode.
  """
  def cycle_count(opcode) do
    case get_instruction(opcode) do
      {_, _, cycles} -> cycles
      _ -> 2
    end
  end
end