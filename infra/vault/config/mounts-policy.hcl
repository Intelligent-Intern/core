path "sys/mounts" {
  capabilities = ["read", "list"]
}
path "sys/*" {
  capabilities = ["read", "list"]
}
