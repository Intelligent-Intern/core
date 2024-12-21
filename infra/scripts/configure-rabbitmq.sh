#!/bin/bash

configure_rabbitmq() {
  docker exec "$RABBIT_INSTANCE" sh -c 'echo "something" > /var/lib/rabbitmq/.erlang.cookie && chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie && chmod 400 /var/lib/rabbitmq/.erlang.cookie'
  docker restart "$RABBIT_INSTANCE"
  sleep 5

  docker exec "$RABBIT_INSTANCE" rabbitmq-plugins enable rabbitmq_management
  docker exec "$RABBIT_INSTANCE" rabbitmqctl add_vhost /
  docker exec "$RABBIT_INSTANCE" rabbitmqctl set_permissions -p / "${RABBITMQ_USER}" ".*" ".*" ".*"

  curl -u "${RABBITMQ_USER}":"${RABBITMQ_PASSWORD}" -X PUT "http://${RABBIT_INSTANCE_IP}:15672/api/exchanges/%2f/$MINIO_NOTIFY_AMQP_EXCHANGE" \
      -H "Content-Type: application/json" \
      -d '{"type":"direct","auto_delete":false,"durable":true,"internal":false,"arguments":{}}'
  curl -u "${RABBITMQ_USER}":"${RABBITMQ_PASSWORD}" -X PUT "http://${RABBIT_INSTANCE_IP}:15672/api/queues/%2f/$MINIO_INCOMING_PUT_QUEUE" \
      -H "Content-Type: application/json" \
      -d '{"auto_delete":false,"durable":true}'
  curl -u "${RABBITMQ_USER}":"${RABBITMQ_PASSWORD}" -X POST "http://${RABBIT_INSTANCE_IP}:15672/api/bindings/%2f/e/IIExchange/q/$MINIO_INCOMING_PUT_QUEUE" \
      -H "Content-Type: application/json" \
      -d '{"routing_key":"'"$MINIO_NOTIFY_AMQP_ROUTING_KEY"'","arguments":{}}'
}
