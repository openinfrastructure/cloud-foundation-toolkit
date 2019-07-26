#!/usr/bin/env bash

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

# Trap handler to delete the temporary directory created by
# setup_trap_handler() and used by maketemp()
finish() {
  if [[ -n "${DELETE_AT_EXIT:-}" ]]; then
    rm -rf "${DELETE_AT_EXIT}"
  fi
}

# Create a temporary directory and store the path in DELETE_AT_EXIT.  Register
# a trap handler to automatically remove this temporary directory.  Intended
# for use with maketemp() to automatically clean up temporary files, especially
# those used to store credentials.
setup_trap_handler() {
  readonly DELETE_AT_EXIT="$(mktemp -d)"
  trap finish EXIT
}

# Integration testing requires different behavior for its trap handler (running
# `kitchen destroy` along with cleaning up the environment). Because you can't
# have more than one trap handler for a signal, this function sets up the trap
# handler to call the finish_integration() function unique to integration tests.
setup_trap_handler_integration() {
  setup_trap_handler
  trap finish_integration exit
}

# If DELETE_AT_EXIT is set (by setup_trap_handler), create a temporary file in
# the auto-cleaned up directory while avoiding overwriting TMPDIR for other
# processes.  Otherwise, create a temporary file or directory normally as per
# mktemp.
#
# shellcheck disable=SC2120 # (Arguments may be passed, e.g. maketemp -d)
maketemp() {
  if [[ -n "${DELETE_AT_EXIT:-}" ]]; then
    TMPDIR="${DELETE_AT_EXIT}" mktemp "$@"
  else
    mktemp "$@"
  fi
}

# find_files is a helper to exclude .git directories and match only regular
# files to avoid double-processing symlinks.
find_files() {
  local pth="$1"
  shift
  # Note: Take care to use -print or -print0 when using this function,
  # otherwise excluded directories will be included in the output.
  find "${pth}" '(' \
    -path '*/.git' -o \
    -path '*/.terraform' -o \
    -path '*/.kitchen' ')' \
    -prune -o -type f "$@"
}

# Compatibility with both GNU and BSD style xargs.
compat_xargs() {
  local compat=()
  # Test if xargs is GNU or BSD style.  GNU xargs will succeed with status 0
  # when given --no-run-if-empty and no input on STDIN.  BSD xargs will fail and
  # exit status non-zero If xargs fails, assume it is BSD style and proceed.
  # stderr is silently redirected to avoid console log spam.
  if xargs --no-run-if-empty </dev/null 2>/dev/null; then
    compat=("--no-run-if-empty")
  fi
  xargs "${compat[@]}" "$@"
}

# This function makes sure that the required files for
# releasing to OSS are present
function basefiles() {
  local fn required_files="LICENSE README.md"
  echo "Checking for required files ${required_files}"
  for fn in ${required_files}; do
    test -f "${fn}" || echo "Missing required file ${fn}"
  done
}

# This function runs the hadolint linter on
# every file named 'Dockerfile'
function lint_docker() {
  echo "Running hadolint on Dockerfiles"
  find_files . -name "Dockerfile" -print0 \
    | compat_xargs -0 hadolint
}

# This function runs 'terraform validate' against all
# directory paths which contain *.tf files.
function check_terraform() {
  set -e
  # fmt is before validate for faster feedback, validate requires terraform
  # init which takes time.
  echo "Running terraform fmt"
  find_files . -name "*.tf" -print0 \
    | compat_xargs -0 -n1 dirname \
    | sort -u \
    | compat_xargs -t -n1 terraform fmt -diff -check=true -write=false
  rval="$?"
  if [[ "${rval}" -gt 0 ]]; then
    echo "Error: terraform fmt failed with exit code ${rval}" >&2
    echo "Check the output for diffs and correct using terraform fmt <dir>" >&2
    return "${rval}"
  fi
  echo "Running terraform validate"
  # Change to a temporary directory to avoid re-initializing terraform init
  # over and over in the root of the repository.
  find_files . -name "*.tf" -print \
    | grep -v 'test/fixtures/shared' \
    | compat_xargs -n1 dirname \
    | sort -u \
    | compat_xargs -t -n1 terraform_validate
}

# This function runs 'go fmt' and 'go vet' on every file
# that ends in '.go'
function golang() {
  echo "Running go fmt and go vet"
  find_files . -name "*.go" -print0 | compat_xargs -0 -n1 go fmt
  find_files . -name "*.go" -print0 | compat_xargs -0 -n1 go vet
}

# This function runs the flake8 linter on every file
# ending in '.py'
function check_python() {
  echo "Running flake8"
  find_files . -name "*.py" -print0 | compat_xargs -0 flake8
  return 0
}

# This function runs the shellcheck linter on every
# file ending in '.sh'
function check_shell() {
  echo "Running shellcheck"
  find_files . -name "*.sh" -print0 | compat_xargs -0 shellcheck -x
}

function check_trailing_whitespace() {
  echo -n 'Warning: check_trailing_whitespace is deprecated use ' >&2
  echo 'check_whitespace' >&2
  check_whitespace
}

# Check for common whitespace errors:
# Trailing whitespace at the end of line
# Missing newline at end of file
check_whitespace() {
  local rc
  echo "Checking for trailing whitespace"
  find_files . -print \
    | grep -v -E '\.(pyc|png)$' \
    | compat_xargs grep -H -n '[[:blank:]]$'
  rc=$?
  if [[ ${rc} -eq 0 ]]; then
    return 1
  fi
  echo "Checking for missing newline at end of file"
  find_files . -print \
    | compat_xargs check_eof_newline
}

function generate_docs() {
  echo "Generating markdown docs with terraform-docs"
  local path
  while read -r path; do
    if [[ -e "${path}/README.md" ]]; then
      # script seem to be designed to work into current directory
      cd "${path}" && echo "Working in ${path} ..."
      terraform_docs.sh . && echo Success! || echo "Warning! Exit code: ${?}"
      cd - >/dev/null
    else
      echo "Skipping ${path} because README.md does not exist."
    fi
  done < <(find_files . -name '*.tf' -print0 \
    | compat_xargs -0 -n1 dirname \
    | sort -u)
}

function prepare_test_variables() {
  echo "Preparing terraform.tfvars files for integration tests"
  #shellcheck disable=2044
  for i in $(find ./test/fixtures -type f -name terraform.tfvars.sample); do
    destination=${i/%.sample/}
    if [ ! -f "${destination}" ]; then
      cp "${i}" "${destination}"
      echo "${destination} has been created. Please edit it to reflect your GCP configuration."
    fi
  done
}

function check_headers() {
  echo "Checking file headers"
  # Use the exclusion behavior of find_files
  find_files . -type f -print0 \
    | compat_xargs -0 check_headers
}


# Given SERVICE_ACCOUNT_JSON with the JSON string of a service account key,
# initialize the SA credentials for use with:
# 1: terraform
# 2: gcloud
# 3: gsutil
# 4: Kitchen and inspec
#
# Add service acocunt support for additional tools as needed, preferring the
# use of environment varialbes so that the variable may be removed and an
# instance service account with Google Managed Keys used instead.
init_credentials() {
  if [[ -z "${SERVICE_ACCOUNT_JSON:-}" ]]; then
    echo "Info: SERVICE_ACCOUNT_JSON is not set.  init_credentials() has no effect." >&2
    return 0
  fi

  local tmpfile
  # shellcheck disable=SC2119
  tmpfile="$(maketemp)"
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

setup_environment() {
  echo 'Warning: setup_environment is deprecated.  Use init_credentials instead.' >&2
  init_credentials
}

# This function is called by /usr/local/bin/test_integration.sh and can be
# overridden on a per-module basis to implement additional steps.
run_integration_tests() {
  kitchen create
  kitchen converge
  kitchen verify
}

# Integration testing requires `kitchen destroy` to be called up before the
# environment is cleaned up.
finish_integration() {
  local rv=$?
  kitchen destroy
  finish
  exit "${rv}"
}

# Intended to allow a module to customize a particular check or behavior.  For
# example, the pubsub module runs "kitchen converge" twice instead of the
# default one time.
if [[ -e /workspace/test/task_helper_functions.sh ]]; then
  # shellcheck disable=SC1091 # (May not exist)
  source /workspace/test/task_helper_functions.sh
fi
