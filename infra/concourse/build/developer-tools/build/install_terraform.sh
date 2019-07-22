#!/bin/bash

set -e
set -u

TERRAFORM_VERSION=$1

cd /build

wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
install -o 0 -g 0 -m 0755 terraform /usr/local/bin/