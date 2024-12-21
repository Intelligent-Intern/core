#!/bin/bash
export VAULT_ADDR="http://localhost:8200"
vault login $VAULT_TOKEN

vault kv put secret/db_credentials db_host={{ db_host }} db_user={{ db_user }} db_password={{ db_password }}
