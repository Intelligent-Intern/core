#!/bin/bash

configure_postgres() {
    local pg_data_dir="./var/postgres/data"
    local pg_config_dir="./infra/db/postgres"

    log_message() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
    }

    error_exit() {
        log_message "ERROR: $1"
        exit 1
    }

    log_message "Copying PostgreSQL configuration files..."
    cp "$pg_config_dir/pg_hba.conf" "$pg_data_dir/pg_hba.conf" || error_exit "Failed to copy pg_hba.conf"
    cp "$pg_config_dir/postgresql.conf" "$pg_data_dir/postgresql.conf" || error_exit "Failed to copy postgresql.conf"

    log_message "Restarting PostgreSQL container..."
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" \
        docker compose --env-file .env.local stop db || error_exit "Failed to stop PostgreSQL container"
    sudo -u"$LOCAL_USER" VAULT_URL="$VAULT_URL" VAULT_ROLE_ID="$VAULT_ROLE_ID" VAULT_SECRET_ID="$VAULT_SECRET_ID" \
        docker compose --env-file .env.local up -d db || error_exit "Failed to start PostgreSQL container"

    log_message "Waiting for PostgreSQL to become ready..."
    until docker exec -it db pg_isready -U "$POSTGRES_USER" -d postgres > /dev/null 2>&1; do
        sleep 2
    done

    create_role_and_db() {
        local role=$1
        local password=$2
        local database=$3

        log_message "Checking if role '$role' exists..."
        docker exec -it db psql -U "$POSTGRES_USER" -d postgres -c \
            "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$role') THEN CREATE ROLE $role LOGIN PASSWORD '$password'; END IF; END \$\$;" \
            || error_exit "Failed to create role '$role'"

        if [[ -n "$database" ]]; then
            log_message "Checking if database '$database' exists..."
            if ! docker exec -it db psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$database';" | grep -q 1; then
                log_message "Creating database '$database' owned by '$role'..."
                docker exec -it db psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE $database OWNER $role;" \
                    || error_exit "Failed to create database '$database'"
            else
                log_message "Database '$database' already exists."
            fi
        fi
    }

    log_message "Configuring default PostgreSQL roles and databases..."
    create_role_and_db "$POSTGRES_USER" "$POSTGRES_PASSWORD" "$POSTGRES_DB"
    create_role_and_db "$N8N_DB_USER" "$N8N_DB_PASSWORD" "$N8N_DB_NAME"
    create_role_and_db "$KEYCLOAK_DB_USER" "$KEYCLOAK_DB_PASSWORD" "$KEYCLOAK_DB_NAME"

    log_message "Verifying pgvector installation..."
    docker exec -it db psql -U "$POSTGRES_USER" -d postgres -c "CREATE EXTENSION IF NOT EXISTS vector;" \
        || error_exit "Failed to create pgvector extension"
    docker exec -it db psql -U "$POSTGRES_USER" -d postgres -c "SELECT * FROM pg_extension WHERE extname = 'vector';" \
        || error_exit "pgvector extension not properly installed"

    log_message "PostgreSQL configuration completed successfully."
}

configure_postgres
