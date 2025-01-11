#!/bin/bash

add_local_developer_policies_to_vault() {
  docker exec -it vault sh -c "cat /vault/config/pypi-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write pypi-policy -"
  docker exec -it vault sh -c "cat /vault/config/docker-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write docker-policy -"
  docker exec -it vault sh -c "cat /vault/config/rabbitmq-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write rabbitmq-policy -"
  docker exec -it vault sh -c "cat /vault/config/postgresql-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write postgresql-policy -"
  docker exec -it vault sh -c "cat /vault/config/minio-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write minio-policy -"
  docker exec -it vault sh -c "cat /vault/config/redis-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write redis-policy -"
  docker exec -it vault sh -c "cat /vault/config/env-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write env-policy -"
  docker exec -it vault sh -c "cat /vault/config/loki-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write loki-policy -"
  docker exec -it vault sh -c "cat /vault/config/logging-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write logging-policy -"
  docker exec -it vault sh -c "cat /vault/config/openai-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write openai-policy -"
  docker exec -it vault sh -c "cat /vault/config/azure-openai-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write azure-openai-policy -"
  docker exec -it vault sh -c "cat /vault/config/mounts-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write mounts-policy -"
  docker exec -it vault sh -c "cat /vault/config/identity-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write identity-policy -"
  docker exec -it vault sh -c "cat /vault/config/secret-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write secret-policy -"
  docker exec -it vault sh -c "cat /vault/config/sys-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write sys-policy -"
  docker exec -it vault sh -c "cat /vault/config/cubbyhole-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write cubbyhole-policy -"
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault auth enable approle"
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault write auth/approle/role/local_developer token_policies=\"local_developer_policy\" token_ttl=1h token_max_ttl=1h"
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault write auth/approle/role/local_developer token_policies=\"local_developer_policy,pypi-policy,docker-policy,rabbitmq-policy,postgresql-policy,minio-policy,redis-policy,env-policy,loki-policy,logging-policy,openai-policy,azure-openai-policy,mounts-policy,identity-policy,secret-policy,sys-policy,cubbyhole-policy\""
}

create_local_developer_policies() {
cat <<EOF > ./infra/vault/config/loki-policy.hcl
path "secret/data/data/loki" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/logging-policy.hcl
path "secret/data/data/logging" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/openai-policy.hcl
path "secret/data/data/openai" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/azure-openai-policy.hcl
path "secret/data/data/azure_openai" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/pypi-policy.hcl
path "secret/data/data/pypi" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/docker-policy.hcl
path "secret/data/data/docker" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/rabbitmq-policy.hcl
path "secret/data/data/rabbitmq" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/postgresql-policy.hcl
path "secret/data/data/postgresql" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/minio-policy.hcl
path "secret/data/data/minio" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/redis-policy.hcl
path "secret/data/data/redis" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/env-policy.hcl
path "secret/data/data/env" {
  capabilities = ["read"]
}
EOF

cat <<EOF > ./infra/vault/config/mounts-policy.hcl
path "sys/mounts" {
  capabilities = ["read", "list"]
}
path "sys/*" {
  capabilities = ["read", "list"]
}
EOF

cat <<EOF > ./infra/vault/config/identity-policy.hcl
path "identity/*" {
  capabilities = ["read", "list"]
}
EOF

cat <<EOF > ./infra/vault/config/secret-policy.hcl
path "secret/*" {
  capabilities = ["read", "list"]
}
EOF

cat <<EOF > ./infra/vault/config/sys-policy.hcl
path "sys/*" {
  capabilities = ["read", "list"]
}
EOF

cat <<EOF > ./infra/vault/config/cubbyhole-policy.hcl
path "cubbyhole/*" {
  capabilities = ["read", "list"]
}
EOF
}

add_secrets_to_vault() {
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/logging log_type=\"$LOG_TYPE\" log_level=\"$LOG_LEVEL\" log_file_limit=\"$LOG_FILE_LIMIT\" log_backup_count=\"$LOG_BACKUP_COUNT\" log_separation=\"$LOG_SEPARATION\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/loki url=\"$LOKI_URL\" tenant=\"$LOKI_TENANT\" username=\"$LOKI_USERNAME\" password=\"$LOKI_PASSWORD\" log_level=\"$LOKI_LOG_LEVEL\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/openai provider=\"$OPENAI_PROVIDER\" model=\"$OPENAI_MODEL\" api_key=\"$OPENAI_API_KEY\" max_tokens=\"$OPENAI_MAX_TOKENS\" temperature=\"$OPENAI_TEMPERATURE\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/azure_openai provider=\"$AZURE_OPENAI_PROVIDER\" model=\"$AZURE_OPENAI_MODEL\" api_key=\"$AZURE_OPENAI_API_KEY\" endpoint=\"$AZURE_OPENAI_ENDPOINT\" deployment_id=\"$AZURE_OPENAI_DEPLOYMENT_ID\" max_tokens=\"$AZURE_OPENAI_MAX_TOKENS\" temperature=\"$AZURE_OPENAI_TEMPERATURE\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/file filepath=\"$FILE_LOG_PATH\" log_level=\"$FILE_LOG_LEVEL\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/postgresql postgresql_db=\"$POSTGRES_DB\" postgresql_user=\"$POSTGRES_USER\" postgresql_password=\"$POSTGRES_PASSWORD\" postgresql_host=\"$POSTGRES_HOST\" postgresql_port=\"$POSTGRES_PORT\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/n8n db_type=\"$N8N_DB_TYPE\" db_host=\"$N8N_DB_HOST\" db_port=\"$N8N_DB_PORT\" db_name=\"$N8N_DB_NAME\" db_user=\"$N8N_DB_USER\" db_password=\"$N8N_DB_PASSWORD\" rabbitmq_host=\"$N8N_RABBITMQ_HOST\" rabbitmq_user=\"$N8N_RABBITMQ_USER\" rabbitmq_password=\"$N8N_RABBITMQ_PASSWORD\" rabbitmq_vhost=\"$N8N_RABBITMQ_VHOST\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/keycloak keycloak_db_type=\"$KEYCLOAK_DB_TYPE\" keycloak_db_host=\"$KEYCLOAK_DB_HOST\" keycloak_db_port=\"$KEYCLOAK_DB_PORT\" keycloak_db_name=\"$KEYCLOAK_DB_NAME\" keycloak_db_user=\"$KEYCLOAK_DB_USER\" keycloak_db_schema=\"$KEYCLOAK_DB_SCHEMA\" keycloak_db_password=\"$KEYCLOAK_DB_PASSWORD\" keycloak_hostname=\"$KEYCLOAK_HOSTNAME\" keycloak_url=\"$KEYCLOAK_URL\" keycloak_admin_user=\"$KEYCLOAK_ADMIN_USER\" keycloak_admin_password=\"$KEYCLOAK_ADMIN_PASSWORD\" keycloak_realm=\"$KEYCLOAK_REALM\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/redis redis_host=\"$REDIS_HOST\" redis_port=\"$REDIS_PORT\" redis_password=\"$REDIS_PASSWORD\" redis_db=\"$REDIS_DB\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/minio minio_access_key=\"$MINIO_ACCESS_KEY\" minio_secret_key=\"$MINIO_SECRET_KEY\" minio_endpoint=\"$MINIO_ENDPOINT\" incoming_bucket=\"$MINIO_INCOMING_BUCKET\" minio_use_local_log_storage=\"$MINIO_USE_LOCAL_STORAGE\" logs_bucket=\"$MINIO_LOGS_BUCKET\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/docker registry_url=\"$REGISTRY_URL\" username=\"$DOCKER_USERNAME\" password=\"$DOCKER_PASSWORD\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/pypi PYPI_REPOSITORY_USERNAME=\"$PYPI_REPOSITORY_USERNAME\" PYPI_REPOSITORY_PASSWORD=\"$PYPI_REPOSITORY_PASSWORD\" PYPI_REPOSITORY_URL=\"$PYPI_REPOSITORY_URL\" PIP_EXTRA_INDEX_URL=\"$PIP_EXTRA_INDEX_URL\" PIP_INDEX_URL=\"$PIP_INDEX_URL\" PIP_TRUSTED_HOST=\"$PIP_TRUSTED_HOST\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/neo4j auth=\"$NEO4J_AUTH\" bolt_address=\"$NEO4J_BOLT_ADDRESS\" http_address=\"$NEO4J_HTTP_ADDRESS\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/mercure publisher_jwt_key=\"$MERCURE_PUBLISHER_JWT_KEY\" subscriber_jwt_key=\"$MERCURE_SUBSCRIBER_JWT_KEY\" cors_allowed_origins=\"$MERCURE_CORS_ALLOWED_ORIGINS\""
}


configure_vault() {
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
  if [[ -z "$DIR" || "$DIR" == "/" ]]; then
      exit 1
  fi
  cd "$DIR"/../../ || exit 1
  rm -rf ./var/vault/data
  mkdir ./var/vault/data
  chmod -R 777 ./var/vault/data
  sudo -u"${SUDO_USER:-$(whoami)}" VAULT_ROLE_ID=empty VAULT_SECRET_ID=empty docker compose --env-file=.env.local --profile vault up -d
  sleep 1
  VAULT_ADDR="http://10.30.10.116:8300"
  VAULT_ROLE_NAME="local_developer"
  VAULT_TOKEN="root"
  docker exec -it vault sh -c "apk add --no-cache jq"
  until curl --silent --fail http://10.30.10.116:8300/v1/sys/health; do
    echo "waiting for vault to become responsive"
    sleep 1
  done
  create_local_developer_policies
  add_local_developer_policies_to_vault
  SECRET_ID=$(sudo -u"${SUDO_USER:-$(whoami)}" docker exec -i vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault write -format=json -f auth/approle/role/$VAULT_ROLE_NAME/secret-id" | jq -r .data.secret_id)
  export VAULT_SECRET_ID=$SECRET_ID
  export VAULT_ROLE_ID=$(docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault read -format=json auth/approle/role/$VAULT_ROLE_NAME/role-id" | jq -r .data.role_id)
  echo -e "VAULT_URL=$VAULT_ADDR\nVAULT_ROLE_NAME=$VAULT_ROLE_NAME\nVAULT_TOKEN=$VAULT_TOKEN\nVAULT_SECRET_ID=$SECRET_ID\nVAULT_ROLE_ID=$VAULT_ROLE_ID" > ./config/.env.vault
  chown "$LOCAL_USER":"$LOCAL_GROUP" ./config/.env.vault
  add_secrets_to_vault
}
