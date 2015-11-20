#!/usr/bin/env bash

set -e

. ./bootstrap.sh

runPlaybook -d provisioning/ansible_role_dependencies.yml "$@" provisioning/mavenBuild.yml
