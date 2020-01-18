#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
FACTORIO_ROOT=$script_dir/../..

for lib in "${FACTORIO_ROOT}"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

# Push locations.json to Storage
gsutil_args=(
  cp
  -P
  "${FACTORIO_ROOT}/lib/locations.json"
  gs://jlucktay-factorio-storage/lib/locations.json
)

gsutil "${gsutil_args[@]}"

# Submit build and block (not async)
substitutions=(
  "_IMAGE_FAMILY=$FACTORIO_IMAGE_FAMILY"
  "_IMAGE_NAME=$FACTORIO_IMAGE_NAME"
  "_IMAGE_ZONE=$FACTORIO_IMAGE_ZONE"
)

gcloud \
  builds \
  submit \
  --config="$script_dir/cloudbuild.yaml" \
  --substitutions="$(factorio::join_by , "${substitutions[@]}")" \
  "$script_dir"

# Clean up old image(s); all but most recent
gcloud_args=(
  "--format=json"
  compute
  images
  list
  "--filter=family:$FACTORIO_IMAGE_FAMILY"
  '--sort-by=~creationTimestamp'
)

images=$(gcloud "${gcloud_args[@]}")

# 'i' starts from 1 to preserve the first/newest image
for ((i = 1; i < $(jq length <<< "$images"); i += 1)); do
  image_name=$(jq --raw-output ".[$i].name" <<< "$images")

  echo "Pruning old image '$image_name'..."
  gcloud \
    compute \
    images \
    delete \
    --quiet \
    "$image_name"
done
