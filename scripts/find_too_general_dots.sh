#!/bin/bash

DIR="$1"
CRITICAL_NUM="$2"
for g in "$DIR"/*.dot; do
	matched=$(grep --perl-regexp '"mypass_struct\.(.*)_stub" -> "mypass_struct\.(?!\g1)' $g | wc -l)
  # echo $matched
	if (( matched >= CRITICAL_NUM )); then
    echo $g
	fi
done
