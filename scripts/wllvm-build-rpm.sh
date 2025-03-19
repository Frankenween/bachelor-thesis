#!/bin/bash

set -x

SRC="$1"
BUILDDIR="$2"
SPEC_PATH="$BUILDDIR/SPECS/kernel.spec"

# Unpack archive
echo Unpacking archive
rpm -ivh --define "_topdir ${BUILDDIR}" $SRC > /dev/null

# Fixup spec file
echo Fixing spec file
sed -i 's/%global clang_make_opts HOSTCC=clang CC=clang/%global clang_make_opts HOSTCC=wllvm CC=wllvm/g' "$SPEC_PATH"
sed -i 's/%define make_target bzImage/%define make_target all/' "$SPEC_PATH"

# Build it!
echo Building!

WITH_OPTS=("toolchain_clang")
WITHOUT_OPTS=("debug" "debuginfo" "bpftool" "perf" "kabichk" "tools" "headers" "cross-headers" "doc" "ipaclones")

WITH_OPTS_STR="$(printf " --with %s" "${WITH_OPTS[@]}")"
WITHOUT_OPTS_STR="$(printf " --without %s" "${WITHOUT_OPTS[@]}")"

TOPDIR_MACRO="$(printf "'_topdir %s'" "$BUILDDIR")"
BUILDDIR_MACRO="$(printf "'_builddir %s'" "$BUILDDIR/BUILD")"
RPMDIR_MACRO="$(printf "'_rpmdir %s'" "$BUILDDIR/RPMS")"

bash -c "rpmbuild -bc "$SPEC_PATH" $WITHOUT_OPTS_STR $WITH_OPTS_STR -D $TOPDIR_MACRO -D $BUILDDIR_MACRO -D $RPMDIR_MACRO -D 'dist ir'"
