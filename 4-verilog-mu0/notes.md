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
RAM_INIT_FILE must be of the form memory_file.txt, a text file containing hex values
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
- Uses the `timeunit` keyword to specify the time unit and time precision of the
  simulation.
- Contains 2 `parameters`, RAM_INIT_FILE set to the contents of countdown.hex.txt,
  the binary for the countdown program and TIMEOUT_CYCLES set to 10000.
- All necessary logic is declared for the CPU and RAM.
- Module instances of the RAM and CPU are created using ordered instantiation
  instead of named instantiation (potentially bad practice).
- The RAM's RAM_INIT_FILE parameter is overridden in instantiation using the following
  syntax:
  `RAM_16x4096_delayX #(RAM_INIT_FILE) ramInst(input_params)`
  The `#()` allows us to replace the parameter used by ramInst, allowing us to
  load the values we want into the RAM.
- The first loop in the testbench is to generate the clock to run our system.
  Each clock cycle takes 20 time units (in this case 20ns), and repeats a total
  of TIMEOUT_CYCLES times. If the testbench has not concluded running, it will
  exit with a fatal error.
- The second loop runs our CPU by flipping rst to 1, which should put our CPU
  into our first state. rst is then set back to 0 and we assert that the CPU is
  now running.
  The loop
  ```
  while (running) begin
    @(posedge clk);
  end
  ```
  waits for our CPU to stop running, and once this is done the testbench displays
  that the testbench has finished running and exits successfully.

**RAM_countdown_delay0**
This file seems like it could be used to test the CPU independantly from the RAM.
This could be used in parallel with the testbench to ensure that the CPU performs
all the expected operations for the *countdown* program. If the CPU performs any
unexpected writes / reads the program will exit with a failure code.

utils
-----
This directory contains all the software needed to build and test the circuits.

**mu0.hpp + mu0_*.cpp**
This header file contains the declarations for a variety of mu0 functions which
are used in the assembler, disassembler and simulator. The purpose of each function
is included in the hpp file. These files are pretty self explanatory and
well-commented, read them if you want to understand how then assembler and simulator
is actually implemented.
*Note: mu0_read_binary is defined in mu0_disassembly.cpp*

mu0_opname_to_opcode seems to lack a definition. This is likely because the
function mu0_is_instruction has been overloaded to directly take a string, so the
function has probably been refactored as mu0_is_instruction is used directly on
strings instead of converting. (This should be confirmed when going through the
other cpp files)

**assembler.cpp**
This file converts files written in assembly language into a hex binary which can
then be loaded into our RAM file for simulation.
It stores data and intructions as a vector of pairs of strings, and labels as a
map of strings to ints.
It processes the input file as follows:
- Streams a string at a time.
- Checks if the string is a label. If it is it ensures this label has not been
  used before, then adds it to the map, associating it's value to the line its
  on (done using size of data_and_inst vector)
- Then checks if the string is an instruction. If it is it streams the next string
  in the istream as the address operand of the instruction (if the instruction
  requires an address), and adds it to data_and_inst as {instr, address}
- It finally checks if the string is data. If it is it's added to data_and_inst
  as {data, ""}
- If the string matches none of these, the assembler exits with an error code.

Next the assembler must output the binary and embed labels. It switches the
output stream to print everything in 4-digit hex, padding with 0s if necessary.
It then loops through data_and_inst performing the following:
- It checks if the first part of the pair is an intruction.
  - If it is, it loops through a vector of opnames to identify which opcode
    matches the opname (this likely replaced *mu0_opname_to_opcode*).
  - Next, it checks the second part of the pair containing the address operand.
    If the address is a numerical value, it is converted to an integer. If the
    address corresponds to a label, it checks the map of labels for the
    appropriate address.
  - Finally, it combines the opcode and address, printing them as a 4-digit hex
- Otherwise, the index in the vector must correspond to data, so it is simply
  printed as a 4-digit hex value.

**disassembler.cpp**
This file is probably to convert binary back to assembly language, but since it
is not used by any of the test scripts I've ignored it.

**simulator.cpp**
This file is to simulate what happens when we run a program by changing the
values stored in memory and returning the value stored in acc.
*Note: if ACC is non-zero, this will cause the program to exit with a failure
code*

Test Scripts
------------
There are 4 important test scripts which allow us to compile and run the different
testcases created for our CPU. Note that run_all.sh builds upon run_all_testcases.sh
which itself builds upon run_one_testcase.sh.

**General Notes**
`set -eou pipefail` is used at the start of all of these scripts.
- `set -e` will cause the whole script to exit if a command fails
- `set -u` will treat unset variables as errors and immediately exit
- `set -o pipefail` causes pipelines (`command | command`) to produce a failure
  code if any command errors (pipelines will only normally return a failure if
  the last command errors)

To use variables in shell script, simply define them first, then whenever you
want to use them use `$variable_name`. If you want to concatenate you variable
with a command, it's important to use `${variable_name}`. This is commonly used
for repeated text patterns in a script.
You can also pass command line parameters to scripts. To access these values
you can use `$1, $2, $3, ...` for the first, second, third parameters etc.

`> /dev/sterr` causes outputs to be printed to `sterr` instead of `stdout`
This can be also done using `>&2`

**build_utils.sh**
This is a simple script to understand, it just compiles all the files in utils
into assembler, simulator and disassembler (unused).

**run_one_testcase.sh**
This script takes 2 command line parameters which specify the cpu variant and
testcase being run.
- The script first runs the assembler on the testcase file specified, capturing
  the output in test/1-binary as a hex.txt file.
- Next it compiles the testbench using the appropriate simulator depending on the
  variant specified.
  `-P CPU_MU0_${VARIANT}_tb.RAM_INIT_FILE=\"test/1-binary/${TESTCASE}.hex.txt`
  enables us to directly set values of parameters in the testbench file at compile-time
- `set +e` is used when running the testbench to disable automatic script failure
  the simulation could go wrong. The result is captured in test/3-output as a
  filename.stdout (this is later used for further processing of the output)
- The exit code of the simulation is captured using `RESULT=$?`
- `set -e` is re-enabled after running the simulation.
- An if statement is then used to determine if the simulator returned a failure
  code, and exits if it did. If statements can be written in bach using the following
  syntax:
  ```
  if [<some tests>]
  then
    <commands>
  fi
  ```
  Where everything between the then and fi will be executed if the tests between
  the square brackest are true. The [] refer to the command [test](https://ss64.com/bash/test.html)
  which supports many operators. The use of [[]] refers to an extended or new
  test, which is more versatile than a regular test (i.e. can handle null exceptions)
  `[["${RESULT}" -ne 0]]` is equivalent to RESULT != 0.
- Next the script processes the output from .stdout, using [grep](https://man7.org/linux/man-pages/man1/grep.1.html)
  to spot any lines containing `PATTERN="CPU : OUT   :"` and storing them in
  <testcase>.out-lines (toggles set +e for this process):
  `grep "${PATTERN}" test/3-output/CPU_MU0_${VARIANT}_tb_${TESTCASE}.stdout > test/3-output/CPU_MU0_${VARIANT}_tb_${TESTCASE}.out-lines`
- [sed](https://www.gnu.org/software/sed/manual/sed.html#Overview) is then used to
  replace "CPU : OUT   :" with an empty string and stores this as <testcase>.out:
  `sed -e "s/${PATTERN}/${NOTHING}/g" test/3-output/CPU_MU0_${VARIANT}_tb_${TESTCASE}.out-lines > test/3-output/CPU_MU0_${VARIANT}_tb_${TESTCASE}.out`
  - The `-e` ensures that sed uses the first non-option parameter as the script and
    the next one as the file to run the script on
  - The `s` at the start of the first parameter identifies the regular-expression
    being searched for and the replacement string `s/regexp/replacement/[flags]`
  - The `g` flag indicates that the contents of the patter space should be replaced
    by the contents of the hold space (corresponding to regexp and replacement repectively)
- The script then runs the simulator using the same hex file, capturing the output
  in test/4-referece/<testcase>.out (once again toggling set +e)
- The output from the simulator is compared to the output from the verilog file using
  [diff](https://ss64.com/bash/diff.html), storing the results using `RESULT=$?`
  `diff -w test/4-reference/${TESTCASE}.out test/3-output/CPU_MU0_${VARIANT}_tb_${TESTCASE}.out`
  - The `-w` flag ignores all whitespace
  - `set +e` is also toggled for this process
- Finally, the script uses an `if else` statement (similar syntax to previous if statement)
  to determine if the testbench has passed (same as reference output) or failed (different)
*Note: since all files are produced as .out or .out-lines nothing appears to be
saved in the test output directories*

**run_all_testcases.sh**
This script takes a single command-line parameter specifying the cpu variant being
tested.
- Uses a wild-card `*` to specify every file with the pattern `TESTCASES="test/0-assembly/*.asm.txt"`
  is a testcase file.
- Script then uses a for loop to test every instance of testcase:
  ```
  for i in ${TESTCASES}; do
    execute intructions
  done
  ```
- In order to extract each individiual testcase name, [basename](https://ss64.com/bash/basename.html)
  is used:
  `TESTNAME=$(basename ${i} .asm.txt)`
  This strips the directory and suffix from filenames, then allowing us to pass
  TESTNAME as one of the command-line parameters for *run_one_testcase*, repeating
  for each file matching the TESTCASES pattern.

**run_all.sh**
This is a very simple script, which simply runs *build_utils.sh* and *run_all_testcases*
for each variant (delay0 and delay1)
