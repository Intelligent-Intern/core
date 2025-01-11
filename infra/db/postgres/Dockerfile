FROM timescale/timescaledb:latest-pg14

# Add external repository for LLVM and install clang-15
RUN apk update && apk add --no-cache \
    postgresql-dev gcc make git musl-dev llvm15 clang15 && \
    git clone https://github.com/pgvector/pgvector.git /pgvector && \
    cd /pgvector && make && make install && \
    apk del git gcc make musl-dev llvm15 clang15 && \
    rm -rf /var/cache/apk/* /pgvector
