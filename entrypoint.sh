#!/bin/bash
set -e

if [ -n "$GITHUB_EVENT_PATH" ]; then
    EVENT_PATH=$GITHUB_EVENT_PATH
elif [ -f ./sample_push_event.json ]; then
    EVENT_PATH="./sample_push_event.json"
    LOCAL_TEST=true
else
    echo "No JSON data to process"
    exit 1
fi

env
jq . < $EVENT_PATH

if jq '.commits[].message, .head_commit.message' < $EVENT_PATH | grep -i -q "$*"; then
    VERSION=$(date +%F.%s)
    DATA="$(printf '{"tag_name":"v%s",' $VERSION)"
    DATA="${DATA} $(printf '"target_commitish":"main",')"
    DATA="${DATA} $(printf '"name":"v%s",' $VERSION)"
    DATA="${DATA} $(printf '"body":"Automated release based on keyword: %s",' "$*")"
    DATA="${DATA} $(printf '"draft":false, "prerelease":false}')"

    URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/releases"

    if [[ "${LOCAL_TEST}" == *"true"* ]]; then
        echo "## [TESTING] Keyword was found but no release was crated."
    else
        echo $DATA | http POST $URL "Authorization: token ${GITHUB_TOKEN}" | jq .
    fi
else
    echo "Nothing to process."
fi
