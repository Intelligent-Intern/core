path "auth/approle/role/local_developer/role-id" {
  capabilities = ["read"]
}
path "auth/approle/role/local_developer/secret-id" {
  capabilities = ["create", "read"]
}
