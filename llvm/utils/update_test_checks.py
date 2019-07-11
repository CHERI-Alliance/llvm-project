#!/usr/bin/env python

"""A script to generate FileCheck statements for 'opt' regression tests.

This script is a utility to update LLVM opt test cases with new
FileCheck patterns. It can either update all of the tests in the file or
a single test function.

Example usage:
$ update_test_checks.py --opt=../bin/opt test/foo.ll

Workflow:
1. Make a compiler patch that requires updating some number of FileCheck lines
   in regression test files.
2. Save the patch and revert it from your local work area.
3. Update the RUN-lines in the affected regression tests to look canonical.
   Example: "; RUN: opt < %s -instcombine -S | FileCheck %s"
4. Refresh the FileCheck lines for either the entire file or select functions by
   running this script.
5. Commit the fresh baseline of checks.
6. Apply your patch from step 1 and rebuild your local binaries.
7. Re-run this script on affected regression tests.
8. Check the diffs to ensure the script has done something reasonable.
9. Submit a patch including the regression test diffs for review.

A common pattern is to have the script insert complete checking of every
instruction. Then, edit it down to only check the relevant instructions.
The script is designed to make adding checks to a test case fast, it is *not*
designed to be authoratitive about what constitutes a good test!
"""

from __future__ import print_function

import argparse
import glob
import itertools
import os         # Used to advertise this file's name ("autogenerated_note").
import string
import subprocess
import sys
import tempfile
import re

from UpdateTestChecks import common

ADVERT = '; NOTE: Assertions have been autogenerated by '

# RegEx: this is where the magic happens.

IR_FUNCTION_RE = re.compile('^\s*define\s+(?:internal\s+)?[^@]*@([\w-]+)\s*\(')





def main():
  from argparse import RawTextHelpFormatter
  parser = argparse.ArgumentParser(description=__doc__, formatter_class=RawTextHelpFormatter)
  parser.add_argument('-v', '--verbose', action='store_true',
                      help='Show verbose output')
  parser.add_argument('--opt-binary', default='opt',
                      help='The opt binary used to generate the test case')
  parser.add_argument(
      '--function', help='The function in the test file to update')
  parser.add_argument('tests', nargs='+')
  args = parser.parse_args()

  autogenerated_note = (ADVERT + 'utils/' + os.path.basename(__file__))

  opt_basename = os.path.basename(args.opt_binary)
  if not re.match(r'^opt(-\d+)?$', opt_basename):
    print('ERROR: Unexpected opt name: ' + opt_basename, file=sys.stderr)
    sys.exit(1)
  opt_basename = 'opt'

  test_paths = []
  for test in args.tests:
    if not glob.glob(test):
      print('WARNING: Test file \'%s\' was not found. Ignoring it.' % (test,), file=sys.stderr)
      continue
    test_paths.append(test)

  for test in test_paths:
    if args.verbose:
      print('Scanning for RUN lines in test file: %s' % (test,), file=sys.stderr)
    with open(test) as f:
      input_lines = [l.rstrip() for l in f]

    raw_lines = [m.group(1)
                 for m in [common.RUN_LINE_RE.match(l) for l in input_lines] if m]
    run_lines = [raw_lines[0]] if len(raw_lines) > 0 else []
    for l in raw_lines[1:]:
      if run_lines[-1].endswith("\\"):
        run_lines[-1] = run_lines[-1].rstrip("\\") + " " + l
      else:
        run_lines.append(l)

    if args.verbose:
      print('Found %d RUN lines:' % (len(run_lines),), file=sys.stderr)
      for l in run_lines:
        print('  RUN: ' + l, file=sys.stderr)

    prefix_list = []
    for l in run_lines:
      cmds = [cmd.strip() for cmd in l.split('|', 1)]
      if len(cmds) < 2:
        cmds.append("INVALID")
      (tool_cmd, filecheck_cmd) = tuple(cmds)

      if tool_cmd.startswith("%cheri"):
        tool_cmd = tool_cmd.replace("%cheri_purecap_opt", "opt -mtriple=cheri-unknown-freebsd -target-abi purecap -relocation-model pic -mcpu=cheri128 -mattr=+cheri128")
        tool_cmd = tool_cmd.replace("%cheri128_purecap_opt", "opt -mtriple=cheri-unknown-freebsd -target-abi purecap -relocation-model pic -mcpu=cheri128 -mattr=+cheri128")
        tool_cmd = tool_cmd.replace("%cheri256_purecap_opt", "opt -mtriple=cheri-unknown-freebsd -target-abi purecap -relocation-model pic -mcpu=cheri256 -mattr=+cheri256")
        tool_cmd = tool_cmd.replace("%cheri_opt", "opt -mtriple=cheri-unknown-freebsd -mcpu=cheri128 -mattr=+cheri128")
        tool_cmd = tool_cmd.replace("%cheri128_opt", "opt -mtriple=cheri-unknown-freebsd -mcpu=cheri128 -mattr=+cheri128")
        tool_cmd = tool_cmd.replace("%cheri256_opt", "opt -mtriple=cheri-unknown-freebsd -mcpu=cheri256 -mattr=+cheri256")

      if not tool_cmd.startswith(opt_basename + ' '):
        print('WARNING: Skipping non-%s RUN line: %s' % (opt_basename, l), file=sys.stderr)
        continue

      if not filecheck_cmd.startswith('FileCheck '):
        print('WARNING: Skipping non-FileChecked RUN line: ' + l, file=sys.stderr)
        continue

      tool_cmd_args = tool_cmd[len(opt_basename):].strip()
      tool_cmd_args = tool_cmd_args.replace('< %s', '').replace('%s', '').strip()

      check_prefixes = [item for m in common.CHECK_PREFIX_RE.finditer(filecheck_cmd)
                               for item in m.group(1).split(',')]
      if not check_prefixes:
        check_prefixes = ['CHECK']

      # FIXME: We should use multiple check prefixes to common check lines. For
      # now, we just ignore all but the last.
      prefix_list.append((check_prefixes, tool_cmd_args))

    func_dict = {}
    for prefixes, _ in prefix_list:
      for prefix in prefixes:
        func_dict.update({prefix: dict()})
    for prefixes, opt_args in prefix_list:
      if args.verbose:
        print('Extracted opt cmd: ' + opt_basename + ' ' + opt_args, file=sys.stderr)
        print('Extracted FileCheck prefixes: ' + str(prefixes), file=sys.stderr)

      raw_tool_output = common.invoke_tool(args.opt_binary, opt_args, test)
      common.build_function_body_dictionary(
              common.OPT_FUNCTION_RE, common.scrub_body, [],
              raw_tool_output, prefixes, func_dict, args.verbose)

    is_in_function = False
    is_in_function_start = False
    prefix_set = set([prefix for prefixes, _ in prefix_list for prefix in prefixes])
    if args.verbose:
      print('Rewriting FileCheck prefixes: %s' % (prefix_set,), file=sys.stderr)
    output_lines = []
    output_lines.append(autogenerated_note)

    for input_line in input_lines:
      if is_in_function_start:
        if input_line == '':
          continue
        if input_line.lstrip().startswith(';'):
          m = common.CHECK_RE.match(input_line)
          if not m or m.group(1) not in prefix_set:
            output_lines.append(input_line)
            continue

        # Print out the various check lines here.
        common.add_ir_checks(output_lines, ';', prefix_list, func_dict, func_name)
        is_in_function_start = False

      if is_in_function:
        if common.should_add_line_to_output(input_line, prefix_set):
          # This input line of the function body will go as-is into the output.
          # Except make leading whitespace uniform: 2 spaces.
          input_line = common.SCRUB_LEADING_WHITESPACE_RE.sub(r'  ', input_line)
          output_lines.append(input_line)
        else:
          continue
        if input_line.strip() == '}':
          is_in_function = False
        continue

      # Discard any previous script advertising.
      if input_line.startswith(ADVERT):
        continue

      # If it's outside a function, it just gets copied to the output.
      output_lines.append(input_line)

      m = IR_FUNCTION_RE.match(input_line)
      if not m:
        continue
      func_name = m.group(1)
      if args.function is not None and func_name != args.function:
        # When filtering on a specific function, skip all others.
        continue
      is_in_function = is_in_function_start = True

    if args.verbose:
      print('Writing %d lines to %s...' % (len(output_lines), test), file=sys.stderr)

    with open(test, 'wb') as f:
      sys.stderr.writelines(['{}\n'.format(l).encode('utf-8') for l in output_lines])
      f.writelines(['{}\n'.format(l).encode('utf-8') for l in output_lines])


if __name__ == '__main__':
  main()
