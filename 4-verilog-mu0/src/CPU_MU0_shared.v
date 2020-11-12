

/*
STP 0111 stop
JNE S 0110 if ACC ≠ 0, PC := S
JGE S 0101 if ACC > 0, PC := S
JMP S 0100 PC := S
SUB S 0011 ACC := ACC – mem[S]
ADD S 0010 ACC := ACC + mem[S]
STO S 0001 mem[S] := ACC
LDA S 0000 ACC := mem[S]
OUT S 1000 print(Acc)
*/

module CPU_MU0_shared(
    input logic clk,
    input logic rst,
    output logic running,
    output logic[11:0] address,
    output logic write,
    output logic read,
    output logic[15:0] writedata,
    input logic[15:0] readdata
    );

    /* Using an enum to define constants */
    typedef enum logic[3:0] {
        OPCODE_LDA = 4'd0,
        OPCODE_STO = 4'd1,
        OPCODE_ADD = 4'd2,
        OPCODE_SUB = 4'd3,
        OPCODE_JMP = 4'd4,
        OPCODE_JGE = 4'd5,
        OPCODE_JNE = 4'd6,
        OPCODE_STP = 4'd7,
        OPCODE_OUT = 4'd8
    } opcode_t;

    /* Another enum to define CPU states. */
    typedef enum logic[1:0] {
        FETCH = 2'b00,
        EXEC_1  = 2'b01,
        EXEC_2  = 2'b10,
        HALTED =           2'b11
    } state_t;

    parameter DELAY = "delay0";

    logic[11:0] pc, pc_next;
    logic[15:0] acc;

    logic[16:0] instr;
    opcode_t instr_opcode;
    logic[11:0] instr_constant;

    logic[1:0] state;

    // Decide what address to put out on the bus, and whether to write
    assign address = (state==FETCH) ? pc : instr_constant;
    assign write = (state==EXEC_2) ? instr_opcode==OPCODE_STO : 0;
    assign read = (state==FETCH) ? 1 : ((state==EXEC_1 && (instr_opcode==OPCODE_LDA || instr_opcode==OPCODE_ADD  || instr_opcode==OPCODE_SUB ) && DELAY == "delay1") || (state==EXEC_2 && (instr_opcode==OPCODE_LDA || instr_opcode==OPCODE_ADD  || instr_opcode==OPCODE_SUB ) && DELAY == "delay0"));
    assign writedata = acc;

    // Break-down the instruction into fields
    // these are just wires for our convenience
    assign instr_opcode = (state==EXEC_1) ? readdata[15:12] : instr[15:12];
    assign instr_constant = (state==EXEC_1) ? readdata[11:0] : instr[11:0];

    // This is used in many places, as most instructions go forwards by one step.
    // Defining it once makes it more likely the synthesis tool will only create
    // one concrete instance.
    wire[11:0] pc_increment;
    assign pc_increment = pc + 1;

    /* We are targetting an FPGA, which means we can specify the power-on value of the
        circuit. So here we set the initial state to 0, and set the output value to
        indicate the CPU is not running.
    */
    initial begin
        state = HALTED;
        running = 0;
    end

    /* Main CPU sequential update logic. Where combinational logic is simple, it
        has been incorporated directly here, rather than splitting it into another
        block.

         Note: this is always rather than always_ff due to limitations in the verilog
        simulator, which can't deal with $display in always_ff blocks.
    */
    always @(posedge clk) begin
        if (rst) begin
            $display("CPU : INFO  : Resetting.");
            state <= FETCH;
            pc <= 0;
            acc <= 0;
            running <= 1;
        end
        else if (state==FETCH) begin
            $display("CPU : INFO  : Fetching (addr), address=%h.", pc);
            if(DELAY=="delay0") begin
                instr <= readdata;
                state <= EXEC_2;
            end
            if(DELAY=="delay1") begin
                state <= EXEC_1;
            end
        end
        else if (state==EXEC_1) begin
            $display("CPU : INFO  : Executing (addr), opcode=%h, acc=%h, imm=%h, readdata=%x", instr_opcode, acc, instr_constant, readdata);
            instr <= readdata;
            state <= EXEC_2;
        end
        else if (state==EXEC_2) begin
            $display("CPU : INFO  : Executing (data), opcode=%h, acc=%h, imm=%h, readdata=%x", instr_opcode, acc, instr_constant, readdata);
            case(instr_opcode)
                OPCODE_LDA: begin
                    acc <= readdata;
                    pc <= pc_increment;
                    state <= FETCH;
                end
                OPCODE_STO: begin
                    pc <= pc_increment;
                    state <= FETCH;
                end
                OPCODE_ADD: begin
                    acc <= acc + readdata;
                    pc <= pc_increment;
                    state <= FETCH;
                end
                OPCODE_SUB: begin
                    acc <= acc - readdata;
                    pc <= pc_increment;
                    state <= FETCH;
                end
                OPCODE_JMP: begin
                    pc <= instr_constant;
                    state <= FETCH;
                end
                OPCODE_JGE: begin
                    if (acc > 0) begin
                        pc <= instr_constant;
                    end
                    else begin
                        pc <= pc_increment;
                    end
                    state <= FETCH;
                end
                OPCODE_JNE: begin
                    if (acc != 0) begin
                        pc <= instr_constant;
                    end
                    else begin
                        pc <= pc_increment;
                    end
                    state <= FETCH;
                end
                OPCODE_OUT: begin
                    $display("CPU : OUT   : %d", $signed(acc));
                    pc <= pc_increment;
                    state <= FETCH;
                end
                OPCODE_STP: begin
                    // Stop the simulation
                    state <= HALTED;
                    running <= 0;
                end
            endcase
        end
        else if (state==HALTED) begin
            // do nothing
        end
        else begin
            $display("CPU : ERROR : Processor in unexpected state %b", state);
            $finish;
        end
    end
endmodule
