#!/usr/bin/env python3

import argparse
import python_minifier
import sys

from os.path import basename


def parse_args() -> argparse.Namespace:
    progname = basename(sys.argv[0])
    parser = argparse.ArgumentParser(prog=progname)
    parser.add_argument("infile", metavar="<infile>", type=str)
    return parser.parse_args()


def main():
    args = parse_args()
    with open(args.infile) as f:
        print(python_minifier.minify(f.read()))


if __name__ == "__main__":
    main()
