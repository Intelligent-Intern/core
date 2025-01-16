<?php

namespace App\Interface;

use App\Service\VaultService;
use Laudis\Neo4j\Contracts\TransactionInterface;
use Psr\Log\LoggerInterface;

interface GraphDBServiceInterface
{
    public function supports(string $provider): bool;
    public function setLogger(LoggerInterface $logger): void;
    public function setVaultService(VaultService $vaultService): void;
    // Node Operations
    public function createNode(array $properties): array;
    public function findNodeById(string $id): ?array;
    public function updateNode(array $node, array $newProperties): array;
    public function deleteNode(array $node, bool $cascade = false): void;
    // Edge Operations
    public function createEdge(array $fromNode, array $toNode, string $type, array $properties = []): array;
    public function deleteEdge(array $edge): void;
    public function getNeighbors(array $node, string $relationshipType = null): array;
    // Subgraph Operations
    public function extractSubgraph(array $rootNode, int $depth, array $criteria = []): array;
    public function compareSubgraphs(array $subgraphA, array $subgraphB): float;
    // Query Execution
    public function runCustomQuery(string $cypherQuery, array $parameters = []): array;
    // Graph Analysis
    public function getNodeCount(string $label = null): int;
    public function findPath(array $startNode, array $endNode, array $criteria = []): array;
    // Transaction Operations
    public function startTransaction(): TransactionInterface;
    public function commitTransaction(TransactionInterface $transaction): void;
    public function rollbackTransaction(TransactionInterface $transaction): void;
    // Context Evolution (Weight Management)
    public function adjustEdgeWeight(string $edgeId, float $delta, string $weightType = 'normalWeight'): void;
    public function setPriorityWeightForMood(string $mood, float $weightIncrease): void;
    public function resetPriorityWeights(): void;
    public function decayAllWeights(string $weightType, float $decayFactor): void;
    // Context-Sensitive Queries
    public function getRelevantEdges(float $threshold, string $weightType = 'priorityWeight'): array;
}
