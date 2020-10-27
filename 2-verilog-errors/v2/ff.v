module ff(
    input logic clock,
    input logic d,
    output logic q
);
    always_ff @(posedge clock) begin
        q <= d;
    end

endmodule
