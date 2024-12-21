#!/bin/bash
set -e
if [[ "$(whoami)" != "root" ]]; then
    echo "This script must be run as root."
    exit 0;
fi
LOCAL_USER="${SUDO_USER:-$(whoami)}"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Check if DIR is empty or set to root "/"
if [[ -z "$DIR" || "$DIR" == "/" ]]; then
    echo "Error: Script is running from an invalid directory (root or undefined). Exiting."
    exit 1
fi
# change to root
cd "$DIR"/../../ || exit
# Path to docker-compose.yml - because if we are inside project root then there should be this file
DOCKER_COMPOSE_FILE="./docker-compose.yml"
# Check if utils.sh exists
if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
    echo "Error: Required file '$DOCKER_COMPOSE_FILE' does not exist - we might not be in the right directory. Exiting."
    exit 1
fi

set -a
source ./.env.local
set +a
source ./infra/scripts/utils.sh

start_containers() {
    message "Restarting neo4j" 3 0
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile neo4j --env-file .env.local down
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile neo4j --env-file .env.local up --build -d
}

main() {
    VAULT_SECRET_ID=empty
    VAULT_ROLE_ID=empty
    rm -rf var/neo4j
    mkdir -p "./var/neo4j/data" \
      "./var/neo4j/logs"
    chown -R 7474:7474 ./var/neo4j/data
    chown -R 7474:7474 ./var/neo4j/logs
    chmod -R 777 ./var/neo4j/data
    chmod -R 777 ./var/neo4j/logs
    chown 7474:7474 ./infra/db/neo4j/neo4j.conf
    chmod 644 ./infra/db/neo4j/neo4j.conf
    start_containers
    for i in {5..0}; do
        echo -ne "Waiting for the application to be ready in $i seconds.\r"
        sleep 1
    done
    message "Neo4j has been restarted" 10 0
    show_tools
}
main "$@"