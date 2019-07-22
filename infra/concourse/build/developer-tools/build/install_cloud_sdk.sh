#!/bin/bash

set -e
set -u

CLOUD_SDK_VERSION=$1

cd /build

wget "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz"
tar -C /usr/local -xzf "google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz"
rm "google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz"

# TODO: Cargo-culted the symlink from a previous method. Would be nice to know
# why this is necessary
ln -s /lib /lib64

gcloud config set core/disable_usage_reporting true
gcloud config set component_manager/disable_update_check true
gcloud components install beta --quiet
gcloud components install alpha --quiet

gcloud --version
gsutil version -l