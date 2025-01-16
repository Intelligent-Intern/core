<?php

namespace App\Controller;

use Psr\Log\LoggerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Annotation\Route;

class LogTestController extends AbstractController
{
    public function __construct(
        private readonly LoggerInterface $logger
    ) {}

    #[Route('/log_test', name: 'log_test')]
    public function logTest(): JsonResponse
    {
        try {
            throw new \Exception('Test Exception for Stacktrace');
        } catch (\Exception $e) {
            $this->logger->error('This is a test error log.', ['exception' => $e]);
        }

        return new JsonResponse(['message' => 'Logs written successfully']);
    }
}
