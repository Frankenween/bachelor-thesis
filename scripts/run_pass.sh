#!/bin/bash
PASS="$1"
SRC="$2"
DST="$3"

for file in "$SRC"/*.ll; do
    FILE_NAME="$(basename -s .ll "$file")"
    opt-14 -enable-new-pm=0 -load="$PASS" -instr -S -o "$DST/$FILE_NAME.ll" "$SRC/$FILE_NAME.ll"
    echo
done
