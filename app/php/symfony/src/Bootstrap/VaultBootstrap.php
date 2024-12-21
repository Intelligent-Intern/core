<?php

namespace App\Bootstrap;

use App\Service\VaultService;
use Symfony\Component\HttpClient\HttpClient;

class VaultBootstrap
{
    public static function initialize(): void
    {
        $httpClient = HttpClient::create();
        $vaultService = new VaultService($httpClient);
        $databaseUrl = $vaultService->getPostgresCredentials();
        putenv('DATABASE_URL=' . $databaseUrl);
        $_ENV['DATABASE_URL'] = $databaseUrl;
        $_SERVER['DATABASE_URL'] = $databaseUrl;
    }
}
