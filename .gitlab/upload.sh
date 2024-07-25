#!/bin/bash

cd "$( dirname "$0" )/../dist" || { echo "dist directory not found"; exit 1; }
for var in CI_API_V4_URL CI_PROJECT_ID CI_JOB_TOKEN CI_PROJECT_NAME CI_COMMIT_TAG; do
    [[ -n "${!var}" ]] || { echo "$var variable is missing"; exit 1; }
done


rm -f release-files.txt
touch release-files.txt

PACKAGE_REGISTRY_URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/${CI_PROJECT_NAME}/${CI_COMMIT_TAG}"
echo "Upload debian built packages to Gitlab package registry (${PACKAGE_REGISTRY_URL}):"
for file in *.deb *.whl; do
	# The filename can contain only lowercase letters (a-z), uppercase letter (A-Z), numbers (0-9),
	# dots (.), hyphens (-), or underscores (_).
	filename=$( tr '~' '_' <<< "$file" | tr '+' '_' | sed 's/[^a-zA-Z0-9\.\_\-]//g' )
    echo -n " - Upload '$file' as '$filename'..."
    if ! output=$(
        curl -v --fail-with-body \
            --header "JOB-TOKEN: $CI_JOB_TOKEN" \
            --upload-file "$file" \
            "${PACKAGE_REGISTRY_URL}/${filename}" 2>&1
    ); then
        echo
        # shellcheck disable=SC2001
        echo -e "   => Fail to upload '$file' as '$filename':\n$( sed 's/^/      /' <<< "$output" )"
        exit 1
    fi
    echo " done."
    echo "$filename" >> release-files.txt
done
echo "done."
