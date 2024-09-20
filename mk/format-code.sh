#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

git ls-files -- '*.sh' |
  xargs docker run --rm -u $(id -u):$(id -g) -v $PWD:/mnt -w /mnt mvdan/shfmt:v3 -l -w -s -i=2 -ci
