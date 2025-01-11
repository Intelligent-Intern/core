<?php

namespace App\Factory;

use App\Service\LokiLoggerService;
use App\Service\VaultService;
use Monolog\Level;
use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Psr\Log\LoggerInterface;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

class LoggerFactory
{
    private VaultService $vaultService;

    public function __construct(VaultService $vaultService)
    {
        $this->vaultService = $vaultService;
    }

    /**
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     */
    public function createLogger(): LoggerInterface
    {
        $logTarget = $this->vaultService->fetchSecret('secret/data/data/logging')['target'] ?? 'local';
        $logger = new Logger('app');

        if ($logTarget === 'loki') {
            $logger->pushHandler(new LokiLoggerService($this->vaultService));
        } else {
            $logger->pushHandler(new StreamHandler('php://stdout', Level::Debug));
        }

        return $logger;
    }
}
