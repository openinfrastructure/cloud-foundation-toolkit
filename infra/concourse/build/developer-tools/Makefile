SHELL := /usr/bin/env bash # Make will use bash instead of sh

TERRAFORM_VERSION := 0.12.5
CLOUD_SDK_VERSION := 255.0.0
GSUITE_PROVIDER_VERSION := 0.1.22
TERRAFORM_DOCS_VERSION := 0.6.0
RUBY_VERSION := 2.6.3

DOCKER_TAG_VERSION_DEVELOPER_TOOLS := 0.0.1
DOCKER_IMAGE_DEVELOPER_TOOLS := cft/developer-tools
REGISTRY_URL := gcr.io/cloud-foundation-cicd


.PHONY: build-image-developer-tools
build-image-developer-tools:
	docker build \
		--build-arg CLOUD_SDK_VERSION=${CLOUD_SDK_VERSION} \
		--build-arg GSUITE_PROVIDER_VERSION=${GSUITE_PROVIDER_VERSION} \
		--build-arg TERRAFORM_VERSION=${TERRAFORM_VERSION} \
		--build-arg TERRAFORM_DOCS_VERSION=${TERRAFORM_DOCS_VERSION} \
		--build-arg RUBY_VERSION=${RUBY_VERSION} \
		-t ${DOCKER_IMAGE_DEVELOPER_TOOLS}:${DOCKER_TAG_VERSION_DEVELOPER_TOOLS} .

.PHONY: release-image-developer-tools
release-image-developer-tools:
	docker tag ${DOCKER_IMAGE_DEVELOPER_TOOLS}:${DOCKER_TAG_VERSION_DEVELOPER_TOOLS} \
  ${REGISTRY_URL}/${DOCKER_IMAGE_DEVELOPER_TOOLS}:${DOCKER_TAG_VERSION_DEVELOPER_TOOLS}
	docker push ${REGISTRY_URL}/${DOCKER_IMAGE_DEVELOPER_TOOLS}:${DOCKER_TAG_VERSION_DEVELOPER_TOOLS}

# The docker_run task is provided as an example and reference for other CFT
# Terraform modules to use.  Each module should have an identical `make
# docker_run` task in the module's repository.
.PHONY: docker_run
docker_run: ## Launch a shell within the Docker test environment
	docker run --rm -it \
		-e SERVICE_ACCOUNT_JSON \
		-v $(CURDIR):/workspace \
		cft/developer-tools:0.0.1 \
		/bin/bash

.PHONY: docker_test_lint
docker_test_lint:
	docker run --rm -it \
		-v $(CURDIR):/workspace \
		cft/developer-tools:0.0.1 \
		make test_lint

.PHONY: test_lint
test_lint: check_shell check_headers check_python

.PHONY: check_headers
check_headers:
	@source /usr/local/bin/task_helper_functions.sh && check_headers

.PHONY: check_shell
check_shell:
	@source /usr/local/bin/task_helper_functions.sh && check_shell

.PHONY: check_python
check_python:
	@source /usr/local/bin/task_helper_functions.sh && check_python
