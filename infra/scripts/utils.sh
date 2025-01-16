#!/bin/bash

# colors:
# 1 = orange
# 2 grey green
# 3 yellow
# 4 grey blue
# 5 light purple
# 6 mint
# 7 snow
# 8 grey
# 9 red <<< nice for error
# 10 green <<< nice for success
# 11 orange <<<< nice for warning
# 12 medium light blue
# 13 pink
# 14 medium light green
# 15 white
# 16 black
# 17 dark blue
# 18 medium dark blue
# 19 blue
message() {
    local str color bgcolor boxwidth term_width
    str=${1}
    bgcolor=${2:-0}
    color=${3:-7}
    # Get terminal width, or default to 120 if unavailable
    term_width=$(tput cols 2>/dev/null || echo 120)
    boxwidth=${4:-$term_width}
    # Set color codes
    bgcmd=$(tput setab "$bgcolor")
    colorcmd=$(tput setaf "$color")
    normal=$(tput sgr0)
    echo ""
    # Print top border without line break
    echo -ne "${bgcmd}"
    printf "%*s" "$boxwidth" "" | tr ' ' ' '
    # Print centered message without line break
    echo -ne "${bgcmd}${colorcmd}"
    printf "%*s%s%*s" $(( (boxwidth - ${#str}) / 2 )) "" "$str" $(( (boxwidth - ${#str} + 1) / 2 )) ""
    # Print bottom border without line break
    echo -ne "${bgcmd}"
    printf "%*s" "$boxwidth" "" | tr ' ' ' '
    # Reset colors
    echo -e "${normal}"
    echo ""
    sleep 0.2
}

ask_user() {
    local question="$1"
    local response
    local green="\033[1;32m"
    local red="\033[1;31m"
    local yellow="\033[1;33m"
    local reset="\033[0m"
    while true; do
        echo -e "${yellow}$question${reset} ${green}[y]${reset}/${red}[n]${reset}: \c"
        read -r response
        case "$response" in
            [Yy]* ) return 0 ;;  # yes -> success (Exit-Code 0)
            [Nn]* ) return 1 ;;  # no -> Fehler (Exit-Code 1)
            * ) echo -e "${red}Invalid input. Please enter 'y' or 'n'.${reset}" ;;
        esac
    done
}

# just in case you want to watch the output of an upping container until a specific shell output is found
# unused at the moment (unless you use it and forget to remove this comment)
follow_logs_until() {
    local container_name=$1
    local search_term=$2
    echo "Following logs for $container_name until '$search_term' is found..."
    (sudo docker logs -f "$container_name" 2>&1 | tee /dev/tty | grep --line-buffered -q "$search_term") &
    wait $!
    echo "'$search_term' found in $container_name. Stopping log follow."
}

rabbitmq_ready() {
    nc -z rabbitmq.local 5672
    return $?
}

wait_for_rabbitmq() {
    echo "Waiting for RabbitMQ to become responsive..."
    until rabbitmq_ready; do
        echo "Waiting for RabbitMQ to be responsive..."
        sleep 1
    done
}

minio_ready() {
    nc -z minio.local 9000
    return $?
}

wait_for_minio() {
    echo "Waiting for Minio to become responsive..."
    until minio_ready; do
        echo "Waiting for Minio to be responsive..."
        sleep 1
    done
}

traefik_ready() {
    nc -z traefik.local 80
    return $?
}

wait_for_traefik() {
    echo "Waiting for Traefik to become responsive..."
    until traefik_ready; do
        echo "Waiting for Traefik to be responsive..."
        sleep 1
    done
}

setup_env_local() {
    local ENV_FILE="./config/.env"
    local ENV_LOCAL_FILE="./.env.local"
    local OPENAI_API_KEY_NAME="OPENAI_API_KEY"
    local APP_SECRET_KEY_NAME="APP_SECRET_KEY"
    local OAI_PROVIDER_NAME="OAI_PROVIDER"
    if [[ -f "$ENV_LOCAL_FILE" ]]; then
        echo "$ENV_LOCAL_FILE already exists. Skipping setup."
        return
    fi
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "Error: $ENV_FILE not found. Cannot proceed."
        exit 1
    fi
    echo "Creating $ENV_LOCAL_FILE from $ENV_FILE..."
    cp "$ENV_FILE" "$ENV_LOCAL_FILE"
    if ask_user "Do you want to use Azure as your OAI provider?"; then
        echo "$OAI_PROVIDER_NAME=\"azure\"" >> "$ENV_LOCAL_FILE"
    else
        echo "$OAI_PROVIDER_NAME=\"openai\"" >> "$ENV_LOCAL_FILE"
    fi
    if ask_user "Do you want to set up your OpenAI API Key?"; then
        read -rp "Enter your OpenAI API Key (e.g., sk-proj-...): " OPENAI_API_KEY
        if [[ -z "$OPENAI_API_KEY" ]]; then
            echo "No OpenAI API Key entered. Exiting setup."
            exit 1
        fi
        echo "$OPENAI_API_KEY_NAME=\"$OPENAI_API_KEY\"" >> "$ENV_LOCAL_FILE"
        echo "OpenAI API Key added to $ENV_LOCAL_FILE."
    else
        echo "OpenAI API Key setup skipped. Exiting script."
        exit 1
    fi
    echo "Generating a random APP_SECRET_KEY..."
    # shellcheck disable=SC2155
    local APP_SECRET_KEY="iiAppKey_$(tr -dc 'a-zA-Z0-9_' < /dev/urandom | head -c 50)"
    echo "$APP_SECRET_KEY_NAME=\"$APP_SECRET_KEY\"" >> "$ENV_LOCAL_FILE"
    echo "APP_SECRET_KEY added to $ENV_LOCAL_FILE."
    echo "$ENV_LOCAL_FILE setup complete."
}

init_system() {

    [[ -d ./var/rabbitmq ]] && [[ -d ./var/rabbitmq/data/mnesia ]] && rm -rf ./var/rabbitmq/data/mnesia 2>/dev/null
    [[ -f ./var/rabbitmq/data/.erlang.cookie ]] && rm ./var/rabbitmq/data/.erlang.cookie 2>/dev/null
    [[ -f ./config/.env.vault ]] && rm ./config/.env.vault 2>/dev/null
    [[ -d ./var/vault ]] && rm -rf ./var/vault 2>/dev/null
    docker compose down --volumes
    docker volume prune -f
    sleep 1

    docker stop vault 2>/dev/null && docker rm -f vault 2>/dev/null
    docker stop minio 2>/dev/null && docker rm -f minio 2>/dev/null
    docker stop db 2>/dev/null && docker rm -f db 2>/dev/null
    docker stop pgadmin 2>/dev/null && docker rm -f pgadmin 2>/dev/null
    docker stop rabbitmq 2>/dev/null && docker rm -f rabbitmq 2>/dev/null
    docker stop traefik 2>/dev/null && docker rm -f traefik 2>/dev/null
    docker stop postgres_exporter 2>/dev/null && docker rm -f postgres_exporter 2>/dev/null
    docker stop prometheus 2>/dev/null && docker rm -f prometheus 2>/dev/null
    docker stop loki 2>/dev/null && docker rm -f loki 2>/dev/null
    docker stop grafana 2>/dev/null && docker rm -f grafana 2>/dev/null
    docker stop redis 2>/dev/null && docker rm -f redis 2>/dev/null
    docker stop n8n 2>/dev/null && docker rm -f redis 2>/dev/null
    docker stop redis-commander 2>/dev/null && docker rm -f redis-commander 2>/dev/null
    docker stop cadvisor 2>/dev/null && docker rm -f cadvisor 2>/dev/null

    echo ''
}

# we need to make sure not to have post conflicts with other projects you work on
# used by run and build script
stop_all_docker_containers() {
    if [[ "$ENVIRONMENT" == "develop" || "$ENVIRONMENT" == "test" ]]; then
        echo "KILL all running Docker containers - just to make sure."
        if ! systemctl is-active --quiet docker; then
            echo "Docker daemon is not running. Please start it."
            exit 1
        fi
        if [[ -n "$(docker ps -q)" ]]; then
            echo "Stopping running containers..."
            docker kill "$(docker ps -q)" > /dev/null 2>&1 || echo "Failed to stop some containers."
        else
            echo "No containers are running."
        fi
        echo "Pruning Docker containers, networks, volumes, and images."
        docker system prune -f > /dev/null 2>&1
    else
        echo "ARE YOU NUTS?"
        exit 1
    fi
    docker stop vault 2>/dev/null && docker rm -f vault 2>/dev/null
    docker stop minio 2>/dev/null && docker rm -f minio 2>/dev/null
    docker stop db 2>/dev/null && docker rm -f db 2>/dev/null
    docker stop pgadmin 2>/dev/null && docker rm -f pgadmin 2>/dev/null
    docker stop rabbitmq 2>/dev/null && docker rm -f rabbitmq 2>/dev/null
    docker stop traefik 2>/dev/null && docker rm -f traefik 2>/dev/null
    docker stop postgres_exporter 2>/dev/null && docker rm -f postgres_exporter 2>/dev/null
    docker stop prometheus 2>/dev/null && docker rm -f prometheus 2>/dev/null
    docker stop loki 2>/dev/null && docker rm -f loki 2>/dev/null
    docker stop grafana 2>/dev/null && docker rm -f grafana 2>/dev/null
    docker stop redis 2>/dev/null && docker rm -f redis 2>/dev/null
    docker stop n8n 2>/dev/null && docker rm -f n8n 2>/dev/null
    docker stop redis_commander 2>/dev/null && docker rm -f redis_commander 2>/dev/null
    docker stop symfony 2>/dev/null && docker rm -f symfony 2>/dev/null
    docker stop keycloak 2>/dev/null && docker rm -f keycloak 2>/dev/null
    docker stop mercure 2>/dev/null && docker rm -f mercure 2>/dev/null
    docker stop neo4j 2>/dev/null && docker rm -f neo4j 2>/dev/null
    docker stop mailcatcher 2>/dev/null && docker rm -f mailcatcher 2>/dev/null
    docker stop python_demo 2>/dev/null && docker rm -f python_demo 2>/dev/null
    docker stop pdf_split_service 2>/dev/null && docker rm -f pdf_split_service 2>/dev/null
    docker stop n8n_setup 2>/dev/null && docker rm -f n8n_setup 2>/dev/null
    docker stop redis-commander 2>/dev/null && docker rm -f redis-commander 2>/dev/null
    docker stop cadvisor 2>/dev/null && docker rm -f cadvisor 2>/dev/null

    echo ''
}

check_and_install_mkcert() {
  apt install libnss3-tools mkcert -y
  sudo -u"$LOCAL_USER" mkcert -install
}

update_certs() {
    message "Update certs"
    local compose_file="./docker-compose.yml"
    local certs_dir="./var/traefik/certificates"
    # shellcheck disable=SC2155
    local cert_file="$(mkcert -CAROOT)/rootCA.pem"
    local chrome_nssdb_path="$HOME/.pki/nssdb"
    # shellcheck disable=SC2207
    # shellcheck disable=SC2016
    local domains=($(grep -oP 'Host\(`\K[^`]*' "$compose_file"))
    echo "Generating SSL certificate..."
    local domain_args=""
    for domain in "${domains[@]}"; do
        domain_args+="$domain "
    done
    sudo -u"$LOCAL_USER" mkcert -install
    # shellcheck disable=SC2046
    sudo -u"$LOCAL_USER" mkcert -cert-file "$certs_dir/local-cert.pem" -key-file "$certs_dir/local-key.pem" $(echo "$domain_args" | tr ' ' '\n' | grep -oP '^[a-zA-Z0-9.-]*\.[a-zA-Z]{2,}$')
    while [[ ! -f "$certs_dir/local-cert.pem" || ! -f "$certs_dir/local-key.pem" ]]; do
        echo "Waiting for certificates to be generated..."
        sleep 1
    done
    echo "SSL certificate generated."
    find /usr/local/share/ca-certificates/ -name "mkcert-rootCA.crt" -exec rm {} \;
    cp "$cert_file" /usr/local/share/ca-certificates/mkcert-rootCA.crt
    update-ca-certificates
    if [[ -d "$chrome_nssdb_path" ]]; then
        echo "Adding mkcert Root Certificate to Chrome's NSS database..."
        certutil -d sql:"$chrome_nssdb_path" -A -t "C,," -n "mkcert Root CA" -i "$cert_file"
    else
        echo "Initializing Chrome NSS database and adding mkcert Root Certificate..."
        mkdir -p "$chrome_nssdb_path"
        certutil -N --empty-password -d sql:"$chrome_nssdb_path"
        certutil -d sql:"$chrome_nssdb_path" -A -t "C,," -n "mkcert Root CA" -i "$cert_file"
    fi
    chmod 755 "$certs_dir"
    chmod 644 "$certs_dir/local-cert.pem"
    chmod 600 "$certs_dir/local-key.pem"
    chown "$LOCAL_USER":"$LOCAL_GROUP" "$certs_dir/local-cert.pem" "$certs_dir/local-key.pem"
}

update_hosts_file() {
    local entries=(
        "10.30.10.100 traefik"
        "127.0.0.1 traefik.local"
        "10.30.10.101 python_demo"
        "127.0.0.1 python-demo.local"
        "10.30.10.101 pdf_split_service"
        "127.0.0.1 pdf-split-service.local"
        "10.30.10.102 symfony"
        "127.0.0.1 symfony.local"
        "10.30.10.103 neo4j"
        "127.0.0.1 neo4j.local"
        "127.0.0.1 neo4j-bolt.local"
        "10.30.10.104 db"
        "10.30.10.105 pgadmin"
        "127.0.0.1 pgadmin.local"
        "10.30.10.106 postgres_exporter"
        "10.30.10.107 prometheus"
        "127.0.0.1 prometheus.local"
        "10.30.10.108 minio"
        "127.0.0.1 s3.local"
        "127.0.0.1 minio.local"
        "10.30.10.109 rabbitmq"
        "127.0.0.1 rabbitmq.local"
        "10.30.10.111 loki"
        "127.0.0.1 loki.local"
        "10.30.10.112 grafana"
        "127.0.0.1 grafana.local"
        "10.30.10.113 redis"
        "10.30.10.114 redis-commander"
        "127.0.0.1 redis-commander.local"
        "10.30.10.115 mercure"
        "127.0.0.1 mercure.local"
        "10.30.10.116 vault"
        "127.0.0.1 vault.local"
        "10.30.10.117 n8n"
        "127.0.0.1 n8n.local"
        "10.30.10.118 mailcatcher"
        "127.0.0.1 mailcatcher.local"
        "10.30.10.119 keycloak"
        "127.0.0.1 keycloak.local"
        "127.0.0.1 cadvisor.local"
    )
    for entry in "${entries[@]}"; do
        if ! grep -qF "$entry" /etc/hosts; then
            echo "$entry" | sudo tee -a /etc/hosts > /dev/null
        fi
    done
    echo "Updated /etc/hosts with necessary entries."
}

show_tools() {
  echo ""
  echo "Here are some tools that might help you:"
  echo ""
  echo "https://mailcatcher.local - Mailcatcher"
  echo "https://traefik.local - traefik dashboard"
  echo "https://vault.local - secrets store - token: root - and IAM (we only use it as secrets store yet)"
  echo "https://pgadmin.local - pgadmin instance - PGADMIN_DEFAULT_EMAIL=${PGADMIN_DEFAULT_EMAIL} - PGADMIN_DEFAULT_PASSWORD=${PGADMIN_DEFAULT_PASSWORD}"
  echo "http://localhost:7474/ - yeah I know the traefik config is not working yet - got other things to do - neo4j instance - user: neo4j - pass: SecurePass123"
  echo "https://minio.local - data storage - MINIO_ROOT_USER=${MINIO_ROOT_USER} - MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD} "
  echo "https://rabbitmq.local - message broker - RABBITMQ_DEFAULT_USER=${RABBITMQ_USER} - RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD}"
  echo "https://prometheus.local - metrics exporter"
  echo "https://grafana.local - monitoring - GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER} - GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD}"
  echo "https://cadvisor.local - even more monitoring"
  echo "https://n8n.local - automation tool"
  echo "https://keycloak.local - keycloak instance - ${KEYCLOAK_ADMIN_USER} / ${KEYCLOAK_ADMIN_PASSWORD}"
  echo "https://symfony.local - Symfony API platform with graphQL"
  echo "https://python-demo.local - python demo to show abilities of core iilib"
  echo "https://app.local - frontend"
}

run_reset() {
    message "YOU ARE ABOUT TO RESET THE INFRASTRUCTURE!!!" 9 3
    echo "this will delete everything you made when you were inside the gui of tools like grafana"
    echo "e.g. delete dashboards that you created manually - which btw. is a very dirty thing to do "
    echo "You are also deleting all local databases and basically everything in ./var folder"
    echo "It will be like a fresh install of this infrastructure"
    local PASSWORD="supersecurepassword" # <<<< here is the password - are you really sure?
    read -rsp "Enter the password to confirm reset: " entered_password
    echo
    if [[ "$entered_password" != "$PASSWORD" ]]; then
        echo "Incorrect password. Aborting reset."
        return 1
    fi
    echo "Password verified. Proceeding with reset..."
    echo "Deleting the Grafana data folder..."
    rm -rf ./var/grafana/data
    echo "Deleting the MinIO data folder..."
    rm -rf ./var/minio/data
    echo "Deleting the Redis data folder..."
    rm -rf ./var/redis/data
    echo "Deleting the Postgres data folder..."
    rm -rf ./var/postgres/data
    echo "Deleting the RabbitMQ data folder..."
    rm -rf ./var/rabbitmq/data
    rm -rf ./var/rabbitmq/log
    echo "Deleting the n8n data folder..."
    rm -rf ./var/n8n/data
    echo "Deleting the Mercure data folder..."
    rm -rf ./var/mercure/caddy/data
    echo "Deleting the Symfony data folder..."
    rm -rf ./var/symfony/data
    echo "Deleting the Vault data folder..."
    rm -rf ./var/vault/data
    rm -rf ./var/vault/log
    echo "Deleting the Neo4j data folder..."
    rm -rf ./var/neo4j/data
    rm -rf ./var/neo4j/log
    echo "Deleting the Keycloak data folder..."
    rm -rf ./var/keycloak/data
    message "All specified data folders have been deleted."
}

run_scripts() {
    source ./infra/scripts/configure-postgres.sh
    source ./infra/scripts/configure-rabbitmq.sh
    source ./infra/scripts/configure-minio.sh
    source ./infra/scripts/configure_keycloak.sh
    for i in {3..0}; do
        echo -ne "a little delay before we configure postgres: $i seconds.\r"
        sleep 1
    done
    message "Setting up Postgres server..."
    configure_postgres
    for i in {5..0}; do
        echo -ne "a little delay before we configure rabbitmq: $i seconds.\r"
        sleep 1
    done
    message "Binding the queue to the $MINIO_NOTIFY_AMQP_EXCHANGE with the routing key '$MINIO_NOTIFY_AMQP_ROUTING_KEY'"
    configure_rabbitmq
    message "Setting up Minio PUT Event. Let's start minio after the binding is done"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --env-file .env.local --profile storage up --build -d
    for i in {3..0}; do
        echo -ne "a little delay before we configure minio: $i seconds.\r"
        sleep 1
    done
    configure_minio
}

start_containers_and_run_scripts() {
    message "Starting containers" 3 0
    message "Starting minio..."
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile storage --env-file .env.local up --build -d
    message "Starting postgres..."
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile postgres --env-file .env.local up --build -d
    message "Starting pgadmin..."
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile db-tools --env-file .env.local up --build -d
    message "Starting rabbitmq..."
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile messaging --env-file .env.local up --build -d
    message "Running scripts to configure the systems"
    run_scripts
    message "Starting prometheus"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile monitoring-system --env-file .env.local up --build -d
    message "Starting Database Metrics Exporter for prometheus"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile metric-aggregator --env-file .env.local up --build -d
    message "Starting Loki to grab logs for Grafana"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile log-database --env-file .env.local up --build -d
    message "Starting Redis Cache"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile cache --env-file .env.local up --build -d
    for i in {2..0}; do
        echo -ne "Waiting for Redis node to be ready: $i seconds...\r"
        sleep 1
    done
    message "Starting redis-commander"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile cache-ui --env-file .env.local up --build -d
    message "Starting n8n"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile n8n --env-file .env.local up --build -d
    sudo chmod -R 777 ./var/n8n
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile n8n --env-file .env.local stop
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile n8n --env-file .env.local up -d
    message "Starting mailcatcher"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile mail-ui --env-file .env.local up --build -d
    message "Starting neo4j"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile neo4j --env-file .env.local up --build -d
    message "Starting mercure"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile mercure --env-file .env.local up --build -d
    message "Starting the application" 0 6
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile python_demo --env-file .env.local up --build -d
    message "Starting the pdf_split_service" 0 6
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile pdf_split_service --env-file .env.local up --build -d
    sleep 5
    message "Starting keycloak" 0 6
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile keycloak --env-file .env.local up --build -d
    message "Starting the symfony api" 0 6
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile symfony --env-file .env.local up --build -d
    #sleep 5
    #message "configure n8n" 0 6
    #sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile n8n_setup --env-file .env.local up --build -d
}

start_containers() {
    message "Starting containers" 3 0
    message "Starting minio..."
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile storage --env-file .env.local up --build -d
    message "Starting postgres..."
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile postgres --env-file .env.local up --build -d
    message "Starting pgadmin..."
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile db-tools --env-file .env.local up --build -d
    message "Starting rabbitmq..."
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile messaging --env-file .env.local up --build -d
    message "Starting prometheus"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile monitoring-system --env-file .env.local up --build -d
    message "Starting Database Metrics Exporter for prometheus"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile metric-aggregator --env-file .env.local up --build -d
    message "Starting Loki to grab logs for Grafana"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile log-database --env-file .env.local up --build -d
    message "Starting Redis Cache"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile cache --env-file .env.local up --build -d
    for i in {2..0}; do
        echo -ne "Waiting for Redis node to be ready: $i seconds...\r"
        sleep 1
    done
    message "Starting redis-commander"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile cache-ui --env-file .env.local up --build -d
    message "Starting n8n"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile n8n --env-file .env.local up --build -d
    message "Starting mailcatcher"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile mail-ui --env-file .env.local up --build -d
    message "Starting neo4j"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile neo4j --env-file .env.local up --build -d
    message "Starting mercure"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile mercure --env-file .env.local up --build -d
    message "Starting the application" 0 6
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile python_demo --env-file .env.local up --build -d
    message "Starting the pdf_split_service" 0 6
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile pdf_split_service --env-file .env.local up --build -d
    message "Starting keycloak" 0 6
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile keycloak --env-file .env.local up --build -d
    message "Starting the symfony api" 0 6
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile symfony --env-file .env.local up --build -d
}

start_service_with_retry() {
    local service_name="$1"
    local profile="$2"
    for attempt in {1..3}; do
        echo "Starting $service_name (Attempt $attempt)..."
        sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --profile "$profile" --env-file .env.local up --build --remove-orphans -d "$service_name" && return 0
        echo "Failed to start $service_name. Retrying in 3 seconds..."
        sleep 3
    done
    echo "Error: Unable to start $service_name after 3 attempts."
    return 1
}
