#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 file1 [file2 ...]"
  exit 1
fi

# Output file (append or overwrite as needed)
output_file="line_count_results.txt"
>"$output_file"

total_lines=0
count_files=0

for f in "$@"; do
  if [ -f "$f" ]; then
    # Count lines
    lines_in_file=$(wc -l <"$f")
    total_lines=$((total_lines + lines_in_file))
    count_files=$((count_files + 1))
    echo "File: $f has $lines_in_file lines." | tee -a "$output_file"
  else
    echo "Warning: $f is not a valid file." | tee -a "$output_file"
  fi
done

echo "----------------------------------" | tee -a "$output_file"
echo "Number of files processed: $count_files" | tee -a "$output_file"
echo "Total number of lines: $total_lines" | tee -a "$output_file"
