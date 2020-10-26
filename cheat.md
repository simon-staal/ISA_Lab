Useful Commands / Shortcuts
===========================

**Compiling Verilog**
```bash
iverilog -Wall -g 2012 -s and_not_testbench -o and_not_testbench and_gate.v or_gate.v and_not_testbench.v
```
-   `-Wall` : Enable all warnings during compilation.
-   `-g 2012` : Use the 2012 revision of the Verilog language. This allows for
        additional language constructs compared with "classic" Verilog.
-   `-s and_not_testbench` : Specify that `and_not_testbench` should be the top-level module. In this case
        it could be inferred, but it does not hurt to specify explicitly.

**Writing Verilog Tips**
*always_comb*
-   Assignment done through blocking `r = a&b`
-   You should only assing to variables once on any path through the code

*always_ff*
-   Used for sequential logic, uses non-blocking asignment operator `a <= a_n`
-   Include `always_ff @(posedge clk)` to show asignment occurs at rising clock edge
-   You can combine combinatorial and sequential logic into a single sequential block

*Testbenches*
-   `$display` prints a formatted string similar to `printf`, %d for decimal %h for hex
-   `initial` block contains what is to be simulated, multiple can exist and will execute at the same time,
    however only one can actually run at the same time, do not have competing blocks that read and write
    from the same signals
-   _Delays:_ Timing controls
    - `#n;` : delay control - wait for `n` time units.
    - `@(posedge sig);` : event control - wait until a rising edge on `sig`.
    - `wait (expr);` wait statement - wait until expression `expr` is true.
-   It can be good to split blocks into timing and event driven blocks, i.e. timing and clock edges
-   `$finish` can be used to indicate a testbench has completed successfully (return 0)
It can be useful to split your test-bench into 4 parts:
1. Clock generator using initial, only block using explicit time delay
2. Tent-bench block using initial, sensitive to -ve clock edge containing checking of outputs and setting of inputs
3. The DUT module synchronus to the +ve clock edge
4. (Optional) Helper modules such as RAMs / counters, ideally synthesisable and sensetive to +ve clock edge

*Clocks*
-   Generate a fixed number of cycles using `repeat(n)` block
    ```
    repeat(1000) begin
        clk = 0;
        #1;
        clk = 1;
        #1;
    end
    ```
-   Use `$fatal` to exit simulation once required cycles are complete:
    `$fatal(2, "Test-bench has not completed after 1000 clock cycles. Giving up.");`
-   When testing assertions, it is good to test them at the negative clock edge to ensure any changes
    in logic have been completed (analagous to hold times)

*Verilog cheat-sheet: * https://www.cl.cam.ac.uk/teaching/1011/ECAD+Arch/files/SystemVerilogCheatSheet.pdf
