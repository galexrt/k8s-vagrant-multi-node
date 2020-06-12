#!/bin/bash

IGNORE_REGEX=".git.*|.md|LICENSE"
SKIP_BUILD=True

while read -r file; do
    if ! echo "$file" | grep -Pq "$IGNORE_REGEX"; then
        SKIP_BUILD=False
        break
    fi
done < <(git diff --name-only master..."${TRAVIS_COMMIT}")

if [[ $SKIP_BUILD == True ]]; then
    echo "Only changed files that are ignored have been found. Terminating Travis run."
    travis_terminate 0
    exit 0
else
    echo "Other non-ignored files have been found. Contiuning with run ..."
fi
