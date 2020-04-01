#===----------------------------------------------------------------------===##
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===----------------------------------------------------------------------===##

"""run.py is a utility for running a program.

It can perform code signing, forward arguments to the program, and return the
program's error code.
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--codesign_identity', type=str, required=False)
    parser.add_argument('--dependencies', type=str, nargs='*', required=True)
    parser.add_argument('--env', type=str, nargs='*', required=True)
    (args, remaining) = parser.parse_known_args(sys.argv[1:])

    if len(remaining) < 2:
        sys.stderr.write('Missing actual commands to run')
        exit(1)
    remaining = remaining[1:] # Skip the '--'

    # Do any necessary codesigning.
    if args.codesign_identity:
        exe = remaining[0]
        rc = subprocess.call(['xcrun', 'codesign', '-f', '-s', args.codesign_identity, exe], env={})
        if rc != 0:
            sys.stderr.write('Failed to codesign: ' + exe)
            return rc

    # Extract environment variables into a dictionary
    env = {k : v  for (k, v) in map(lambda s: s.split('=', 1), args.env)}

    try:
        tmpDir = tempfile.mkdtemp()

        # Ensure the file dependencies exist and copy them to a temporary directory.
        for dep in args.dependencies:
            if not os.path.exists(dep):
                sys.stderr.write('Missing file or directory "{}" marked as a dependency of a test'.format(dep))
                exit(1)
            if os.path.isdir(dep):
                shutil.copytree(dep, os.path.join(tmpDir, os.path.basename(dep)), symlinks=True)
            else:
                shutil.copy2(dep, tmpDir)

        # Run the executable with the given environment in the temporary directory.
        return subprocess.call(' '.join(remaining), cwd=tmpDir, env=env, shell=True)
    finally:
        shutil.rmtree(tmpDir)

if __name__ == '__main__':
    exit(main())
