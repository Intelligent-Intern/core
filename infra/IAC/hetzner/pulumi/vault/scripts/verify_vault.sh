#!/bin/bash
export VAULT_ADDR="http://localhost:8200"
vault login $VAULT_TOKEN

vault kv get secret/db_credentials
