#!/bin/bash

add_local_developer_policies_to_vault() {
  docker exec -it vault sh -c "cat /vault/config/pypi-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write pypi-policy -"
  docker exec -it vault sh -c "cat /vault/config/docker-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write docker-policy -"
  docker exec -it vault sh -c "cat /vault/config/rabbitmq-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write rabbitmq-policy -"
  docker exec -it vault sh -c "cat /vault/config/postgres-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write postgres-policy -"
  docker exec -it vault sh -c "cat /vault/config/minio-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write minio-policy -"
  docker exec -it vault sh -c "cat /vault/config/redis-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write redis-policy -"
  docker exec -it vault sh -c "cat /vault/config/env-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write env-policy -"
  docker exec -it vault sh -c "cat /vault/config/loki-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write loki-policy -"
  docker exec -it vault sh -c "cat /vault/config/logging-policy.hcl | VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault policy write logging-policy -"

  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault auth enable approle"
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault write auth/approle/role/local_developer token_policies=\"local_developer_policy\" token_ttl=1h token_max_ttl=1h"
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault write auth/approle/role/local_developer token_policies=\"local_developer_policy,pypi-policy,docker-policy,rabbitmq-policy,postgres-policy,minio-policy,redis-policy,env-policy,loki-policy,logging-policy\""
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

cat <<EOF > ./infra/vault/config/policy.hcl
path "auth/approle/role/local_developer/role-id" {
  capabilities = ["read"]
}
path "auth/approle/role/local_developer/secret-id" {
  capabilities = ["create", "read"]
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

cat <<EOF > ./infra/vault/config/postgres-policy.hcl
path "secret/data/data/postgres" {
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
}

add_secrets_to_vault() {
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/docker registry_url=\"$REGISTRY_URL\" username=\"$DOCKER_USERNAME\" password=\"$DOCKER_PASSWORD\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/pypi PYPI_REPOSITORY_USERNAME=\"$PYPI_REPOSITORY_USERNAME\" PYPI_REPOSITORY_PASSWORD=\"$PYPI_REPOSITORY_PASSWORD\" PYPI_REPOSITORY_URL=\"$PYPI_REPOSITORY_URL\" PIP_EXTRA_INDEX_URL=\"$PIP_EXTRA_INDEX_URL\" PIP_INDEX_URL=\"$PIP_INDEX_URL\" PIP_TRUSTED_HOST=\"$PIP_TRUSTED_HOST\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/rabbitmq username=\"$RABBITMQ_USER\" password=\"$RABBITMQ_PASSWORD\" host=\"$RABBITMQ_HOST\" port=\"$RABBITMQ_PORT\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/postgres username=\"$POSTGRES_USER\" password=\"$POSTGRES_PASSWORD\" host=\"$POSTGRES_HOST\" port=\"$POSTGRES_PORT\" database=\"$POSTGRES_DB\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/minio minio_access_key=\"$MINIO_ACCESS_KEY\" minio_secret_key=\"$MINIO_SECRET_KEY\" minio_endpoint=\"$MINIO_ENDPOINT\" incoming_bucket=\"$MINIO_INCOMING_BUCKET\" minio_use_local_storage=\"$MINIO_USE_LOCAL_STORAGE\" logs_info_bucket=\"$MINIO_LOGS_INFO_BUCKET\" logs_error_bucket=\"$MINIO_LOGS_ERROR_BUCKET\" logs_warning_bucket=\"$MINIO_LOGS_WARNING_BUCKET\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/redis redis_host=\"$REDIS_HOST\" redis_port=\"$REDIS_PORT\" redis_password=\"$REDIS_PASSWORD\" redis_db=\"$REDIS_DB\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/env workflow_init_path=\"$WORKFLOW_INIT_PATH\" docker_registry=\"$DOCKER_REGISTRY\" pypi_repository=\"$PYPI_REPOSITORY\" log_level=\"$LOG_LEVEL\" log_file_limit=\"$LOG_FILE_LIMIT\" log_backup_count=\"$LOG_BACKUP_COUNT\" log_separation=\"$LOG_SEPARATION\" test_data_directory=\"$TEST_DATA_DIRECTORY\" storage_directory=\"$STORAGE_DIRECTORY\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/loki url=\"http://loki:3100/loki/api/v1/push\""
  docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv put secret/data/logging target=\"loki\" level=\"debug\""
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
  # shellcheck disable=SC2155
  export VAULT_ROLE_ID=$(docker exec -it vault sh -c "VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault read -format=json auth/approle/role/$VAULT_ROLE_NAME/role-id" | jq -r .data.role_id)
  echo -e "VAULT_URL=$VAULT_ADDR\nVAULT_ROLE_NAME=$VAULT_ROLE_NAME\nVAULT_TOKEN=$VAULT_TOKEN\nVAULT_SECRET_ID=$SECRET_ID\nVAULT_ROLE_ID=$VAULT_ROLE_ID" > ./config/.env.vault
  chown "$LOCAL_USER":"$LOCAL_GROUP" ./config/.env.vault
}
