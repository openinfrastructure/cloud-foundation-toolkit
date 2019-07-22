#!/bin/bash

set -e
set -u

cd /build

TERRAFORM_DOCS_VERSION=$1

wget "https://github.com/segmentio/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64"
install -o 0 -g 0 -m 0755 "terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64" /usr/local/bin/terraform-docs