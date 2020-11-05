Notes on Implementation Logic
=============================
Brief notes detailing understanding of each of the modules + testbenches

Multiplier Iterative
--------------------
Implementation for a clocked 32 bit multiplier (64 bit output) with a valid_in
input to enable loading of new inputs, and a valid_out to indecate when the
calculation is complete.

**v0**
- Uses `always @(*)` instead of `always_comb`, worse style.
- Uses long multiplication technique, takes 32 (33?) cycles to complete
- Critical path would be `acc_next = acc + (mp[0] ? mc : 0)`

**v1**
- Similar style to v0
- Includes small optimisation to check if the multiplier is 0 to quickly finish
  the operation (i.e. can take less than 33 cycles to complete).
- Same critical path as v0

**v2**
- Uses `always_comb`, better style
- Splits the multiplication into 'chunks' for faster performance, takes up to
  9 cycles max to complete
- Critical path is now `acc_next = acc + mp_nibble * mc`, which multiplies a 32
  bit number by a 4 bit number (longer critical path than previous versions)
- Note: `assign mp_nibble = mp[3:0]` outside any loops continually updates the
  value of mp_nibble.

**v3**
- Performs entire operation in 1 cycle, performs entire multiplpication combinatorially
- Much faster perfromance than any other versions, but the critical path is
  significantly longer.
- Easiest version to understand, could present issues in chip area consumed to
  create component.

**Testbench**
- All clock control info contained in a seperate begin loop, each clock cycle takes
  20 units of time to complete, waits 5 time units before starting clock at start
  of simulation.
- In testing loop, changes / checks valid_in / valid_out 1 time unit after posedge
- First repeat loop tests multiplications of 0^2 to 99^2, lacks asserts() making this
  loop effectively useless.
- In second repeat loop, a and b start at 99, then 2 large values are added to them
  to generate pseudo-random values to test (not best approach)
- Displaying the result of each multiplication floods the output when running a
  testbench, so I commented these lines out.
- Displaying the time taken to perform multiplications is very useful to compare
  the time efficiency of different implementations.

Multiplier Parallel
-------------------
Implementation for a parallel multiplier, which uses registers to store the previous
inputs and outputs the result 1 cycle later.

**v0**
- In terms of chipspace / critical path, very similar to v3 of the iterative multiplier,
  takes 1 cycle to perform a 32 x 32 bit multiplication.

**v1**
- Creates 4 40-bit accumulators, which each store an 8 bit chunk of the multiplication.
  r then sums shifted versions of these outputs.
- Accumulators are 40 bits because it performs an 8 x 32 bit multiplication, then
  are scaled to fit the 64-bit output.
- Reduces the critical path of the module by a factor of 4, but also doubles the
  number of registers used.

**v2**
- Splits the inputs into the front 16 bits and the back 16 bits, then performs those
  multiplications (a_hi + a_lo)(b_hi + b_lo), then shifts those ouptuts appropriately
- Uses 4 32-bit accumulators instead of 4-40 bit accumulators, saving space, and
  performs 16 x 16 bit multiplication.
- Depending on how the 16 x 16 multiplication is performed, it should have a similar
  critical path to v1, whilst using smaller registers.
- Note that the sub values (a_hi, a_lo, b_hi, b_lo) are continually assigned, whilst
  the multiplied values are stored into FFs.

**v3**
- Similar implementation to v2, but instead of continually assigning the sub values,
  these values are stored into 16-bit registers sequentially. The sub-multiplications
  are then continually assigned, before being combined into r sequentially.
- This saves additional space, as now only 16 bit registers are needed, and the
  sub multiplications are performed 'combinatorially' and no longer need to be
  stored.
- Using an `always_comb` block in the sub multiplication would be better style
  for increased clarity.

**v4**
- Continually splits the inputs into 3 sub sections (10-bit, 11-bit, 11-bit = 32 bits)
- Performs 9 sub multiplications and stores the results into 64-bit registers,
  which are larger than required (22 bits should be sufficient to store any result)
- Shifts the results of these sub multiplications appropriately, then sums the results
  (if smaller registers were used the v2 combination approach could be used)
- This should reduce the critical path compared to previous implementations, but
  uses a much larger amount of space as so many large registers are needed. Using
  an appraoch similar to the v3 implementation could solve this issue
- Continually assigning inputs for a pipelined module is bad practice, we want these
  values to update every clock cycle.

**v5**
- Before even looking at the implementation, I noticed that this implementation
  was cripplingly slow when run in the testbench
- The implementation uses 33 * 3 signals, 66 64-bit and 33 32-bit.
- At the clock edge, it sets the values of mp[0] (64-bit) to a and mc[0] (32-bit)
  to b (both registers). It continually assigns acc[0] to 0.
- There is then a 32 cycle loop which does the following:
  - Sets `acc[i+1] = acc[i] + ((mc[i]&1) ? mp[i] : 0)`
    This adds the value of mp to acc, depending on the LSB of mc
  - Sets `mp[i+1] = mp[i]<<1`
    Effectively doubles the value of mp
  - Sets `mc[i+1] = mc[i]>>1`
    Allows us to look at the next bit of mc for our acc operation
- All assignments in this loop are done continually, i.e. should be performed in
  1 cycle.
- The output of acc[32] is then outputted as the result of the operation
- This essentialy copies the implementation of the iterative adder v0, but performs
  the entire operation in 1 cycle.
- The module can be thought of using a 32-bit register to store input b and a 64-bit
  register to store a. The rest of the signals in this module are combinatorial
  (except the output which updates each clock cycle), as the assignments are all
  continuous.
- Looking at the code, I'm not too sure why the runtime of this module is so slow,
  probably because I don't know exactly how a genvar loop is implemented in terms
  of digital logic without the `generate` and `endgenerate` blocks I used for the
  32-bit adder.

**Testbench**
- This testbench has a clock rate of 10 time units (ns) per cycle (double speed
  of iterative) It does not contain an exit condition for a certain number of
  cycles, instead running infinitely (this is why the v5 testbench runs for sooo
  long without terminating)
- This testbench runs many more loops than the iterative one (100 vs 10000)
- It uses the adding method from the iterative testbench to produce pseudo-random
  numbers, storing inputs from the 2 previous cycles.
- It then checks the outputs from the inputs provided 2 cycles earlier. This is because
  it takes 1 cycle for the multiplier to take in the input and 1 cycle to produce
  the output.
- The testbench does not output the runtime of each component, as in principle
  these should all take the same number of cycles to run (cpu-runtime is different)
- This testbench is more thorough than the previous one in terms of the number of
  inputs tested, but doesn't test the max input/output edge cases.
- Both testbenches could use `@(negedge clk)` when testing assertions / updating
  values, instead of using explicit time delays, but this is more of a question of
  style (afaik).

Register File
-------------
Implementation for a 16-bit register file containing 4 registers. Supports read
and write functionality. New syntax \`timescale 1ns/100ps specifies time scale
of the module (\#1 = 1ns) and the time precision, or what times will be rounded
to (100ps)

**v0**
- Combinatorially outputs the value stored in the register selected by read_index_a
  (represents mux gate). If reset is enabled 0 is outputted.
- `else read_data_a = 16'hxxxx` means that the output is set to an unknown /
  don't care 16-bit value, this branch should never be triggered.
- Assigns the incoming value at the next clock edge in the register selected by
  write_index if write_enable is high, or sets the value to 0 if reset is enabled.
- Uses 1-line if / else statements

**v1**
- Same logic as v0, but uses the [case statement](chipverify.com/verilog/verilog-case-statement)
  to represent the same logic.

**v2**
- This module uses `logic[15:0] regs[3:0]`, which creates an array containg 4 16-bit
  registers (I think).
- `logic[15:0] reg_0, reg_1` are used to bring the array signals out, allowing us
  to view them in waveforms, and are strictly for troubleshooting (will be optimised
  out in synthesis). I have commented these out.
- Uses `integer index` to loop through all registers in the array to reset them.
- Logic is fundementally the same to previous versions, written more concisely.

**v3**
- Uses chained ternary operators (why...) for *extremely legible* code. Please
  don't do this guys.

**Simple Testbench**
