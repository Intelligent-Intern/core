#!/bin/bash
set -e

if [[ "$(whoami)" != "root" ]]; then
  echo "This script must be run as root to stop processes and modify var folder."
  exit 0;
fi

LOCAL_USER="${SUDO_USER:-$(whoami)}"
LOCAL_GROUP=$(id -gn "$LOCAL_USER")
if ! getent group "$(id -g "$LOCAL_USER")" &> /dev/null; then
    echo "Group with GID $(id -g "$LOCAL_USER") not found. Creating group..."
    sudo groupadd --gid "$(id -g "$LOCAL_USER")" "$LOCAL_GROUP"
fi
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
# once those files exist we don't check and install docker or python anymore
PYTHON_PREFS_FILE="./var/preferences/.python_preferences"
DOCKER_PREFS_FILE="./var/preferences/.docker_preferences"

source ./infra/scripts/utils.sh
source ./infra/scripts/container-utils.sh
source ./infra/scripts/install-python-and-ensure-venv.sh
source ./infra/scripts/create-postgres-exporter-yml.sh
source ./infra/scripts/configure-docker.sh
source ./infra/scripts/configure-private-pypi.sh
source ./infra/scripts/configure-vault.sh

set -a
source ./.env.local
source ./config/.env.pypi
source ./config/.env.docker
set +a

main() {
  # be careful here:
  # run_reset

  VAULT_SECRET_ID=empty
  VAULT_ROLE_ID=empty
  init_system
  # while we are developing the build script we always delete this... normally the build script is only run once anyways
  # after that we should use the make up command
  rm -rf var/minio/ var/rabbitmq/
  update_hosts_file
  systemctl start docker
  # shellcheck disable=SC2034
  ENVIRONMENT="develop"
  stop_all_docker_containers
  systemctl restart docker
  mkdir -p "./var/rabbitmq/data" \
    "./var/traefik/certificates" \
    "./var/grafana" \
    "./var/vault/data/sys" \
    "./var/vault/log" \
    "./var/neo4j/data" \
    "./var/postgres/data" \
    "./var/neo4j/logs"
  chown -R "$LOCAL_USER": ./var
  chown -R 472:472 ./var/grafana
  chown -R 8200:8200 ./var/vault
  chown -R 7474:7474 ./var/neo4j/data
  chown -R 7474:7474 ./var/neo4j/logs
  chmod -R 777 ./var/neo4j/data
  chmod -R 777 ./var/neo4j/logs
  chown 7474:7474 ./infra/db/neo4j/neo4j.conf
  chmod 644 ./infra/db/neo4j/neo4j.conf
  install_docker_and_compose
  install_python_and_venv
  setup_env_local
  check_and_install_mkcert
  create_postgres_exporter_yml
  message "Init system"
  ensure_symfony_container
  ensure_nodejs_app_container
  ensure_python_app_container
  update_certs
  message "Starting traefik..."
  sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --env-file .env.local --profile infra up --build --remove-orphans -d
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
  ensure_docker_login
  ensure_pypi_private_repo_login
  create_pypi_env
  echo "Starting containers..."
  start_containers_and_run_scripts
  configure_keycloak
  rm -rf ./var/grafana
  mkdir -p ./var/grafana/data
  chown -R 472:472 ./var/grafana
  echo "Starting Grafana for Metric and Log Visualisation - want to see errors or communication with oai models?"
  start_service_with_retry grafana data-visualisation || exit 1
  chown "$LOCAL_USER":"$LOCAL_GROUP" -R "$PYTHON_PREFS_FILE"
  chown "$LOCAL_USER":"$LOCAL_GROUP" -R "$DOCKER_PREFS_FILE"
  chown "$LOCAL_USER":"$LOCAL_GROUP" -R ./config
  chown "$LOCAL_USER":"$LOCAL_GROUP" -R .env.local
  for i in {5..0}; do
      echo -ne "Waiting for the application to be ready in $i seconds.\r"
      sleep 1
  done
  echo "It might take a lot longer for pgadmin to be ready - be patient"
  message "   Welcome to intelligent intern local development infrastructure  " 10 0
  show_tools
}

main "$@"