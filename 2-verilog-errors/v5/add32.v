module add32(
      input logic[31:0] a,
      input logic[31:0] b,
      input logic cin,
      output logic[31:0] sum,
      output logic cout
  );
      wire logic[32:0] carry;
      assign carry[0] = cin;
      genvar i;
      generate
          for(i = 0; i < 32; i=i+1) begin
              fadd faddi(a[i],b[i],carry[i],sum[i],carry[i+1]);
          end
      endgenerate

      assign cout = carry[32];

endmodule
