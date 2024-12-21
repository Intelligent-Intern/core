#!/bin/bash

if [[ "$(whoami)" != "root" ]]; then
  echo "This script must be run as root to stop processes and modify var folder."
  exit 0;
fi

# get the group of the logged in user
# we want to give group permission to volumes so we can delete and look into that stuff
# shellcheck disable=SC2034
LOCAL_USER="${SUDO_USER:-$(whoami)}"

# Ensure we are in the correct directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"/../../ || exit

echo "Source .env vars"
set -a
source .env.local
source ./config/.env.pypi
source ./config/.env.docker
source ./config/.env.vault
set +a
echo "Source libs"
source ./infra/scripts/utils.sh
source ./infra/scripts/configure-vault.sh

main() {
    VAULT_SECRET_ID=empty
    VAULT_ROLE_ID=empty
    stop_all_docker_containers
    message "Init system"
    init_system
    message "Starting traefik..."
    sudo -u"$LOCAL_USER" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --env-file .env.local --profile infra up --remove-orphans -d
    wait_for_traefik
    mkdir -p "./var/vault"
    chown -R 8200:8200 ./var/vault
    configure_vault
    add_secrets_to_vault
    message "Sourcing vault role id and secret id" 15 0
    source ./config/.env.vault
    if [ -z "$VAULT_ROLE_ID" ]; then
      echo "Error: VAULT_ROLE_ID is not set. Exiting."
      exit 1
    else
      echo "VAULT_ROLE_ID is: $VAULT_ROLE_ID"
    fi
    message "Starting the containers - rabbitmq, minio, timescale/postgis,..."
    start_containers
    message "Starting Grafana for Metric and Log Visualisation - want to see errors or communication with oai models?"
     sudo -u"$LOCAL_USER" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --env-file .env.local --profile data-visualisation up -d grafana
    for i in {5..0}; do
        echo -ne "Waiting for the application to be ready in $i seconds.\r"
        sleep 1
    done
    echo "it might take a lot longer for pgadmin to be ready - be patient"
    message "Welcome to automation local development infrastructure" 6 0
    show_tools
}

main "$@"