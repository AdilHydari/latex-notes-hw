#!/bin/bash

# Compile the test program
echo "Compiling p1_test.c..."
gcc -Wall -o p1_test p1_test.c

if [ $? -ne 0 ]; then
    echo "Compilation failed. Exiting."
    exit 1
fi

echo "Compilation successful."

# Define parameters
EXIT_VALUES=(0 1)
SLEEP_TIMES=(5 20)
FLAG_CASES=(1 2 3)
COND_CASES=(1 2)

# Create a directory for test results
mkdir -p test_results

# Run tests for all combinations
for exit_val in "${EXIT_VALUES[@]}"; do
    for sleep_time in "${SLEEP_TIMES[@]}"; do
        for flag_case in "${FLAG_CASES[@]}"; do
            for cond_case in "${COND_CASES[@]}"; do
                echo "======================================================="
                echo "Running test with:"
                echo "  Exit Value: $exit_val"
                echo "  Sleep Time: $sleep_time"
                echo "  FLAG Case: $flag_case (${flag_case}=1:WUNTRACED|WCONTINUED, 2:WUNTRACED|WCONTINUED|WNOHANG, 3:WNOHANG)"
                echo "  CONDITIONAL Case: $cond_case (${cond_case}=1:C1, 2:C2)"
                
                # Create unique log file name
                log_file="test_results/test_exit${exit_val}_sleep${sleep_time}_flag${flag_case}_cond${cond_case}.log"
                
                # Run the test program and capture output
                echo "Test started at $(date)" | tee "$log_file"
                ./p1_test "$exit_val" "$sleep_time" "$flag_case" "$cond_case" 2>&1 | tee -a "$log_file"
                echo "Test finished at $(date)" | tee -a "$log_file"
                echo "======================================================="
                echo ""
                
                # Add a short delay between tests
                sleep 2
            done
        done
    done
done

echo "All tests completed. Results are in the test_results directory."
