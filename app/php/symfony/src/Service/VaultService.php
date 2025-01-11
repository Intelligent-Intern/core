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

    /**
     * @return array
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function fetchAllSecrets(): array
    {
        $token = $this->authenticate();
        $response = $this->httpClient->request('GET', "{$this->vaultUrl}/v1/secret/metadata?list=true", [
            'headers' => ['X-Vault-Token' => $token],
        ]);
        $data = $response->toArray();
        $keys = $data['data']['keys'] ?? throw new \RuntimeException('No keys found in Vault.');
        $allSecrets = [];
        foreach ($keys as $key) {
            $secretData = $this->fetchSecret("secret/data/{$key}", $token);
            $allSecrets = array_merge($allSecrets, $secretData);
        }

        return $allSecrets;
    }

    /**
     * @param string $path
     * @param string $token
     * @return array
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function fetchSecret(string $path, string $token): array
    {
        $response = $this->httpClient->request('GET', "{$this->vaultUrl}/v1/{$path}", [
            'headers' => ['X-Vault-Token' => $token],
        ]);
        $data = $response->toArray();
        return $data['data']['data'] ?? throw new \RuntimeException("Secret {$path} not found.");
    }
}