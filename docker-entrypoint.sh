#!/usr/bin/env bash
set -e

# this if will check if the first argument is a flag
# but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "${1:0:1}" = '-' ]; then
    set -- /opt/actions-runner/run.sh "$@"
fi

# check if running run.sh
if [ "$1" = '/opt/actions-runner/run.sh' ]; then
  REPOSITORY_TOKEN=$(curl -L -X POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPOSITORY}/actions/runners/registration-token" | jq .token --raw-output)
  /opt/actions-runner/config.sh --unattended --url "https://github.com/${REPOSITORY}" --token "$REPOSITORY_TOKEN" --disableupdate --replace --name "$RUNNER_NAME"
  exec /opt/actions-runner/run.sh
fi

# else default to run whatever the user wanted like "bash"
exec "$@"
