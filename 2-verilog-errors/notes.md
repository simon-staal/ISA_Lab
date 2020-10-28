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
testbench completing successfully. However, the `clock_enable` functionality has not
been tested in this testbench.

Adding this functionality testing into the testbench shows that the module works as expected.

**v4**
Compiling the testbench results in no compiler warnings. Looking at the logic used
inside *or_gate.v*, we can notice that r is combinatorially assigned to potentially
multiple times in the same path which is BAD. Replacing all the garbage logic with
the simple combinatorial assignment `r = a|b` leads the testbench to compiling and
running successfully.

I don't know why the module is called *or_gate.v* instead of *or.v* and it's dumb
as fuck imo. The style of the module was dogshit and hurt my soul.

**v5**
After running and generating the waveform for the testbench, I noticed that the cin
into the 4-bit adder caused an increase of 8 instead of an increse of 1. This indicates
that the cin value is being fed into the MSB adder in our 4-bit adder, resulting in
the inccorect sum being calculated. Looking at *add4.v* we can see this is the case, as
the cin value into the adder is being used as the cin for the adder performing the MSB calculation.

After reversing the way *carry[4:0]* is treated in the 4-bit adder, and re-compiling
/ running the testbench we can now see that the adder works as intended.

Using the same testbenching strategy of testing every possible combination would not work
for a 32-bit adder. For a 4-bit adder this method uses 2^9 combinations (4 + 4 + 1)
but for a 32-bit adder it would require 2^65 combinations (3.7e19) which would take
too long to calculate (and would more than likely overflow the container for i)

To create a 32-bit adder from full-adders, I used the following generate loop:
```
genvar i;
generate
    for(i = 0; i < 32; i=i+1) begin
        fadd faddi(a[i],b[i],carry[i],sum[i],carry[i+1]);
    end
endgenerate
```
This should hopefully create 32 instances of fadders to perform the calculations on
each bit.

To test this module I copied the testbench for the 4-bit adder, which will only test
the first 512 combinations of inputs.
The testbench initially failed the assertions, and after opening the waveform I
noticed this was because the the checks performed using true_sum hadn't been updated
to work for 32 bits. The conditions were updated to the following:
```
assert( (true_sum & 32'hFFFFFFFF) == sum );
assert( (true_sum >> 32) == cout );
```
This now led the testbench to compile and run successfully.

One final test I wanted to run was to check if the adder worked for the largest
possible values of a, b and cin:
```
//Test max values
a = 32'hFFFFFFFF;
b = 32'hFFFFFFFF;
cin = 1;
#1;
assert( 32'hFFFFFFFF == sum );
assert( 1 == cout );
```
This test also ran successfully.

**v6**
Looking through the test bench, everything seems to make sense and after compiling
and running the testbench everything works fine. However, upon closer inspection,
the repeat loop happens 1 too few times. After updating the repeat value to 2^16
in order to exhaustively test every possibility, I re-compiled and ran the testbench.
After visualising the waverform, the bug was revealed, both the *count* and *count_ref*
values for *x = 0xFFFF* were 0 instead of 16. *count_ref* is stored in a 4-bit logic
instead of a 5-bit logic, so the value overflows. After fixing this issue in the
testbench, I re-compiled and ran the testbench:
```
FATAL: hamming16_tb.v:29: Mis-match : x=1111111111111111, count= 0, count_ref=16
       Time: 65536 Scope: hamming16_tb
```
We can now see that the test-bench correctly identifies the issue in hamming16_t.
Looking inside *hamming16.v* we can see that the bug arises from the same overflow
issue that was present in the testbench, as *count_sum* is also stored in a 4-bit
logic instead of 5-bit. After fixing this issue, our testbench now compiles and
runs sucessfully.

From this we can see the risk of having the same person design the circuit and testbench,
as any of these 'carry-over' errors can lead to being unable to recognise flaws in design.
It is less likely for 2 people to make the same oversight of making the *count* logic
too small, hopefully catching out the error. The advantage of this heirarchal composition
style is that it allows you to build in complexity more easily, constructing more
complex components out of simpler components rather than building complex components
from scratch.

Testbenching for this component could be done instead for particular values of count.
This bug in the testbenching would have been avoided if intead of running through
combination an input was generated for each possible value of count (0-16) to ensure
that the component can correctly identify every possible value. This approach is
particularly relevant for larger components (32-bit+) where exhaustively testing
every possiblity becomes impossible.

**v7**
Running and compiling the testbench outputs the following errors:
```
ERROR: add_sub_logic_tb.v:35:
       Time: 5 Scope: add_sub_logic_tb
ERROR: add_sub_logic_tb.v:45:
       Time: 7 Scope: add_sub_logic_tb
ERROR: add_sub_logic_tb.v:49:
       Time: 8 Scope: add_sub_logic_tb
```
The first error corresponds to the following snippet (line 35):
```
op=2; a=7;  b=11;
#1;
assert(!r);
```
This operation is meant to output r = ~b, which in this case would mean r=0xFFF4
This clearly shows that the assert is incorrect, and should be changed to
`assert(r == 16'hFFF4)` or ~~`assert(!r == 11)`~~ <-(doesn't work)

After updating the snippet to:
```
op=2; a=7;  b=11;
#1;
assert(r==16'hfff4);
```
Our testbench now outputs:
```
ERROR: add_sub_logic_tb.v:45:
       Time: 7 Scope: add_sub_logic_tb
ERROR: add_sub_logic_tb.v:49:
       Time: 8 Scope: add_sub_logic_tb
```
Indicating that we have solved the line 35 issue. The following error (line 45)
corresponds to:
```
op=3; a=3; b=10;
#1;
assert(r==16'hfff5);
```
Looking at our ALU we can see that *op=3* should return the cout of the operation
a-b (equivalent to a>b), meaning that r should be equal to 0 in this case as the carry out of the
operation will be 0. Replacing the assert condition with `assert(r==0)` or
`assert(!r)` solves this issue.
We can observe a similar issue for the final error, corresponding to line 49:
```
op=3; a=10; b=3;
#1;
assert(r==16'hfffC);
```
Where this time the carry-out of the operation will be equal to 1, so the assert
condition should be `assert(r==1)`
After having made these changes the testbench compiles and runs successfully.

Assuming that the purpose of op=3 is a>b, an interesting edge-case is presented
when a = b. In these cases, there is going to be a *cout=1*, so this operation
might instead be a>=b. Additionally, this operation doesn't for -ve values of a or b
where the 2s complement encoding causes weird behaviour, for example:
```
op=3; a=12; b=-1;
#1;
assert(r==1);
```
causes an error in the testbench, where intuitively the operation should return 0.

For these situations where it is unclear if the testbench or original module is
incorrect, it is important to refer back to the purpose of the module (which would've
been good to know here...)

When testbenching complex components like ALUs, it's important to consider the
widest possible variety of input cases, and write testbenches which incorporate these.
Edge cases such as -ve inputs, 0 inputs, or MAX_SIZE inputs are all important cases
to consider when testing these componennts.
