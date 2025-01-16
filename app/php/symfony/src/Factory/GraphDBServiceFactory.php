<?php

namespace App\Factory;

use App\Interface\GraphDBServiceInterface;
use App\Service\VaultService;
use Psr\Log\LoggerInterface;
use RuntimeException;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

class GraphDBServiceFactory
{
    private array $strategies = [];

    public function __construct(
        private readonly VaultService $vaultService,
        private readonly LoggerInterface $logger
    ) {
        $this->logger->info("GraphDBFactory initialized with VaultService and Logger.");
    }

    public function addStrategy(GraphDBServiceInterface $strategy): void
    {
        $className = (new \ReflectionClass($strategy))->getShortName();
        $serviceName = str_replace('Service', '', $className);

        $strategy->setVaultService($this->vaultService);
        $strategy->setLogger($this->logger);

        $this->strategies[strtolower($serviceName)] = $strategy;
        $this->logger->info("Strategy {$serviceName} added to factory.");
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function create(): GraphDBServiceInterface
    {
        try {
            $provider = strtolower(
                $this->vaultService->fetchSecret('secret/data/data/config')['GRAPHDB_PROVIDER']
                ?? throw new RuntimeException('GRAPHDB_PROVIDER is not set')
            );
            $this->logger->info("Requested provider: {$provider}.");
            foreach ($this->strategies as $strategy) {
                if ($strategy->supports($provider)) {
                    $this->logger->info("Returning strategy for provider: {$provider}.");
                    return $strategy;
                }
            }
            $this->logger->error("No strategy found for provider: {$provider}.");
            throw new RuntimeException("No GraphDB strategy found for provider '{$provider}'");
        } catch (\Exception $e) {
            $this->logger->error('Error occurred while creating GraphDB service.', ['exception' => $e]);
            throw $e;
        }
    }
}
