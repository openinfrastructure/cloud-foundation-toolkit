ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION-alpine

# Required to download and install Terraform
ARG TERRAFORM_VERSION
ENV TERRAFORM_VERSION ${TERRAFORM_VERSION}

# Required to download and install the Terraform gsuite provider
ARG PROVIDER_GSUITE_VERSION
ENV PROVIDER_GSUITE_VERSION ${PROVIDER_GSUITE_VERSION}

# Required to download and install Google Cloud SDK
# Google Cloud SDK is located at /usr/local/google-cloud-sdk
ARG CLOUD_SDK_VERSION
ENV CLOUD_SDK_VERSION ${CLOUD_SDK_VERSION}

# $WORKSPACE is intended for assets that persist across multiple build steps in a pipeline.
# It's also where the project git repository is located.
# https://cloud.google.com/cloud-build/docs/build-config
ENV WORKSPACE="/workspace"
ENV PATH /usr/local/google-cloud-sdk/bin:$PATH

# Copy the contents of build to /build to access files necessary during the build step
ADD ./build /build

# bash is preferred over /bin/sh
RUN apk add --no-cache bash

# All package-level dependencies are handled by install_dependencies.sh
RUN /build/install_dependencies.sh
