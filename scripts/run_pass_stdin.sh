#!/bin/bash

PASS_DIR="$1"

while read file; do
  opt-14 -enable-new-pm=0 -load="$PASS_DIR/purge_stores.so" -remove-store -S -o "$file.instr" $file
  opt-14 -enable-new-pm=0 -load="$PASS_DIR/ir_instr.so" -instr -S -o "$file.instr" "$file.instr"
done
