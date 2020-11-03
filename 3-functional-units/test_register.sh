#!/bin/bash

set -e

echo "Compiling testbenches..."
iverilog -Wall -g 2012 -s register_file_tb_simple -o register_file_simple_v0 register_file_tb_simple.v register_file_v0.v
iverilog -Wall -g 2012 -s register_file_tb_simple -o register_file_simple_v1 register_file_tb_simple.v register_file_v1.v
iverilog -Wall -g 2012 -s register_file_tb_simple -o register_file_simple_v2 register_file_tb_simple.v register_file_v2.v
iverilog -Wall -g 2012 -s register_file_tb_simple -o register_file_simple_v3 register_file_tb_simple.v register_file_v3.v

iverilog -Wall -g 2012 -s register_file_tb -o register_file_random_v0 register_file_tb_random.v register_file_v0.v
iverilog -Wall -g 2012 -s register_file_tb -o register_file_random_v1 register_file_tb_random.v register_file_v1.v
iverilog -Wall -g 2012 -s register_file_tb -o register_file_random_v2 register_file_tb_random.v register_file_v2.v
iverilog -Wall -g 2012 -s register_file_tb -o register_file_random_v3 register_file_tb_random.v register_file_v3.v
echo "Testbenches compiled successfully"

echo "Testing simple testbenches"
echo "Testing v0"
./register_file_simple_v0
echo "v0 successful"

echo "Testing v1"
./register_file_simple_v1
echo "v1 successful"

echo "Testing v2"
./register_file_simple_v2
echo "v2 successful"

echo "Testing v3"
./register_file_simple_v3
echo "v3 successful"
echo "All simple testbenches tested successfully"

echo "Testing random testbenches"
echo "Testing v0"
./register_file_random_v0
echo "v0 successful"

echo "Testing v1"
./register_file_random_v1
echo "v1 successful"

echo "Testing v2"
./register_file_random_v2
echo "v2 successful"

echo "Testing v3"
./register_file_random_v3
echo "v3 successful"
echo "All random testbenches tested successfully"

echo "ALL VERSIONS TESTED SUCCESSFULLY"
