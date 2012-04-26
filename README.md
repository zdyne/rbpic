rbpic
=====

Syntactic sugar for writing assembly that targets Microchip PIC10
processors.

History
-------

In 2006 I made a small circuit to drive an RGB LED through a "random"
sequence of colors. I found writing PIC assembly to be tedious and not
all that much fun, especially when the code, compile, run cycle
included unseating a small IC from a DIP socket, programming it and
then (carefully) reseating it. I didn't want to purchase a
C compiler license since this was a hobby project, but I *did* want to
learn how to write my own DSL in Ruby. Armed with the *Pickaxe* book
and Google Code Search I figured out how to use `instance_eval` to
make it all work.

Limitations
-----------

* I only needed to target one microcontroller (PIC10F202) and that is
  what is in the code. I tried to make it obvious where to add
  functionality for other members of the PIC10 family.
* The emitted assembly is likely PIC10-specific and may not work
  with the other families of chips.
* There are some processor-specific configuration flags that are
  hard-coded.
* A lot of assembly concepts bled into the resulting DSL. To this end,
  it's best to think of rbpic as a *slightly easier* version of
  PIC assembly.
* While the output assembly seems to work well, it's not optimized at
  all. (Any perceived optimization is coincidental at best.)
  
Usage
-----

    rbpic-compile [-S] <script.rsm>

`rbpic-compile` will output the compiled assembly as `<script.asm>` in
addition to invoking
[`mpasmx`](http://www.microchip.com/pagehandler/en-us/family/mplabx/)
to generate `<script.hex>`. If you are on a platform where `mpasmx`
doesn't run or you don't want to install it, the `-S` option outputs
the compiled assembly only.

DSL Syntax
----------

* `constants(&block)`

  > A block that defines a set of global varibles that can be
    referenced later using other routnes. (This is how you add
    "variables" to your assembly.)

* `init_clock`

  > Copies the oscillator calibration value into the `OSCCAL`
    register. Configures the `OPTION` register. This must be the first
    call in your script, if you choose to use it, or else it is
    possible that the `W` register will be overwritten and a bad value
    will be copied into the `OSCCAL` register.
    
* `subr(label, &block)`

  > Creates a new subroutine. There is a limit to the number of
    nested subroutine calls that can be made. The PIC10F202 has a
    2-deep stack. If you go beyond this limit, the processor is happy
    to comply by dropping the oldest return values. The compiler does
    not currently prevent this from happening.
    
* `done(W)`

  > Returns from the current subroutine and sets the `W` register to
    the specified value. Currently, you must add this call to the end
    of your `subr` block. Future versions of `subr` should do this
    automatically.
    
* `config_io({port, state})`

  > Configure the GPIO tristate register. Takes a hash mapping ports
    (`:gp0`, etc.) to their state (`:out`, etc.). This routine is
    highly coupled to the GPIO module in the PIC10F2xx series as it
    only supports exactly 4 GPIO pins. (Bigger PIC processors have
    multiple I/O ports with up to 8 pins per port!)
    
    
* `set(sym, val)`

  > Sets a symbol previous defined in `constants` to the specfied
    value.
    
* `loop(label, &block)`

  > Creates a loop named `label` whose implementation is in
    `block`. One suggested convention is to have a top-level loop
    called 'main'.
    
* `block(label, &block)`

  > Similar to `loop` but does not `goto` the loop label at the end of
    the block. Mostly used to logically group code together with a
    useful name.
    
* `set_io({port, value})`

  > Sets the specified `port` to `value` where `value` is either `:hi`
    or `:lo`. This routine is aware that `:gp3` on the PIC10F202 is an
    input-only port and won't let you set it.
    
* `set_bit(var, bit)`

  > Sets the specified `bit` in `var`.
  
* `clear_bit(var, bit)`

  > Clears the specified `bit` in `var`.
  
* `test(var, bit, target)`

  > Tests the specified `bit` in `val` and, counterintuitively, if it
    isn't set then jumps to the `target` label.

* `decrement_by(val, sym)`

  > Decrements `sym` by `val`.
  
* `increment_by(val, sym)`

  > Increments `sym` by `val`.

* `copy(from, to)`

  > Copies the value in `from` to `to`.

* `test_carry(target)`

  > Tests the carry bit of the `STATUS` register and jumps to the
    `target` label if it is clear.
    
* `add(val, to)`

  > Adds `val` to the symbol `to`.
  
* `subtract(val, from)`

  > Subtracts `val` from `from`.
  
* `subtract_and_set(sym, from)`

  > Subtracts the value of `sym` from `from`.
  
* `delay(secs)`

  > Delays execution for `secs` seconds. The compiler automatically
    creates a subroutine called `Four_microsecond_delay`, which relies
    on the fact that a single cycle takes 1 μs for a PIC10F202 running
    at 4 Mhz. Your mileage may vary. The code generated by this
    routine is also very space inefficient as it splats out (`secs` /
    4 μs) number of calls to `Four_microsecond_delay`.
    
* `decrement_and_test(var, *ops)`

  > Decrement `var` and test if it is zero. If `var` is non-zero,
    `*ops` is executed, where `*ops` should be a set of arguments that
    will be interpolated as the next line of RSM: `:jump,
    :some_label`, for instance.
    
* `jump(label)`

  > Goto the specified `label`.
  
* `increment(var)`

  > Increments `var` by one.
  
* `decrement(var)`

  > Decrements `var` by one.

* `<subroutine name>`

  > Calls the subroutine.

Examples
--------

The `examples/` directory contains a few basic samples of
RSM. More complex examples are not useful without having the complete
hardware package.

The Future
----------
  
* PIC18 support
* Cleaning up the DSL syntax / making it more idiomatic

References
----------

* [MPASM(TM) Assembler, MPLINK(TM) Object Linker, MPLIB(TM) Object
  Librarian User's
  Guide](http://ww1.microchip.com/downloads/en/DeviceDoc/33014J.pdf)
* [PIC10F200/202/204/206 Data
  Sheet](http://ww1.microchip.com/downloads/en/DeviceDoc/41239D.pdf)

Legalese
--------

License: BSD (see included LICENSE file)

Copyright (c) 2006-2012, Patrick J. Franz
