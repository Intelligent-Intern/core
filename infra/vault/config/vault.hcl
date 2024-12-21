listener "tcp" {
  address     = "10.30.10.116:8300"
  tls_disable = 1
}

storage "file" {
  path = "/vault/data"
}
ui = true

api_addr = "http://10.30.10.116:8300"