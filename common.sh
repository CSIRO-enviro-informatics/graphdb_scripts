#!/bin/bash
set -e

export AWS_ACCESS_KEY_ID="${LOCI_S3_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${LOCI_S3_SECRET_ACCESS_KEY}"

SCRIPT_HOME=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

#import env vars to shell
export $(grep -v '^#' ${SCRIPT_HOME}/common.env | sed '/^$/d' | xargs -0)