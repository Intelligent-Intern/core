<?php

namespace App\Controller;

use Psr\Log\LoggerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Annotation\Route;

class LogTestController extends AbstractController
{
    private LoggerInterface $logger;

    public function __construct(LoggerInterface $logger)
    {
        $this->logger = $logger;
    }

    #[Route('/log_test', name: 'log_test')]
    public function logTest(): JsonResponse
    {
        try {
            // Beispiel-Fehler erzeugen
            throw new \Exception('Test Exception for Stacktrace');
        } catch (\Exception $e) {
            $this->logger->error('This is a test error log.', ['exception' => $e]);
        }

        return new JsonResponse(['message' => 'Logs written successfully']);
    }
}
