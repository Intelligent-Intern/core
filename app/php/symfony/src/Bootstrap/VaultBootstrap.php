<?php

namespace App\Bootstrap;
namespace App\Bootstrap;

use App\Service\VaultService;
use Symfony\Component\HttpClient\HttpClient;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

class VaultBootstrap
{
    /**
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     */
    public static function initialize(): void
    {
        $httpClient = HttpClient::create();
        $vaultService = new VaultService($httpClient);

        // Set DATABASE_URL
        $databaseUrl = $vaultService->getPostgresCredentials();
        putenv('DATABASE_URL=' . $databaseUrl);
        $_ENV['DATABASE_URL'] = $databaseUrl;
        $_SERVER['DATABASE_URL'] = $databaseUrl;

        // Fetch Loki credentials
        $lokiConfig = $vaultService->fetchSecret('secret/data/data/loki');
        if (isset($lokiConfig['url'])) {
            putenv('LOKI_URL=' . $lokiConfig['url']);
            $_ENV['LOKI_URL'] = $lokiConfig['url'];
            $_SERVER['LOKI_URL'] = $lokiConfig['url'];
        }
        if (isset($lokiConfig['token'])) {
            putenv('LOKI_TOKEN=' . $lokiConfig['token']);
            $_ENV['LOKI_TOKEN'] = $lokiConfig['token'];
            $_SERVER['LOKI_TOKEN'] = $lokiConfig['token'];
        }
    }
}
