defmodule Elixir6502.CPU.Flags do
  @moduledoc """
  6502 CPU Status Register (P) flags.
  
  Bit layout:
  7 6 5 4 3 2 1 0
  N V - B D I Z C
  
  N = Negative flag
  V = Overflow flag
  - = Unused (bit 5, always 1)
  B = Break flag
  D = Decimal mode flag
  I = Interrupt disable flag
  Z = Zero flag
  C = Carry flag
  """
  
  import Bitwise
  
  defstruct [
    negative: false,        # N - bit 7
    overflow: false,        # V - bit 6
    break: false,           # B - bit 4
    decimal: false,         # D - bit 3
    interrupt_disable: false, # I - bit 2
    zero: false,            # Z - bit 1
    carry: false            # C - bit 0
  ]
  
  @type t :: %__MODULE__{
    negative: boolean(),
    overflow: boolean(),
    break: boolean(),
    decimal: boolean(),
    interrupt_disable: boolean(),
    zero: boolean(),
    carry: boolean()
  }
  
  @doc """
  Creates new flags with all flags cleared.
  """
  def new do
    %__MODULE__{}
  end
  
  @doc """
  Creates flags from a byte value.
  """
  def from_byte(byte) when is_integer(byte) and byte >= 0 and byte <= 255 do
    %__MODULE__{
      negative: (byte &&& 0x80) != 0,
      overflow: (byte &&& 0x40) != 0,
      break: (byte &&& 0x10) != 0,
      decimal: (byte &&& 0x08) != 0,
      interrupt_disable: (byte &&& 0x04) != 0,
      zero: (byte &&& 0x02) != 0,
      carry: (byte &&& 0x01) != 0
    }
  end
  
  @doc """
  Converts flags to a byte value.
  """
  def to_byte(%__MODULE__{} = flags) do
    (if flags.negative, do: 0x80, else: 0) |||
    (if flags.overflow, do: 0x40, else: 0) |||
    0x20 ||| # Bit 5 is always set
    (if flags.break, do: 0x10, else: 0) |||
    (if flags.decimal, do: 0x08, else: 0) |||
    (if flags.interrupt_disable, do: 0x04, else: 0) |||
    (if flags.zero, do: 0x02, else: 0) |||
    (if flags.carry, do: 0x01, else: 0)
  end
  
  @doc """
  Sets the negative and zero flags based on a value.
  """
  def set_nz(%__MODULE__{} = flags, value) do
    %{flags |
      negative: (value &&& 0x80) != 0,
      zero: value == 0
    }
  end
  
  @doc """
  Sets the carry flag.
  """
  def set_carry(%__MODULE__{} = flags, carry?) do
    %{flags | carry: carry?}
  end
  
  @doc """
  Sets the overflow flag.
  """
  def set_overflow(%__MODULE__{} = flags, overflow?) do
    %{flags | overflow: overflow?}
  end
  
  @doc """
  Sets the interrupt disable flag.
  """
  def set_interrupt_disable(%__MODULE__{} = flags, disable?) do
    %{flags | interrupt_disable: disable?}
  end
  
  @doc """
  Sets the decimal flag.
  """
  def set_decimal(%__MODULE__{} = flags, decimal?) do
    %{flags | decimal: decimal?}
  end
  
  @doc """
  Sets the break flag.
  """
  def set_break(%__MODULE__{} = flags, break?) do
    %{flags | break: break?}
  end
end