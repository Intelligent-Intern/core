<?php

namespace App\Interface;

use Psr\Log\LoggerInterface;
use App\Service\VaultService;

interface AIServiceInterface
{
    public function supports(string $provider): bool;
    public function generateEmbedding(string $input): array;
    public function setLogger(LoggerInterface $logger): void;
    public function setVaultService(VaultService $vaultService): void;
}
