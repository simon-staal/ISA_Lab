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
