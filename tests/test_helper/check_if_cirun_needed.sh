#!/bin/bash

IGNORE_REGEX=".md|LICENSE"
SKIP_BUILD=True

set -x

CHANGED_FILES="$(git diff --name-only "$(git merge-base HEAD master)..HEAD")"

echo "Files changed:"
echo "$CHANGED_FILES"

while read -r file; do
    if ! echo "${file}" | grep -Pq "${IGNORE_REGEX}"; then
        SKIP_BUILD=False
        break
    fi
done <<< "${CHANGED_FILES}"

if [[ ${SKIP_BUILD} == True ]]; then
    echo "All changed files are ignored. Terminating Travis run."
    exit 1
else
    echo "Found non-ignored files. Contiuning with run ..."
fi
