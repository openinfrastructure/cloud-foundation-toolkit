#!/bin/bash

set -e
set -u

# coreutils provides xargs and other utilities necessary for lint checks
apk add --no-cache coreutils

# curl is used by unit tests and is nice to have
apk add --no-cache curl

# findutils provides find which is used by lint checks
apk add --no-cache findutils

# git is used to clone repositories
apk add --no-cache git

# go is used for go lint checks
apk add --no-cache go

# grep is used by lint checks
apk add --no-cache grep

# g++ is probably used to install dependencies like psych, but unsure
apk add --no-cache g++

# jq is useful for parsing JSON data
apk add --no-cache jq

# make is used for executing make tasks
apk add --no-cache make

# musl-dev provides the standard C headers
apk add --no-cache musl-dev

# openssh is used for ssh-ing into bastion hosts
apk add --no-cache openssh

# unclear why perl is needed, but is good to have
apk add --no-cache perl

# python 2 is needed for compatibility and linting
apk add --no-cache python

# python 3 is needed for python linting
apk add --no-cache python3

# py-pip is needed for installing pip packages
apk add --no-cache py-pip

# ca-certificates is needed to verify the authenticity of artifacts downloaded
# from the internet
apk add --no-cache ca-certificates

# flake8 and jinja2 are used for lint checks
pip install flake8 jinja2