# Generate LLVM IR for Linux kernel
1. Setup [wllvm](https://github.com/travitch/whole-program-llvm/tree/master) in a python venv
2. Configure it with `clang-14`
    1. Change `PATH` so `clang` version is 14
    2. `export LLVM_COMPILER=clang`
    3. If `clang --version` is not 14, export the path to the clang-14 bin dir:
     `LLVM_COMPILER_PATH=/path/to/clang-14/bin/`
    4. Check with `wllvm-sanity-checker`
3. Build kernel with `CC=wllvm`
    1. `wllvm-build-rpm.sh path/to/src.rpm /path/to/builddir`
    - Note 1: the build will fail due to `.llvm_bc` section in object files.
    It is fine since we don't need linked vmlinux, built-in.a for all
    subsystems is enough.
    - Note 2: use make target `all` to compile both kernel and modules
4. Run `collect_builtins.sh BUILD_DIR` in a directory, where you want to __store__
the results. It will extract LLVM IR from `built-in.a` archives for subsystems
and from all modules.

# Instrument LLVM IR sources for further pointer analysis
[Repository with LLVM machinery](https://github.com/Frankenween/llvm-ptr-track)

1. Run `run_pass.sh DIR/WITH/LIBS DIR/WITH/LLVM-IR OUTPUT/DIR`
    - `DIR/WITH/LIBS` - location with currently two llvm passes: `purge_stores` and `ir_instr`
    - `ir_instr` pass supports some argumets, but this script - doesn't(yet, TODO)
    - Currnetly it may fail in some cases, development is in progress!

# Generate callgraphs for instrumented source files
1. Run `gen_all_dots.sh arg1 arg2 DIR/WITH/LLVM-IR OUTPUT/DIR args...`
    1. `arg1` is a path to [SVF](https://github.com/SVF-tools/SVF) wpa utility
    2. `arg2` is a path to a dot beautifier utility - `dot_fixup_after_svf.pl`.
        Dot graphs, produced by SVF, have ugly node IDs and a lot of useless labels. 
    3. `args...` are additional argumets, passed to SVF `wpa` program.
    - Note 1: No need to add `-dump-callgraph` or `-ind-call-limit`
    - Note 2: This step may take a while. TODO: sort files by their size.

# Link everything together
For this step a special [utility is being developed](https://github.com/Frankenween/dot-linker).

1. Write a proper config file
    1. List all dot graphs
    2. List functions for removal(some functions from mm, `panic`, `printk`, etc.)
    3. Add flatten rules. This is _supposed_ to be a `reparent` pass for stub functions
       from LLVM IR instrumentation
    4. Remove stub functions
    5. Reverse graph if needed
2. Run program and wait a litte
3. Beautify result dot graph with `dot_fixup_after_linker.pl`
4. Enjoy fancy callgraph!
