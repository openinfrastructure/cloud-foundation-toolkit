#!/bin/bash

set -e
set -u

cd /build

wget https://github.com/hadolint/hadolint/releases/download/v1.15.0/hadolint-Linux-x86_64
install -o 0 -g 0 -m 0755 hadolint-Linux-x86_64 /usr/local/bin/hadolint