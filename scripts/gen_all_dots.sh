#!/bin/bash

WPA="$1"
FIXUP="$2"
SRC="$3"
DST="$4"
SVF_ARGS=("$@")
for src in "$SRC"/*.ll; do
	fname=$(basename -s .ll $src)
	$WPA "${SVF_ARGS[@]:4}" -ind-call-limit 1000000000 -dump-callgraph "$src"
	rm -f callgraph_initial.dot
	$FIXUP callgraph_final.dot
	mv callgraph_final.dot "$DST/$fname.dot"
done
