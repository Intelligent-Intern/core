FROM python:3.12-slim
RUN apt-get update && apt-get install -y curl unzip jq \
    && curl -Lo /tmp/vault.zip https://releases.hashicorp.com/vault/1.18.2/vault_1.18.2_linux_amd64.zip \
    && unzip /tmp/vault.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/vault \
    && rm /tmp/vault.zip