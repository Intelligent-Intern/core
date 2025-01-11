<?php

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
     * @throws ClientExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ServerExceptionInterface
     * @throws TransportExceptionInterface
     */
    public static function initialize(): void
    {
        $httpClient = HttpClient::create();
        $vaultService = new VaultService($httpClient);
        $secrets = $vaultService->fetchAllSecrets();
        foreach ($secrets as $key => $value) {
            $envKey = strtoupper(str_replace('.', '_', $key));
            putenv("$envKey=$value");
            $_ENV[$envKey] = $value;
            $_SERVER[$envKey] = $value;
        }
    }
}
