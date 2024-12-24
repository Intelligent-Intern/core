<?php

namespace App\Service;

use GuzzleHttp\Exception\GuzzleException;
use Monolog\Handler\AbstractProcessingHandler;
use GuzzleHttp\Client;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

class LokiLoggerService extends AbstractProcessingHandler
{
    private Client $client;
    private string $lokiUrl;
    private ?string $token;

    /**
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     */
    public function __construct(VaultService $vaultService)
    {
        parent::__construct($this->getLogLevel($vaultService), true);
        $this->client = new Client();
        $this->initializeConfig($vaultService);
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    private function initializeConfig(VaultService $vaultService): void
    {
        $lokiConfig = $vaultService->getLokiConfig();

        $this->lokiUrl = $lokiConfig['url'] ?? throw new \RuntimeException('Loki URL not found in Vault.');
        $this->token = $lokiConfig['token'] ?? null;
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    private function getLogLevel(VaultService $vaultService): int
    {
        $logLevel = $vaultService->fetchSecret('secret/data/data/logging')['level'] ?? 'debug';

        return match (strtolower($logLevel)) {
            'info' => \Monolog\Level::Info->value,
            'notice' => \Monolog\Level::Notice->value,
            'warning' => \Monolog\Level::Warning->value,
            'error' => \Monolog\Level::Error->value,
            'critical' => \Monolog\Level::Critical->value,
            'alert' => \Monolog\Level::Alert->value,
            'emergency' => \Monolog\Level::Emergency->value,
            default => \Monolog\Level::Debug->value,
        };
    }

    /**
     * @throws GuzzleException
     */
    protected function write(array|\Monolog\LogRecord $record): void
    {
        $headers = [];
        if ($this->token) {
            $headers['Authorization'] = "Bearer {$this->token}";
        }

        $exception = $record['context']['exception'] ?? null;
        $stacktrace = '';

        if ($exception instanceof \Throwable) {
            $stacktrace = $exception->getTrace();
        }
        $filteredStacktrace = '';
        if ($stacktrace) {
            foreach ($stacktrace as $item) {
                if (isset($item['class']) && str_contains($item['class'], 'App')) {
                    $filteredStacktrace .= $item['class'] . '::' . ($item['function'] ?? 'unknown') . "\n";
                }
            }
        }
        $log = [
            'streams' => [
                [
                    'stream' => [
                        'level' => $record['level_name'],
                        'application' => 'symfony',
                    ],
                    'values' => [
                        [sprintf("%.0f", microtime(true) * 1e9), json_encode([
                            'message' => $record['message'],
                            'context' => $record['context'],
                            'stacktrace' => $filteredStacktrace,
                        ])],
                    ],
                ],
            ],
        ];

        $this->client->post($this->lokiUrl, [
            'json' => $log,
            'headers' => $headers,
        ]);
    }


}


