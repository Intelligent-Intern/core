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
    private ?string $token = null;

    public function __construct(HttpClientInterface $httpClient)
    {
        $this->httpClient = $httpClient;
        $this->vaultUrl = $_ENV['VAULT_URL'] ?? throw new \RuntimeException('VAULT_URL is not set');
        $this->roleId = $_ENV['VAULT_ROLE_ID'] ?? throw new \RuntimeException('VAULT_ROLE_ID is not set');
        $this->secretId = $_ENV['VAULT_SECRET_ID'] ?? throw new \RuntimeException('VAULT_SECRET_ID is not set');
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ClientExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     */
    private function authenticate(): string
    {
        if ($this->token) {
            return $this->token;
        }

        $response = $this->httpClient->request('POST', "{$this->vaultUrl}/v1/auth/approle/login", [
            'json' => ['role_id' => $this->roleId, 'secret_id' => $this->secretId],
        ]);

        $data = $response->toArray();
        $this->token = $data['auth']['client_token'] ?? null;

        if (!$this->token) {
            throw new \RuntimeException('Failed to authenticate with Vault.');
        }

        return $this->token;
    }

    /**
     * Fetch all secrets from Vault dynamically.
     *
     * @return array
     * @throws TransportExceptionInterface
     * @throws ClientExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     */
    public function fetchAllSecrets(): array
    {
        $token = $this->authenticate();
        $secrets = [];
        $excludeMountPoints = ['cubbyhole/', 'identity/', 'sys/'];

        // Fetch all mounted secret engines
        $response = $this->httpClient->request('GET', "{$this->vaultUrl}/v1/sys/mounts", [
            'headers' => ['X-Vault-Token' => $token],
        ]);
        $mountedEngines = array_keys($response->toArray());

        foreach ($mountedEngines as $mountPoint) {
            if (in_array($mountPoint, $excludeMountPoints, true)) {
                continue;
            }
            $this->processMountPoint($mountPoint, $secrets);
        }

        return $secrets;
    }

    /**
     * Process a single mount point to collect secrets.
     *
     * @param string $mountPoint
     * @param array $secrets
     * @throws TransportExceptionInterface
     * @throws ClientExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     */
    private function processMountPoint(string $mountPoint, array &$secrets): void
    {
        try {
            $response = $this->httpClient->request('GET', "{$this->vaultUrl}/v1/{$mountPoint}metadata?list=true", [
                'headers' => ['X-Vault-Token' => $this->authenticate()],
            ]);
            $keys = $response->toArray()['data']['keys'] ?? [];

            foreach ($keys as $key) {
                $secretData = $this->fetchSecret("{$mountPoint}data/{$key}");
                if ($secretData) {
                    $secrets[$key] = $secretData;
                }
            }
        } catch (\Exception $e) {
            // Log error but do not stop execution for one mount point
        }
    }

    /**
     * Fetch a single secret by path.
     *
     * @param string $path
     * @return array|null
     * @throws TransportExceptionInterface
     * @throws ClientExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     */
    public function fetchSecret(string $path): ?array
    {
        $token = $this->authenticate();

        try {
            $response = $this->httpClient->request('GET', "{$this->vaultUrl}/v1/{$path}", [
                'headers' => ['X-Vault-Token' => $token],
            ]);
            return $response->toArray()['data']['data'] ?? null;
        } catch (\Exception $e) {
            // Log error but continue execution
            return null;
        }
    }
}
