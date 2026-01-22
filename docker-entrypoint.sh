#!/usr/bin/env bash
set -e

# this if will check if the first argument is a flag
# but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "${1:0:1}" = '-' ]; then
    set -- run.sh "$@"
fi

# check if running run.sh
if [ "$1" = 'run.sh' ]; then
  REPOSITORY_TOKEN=$(curl -X POST -H "Authorization: token ${ACCESS_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${REPOSITORY}/actions/runners/registration-token | jq .token --raw-output)
  config.sh --unattended --url $REPOSITORY_URL --token $REPOSITORY_TOKEN --disableupdate --replace [--name $RUNNER_NAME]
  exec run.sh "$@"
fi

# else default to run whatever the user wanted like "bash"
exec "$@"
