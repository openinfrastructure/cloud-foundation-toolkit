#!/bin/bash

set -e
set -u

cd /build

wget https://storage.googleapis.com/kubernetes-release/release/v1.12.2/bin/linux/amd64/kubectl
install -o 0 -g 0 -m 0755 kubectl /usr/local/bin/kubectl