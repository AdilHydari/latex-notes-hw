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

# Run the program in the background with output redirected to log file
./p1 0 25 2>> "$log_file" &
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

# Function to send a signal and mark timestamp
send_signal() {
    local sig_num=$1
    local sig_name=$2
    local time_sec=$3
    
    echo "Sending $sig_name ($sig_num) at $time_sec seconds..." | tee -a "$log_file"
    sleep $time_sec
    echo "$(date) - Sending $sig_name ($sig_num) to child..." | tee -a "$log_file"
    kill -$sig_num $child_pid
    # Capture any waitpid output that might appear immediately
    sleep 0.5
    echo "Current waitpid status at $(date):" | tee -a "$log_file"
    cat "$log_file" | grep "parent\|stopped\|continued\|killed\|exited" | tail -5 >> "$log_file"
    echo "" >> "$log_file"
}

# Send signals at appropriate times
send_signal 18 "SIGCONT" 10  # At 10s
send_signal 19 "SIGSTOP" 2   # At 12s (10+2)
send_signal 18 "SIGCONT" 2   # At 14s (12+2)
send_signal 19 "SIGSTOP" 2   # At 16s (14+2)
send_signal 3 "SIGQUIT" 2    # At 18s (16+2)
send_signal 4 "SIGILL" 1     # At 19s (18+1)
send_signal 6 "SIGABRT" 2    # At 21s (19+2)

echo "Signal sequence completed." | tee -a "$log_file"

# Give parent process time to finish
sleep 5
if ps -p $parent_pid > /dev/null; then
    echo "Parent process still running after signal sequence. Killing it." | tee -a "$log_file"
    kill $parent_pid
else
    echo "Parent process ended naturally." | tee -a "$log_file"
fi

echo "Test completed. Results in $log_file" | tee -a "$log_file"
echo "Final program output:" | tee -a "$log_file"
echo "----------------------------------------" >> "$log_file"
cat "$log_file" | grep "parent\|stopped\|continued\|killed\|exited" | tee -a "$log_file"
