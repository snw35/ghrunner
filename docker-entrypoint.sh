#!/usr/bin/env bash
set -e

# ensure correct HOME when dropping privileges
set_runner_env() {
  RUNNER_HOME=$(getent passwd runner | cut -d: -f6)
  if [ -z "$RUNNER_HOME" ]; then
    RUNNER_HOME=/home/runner
  fi
  export HOME="$RUNNER_HOME"
  export USER=runner
  export LOGNAME=runner
  export XDG_CONFIG_HOME="$RUNNER_HOME/.config"
}

# drop root privileges after fixing docker.sock group ownership
drop_to_runner() {
  set_runner_env
  if command -v setpriv >/dev/null 2>&1; then
    exec setpriv --reuid=runner --regid=runner --init-groups /docker-entrypoint.sh "$@"
  elif command -v runuser >/dev/null 2>&1; then
    exec runuser -u runner -- /docker-entrypoint.sh "$@"
  else
    exec su -s /bin/bash runner -c "$(printf '%q ' /docker-entrypoint.sh "$@")"
  fi
}

# this if will check if the first argument is a flag
# but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "${1:0:1}" = '-' ]; then
    set -- /opt/actions-runner/run.sh "$@"
fi

if [ "$(id -u)" = "0" ]; then
  DOCKER_SOCK=${DOCKER_SOCK:-/var/run/docker.sock}
  if [ -S "$DOCKER_SOCK" ]; then
    DOCKER_SOCK_GID=$(stat -c '%g' "$DOCKER_SOCK")
    if getent group "$DOCKER_SOCK_GID" >/dev/null 2>&1; then
      DOCKER_GROUP=$(getent group "$DOCKER_SOCK_GID" | cut -d: -f1)
    else
      if getent group docker-host >/dev/null 2>&1; then
        groupmod -g "$DOCKER_SOCK_GID" docker-host
      else
        groupadd -g "$DOCKER_SOCK_GID" docker-host
      fi
      DOCKER_GROUP=docker-host
    fi
    usermod -a -G "$DOCKER_GROUP" runner
  fi

  if [ -n "$RUNNER_WORKDIR" ]; then
    mkdir -p "$RUNNER_WORKDIR"
    chown -R runner:runner "$RUNNER_WORKDIR"
  fi

  drop_to_runner "$@"
fi

# check if running run.sh
if [ "$1" = '/opt/actions-runner/run.sh' ]; then
  REPOSITORY_TOKEN=$(curl -L -X POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPOSITORY}/actions/runners/registration-token" | jq .token --raw-output)
  WORKDIR_ARGS=()
  if [ -n "$RUNNER_WORKDIR" ]; then
    WORKDIR_ARGS+=(--work "$RUNNER_WORKDIR")
  fi
  /opt/actions-runner/config.sh --unattended --url "https://github.com/${REPOSITORY}" --token "$REPOSITORY_TOKEN" --disableupdate --replace --name "$RUNNER_NAME" --labels "gpu" --labels "dind" "${WORKDIR_ARGS[@]}"
  exec /opt/actions-runner/run.sh
fi

# else default to run whatever the user wanted like "bash"
exec "$@"
