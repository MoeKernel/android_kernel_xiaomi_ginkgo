#!/bin/bash

# -----------------------------
#   By Akari Nyan - © 2023
# ----------------------------- 

tag="stable"

while getopts "t:h" opt; do
  case $opt in
    t)
      tag="$OPTARG"
      ;;
    h)
      echo "Use: ./ksu_update.sh [-t <tag>] [-h]"
      echo ""
      echo "Options:"
      echo "  -t <tag> Selects the KernelSU tag. Options: stable (default), dev (unstable)"
  
      echo "  -h, --help Display this help message"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ "$tag" = "stable" ]; then
  rm -rf KernelSU
  cmd="bash -"
elif [ "$tag" = "dev" ]; then
  rm -rf KernelSU
  cmd="bash -s main"
else
  echo "tag invalid: $tag" >&2
  exit 1
fi

curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | $cmd

