#!/bin/bash

export PYTHONPATH=/app

export VAULT_ADDR=$VAULT_URL
export VAULT_ROLE_ID=$VAULT_ROLE_ID
export VAULT_SECRET_ID=$VAULT_SECRET_ID

echo "Loading Vault configuration"
echo "VAULT_URL: $VAULT_ADDR"
echo "VAULT_ROLE_ID: $VAULT_ROLE_ID"
echo "VAULT_SECRET_ID: $VAULT_SECRET_ID"

vault write auth/approle/login role_id=$VAULT_ROLE_ID secret_id=$VAULT_SECRET_ID -format=json > response.json
TOKEN=$(jq -r '.auth.client_token' response.json)
export VAULT_TOKEN=$TOKEN

PYPY_DATA=$(vault kv get -format=json secret/data/pypi | jq -r '.data.data')
# shellcheck disable=SC2155
export PYPI_REPOSITORY_URL=$(echo $PYPY_DATA | jq -r '.PYPI_REPOSITORY_URL')
# shellcheck disable=SC2155
export PYPI_REPOSITORY_USERNAME=$(echo $PYPY_DATA | jq -r '.PYPI_REPOSITORY_USERNAME')
# shellcheck disable=SC2155
export PYPI_REPOSITORY_PASSWORD=$(echo $PYPY_DATA | jq -r '.PYPI_REPOSITORY_PASSWORD')
# shellcheck disable=SC2155
export PIP_INDEX_URL=$(echo $PYPY_DATA | jq -r '.PIP_INDEX_URL')
# shellcheck disable=SC2155
export PIP_TRUSTED_HOST=$(echo $PYPY_DATA | jq -r '.PIP_TRUSTED_HOST')
# shellcheck disable=SC2155
export PIP_EXTRA_INDEX_URL=$(echo $PYPY_DATA | jq -r '.PIP_EXTRA_INDEX_URL')

echo "PyPI_REPOSITORY_URL: $PYPI_REPOSITORY_URL"
echo "PyPI_REPOSITORY_USERNAME: $PYPI_REPOSITORY_USERNAME"
echo "PIP_INDEX_URL: $PIP_INDEX_URL"

mkdir -p /home/appuser/.pip
cat > /home/appuser/.pip/pip.conf <<EOL
[global]
index-url = $PIP_INDEX_URL
trusted-host = $PIP_TRUSTED_HOST
extra-index-url = $PIP_EXTRA_INDEX_URL
EOL
chown -R appuser:appuser /home/appuser/.pip

pip install -r /app/requirements.txt

exec flask run --host=0.0.0.0 --port=5000
# python /app/app.py
