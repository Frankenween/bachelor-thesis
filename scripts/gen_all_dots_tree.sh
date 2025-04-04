#!/bin/bash

WPA="$1"
FIXUP="$2"
TREE="$3"
SVF_ARGS=("$@")
for src in $(find "$TREE" -depth -name *.ll.instr); do
	fname="${src%.ll.instr}.dot"
	$WPA "${SVF_ARGS[@]:3}" -ind-call-limit 1000000000 -node-alloc-strat=dense -dump-callgraph "$src"
	rm -f callgraph_initial.dot
	$FIXUP callgraph_final.dot callgraph_final.dot
	mv callgraph_final.dot "$fname"
done
