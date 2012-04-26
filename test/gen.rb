require 'minitest/autorun'
require 'wrong/adapters/minitest'

require 'rbpic/gen'


# Not all test ASM fragments need to be valid code.
class GenTest < MiniTest::Unit::TestCase


  def test_header
    header = ["\t#include \"p10f202.inc\"",
              "\t__config _WDT_OFF & _CP_OFF & _MCLRE_OFF",
              "\torg\t0x00",
              "\tgoto\t$+2",
              "Four_microsecond_delay"]

    asm = RbPIC::RSM.load { }

    header.each { |line| assert { asm.include? line } }
  end

  
  def test_constant_block
    constants = ["\tcblock 0x08",
                 "\t\tconstant1",
                 "\t\tconstant2",
                 "\tendc"]

    asm = RbPIC::RSM.load do
      constants do
        constant1
        constant2
      end
    end

    constants.each { |line| assert { asm.include? line } }
  end


  def test_init_clock
    init = ["\tmovwf\tOSCCAL",
            "\tmovlw\tb'10011000'",
            "\toption"]

    asm = RbPIC::RSM.load do
      init_clock
    end

    init.each { |line| assert { asm.include? line } }
  end

  
  def test_config_io_all_out
    config_io = ["\tmovlw\tb'00000000'",
                 "\ttris\tGPIO"]

    asm = RbPIC::RSM.load do
      config_io(:gp0 => :out, :gp1 => :out, :gp2 => :out, :gp3 => :out)
    end

    config_io.each { |line| assert { asm.include? line } }
  end


  def test_config_io_all_in
    config_io = ["\tmovlw\tb'00001111'",
                 "\ttris\tGPIO"]

    asm = RbPIC::RSM.load do
      config_io(:gp0 => :in, :gp1 => :in, :gp2 => :in, :gp3 => :in)
    end

    config_io.each { |line| assert { asm.include? line } }
  end


  def test_config_io_partial
    config_io = ["\tmovlw\tb'00001100'",
                 "\ttris\tGPIO"]

    asm = RbPIC::RSM.load do
      config_io(:gp0 => :out, :gp1 => :out, :gp2 => :in, :gp3 => :in)
    end

    config_io.each { |line| assert { asm.include? line } }
  end


  def test_set
    set = ["\tmovlw\t0x23",
           "\tmovwf\tconstant0"]

    asm = RbPIC::RSM.load do
      constants { constant0 }
      set(:constant0, 0x23)
    end

    set.each { |line| assert { asm.include? line } }
  end


  def test_loop
    loop = ["Main",
            "\tmovlw\t0x23",
            "\tmovwf\tfoo",
            "\tgoto\tMain"]

    asm = RbPIC::RSM.load do
      loop(:main) { set(:foo, 0x23) }
    end

    loop.each { |line| assert { asm.include? line } }
  end


  def test_block
    block = ["Test_block",
             "\tmovlw\t0x23",
             "\tmovwf\tfoo"]

    asm = RbPIC::RSM.load do
      block(:test_block) { set(:foo, 0x23) }
    end

    block.each { |line| assert { asm.include? line } }
  end


  def test_set_io_hi
    set_io = "\tbsf\tGPIO, 0"

    asm = RbPIC::RSM.load do
      set_io(:gp0 => :hi)
    end

    assert { asm.include? set_io }
  end


  def test_set_io_lo
    set_io = "\tbcf\tGPIO, 0"

    asm = RbPIC::RSM.load do
      set_io(:gp0 => :lo)
    end

    assert { asm.include? set_io }
  end


  def test_set_bit
    set_bit = "\tbsf\tfoo, 0x1"
    
    asm = RbPIC::RSM.load do
      set_bit(:foo, 1)
    end

    assert { asm.include? set_bit }
  end


  def test_clear_bit
    clear_bit = "\tbcf\tfoo, 0x2"

    asm = RbPIC::RSM.load do
      clear_bit(:foo, 2)
    end

    assert { asm.include? clear_bit }
  end


  def test_test
    test = ["\tbtfss\tfoo, 0x1",
            "\tgoto\tTest_test"]

    asm = RbPIC::RSM.load do
      test(:foo, 1, :test_test)
    end

    test.each { |line| assert { asm.include? line } }
  end


  def test_decrement_by
    decrement_by = ["\tmovlw\t0x5",
                    "\tsubwf\tfoo, f"]

    asm = RbPIC::RSM.load do
      decrement_by(5, :foo)
    end

    decrement_by.each { |line| assert { asm.include? line } }
  end


  def test_increment_by
    increment_by = ["\tmovlw\t0x7",
                    "\taddwf\tfoo, f"]

    asm = RbPIC::RSM.load do
      increment_by(7, :foo)
    end

    increment_by.each { |line| assert { asm.include? line } }
  end


  def test_copy
    copy = ["\tmovf\tfoo, w",
            "\tmovwf\tbar"]

    asm = RbPIC::RSM.load do
      copy(:foo, :bar)
    end
  end

  
  def test_test_carry
    test_carry = ["\tbtfss\tSTATUS, 0",
                  "\tgoto\tTest_test_carry"]

    asm = RbPIC::RSM.load do
      test_carry(:test_test_carry)
    end

    test_carry.each { |line| assert { asm.include? line } }
  end


  def test_add
    add = ["\tmovlw\t0x3",
           "\taddwf\tfoo, w"]

    asm = RbPIC::RSM.load do
      add(3, :foo)
    end

    add.each { |line| assert { asm.include? line } }
  end


  def test_subtract
    subtract = ["\tmovlw\t0x5",
                "\tsubwf\tfoo, w"]

    asm = RbPIC::RSM.load do
      subtract(5, :foo)
    end

    subtract.each { |line| assert { asm.include? line } }
  end


  def test_subtract_and_set
    subtract_and_set = ["\tmovf\tfoo, w",
                        "\tsubwf\tbar, f"]

    asm = RbPIC::RSM.load do
      subtract_and_set(:foo, :bar)
    end

    subtract_and_set.each { |line| assert { asm.include? line } }
  end

  
  def test_delay
    delay = "\tcall\tFour_microsecond_delay"

    asm = RbPIC::RSM.load do
      delay(4.0e-6)
    end

    assert { asm.include? delay }
  end


  def test_decrement_and_test
    decrement_and_test = ["\tdecfsz\tfoo, f",
                          "\tgoto\tTest_decrement_and_test"]

    asm = RbPIC::RSM.load do
      decrement_and_test(:foo, :jump, :test_decrement_and_test)
    end

    decrement_and_test.each { |line| assert { asm.include? line } }
  end


  def test_jump
    jump = "\tgoto\tTest_jump"

    asm = RbPIC::RSM.load do
      jump(:test_jump)
    end

    assert { asm.include? jump }
  end


  def test_increment
    increment = "\tincf\tfoo, f"

    asm = RbPIC::RSM.load do
      increment(:foo)
    end

    assert { asm.include? increment }
  end


  def test_decrement
    decrement = "\tdecf\tfoo, f"

    asm = RbPIC::RSM.load do
      decrement(:foo)
    end

    assert { asm.include? decrement }
  end


  def test_subroutine_call
    subroutine_call = "\tcall\tTest_subroutine_call"

    asm = RbPIC::RSM.load do
      test_subroutine_call
    end

    assert { asm.include? subroutine_call }
  end
end
