#! /bin/bash
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Setup temp directory for credentials written to disk
DELETE_AT_EXIT="$(mktemp -d)"
export TMPDIR="${DELETE_AT_EXIT}"

if [[ -z "${SERVICE_ACCOUNT_JSON}" ]]; then
  echo "Error: SERVICE_ACCOUNT_JSON must contain the JSON string (not the" >&2
  echo "file path) of the service account required to execute " >&2
  echo "Terraform/gsutil/gcloud. For example: " >&2
  echo "export SERVICE_ACCOUNT_JSON=\$(< /path/to/credentials.json)" >&2
  exit 1
fi

set -eu

# Always cleanup credentials upon exiting
finish() {
  [[ -d "${DELETE_AT_EXIT}" ]] && rm -rf "${DELETE_AT_EXIT}"
}
trap finish EXIT

source /usr/local/bin/setup_environment.sh
"$@"
