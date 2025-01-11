#!/bin/sh
set -e

cd /app/setup
npm install

if [ -n "$LOKI_URL" ]; then
  npm install pino pino-loki
  export LOG_LEVEL="info"
  export LOKI_URL=${LOKI_URL}
fi

if [ "${1#-}" != "${1}" ] || [ -z "$(command -v "${1}")" ] || { [ -f "${1}" ] && ! [ -x "${1}" ]; }; then
  set -- node "$@"
fi

exec "$@"
