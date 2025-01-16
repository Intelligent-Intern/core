<?php

namespace App\Interface;

use App\Service\VaultService;

interface LogServiceInterface
{
    public function supports(string $provider): bool;
    public function log(string $level, string $message, array $context = []): void;
    public function setVaultService(VaultService $vaultService): void;
}
