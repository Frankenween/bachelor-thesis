#!/bin/bash

src_archive_name() {
  archives=( $(find "$BUILDDIR/SOURCES" -regextype posix-extended -regex '.*linux.*(tar|xz|gz|tgz)' ) )
  len=${#archives[@]} 
  if [ $len -ne 1 ];
  then
    echo "Too many archives!"
    exit 1
  fi
  src_archive="$(basename ${archives[0]})"
  echo "$src_archive"
}

# arg1 - archive name
# arg2 - directory with patches
repack_src_archive() {
  mkdir "$BUILDDIR/src_tmp"
  tar -xf "$BUILDDIR/SOURCES/$1" -C "$BUILDDIR/src_tmp"
  src_dir="$(ls "$BUILDDIR/src_tmp")"
  
  for p in "$2/"*.patch ; do
    patch --dir "$BUILDDIR/src_tmp/$src_dir/" -F0 -p1 < "$p" 
  done

  tar -cf "$BUILDDIR/SOURCES/$1" -C "$BUILDDIR/src_tmp" .
  rm -rf "$BUILDDIR/src_tmp"
}

set -x

SRC="$1"
BUILDDIR="$2"
PATCHES="$3"
SPEC_PATH="$BUILDDIR/SPECS/kernel.spec"

# Unpack archive
echo Unpacking archive
rpm -ivh --define "_topdir ${BUILDDIR}" $SRC > /dev/null

# Apply patches
if [ ! -z "$PATCHES" ]; then
  ARCHIVE_NAME="$(src_archive_name)"
  repack_src_archive "$ARCHIVE_NAME" "$PATCHES"
fi

# Fixup spec file
echo Fixing spec file
sed -i 's/%global clang_make_opts HOSTCC=clang CC=clang/%global clang_make_opts HOSTCC=wllvm CC=wllvm/g' "$SPEC_PATH"
sed -i 's/%define make_target bzImage/%define make_target all/g' "$SPEC_PATH"

# Fix configs
for config_file in $(find ${BUILDDIR}/SOURCES -name kernel-*.config); do
  echo $config_file
  sed -ri 's/(CONFIG_DEBUG_INFO.*)=y/# \1 is not set/g' $config_file
done

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
