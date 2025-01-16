<?php

namespace App\Factory;

use App\Interface\LogServiceInterface;
use App\Service\VaultService;
use RuntimeException;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

class LogServiceFactory
{
    private array $strategies = [];

    public function __construct(
        private readonly VaultService $vaultService
    ) {}

    public function addStrategy(LogServiceInterface $strategy): void
    {
        $className = (new \ReflectionClass($strategy))->getShortName();
        $serviceName = str_replace('Service', '', $className);

        $strategy->setVaultService($this->vaultService);

        $this->strategies[strtolower($serviceName)] = $strategy;
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function create(): LogServiceInterface
    {
        try {
            $logTarget = strtolower(
                $this->vaultService->fetchSecret('secret/data/data/config')['LOG_TARGET']
                ?? throw new RuntimeException('LOG_TARGET is not set')
            );

            foreach ($this->strategies as $strategy) {
                if ($strategy->supports($logTarget)) {
                    return $strategy;
                }
            }

            throw new RuntimeException("No logging strategy found for target '{$logTarget}'");
        } catch (\Exception $e) {
            throw new RuntimeException('Error occurred while creating log service.', 0, $e);
        }
    }
}
