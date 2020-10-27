module or_gate(
    input logic a,
    input logic b,
    output logic  r
);

    always_comb begin
        r = a|b;
    end

endmodule
