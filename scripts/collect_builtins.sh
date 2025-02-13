#!/bin/bash
DIR="$1"
objects=( $(find $DIR -depth -name *.ko) )
objects+=( $(find $DIR -depth -maxdepth 2 -name built-in.a) )
CNT="$(pwd)"

for f in ${objects[@]}; do
	SUBSYS=`basename $(dirname $f)`
	FNAME="$(basename $f)"
	RESULT_NAME="$SUBSYS-$(basename -s .ko $f).ll"
	echo $SUBSYS $(basename $f)

	pushd "$(dirname $f)"
	extract-bc -b -o $RESULT_NAME $FNAME
	llvm-dis -o $RESULT_NAME $RESULT_NAME
	mv "$RESULT_NAME" "$CNT"
	popd
done

