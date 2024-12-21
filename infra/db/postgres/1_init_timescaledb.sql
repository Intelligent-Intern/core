-- init_timescaledb.sql
\connect mydatabase

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS api_logs (
                                        time TIMESTAMPTZ NOT NULL,
                                        request JSONB,
                                        response JSONB,
                                        response_time_ms INT
);

SELECT create_hypertable('api_logs', 'time', if_not_exists => TRUE);
