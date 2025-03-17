#!/bin/bash
PASS_DIR="$1"
SRC="$2"
DST="$3"

for file in "$SRC"/*.ll; do
    FILE_NAME="$(basename -s .ll "$file")"
    opt-14 -enable-new-pm=0 -load="$PASS_DIR/purge_stores.so" -remove-store -S -o "$DST/$FILE_NAME.ll" "$SRC/$FILE_NAME.ll"
    opt-14 -enable-new-pm=0 -load="$PASS_DIR/ir_instr.so" -instr -S -o "$DST/$FILE_NAME.ll" "$DST/$FILE_NAME.ll"
    echo
done
