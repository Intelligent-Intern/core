<?php

namespace App\Factory;

use App\Interface\AIServiceInterface;
use App\Service\VaultService;
use Psr\Log\LoggerInterface;
use RuntimeException;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

class AIServiceFactory
{
    private array $strategies = [];

    public function __construct(
        private readonly VaultService $vaultService,
        private readonly LoggerInterface $logger
    ) {
        $this->logger->info("AIServiceFactory initialized with VaultService and Logger.");
    }

    public function addStrategy(AIServiceInterface $strategy): void
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
    public function create(): AIServiceInterface
    {
        try {
            $provider = strtolower(
                $this->vaultService->fetchSecret('secret/data/data/config')['AI_PROVIDER']
                ?? throw new RuntimeException('AI_PROVIDER is not set')
            );
            $this->logger->info("Requested provider: {$provider}.");
            foreach ($this->strategies as $strategy) {
                if ($strategy->supports($provider)) {
                    $this->logger->info("Returning strategy for provider: {$provider}.");
                    return $strategy;
                }
            }
            $this->logger->error("No strategy found for provider: {$provider}.");
            throw new RuntimeException("No AI strategy found for provider '{$provider}'");
        } catch (\Exception $e) {
            $this->logger->error('Error occurred while creating AI service.', ['exception' => $e]);
            throw $e;
        }
    }
}
