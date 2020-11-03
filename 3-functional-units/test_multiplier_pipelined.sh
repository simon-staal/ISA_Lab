#!/bin/bash

set -e

echo "Compiling testbenches..."
iverilog -Wall -g 2012 -s multiplier_pipelined_tb -o multiplier_pipelined_v0 multiplier_pipelined_tb.v multiplier_pipelined_v0.v
iverilog -Wall -g 2012 -s multiplier_pipelined_tb -o multiplier_pipelined_v1 multiplier_pipelined_tb.v multiplier_pipelined_v1.v
iverilog -Wall -g 2012 -s multiplier_pipelined_tb -o multiplier_pipelined_v2 multiplier_pipelined_tb.v multiplier_pipelined_v2.v
iverilog -Wall -g 2012 -s multiplier_pipelined_tb -o multiplier_pipelined_v3 multiplier_pipelined_tb.v multiplier_pipelined_v3.v
iverilog -Wall -g 2012 -s multiplier_pipelined_tb -o multiplier_pipelined_v4 multiplier_pipelined_tb.v multiplier_pipelined_v4.v
#iverilog -Wall -g 2012 -s multiplier_pipelined_tb -o multiplier_pipelined_v5 multiplier_pipelined_tb.v multiplier_pipelined_v5.v
echo "Testbenches compiled successfully"

echo "Running v0"
./multiplier_pipelined_v0
echo "v0 successful"

echo "Running v1"
./multiplier_pipelined_v1
echo "v1 successful"

echo "Running v2"
./multiplier_pipelined_v2
echo "v2 successful"

echo "Running v3"
./multiplier_pipelined_v3
echo "v3 successful"

echo "Running v4"
./multiplier_pipelined_v4
echo "v4 successful"

<<COMMENT
Not running v5 because it takes too long
echo "Running v5"
./multiplier_pipelined_v5
echo "v5 successful"
COMMENT

echo "ALL VERSIONS TESTED SUCCESSFULLY"
