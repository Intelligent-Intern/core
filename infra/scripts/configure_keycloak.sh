#!/bin/bash


configure_keycloak() {
  error_exit() {
    message "Error: $1" 9 15; exit 1;
  }
  sleep 10
  message "Authenticating with Keycloak..." 17 15
  TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" \
    -d "username=${KEYCLOAK_ADMIN_USER}" \
    -d "password=${KEYCLOAK_ADMIN_PASSWORD}" | jq -r '.access_token')
  [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ] && error_exit "Failed to authenticate with Keycloak."
  message "Authentication successful." 10 15
  create_client() {
    curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}/clients" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"clientId\": \"$1\", \"name\": \"$2\", \"protocol\": \"$3\", \"publicClient\": $4, \
           \"standardFlowEnabled\": true, \"directAccessGrantsEnabled\": false, \
           \"redirectUris\": [\"$5\"]}" > /dev/null
    message "Client '$1' created." 10 15
  }
  curl -s -X POST "${KEYCLOAK_URL}/admin/realms" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"realm\": \"${KEYCLOAK_REALM}\", \"enabled\": true}" > /dev/null
  message "Realm '${KEYCLOAK_REALM}' created." 10 15
  create_client "${KEYCLOAK_SYMFONY_CLIENT_ID}" "${KEYCLOAK_SYMFONY_CLIENT_NAME}" \
    "${KEYCLOAK_SYMFONY_CLIENT_PROTOCOL}" "false" "${KEYCLOAK_SYMFONY_REDIRECT_URI}"
  create_client "${KEYCLOAK_NEXTJS_CLIENT_ID}" "${KEYCLOAK_NEXTJS_CLIENT_NAME}" \
    "${KEYCLOAK_NEXTJS_CLIENT_PROTOCOL}" "true" "${KEYCLOAK_NEXTJS_REDIRECT_URI}"
  create_client "${KEYCLOAK_PDF_SPLIT_CLIENT_ID}" "PDF Split Service" \
    "openid-connect" "false" ""
  create_client "${KEYCLOAK_OCR_CLIENT_ID}" "OCR Service" "openid-connect" "false" ""
  create_client "${KEYCLOAK_SEMANTIC_EXTRACTION_CLIENT_ID}" "Semantic Extraction Service" \
    "openid-connect" "false" ""
  create_client "${KEYCLOAK_FILE_VALIDATION_CLIENT_ID}" "File Validation Service" \
    "openid-connect" "false" ""
}
