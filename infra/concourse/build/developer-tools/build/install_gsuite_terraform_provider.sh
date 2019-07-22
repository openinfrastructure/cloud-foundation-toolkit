#!/bin/bash

set -e
set -u

GSUITE_PROVIDER_VERSION=$1

cd /build

wget "https://github.com/DeviaVir/terraform-provider-gsuite/releases/download/v${GSUITE_PROVIDER_VERSION}/terraform-provider-gsuite_${GSUITE_PROVIDER_VERSION}_linux_amd64.tgz"
tar xzf "terraform-provider-gsuite_${GSUITE_PROVIDER_VERSION}_linux_amd64.tgz"
rm "terraform-provider-gsuite_${GSUITE_PROVIDER_VERSION}_linux_amd64.tgz"
install -o 0 -g 0 -m 0755 -d ~/.terraform.d/plugins/
install -o 0 -g 0 -m 0755 "terraform-provider-gsuite_v${GSUITE_PROVIDER_VERSION}" ~/.terraform.d/plugins/