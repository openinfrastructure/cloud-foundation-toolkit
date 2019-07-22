#!/bin/bash

set -e
set -u

cd /build

wget https://shellcheck.storage.googleapis.com/shellcheck-v0.6.0.linux.x86_64.tar.xz
tar -xf shellcheck-v0.6.0.linux.x86_64.tar.xz
install -o 0 -g 0 -m 0755 shellcheck-v0.6.0/shellcheck /usr/local/bin/shellcheck
rm -rf shellcheck-v0.6.0 shellcheck-v0.6.0.linux.x86_64.tar.xz
