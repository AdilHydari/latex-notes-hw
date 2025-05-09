#!/bin/bash
# This script automates the testing of various signal handling scenarios

# Part 1 - Basic signal testing
echo "===== PART 1: Basic Signal Testing ====="
echo "Starting option_b_signals in background..."
./option_b_signals > output_part1.log 2>&1 &
PARENTPID=$!
echo "Parent PID: $PARENTPID"

sleep 1
echo "Finding child PIDs..."
CHILDPIDS=($(pgrep -P $PARENTPID))
if [ ${#CHILDPIDS[@]} -ne 4 ]; then
    echo "Warning: Expected 4 child processes, found ${#CHILDPIDS[@]}"
fi
CHILD0=${CHILDPIDS[0]:-0}
CHILD1=${CHILDPIDS[1]:-0}
CHILD2=${CHILDPIDS[2]:-0}
CHILD3=${CHILDPIDS[3]:-0}
echo "Child PIDs: $CHILD0 $CHILD1 $CHILD2 $CHILD3"

echo "Sending SIGINT to parent (should be ignored during child phase)..."
sleep 1
kill -SIGINT $PARENTPID

echo "Sending SIGTSTP to child 0 (should be caught if not blocked)..."
sleep 1
kill -SIGTSTP $CHILD0 

echo "Sending two SIGABRTs to child 1..."
kill -SIGABRT $CHILD1
kill -SIGABRT $CHILD1

echo "Sending SIGSEGV to child 2 (may terminate it)..."
kill -SIGSEGV $CHILD2

echo "Waiting for children to complete..."
wait $PARENTPID
echo "Part 1 testing complete. Results in output_part1.log"

echo -e "\n===== PART 2: Signal Queue Testing ====="
echo "Starting option_b_signals in background..."
./option_b_signals > output_part2.log 2>&1 &
PARENTPID=$!
echo "Parent PID: $PARENTPID"

sleep 1
echo "Finding child PIDs..."
CHILDPIDS=($(pgrep -P $PARENTPID))
if [ ${#CHILDPIDS[@]} -ne 4 ]; then
    echo "Warning: Expected 4 child processes, found ${#CHILDPIDS[@]}"
fi
CHILD0=${CHILDPIDS[0]:-0}
CHILD1=${CHILDPIDS[1]:-0}
echo "Child PIDs: $CHILD0 $CHILD1"

echo "Sending SIGINT twice quickly to child 0..."
kill -SIGINT $CHILD0
kill -SIGINT $CHILD0

echo "Waiting for children to complete..."
wait $PARENTPID
echo "Part 2 testing complete. Results in output_part2.log"

echo -e "\n===== PART 3: Mask and Pending Queue Testing ====="
echo "Starting option_b_signals_p3 in background..."
./option_b_signals_p3 > output_part3.log 2>&1 &
PARENTPID=$!
echo "Parent PID: $PARENTPID"

sleep 1
if ! ps -p $PARENTPID > /dev/null; then
    echo "Error: option_b_signals_p3 (PID $PARENTPID) is not running!"
    echo "Check output_part3.log for errors"
    exit 1
fi

echo "Sending signals to parent to fill pre-fork queue..."
for s in INT QUIT TSTP; do
    echo "Sending SIG$s to parent..."
    kill -SIG$s $PARENTPID
    sleep 0.5
done

if ! ps -p $PARENTPID > /dev/null; then
    echo "Error: Parent process terminated after sending signals!"
    echo "Check output_part3.log for details"
    exit 1
fi

# Wait for children to be created and find their PIDs
sleep 2 
echo "Finding child PIDs..."
CHILDPIDS=($(pgrep -P $PARENTPID 2>/dev/null || echo ""))
if [ ${#CHILDPIDS[@]} -ne 4 ]; then
    echo "Warning: Expected 4 child processes, found ${#CHILDPIDS[@]}"
fi
CHILD0=${CHILDPIDS[0]:-0}
CHILD1=${CHILDPIDS[1]:-0}
CHILD2=${CHILDPIDS[2]:-0}
CHILD3=${CHILDPIDS[3]:-0}
echo "Child PIDs: $CHILD0 $CHILD1 $CHILD2 $CHILD3"

echo "Sending signals to test pending queues..."
for s in INT ABRT ILL CHLD FPE HUP TSTP; do
  echo "Sending SIG$s to each process..."
  ps -p $PARENTPID >/dev/null 2>&1 && kill -SIG$s $PARENTPID 2>/dev/null || echo "Parent not running"
  
  if [ $CHILD0 -ne 0 ]; then
    ps -p $CHILD0 >/dev/null 2>&1 && kill -SIG$s $CHILD0 2>/dev/null || echo "Child0 not running"
  fi
  
  if [ $CHILD1 -ne 0 ]; then
    ps -p $CHILD1 >/dev/null 2>&1 && kill -SIG$s $CHILD1 2>/dev/null || echo "Child1 not running"
  fi
  
  if [ $CHILD2 -ne 0 ]; then
    ps -p $CHILD2 >/dev/null 2>&1 && kill -SIG$s $CHILD2 2>/dev/null || echo "Child2 not running"
  fi
  
  if [ $CHILD3 -ne 0 ]; then
    ps -p $CHILD3 >/dev/null 2>&1 && kill -SIG$s $CHILD3 2>/dev/null || echo "Child3 not running"
  fi
  
  sleep 0.2
done

echo "Waiting for children to complete..."
wait $PARENTPID
echo "Part 3 testing complete. Results in output_part3.log"

echo -e "\nAll testing complete!"
