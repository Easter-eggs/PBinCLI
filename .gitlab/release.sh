#!/bin/bash

echo "Creating a release for $CI_COMMIT_TAG"

cd "$( dirname "$0" )/../dist" || { echo "dist directory not found"; exit 1; }
[[ -f release-files.txt ]] || { echo "release-files.txt file is missing"; exit 1; }
for var in CI_API_V4_URL CI_PROJECT_ID CI_PROJECT_NAME CI_JOB_TOKEN CI_COMMIT_TAG CI_COMMIT_SHA; do
    [[ -n "${!var}" ]] || { echo "$var variable is missing"; exit 1; }
done

PACKAGE_REGISTRY_URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/${CI_PROJECT_NAME}/${CI_COMMIT_TAG}"
args=(
	create
	--name "$CI_COMMIT_TAG"
	--description release-notes.md
	--tag-name "$CI_COMMIT_TAG"
	--ref "$CI_COMMIT_SHA"
)
while read -r file; do
	args+=(
		--assets-link
		"$( jo name="$file" url="${PACKAGE_REGISTRY_URL}/$file" link_type=package )"
	)
done < release-files.txt

release-cli "${args[@]}"
