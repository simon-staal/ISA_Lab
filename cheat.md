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
