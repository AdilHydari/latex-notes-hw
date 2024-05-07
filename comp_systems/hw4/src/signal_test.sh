#!/bin/bash

# Compile the original program
gcc -Wall -o p1 p1.c
if [ $? -ne 0 ]; then
    echo "Compilation failed. Exiting."
    exit 1
fi

# Create a log file
log_file="signal_test_output.log"
echo "Signal Testing Log - $(date)" > "$log_file"
echo "Testing p1 with scheduled signals:" >> "$log_file"
echo "Time 10s: Signal 18 (SIGCONT)" >> "$log_file"
echo "Time 12s: Signal 19 (SIGSTOP)" >> "$log_file"
echo "Time 14s: Signal 18 (SIGCONT)" >> "$log_file"
echo "Time 16s: Signal 19 (SIGSTOP)" >> "$log_file"
echo "Time 18s: Signal 3 (SIGQUIT)" >> "$log_file"
echo "Time 19s: Signal 4 (SIGILL)" >> "$log_file"
echo "Time 21s: Signal 6 (SIGABRT)" >> "$log_file"
echo "----------------------------------------" >> "$log_file"

# Run the program in the background and capture its output
# Using 20 for exit value and 25 for sleep time to ensure child process stays alive during signal testing
./p1 0 25 > >(tee -a "$log_file") 2> >(tee -a "$log_file" >&2) &
parent_pid=$!
echo "Parent process PID: $parent_pid" | tee -a "$log_file"

# Wait a moment for the child to be created
sleep 1

# Get the child process PID
child_pid=$(pgrep -P $parent_pid)
if [ -z "$child_pid" ]; then
    echo "Failed to get child PID. Exiting." | tee -a "$log_file"
    kill $parent_pid
    exit 1
fi

echo "Child process PID: $child_pid" | tee -a "$log_file"
echo "----------------------------------------" >> "$log_file"
echo "Begin sending signals according to schedule:" | tee -a "$log_file"

# Send signals according to the schedule
(
    echo "Waiting 10 seconds to send SIGCONT (18)..." | tee -a "$log_file"
    sleep 10
    echo "$(date) - Sending SIGCONT (18) to child..." | tee -a "$log_file"
    kill -18 $child_pid
    
    echo "Waiting 2 seconds to send SIGSTOP (19)..." | tee -a "$log_file"
    sleep 2
    echo "$(date) - Sending SIGSTOP (19) to child..." | tee -a "$log_file"
    kill -19 $child_pid
    
    echo "Waiting 2 seconds to send SIGCONT (18)..." | tee -a "$log_file"
    sleep 2
    echo "$(date) - Sending SIGCONT (18) to child..." | tee -a "$log_file"
    kill -18 $child_pid
    
    echo "Waiting 2 seconds to send SIGSTOP (19)..." | tee -a "$log_file"
    sleep 2
    echo "$(date) - Sending SIGSTOP (19) to child..." | tee -a "$log_file"
    kill -19 $child_pid
    
    echo "Waiting 2 seconds to send SIGQUIT (3)..." | tee -a "$log_file"
    sleep 2
    echo "$(date) - Sending SIGQUIT (3) to child..." | tee -a "$log_file"
    kill -3 $child_pid
    
    echo "Waiting 1 second to send SIGILL (4)..." | tee -a "$log_file"
    sleep 1
    echo "$(date) - Sending SIGILL (4) to child..." | tee -a "$log_file"
    kill -4 $child_pid
    
    echo "Waiting 2 seconds to send SIGABRT (6)..." | tee -a "$log_file"
    sleep 2
    echo "$(date) - Sending SIGABRT (6) to child..." | tee -a "$log_file"
    kill -6 $child_pid
    
    echo "Signal sequence completed." | tee -a "$log_file"
) &

# Wait for parent process to finish
wait $parent_pid
echo "Test completed. Results in $log_file" | tee -a "$log_file"

# Add analysis to log file
echo "" >> "$log_file"
echo "----------------------------------------" >> "$log_file"
echo "Analysis of Results:" >> "$log_file"
echo "The signals were sent in this order and should have these effects:" >> "$log_file"
echo "1. SIGCONT (18) at 10s - Continue if stopped (no effect if already running)" >> "$log_file"
echo "2. SIGSTOP (19) at 12s - Stop the process (process is suspended)" >> "$log_file"
echo "3. SIGCONT (18) at 14s - Continue the stopped process" >> "$log_file"
echo "4. SIGSTOP (19) at 16s - Stop the process again" >> "$log_file"
echo "5. SIGQUIT (3) at 18s - Quit signal (should terminate process with core dump)" >> "$log_file"
echo "6. SIGILL (4) at 19s - Illegal instruction (won't reach this if SIGQUIT worked)" >> "$log_file"
echo "7. SIGABRT (6) at 21s - Abort (won't reach this if earlier signals worked)" >> "$log_file"
echo "" >> "$log_file"
echo "Expected behavior: Process should be suspended twice and then terminated by SIGQUIT." >> "$log_file"
