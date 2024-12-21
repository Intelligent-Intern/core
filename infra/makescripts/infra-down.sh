#!/bin/bash

# shellcheck disable=SC2034
ENVIRONMENT="develop"

if [[ "$(whoami)" != "root" ]]; then
  echo "This script must be run as root to stop processes."
  exit 0;
fi

source ./infra/scripts/utils.sh

main() {
    stop_all_docker_containers
}

main "$@"