Bugfixing Notes
===============

**v1**
Obtained the following warnings when compiling:
```
add_one_tb.v:29: warning: Port 1 (x) of add_one expects 8 bits, got 9.
add_one_tb.v:29:        : Pruning 1 high bits of the expression.
add_one_tb.v:29: warning: Port 2 (y) of add_one expects 8 bits, got 9.
add_one_tb.v:29:        : Padding 1 high bits of the expression.
```
These warnings indicate that there is a mismatching in the size of the signals
feeding into the ports x and y, looking in the testbench, we can see that 9 bit
busses are used as inputs to our 8-bit adder, which is clearly an issue. After
updating the length of the logic to [7:0] and recompiling no warnings are printed.

Testbench ran successfully after this change

**v2**
Opening the waveform produced from the testbench shows the output q updating to
the value of d at the falling clock edge. When switching to *always_ff*, the following
warning is displayed when compiling:
```
ff.v:6 Warning: Synthesis requires the sensitivity list of an always_ff process
to only be edge sensitive. clk is missing a pos/negedge.
```
Adding *posedge* inside our @() removes this compiler error and enables the testbench
to run successfully

**v3**
Before compiling / running this test, I replaced the *always* to *always_ff*
Compiling provided the following warnings:
```
ff.v:7 Warning: Synthesis requires the sensitivity list of an always_ff process
to only be edge sensitive. clk is missing a pos/negedge.
ff.v:7 Warning: Synthesis requires the sensitivity list of an always_ff process
to only be edge sensitive. d is missing a pos/negedge.
```
The ff should only change values at the rising edge of the clk of `c` input.
`c` was changed to an `input logic` instead of just `input` and the @() was changed
to be only at the posedge of c.

After compiling without warnings and running the testbench, we obtain the follwing error:
```
ERROR: ff_tb.v:50:
       Time: 16 Scope: ff_tb
```
Opening the waveform output we can see that the output behaves as expected, so this
indicates there must be an incorrect `assert()` at line 50. This is the case, as
the value of q should not change since there has been no rising clk edge.

Recompiling and running the testbench after having fixed this assert leads to the
testbench completing successfully. However, the `ce` functionality has not been tested
in this testbench. 
