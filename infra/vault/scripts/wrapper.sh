#!/bin/sh -e

echo "Configuring DNS and routing..."
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
echo 'nameserver 8.8.4.4' >> /etc/resolv.conf
ip route del default || true
ip route add default via 10.30.10.1 dev eth0 || true
ip link set eth0 up || true

echo "Verifying connectivity..."
ping -c 3 8.8.8.8 || {
  echo "Network unreachable. Exiting."
  exit 1
}

echo "Starting Vault in Dev mode with root token..."
exec vault server -dev -dev-root-token-id="${VAULT_DEV_ROOT_TOKEN_ID}" -config=/vault/config/vault.hcl


