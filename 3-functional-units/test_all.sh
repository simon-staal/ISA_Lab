#!/bin/bash

set -e

echo "TESTING MULTIPLIER ITERATIVE"
bash test_multiplier_iterative.sh
echo "MULTIPLIER ITERATIVE SUCCESSFUL"

echo "TESTING MULTIPLIER PIPELINED"
bash test_multiplier_pipelined.sh
echo "MULTIPLIER PIPELINED SUCCESSFUL"

echo "TESTING REGISTER FILE"
bash test_register.sh
echo "REGISTER FILE SUCCESSFUL"

echo "ALL MODULES TESTED SUCCESSFULLY"
