#
# Code generator for rbPIC.
#

module RbPIC

  VERSION = '1.0.0'

  class RSMConstant
    
    def initialize(code)
      @code = code
      @code << "\tcblock 0x08"
    end


    def method_missing(sym, *args)
      @code << "\t\t#{sym.to_s}"
    end

  end


  class RSM

    attr_reader :code


    def self.load(rsm=nil, &blk)
      c = RSM.new

      if block_given?
        c.instance_eval &blk
      else
        c.instance_eval IO.read(rsm), rsm
      end

      c.end_code
      c.code
    end


    def initialize
      @code = []

      _emit "\t\#include \"p10f202.inc\""
      _emit "\t__config _WDT_OFF & _CP_OFF & _MCLRE_OFF"
      _emit ''
      _emit "\torg\t0x00"
      # Skip over the delay routine
      _emit "\tgoto\t$+2"
      _emit ''
      # Create our default 4 microsecond delay routine
      subr(:four_microsecond_delay) { done 0 }
      _emit ''
    end


    def subr(label, &b)
      _emit "#{label.to_s.capitalize}"
      self.instance_eval(&b)
      _emit ''
    end


    def done(w)
      _emit "\tretlw\t0x#{w.to_s(16)}"
      _emit ''
    end


    def constants(&b)
      c = RSMConstant.new @code
      c.instance_eval &b
      
      _emit "\tendc"
      _emit ''
    end

    # The internal 4 MHz oscillator has a calibration value stored in
    # the last memory location. On device reset it is loaded into the W
    # register. init_clock moves the calibration value into the OSCCAL
    # register and configures the OPTION register as:
    #   ~GPWU: disabled
    #   ~GPPU: enabled
    #    T0CS: transition on internal instruction cycle clock
    #    T0SE: increment on high-to-low transition
    #     PSA: prescalar assigned to WDT
    # PS<2:0>: WDT rate 1:1
    def init_clock
      _emit "\tmovwf\tOSCCAL"
      _emit "\tmovlw\tb'10011000'"
      _emit "\toption"
      _emit ''
    end


    def config_io(pins)
      tris = 0
      
      pins.each do |pin, state|
        case pin
        when :gp0
          state == :out ? tris &= ~0x1 : tris |= 0x1

        when :gp1
          state == :out ? tris &= ~0x2 : tris |= 0x2

        when :gp2
          state == :out ? tris &= ~0x4 : tris |= 0x4

        when :gp3
          state == :out ? tris &= ~0x8 : tris |= 0x8
        end
      end

      _emit "\tmovlw\tb'#{tris.to_s(2).rjust(8, '0')}'"
      _emit "\ttris\tGPIO"
      _emit ''
    end


    def set(sym, val)
      _emit "\tmovlw\t0x#{val.to_s(16)}"
      _emit "\tmovwf\t#{sym.to_s}"
      _emit ''
    end


    def loop(label, &blk)
      block label, &blk
      _emit "\tgoto\t#{label.to_s.capitalize}"
      _emit ''
    end


    def block(label, &blk)
      _emit "#{label.to_s.capitalize}"
      self.instance_eval &blk
      _emit ''
    end


    def set_io(ports)
      ports.each do |p, state|
        case p
        when :gp0
          state == :hi ? _emit("\tbsf\tGPIO, 0") : _emit("\tbcf\tGPIO, 0")
        when :gp1
          state == :hi ? _emit("\tbsf\tGPIO, 1") : _emit("\tbcf\tGPIO, 1")
        when :gp2
          state == :hi ? _emit("\tbsf\tGPIO, 2") : _emit("\tbcf\tGPIO, 2")
        else
          abort "Invalid port #{p.to_s} specified"
        end
      end
      _emit ''
    end


    def set_bit(var, bit)
      _emit "\tbsf\t#{var.to_s}, 0x#{bit.to_s(16)}"
      _emit ''
    end


    def clear_bit(var, bit)
      _emit "\tbcf\t#{var.to_s}, 0x#{bit.to_s(16)}"
      _emit ''
    end


    def test(var, bit, target)
      _emit "\tbtfss\t#{var.to_s}, 0x#{bit.to_s(16)}"
      _emit "\tgoto\t#{target.to_s.capitalize}"
      _emit ''
    end


    def decrement_by(val, sym)
      _emit "\tmovlw\t0x#{val.to_s(16)}"
      _emit "\tsubwf\t#{sym.to_s}, f"
      _emit ''
    end


    def increment_by(val, sym)
      _emit "\tmovlw\t0x#{val.to_s(16)}"
      _emit "\taddwf\t#{sym.to_s}, f"
      _emit ''
    end


    def copy(from, to)
      _emit "\tmovf\t#{from.to_s}, w"
      _emit "\tmovwf\t#{to.to_s}"
      _emit ''
    end


    def test_carry(label)
      _emit "\tbtfss\tSTATUS, 0"
      _emit "\tgoto\t#{label.to_s.capitalize}"
      _emit ''
    end

    
    def add(val, to)
      _emit "\tmovlw\t0x#{val.to_s(16)}"
      _emit "\taddwf\t#{to.to_s}, w"
      _emit ''
    end

    
    def subtract(val, from)
      _emit "\tmovlw\t0x#{val.to_s(16)}"
      _emit "\tsubwf\t#{from.to_s}, w"
      _emit ''
    end


    def subtract_and_set(sym, from)
      _emit "\tmovf\t#{sym.to_s}, w"
      _emit "\tsubwf\t#{from.to_s}, f"
    end


    def delay(secs)
      # Number of 4 microsecond delays to do
      n = secs / 4.0e-6
      n.ceil.to_i.times do
        _emit "\tcall\tFour_microsecond_delay"
      end
      _emit ''
    end


    def decrement_and_test(var, *ops)
      _emit "\tdecfsz\t#{var.to_s}, f"
      self.send ops[0], ops[1]
      _emit ''
    end


    def jump(label)
      _emit "\tgoto\t#{label.to_s.capitalize}"
      _emit ''
    end


    def increment(var)
      _emit "\tincf\t#{var.to_s}, f"
      _emit ''
    end

    
    def decrement(var)
      _emit "\tdecf\t#{var.to_s}, f"
      _emit ''
    end


    def end_code
      _emit "\tend"
      _emit ''
    end


    def method_missing(sym)
      _emit "\tcall\t#{sym.to_s.capitalize}"
    end


    private

    
    def _emit(s)
      @code << s
    end
  end

end
