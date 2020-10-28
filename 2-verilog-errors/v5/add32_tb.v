module add32_tb();

    logic[31:0] a, b, sum;
    logic cin, cout;
    logic [32:0] true_sum;

    logic[8:0] i;
    initial begin
        $dumpfile("add32.vcd");
        $dumpvars(0, add32_tb);

        /* Loop over every possible input pattern */

        i=0;
        repeat (512) begin
            a=(i>>5)&15;
            b=(i>>1)&15;
            cin=i&1;
            true_sum = (a+b+cin);
            #1;

            assert( (true_sum & 32'hFFFFFFFF) == sum );
            assert( (true_sum >> 32) == cout );

            i=i+1;
        end

        //Test max values
        a = 32'hFFFFFFFF;
        b = 32'hFFFFFFFF;
        cin = 1;
        #1;
        assert( 32'hFFFFFFFF == sum );
        assert( 1 == cout );
    end

    add32 dut(
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

endmodule
