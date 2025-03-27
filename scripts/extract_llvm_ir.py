#!/bin/python3

import subprocess
import argparse
import os
import glob

def disasm_one_file(rela):
    dir = os.path.dirname(rela)
    name = os.path.splitext(os.path.basename(rela))[0]
    # Resolve path
    result_dir = os.path.join(args.output_dir, dir)
    os.makedirs(result_dir, exist_ok=True)
    output_file = os.path.join(result_dir, name)
    # print(name, result_dir, output_file)
    subprocess.run([
        "extract-bc",
        "-b",
        "-o",
        output_file + ".ll", # Use the same file to avoid deletion
        os.path.join(build_root, rela),
    ], stderr=None, stdout=None)
    subprocess.run([
        "llvm-dis",
        "-o",
        output_file + ".ll",
        output_file + ".ll"
    ], stderr=None, stdout=None)
    return output_file + ".ll"

def disasm_module_complete(rela):
    mod_path = rela[:-3] + ".mod"
    with open(os.path.join(build_root, mod_path)) as obj_list:
        objs = list(obj_list.read().split())
        print(objs)
        for obj in objs:
            disasm_one_file(obj)

def disasm_modules():
    for mod in glob.glob(f"{build_root}/**/*.ko", recursive=True):
        rela = os.path.relpath(mod, build_root)
        if rela in should_split:
            disasm_module_complete(rela)
            continue
        result = disasm_one_file(rela)
        ir_size = os.path.getsize(result)
        # Too big, unluck :(
        if ir_size > mem_limit:
            os.remove(result)
            print(f"Module {rela} is split: IR size is {ir_size / 1024 ** 2} Mb")
            disasm_module_complete(rela)

def disasm_builtin(rela):
    # TODO: do this recursively - bigger results help pointer analysis
    # For now - get all object files and disasm them independently
    archive_data = subprocess.run([
        "ar", "-t", os.path.join(build_root, rela)
    ], capture_output=True)
    builtin_path = os.path.dirname(rela)
    objs = list(archive_data.stdout.split())
    for obj in objs:
        real_name = obj.decode("utf-8")
        # ar -t returns paths relative to archive
        disasm_one_file(os.path.join(builtin_path, real_name))

def disasm_builtins():
    for builtin in glob.glob(f"{build_root}/*/built-in.a", recursive=False):
        rela = os.path.relpath(builtin, build_root)
        disasm_builtin(rela)

parser = argparse.ArgumentParser("LLVM IR fetcher")
parser.add_argument("build_root")
parser.add_argument("-s", "--split",
                    help="""
                    File with objects that should be splitted.
                    Each file is a relative path to the file.
                    """)
parser.add_argument("-o", "--output-dir",
                    help="Root directory for output tree",
                    default=os.getcwd())
parser.add_argument("-m", "--mem-limit",
                    help="Critical size(in Mb) of .ll source, after which we will try to split it",
                    default=10)
args = parser.parse_args()
build_root = os.path.abspath(args.build_root)
mem_limit = int(args.mem_limit) * 1024 * 1024

should_split = set()
if args.split:
    # TODO: test me!
    with open(args.split) as split_list:
        for path in split_list:
            should_split.add(path)

# disasm_modules()
disasm_builtins()
