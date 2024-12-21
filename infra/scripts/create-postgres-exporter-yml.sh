#!/bin/bash

create_postgres_exporter_yml() {
    message "Create config for postgres_exporter"
    cat <<EOF > ./infra/metrics/prometheus/postgres_exporter.yml
auth_modules:
  my_db:
    type: userpass
    userpass:
      username: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
    options:
      sslmode: disable
EOF

    cat <<EOF > ./infra/metrics/prometheus/queries.yaml
pg_stat_activity_successful:
  query: "SELECT time_bucket('1 hour', time) AS bucket, COUNT(*) AS successful_requests FROM api_logs WHERE status = '200' GROUP BY bucket"
  metrics:
    - bucket:
        usage: "LABEL"
        description: "Time bucket in hours"
    - successful_requests:
        usage: "COUNTER"
        description: "Number of successful OpenAI API requests"

pg_stat_activity_failed:
  query: "SELECT time_bucket('1 hour', time) AS bucket, COUNT(*) AS failed_requests FROM api_logs WHERE status != '200' GROUP BY bucket"
  metrics:
    - bucket:
        usage: "LABEL"
        description: "Time bucket in hours"
    - failed_requests:
        usage: "COUNTER"
        description: "Number of failed OpenAI API requests"
EOF
    chmod 777 ./infra/metrics/prometheus/postgres_exporter.yml
    chmod 777 ./infra/metrics/prometheus/queries.yaml
    echo "postgres_exporter.yaml generated with database: ${POSTGRES_DB}"
}
