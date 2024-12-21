#!/bin/bash
set -e

if [[ "$(whoami)" != "root" ]]; then
  echo "This script must be run as root to stop processes and modify var folder."
  exit 0;
fi
LOCAL_USER="${SUDO_USER:-$(whoami)}"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Check if DIR is empty or set to root "/"
if [[ -z "$DIR" || "$DIR" == "/" ]]; then
    echo "Error: Script is running from an invalid directory (root or undefined). Exiting."
    exit 1
fi
# change to project root
cd "$DIR"/../../ || exit
# Path to docker-compose.yml - because if we are inside project root then there should be this file
DOCKER_COMPOSE_FILE="./docker-compose.yml"
# Check if utils.sh exists
if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
    echo "Error: Required file '$DOCKER_COMPOSE_FILE' does not exist - we might not be in the right directory. Exiting."
    exit 1
fi
source ./infra/scripts/utils.sh
source ./infra/scripts/configure-docker.sh
source ./infra/scripts/configure-private-pypi.sh
# now we should have all env.vars
set -a
source ./.env.local
source ./config/.env.pypi
source ./config/.env.docker
source ./config/.env.vault
set +a

export VAULT_URL="$VAULT_URL"
export VAULT_ROLE_ID="$VAULT_ROLE_ID"
export VAULT_SECRET_ID="$VAULT_SECRET_ID"

start_containers() {
    message "Restarting the application" 0 6
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile python_demo --env-file .env.local down
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile python_demo --env-file .env.local up --build -d
}

main() {
  ensure_docker_login
  ensure_pypi_private_repo_login
  start_containers
  message "   Container was restarted  " 6 0
  show_tools
}

main "$@"