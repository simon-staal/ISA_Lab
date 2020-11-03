#!/bin/bash

set -e

echo "Compiling testbenches..."
iverilog -Wall -g 2012 -s multiplier_iterative_tb -o multiplier_iterative_v0 multiplier_iterative_tb.v multiplier_iterative_v0.v
iverilog -Wall -g 2012 -s multiplier_iterative_tb -o multiplier_iterative_v1 multiplier_iterative_tb.v multiplier_iterative_v1.v
iverilog -Wall -g 2012 -s multiplier_iterative_tb -o multiplier_iterative_v2 multiplier_iterative_tb.v multiplier_iterative_v2.v
iverilog -Wall -g 2012 -s multiplier_iterative_tb -o multiplier_iterative_v3 multiplier_iterative_tb.v multiplier_iterative_v3.v
echo "Testbenches compiled successfully"

echo "Running v0"
./multiplier_iterative_v0
echo "v0 successful"

echo "Running v1"
./multiplier_iterative_v1
echo "v1 successful"

echo "Running v2"
./multiplier_iterative_v2
echo "v2 successful"

echo "Running v3"
./multiplier_iterative_v3
echo "v3 successful"

echo "ALL VERSIONS TESTED SUCCESSFULLY"
