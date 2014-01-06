#!/usr/bin/env python3

# Copyright (c) 2014, Ruslan Baratov
# All rights reserved.

import argparse
import sys
import tarfile
import os

parser = argparse.ArgumentParser(
    description='Pack/unpack hunter builded directories'
)

tar_gz_help = 'tar gz filename (e.g. my-pack.tar.gz)'
parser.add_argument(
    '--pack',
    metavar='PACK.tar.gz',
    help='Read HUNTER_ROOT environment variable '
        'and pack directory to PACK.tar.gz file'
)

parser.add_argument(
    '--unpack',
    metavar='PACK.tar.gz',
    help='Unpack PACK.tar.gz to empty directory specified '
        'by HUNTER_ROOT environment variable'
)

args = parser.parse_args()

if not args.pack and not args.unpack:
  print('Error: --pack or --unpack required\n')
  parser.print_help()
  sys.exit(1)

hunter_root = os.getenv('HUNTER_ROOT')
if not hunter_root:
  sys.exit('HUNTER_ROOT environment variable is empty')

if not os.path.isabs(hunter_root):
  sys.exit('HUNTER_ROOT path is not absolute: `{}`'.format(hunter_root))

def pack_directory(dir, file):
  if os.path.exists(file):
    sys.exit('File `{}` exists'.format(file))
  if not os.path.exists(dir):
    sys.exit('Directory `{}` not exists'.format(dir))
  if len(os.listdir(dir)) == 0:
    sys.exit('Directory `{}` is empty'.format(dir))
  print('pack directory `{}` to file `{}`'.format(dir, file))
  archive = tarfile.open(name=file, mode='w:gz')

  sources_dir = os.path.join(dir, 'Base', 'Source')
  download_dir = os.path.join(dir, 'Download')

  for root, dirnames, filenames in os.walk(dir):
    for filename in filenames:
      filepath = os.path.join(root, filename)

      if filepath.startswith(sources_dir):
        continue
      if filepath.startswith(download_dir):
        continue

      name = os.path.relpath(filepath, start=dir)
      archive.add(filepath, arcname=name)
  archive.close
  print('done')

def unpack_directory(dir, file):
  print('unpack `{}` to directory `{}`'.format(file, dir))
  if not os.path.exists(file):
    sys.exit('File `{}` not exists'.format(file))
  if os.path.exists(dir) and len(os.listdir(dir)) > 0:
    sys.exit('Directory `{}` is not empty. Please remove it'.format(dir))
  archive = tarfile.open(name=file, mode='r:gz')
  archive.extractall(path=dir)
  archive.close()
  print('done')

if args.pack:
  pack_directory(hunter_root, args.pack)

if args.unpack:
  unpack_directory(hunter_root, args.unpack)
