#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

# shellcheck disable=SC2154
export TF_CLI_ARGS_init="-backend-config=\"bucket=$CLOUDSDK_CORE_PROJECT-tfstate\""

terraform init
