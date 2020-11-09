Notes on code and infrastructure
================================
These notes aim to document my process in going through all the files contained
in the directory, including the verilog implementation of the cpu as well as all
the files used in the testing of the cpu.

scr files
---------
All files in this directory are verilog files describing circuits and testbenches.

**General CPU_MU0 Notes**
Both the delay0 and delay1 implementations of the MU0 CPU share a lot of similar
features.
They have a booleans clk and reset as an input, as well as a 16-bit
readdata likely carrying data into the CPU from memory. As outputs, they have
booleans running, write and read, as well as a 12-bit address output and a 16-bit
write-data output. These 2 outputs suggest that the CPU uses a 16x4096 RAM to run,
which is supported by the RAM verilog filenames.


The instructions they are capable of running are as follows:
```
STP 0111 stop
JNE S 0110 if ACC ≠ 0, PC := S
JGE S 0101 if ACC > 0, PC := S
JMP S 0100 PC := S
SUB S 0011 ACC := ACC – mem[S]
ADD S 0010 ACC := ACC + mem[S]
STO S 0001 mem[S] := ACC
LDA S 0000 ACC := mem[S]
OUT S 1000 print(Acc)
```
The `enum` type, which defines a specific set of values, is used to define these
4-bit opcodes as a new type `opcode_t`. Note that the older C-like syntax is used
to define types:
```
typedef enum logic[3:0] {
  ...
} opcode_t;
```
Similar logic is used to define the CPU states (differences between delay0 / 1).
*Note that state is 2-bits for delay0 and 3-bits for delay1*

Some intermediary logic is then defined:
- 12-bit pc and pc_next
- 16-bit acc
- 17-bit instr
- opcode_t instr_opcode
- 12-bit instr_constant
- 2-bit state *This should probably be 3-bits for delay1, likely an error*

**delay0 Implementation**
The states in the delay0 cpu are as follows:
- FETCH_INSTR (00)
- EXEC_INSTR (01)
- HALTED (10)

*The following assignments are all continuous*
If the state of the CPU is FETCH_INSTR, address is set to the value of pc,
else it is set to the value of the instr_constant.

If the state of the CPU is EXEC_INSTR, write is set to 1 if it's a STO instruction,
otherwise it's set to 0.

read is set to 1 if the state of the CPU is FETCH_INSTR or if it's an LDA, ADD or
SUB instruction.

writedata is set to the value of acc

instr is split into instr_opcode (15:12) and instr_constant (11:0) for convenience.

12-bit logic pc_increment is declared and set to pc+1

*initial loop*
The state is set to HALTED and running is set to 0 to show the CPU is not running.
Since we are targetting an FPGA, we can specify the power-on values of the system,
meaning that if these are not specified the computer is off.

*always @(posedge clk) loop*
For some reason always_ff is not used (bad style?)
This loop is made up of many if statements which perform the following:
If rst:
- state is set to FETCH_INSTR
- pc is set to 0
- acc is set to 0
- running is set to 1

If state==FETCH_INSTR:
- intr is set to readdata
- state is updated to EXEC_INSTR

If state==EXCEC_INSTR:
- Different operations are performed depending on the opcode using `case` syntax
- Each case must update the state and pc, as well as perform all the operations
  required by each instruction.
- STO does seemingly nothing because write and writedata are contiuously assigned
  This assignment is probably done since the RAM is combinatorial
- *BUG in JGE:* updates the value of pc to acc instead of instr_constant

If state==HALTED
- Does nothing (duh)

Else:
- Unexpected state encountered, displays errors and finishes

**delay1 implementation**
The states in the delay1 implementation are as follows:
- FETCH_INSTR_ADDR (000)
- FETCH_INSTR_DATA (001)
- EXEC_INSTR_ADDR (010)
- EXEC_INSTR_DATA (011)
- HALTED (100)
This indicates that there will be some potential errors in our cpu, as a 2-bit
state signal is used in the cpu. This means that we will be unable to represent
the halted state in the cpu.

*The following assignments are all continuous*
address is set to pc if the state is FETCH_INSTR_ADDR, else the instr_constant.

write is set to 1 if the state is EXEC_INSTR_DATA and a STO instruction is being
performed, else 0.

read is set to 1 if the state is FETCH_INSTR_ADDR or if the state is EXEC_INSTR_ADDR
and an LDA, ADD or SUB is being performed (else 0).

Similarly to delay0:
- writedata is set to acc
- instr is split into instr_opcode (15:12) and instr_constant(11:0)
- pc_increment is created and set to pc+1
- state is set to halted in initial loop (*this is probably buggy*)

*always @(posedge clk) loop*
Similar to delay0, but with slightly different state changes:
If state==FETCH_INSTR_ADDR:
- state is updated to FETCH_INSTR_DATA

If state==FETCH_INSTR_DATA
- instr is updated to readdata
- state is updated to EXEC_INSTR_ADDR

If state==EXEC_INSTR_ADDR
- state is updated to EXEC_INSTR_DATA

If state==EXEC_INSTR_DATA
- case syntax is once again used to perform different instructions
- Similar bug to delay0 version for *JGE*
- Useful to note that the EXEC_INSTR_ADDR cycle is only needed for instructions
  that require data from RAM (i.e. LDA, ADD, SUB) and is useless for all other
  instructions.

**RAM Notes**
The RAM blocks are needed to run anything on our CPUs, as they will store all the
data associated with the instructions / values that our CPU operates on. It is
therefore no surprise that the inputs an outputs mesh with our CPU's:
- Boolean inputs clk, write and read
- 12-bit address input
- 16-bit writedata input
- 16-bit readdata output

`parameter RAM_INIT_FILE = ""` is used to allow us to load initial values into the
RAM by specifying a filename during module instantiation (more on this in testbench
notes).

The memory of the ram is then created using `reg [15:0] memory [4095:0]`, an array
containing 4096 16-bit regirsters.

*intial loop*
This loop initialises all the values in our RAM to 0 using a `for` loop. If the
RAM_INIT_FILE parameter is not empty, values are loaded into memory using
`$readmemh(RAM_INIT_FILE, memory)`
RAM_INIT_FILE must be of the form memory_file.mem, a text file containing hex values
seperated by whitespace.

*write path*
The write path for both RAMs (delay 0 and delay1) are synchronous, meaning they
are in an `always @(posedge clk)` loop (unsure why always_ff is not used). If
write is high, `memory[address] <= writedata`.

For *delay0* which has a combinatorial read path, readdata is continually assigned
to memory[address] if read is high, else don't care.

*delay 1* has a synchronous read path, and is implemented inside the sequential
loop, updating `readdata <= memory[address]` after performing any necessary writes.
*NOTE: read logic is not used, readdata is always updated to the value stored
in the address provided to the RAM*

**Testbench Notes**
