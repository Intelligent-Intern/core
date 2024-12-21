#!/bin/bash

# Make sure we are in the right directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"/../../ || exit

# Run integration tests
echo "Running integration tests..."
docker compose --env-file .env.local -f ./docker-compose.yml run --rm app pytest /tests/integration

# Run unit tests
echo "Running unit tests..."
docker compose --env-file .env.local -f ./docker-compose.yml run --rm app pytest /tests/unit

# app/tests/run.sh