<?php

namespace App\DependencyInjection\Compiler;

use App\Bootstrap\VaultBootstrap;
use Symfony\Component\DependencyInjection\Compiler\CompilerPassInterface;
use Symfony\Component\DependencyInjection\ContainerBuilder;

class VaultCompilerPass implements CompilerPassInterface
{
    public function process(ContainerBuilder $container): void
    {
        VaultBootstrap::initialize();
    }
}
