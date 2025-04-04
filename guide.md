# Generate LLVM IR for Linux kernel
1. Setup [wllvm](https://github.com/travitch/whole-program-llvm/tree/master) in a python venv
2. Configure it with `clang-14`
    1. Change `PATH` so `clang` version is 14
    2. `export LLVM_COMPILER=clang`
    3. If `clang --version` is not 14, export the path to the clang-14 bin dir:
     `LLVM_COMPILER_PATH=/path/to/clang-14/bin/`
    4. Check with `wllvm-sanity-checker`
3. Build kernel with `CC=wllvm`
    1. `wllvm-build-rpm.sh path/to/src.rpm /path/to/builddir /path/to/kern/patches`
    - Note 1: `CONFIG_DEBUG_INFO_BTF` must be disabled!
    - Note 2: use make target `all` to compile both kernel and modules
4. Run `extract_llvm_ir.py build_root`
    - `build_root` is self-descriptive
    - `-o output_dir` - a place, where the result will be stored. Original project
      structure is preserved, if there is a `build_root/a/b/obj.o` file,
      `output_dir/a/b/obj.ll` result will be created.
    - `-m sz` - memory bound in Mb.
        - It is a good idea to avoid big files - they create some garbage on analysis stage.
        - If built-in archive is too big, script will split
          it on subarchives(with respect to the project structure) and object files on the
          same level
        - If kernel module is too big, it will be split on objects from
          corresponding .mod file

# Instrument LLVM IR sources for further pointer analysis
[Repository with LLVM machinery](https://github.com/Frankenween/llvm-ptr-track)

1. Run `run_pass_tree.sh DIR/WITH/LIBS TREE/WITH/IR`
    - `DIR/WITH/LIBS` - location with currently two llvm passes: `purge_stores` and `ir_instr`
    - `ir_instr` pass supports some argumets, but this script - doesn't(yet, TODO)
    - Next to .ll files there will be created .ll.instr file with modificated LLVM IR
    - Currnetly it may fail in some cases, development is in progress!

# Generate callgraphs for instrumented source files
1. Run `gen_all_dots_tree.sh arg1 arg2 TREE/WITH/LLVM-IR args...`
    1. `arg1` is a path to [SVF](https://github.com/SVF-tools/SVF) wpa utility
    2. `arg2` is a path to a dot beautifier utility - `dot_fixup_after_svf.pl`.
        It is located in scripts directory.
        Dot graphs, produced by SVF, have ugly node IDs and a lot of useless labels.
    3. Dot files will be stored next to .ll.instr files in a tree.
    4. `args...` are additional argumets, passed to SVF `wpa` program.
        - There should be at least one argument: pointer analysis algorithm.
          A working set is `-ander -ff-eq-base`
        - Note 1: No need to add `-dump-callgraph` or `-ind-call-limit`
        - Note 2: This step may be time/mem consuming  when there are big files(> 50Mb)

# Link everything together
For this step a special [utility is being developed](https://github.com/Frankenween/dot-linker).

1. Write a proper config file
    1. List functions for removal(some functions from mm, `panic`, `printk`, etc.)
    2. Add flatten rules. This is _supposed_ to be a `reparent` pass for stub functions
       from LLVM IR instrumentation
    3. Remove stub functions
    4. Reverse graph if needed
2. Run program and wait a litte
3. Beautify result dot graph with `dot_fixup_after_linker.pl` which is in scripts folder
4. Enjoy fancy callgraph!
