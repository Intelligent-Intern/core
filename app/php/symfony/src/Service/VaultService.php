<?php

namespace App\Service;

use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;

class VaultService
{
    private HttpClientInterface $httpClient;
    private string $vaultUrl;
    private string $roleId;
    private string $secretId;

    public function __construct(HttpClientInterface $httpClient)
    {
        $this->httpClient = $httpClient;
        $this->vaultUrl = $_ENV['VAULT_URL'] ?? throw new \RuntimeException('VAULT_URL is not set');
        $this->roleId = $_ENV['VAULT_ROLE_ID'] ?? throw new \RuntimeException('VAULT_ROLE_ID is not set');
        $this->secretId = $_ENV['VAULT_SECRET_ID'] ?? throw new \RuntimeException('VAULT_SECRET_ID is not set');
    }

    public function getPostgresCredentials(): string
    {
        $secret = $this->fetchSecret('secret/data/data/postgres');
        return sprintf(
            'pgsql://%s:%s@%s:%s/%s',
            $secret['username'], $secret['password'], $secret['host'], $secret['port'], $secret['database']
        );

    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    private function fetchSecret(string $path): array
    {
        $response = $this->httpClient->request('GET', "{$this->vaultUrl}/v1/{$path}", [
            'headers' => ['X-Vault-Token' => $this->authenticate()],
        ]);
        $data = $response->toArray();

        return $data['data']['data'] ?? throw new \RuntimeException("Secret {$path} not found.");
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    private function authenticate(): string
    {
        $response = $this->httpClient->request('POST', "{$this->vaultUrl}/v1/auth/approle/login", [
            'json' => ['role_id' => $this->roleId, 'secret_id' => $this->secretId],
        ]);

        $data = $response->toArray();
        $token = $data['auth']['client_token'] ?? null;

        if (!$token) {
            throw new \RuntimeException('Failed to authenticate with Vault. Response: ' . json_encode($data));
        }

        return $token;
    }

}
