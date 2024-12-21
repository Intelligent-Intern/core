#!/bin/bash

configure_postgres() {
    local pg_data_dir="./var/postgres/data"
    local pg_config_dir="./infra/db/postgres"

    cp "$pg_config_dir/pg_hba.conf" "$pg_data_dir/pg_hba.conf"
    cp "$pg_config_dir/postgresql.conf" "$pg_data_dir/postgresql.conf"

    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --env-file .env.local stop db
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" docker compose --env-file .env.local up -d db

    until docker exec -it db pg_isready -U "$POSTGRES_USER" -d postgres > /dev/null 2>&1; do
        sleep 2
    done

    docker exec -it db psql -U "$POSTGRES_USER" -d postgres -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'myuser') THEN CREATE ROLE myuser LOGIN PASSWORD 'mypassword'; END IF; END \$\$;"
    if ! docker exec -it db psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = 'mydatabase';" | grep -q 1; then
        docker exec -it db psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE mydatabase OWNER myuser;"
    fi

    docker exec -it db psql -U "$POSTGRES_USER" -d postgres -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$N8N_DB_USER') THEN CREATE ROLE $N8N_DB_USER LOGIN PASSWORD '$N8N_DB_PASSWORD'; END IF; END \$\$;"
    if ! docker exec -it db psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$N8N_DB_NAME';" | grep -q 1; then
        docker exec -it db psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE $N8N_DB_NAME OWNER $N8N_DB_USER;"
    fi

    docker exec -it db psql -U "$POSTGRES_USER" -d postgres -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$KEYCLOAK_DB_USER') THEN CREATE ROLE $KEYCLOAK_DB_USER LOGIN PASSWORD '$KEYCLOAK_DB_PASSWORD'; END IF; END \$\$;"
    if ! docker exec -it db psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$KEYCLOAK_DB_NAME';" | grep -q 1; then
        docker exec -it db psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE $KEYCLOAK_DB_NAME OWNER $KEYCLOAK_DB_USER;"
    fi
}
