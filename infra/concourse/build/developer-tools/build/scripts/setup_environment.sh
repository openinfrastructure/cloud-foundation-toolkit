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

if [[ -z "${SERVICE_ACCOUNT_JSON}" ]]; then
  echo "Error: SERVICE_ACCOUNT_JSON must contain the JSON string (not the" >&2
  echo "file path) of the service account required to execute " >&2
  echo "Terraform/gsutil/gcloud. For example: " >&2
  echo "export SERVICE_ACCOUNT_JSON=\$(< /path/to/credentials.json)" >&2
  exit 1
fi

finish() {
  [[ -d "${DELETE_AT_EXIT}" ]] && rm -rf "${DELETE_AT_EXIT}"
}

setup_environment() {
  local tmpfile
  tmpfile="$(mktemp)"
  echo "${SERVICE_ACCOUNT_JSON}" > "${tmpfile}"

  # Terraform and most other tools respect GOOGLE_CREDENTIALS
  # https://www.terraform.io/docs/providers/google/provider_reference.html#credentials-1
  export GOOGLE_CREDENTIALS="${SERVICE_ACCOUNT_JSON}"

  # gcloud variables
  export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE="${tmpfile}"

  # InSpec respects GOOGLE_APPLICATION_CREDENTIALS
  # https://github.com/inspec/inspec-gcp#create-credentials-file-via
  export GOOGLE_APPLICATION_CREDENTIALS="${tmpfile}"

  # Configure gsutil standalone
  # https://cloud.google.com/storage/docs/gsutil/commands/config
  gcloud config set pass_credentials_to_gsutil false
  echo "[Credentials]" > ~/.boto
  echo "gs_service_key_file = ${tmpfile}" >> ~/.boto
}

# if the script is being executed and not sourced, setup a temp directory for
# the credentials, execute setup_environment, and cleanup the temp directory
# on exit. If the script is being sourced only execute setup_environment(), the
# parent shell is responsible for cleanup.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is executed directly
  DELETE_AT_EXIT="$(mktemp -d)"
  export TMPDIR="${DELETE_AT_EXIT}"
  set -eu
  setup_environment
  trap finish EXIT
  "$@"
else
  # Script is sourced
  setup_environment
fi
