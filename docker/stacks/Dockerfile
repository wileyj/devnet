FROM rust:bookworm AS builder

# This will be overridden by the value from docker-compose
ARG STACKS_CORE_BASE_BRANCH=master

RUN echo "Building Stacks Core from branch: $STACKS_CORE_BASE_BRANCH"

# Clone the specified branch from GitHub
RUN git clone --branch $STACKS_CORE_BASE_BRANCH --single-branch --depth=1 https://github.com/stacks-network/stacks-core.git /code/stacks-core
WORKDIR /code/stacks-core
# Apply PR diff to enable SIGNER_APPROVAL_THRESHOLD (default is 70%)
#   https://github.com/stacks-network/stacks-core/pull/6375
RUN curl https://patch-diff.githubusercontent.com/raw/stacks-network/stacks-core/pull/6375.patch | git apply -v --index
RUN apt-get update && apt-get install -y git libclang-dev llvm
RUN curl -#L https://github.com/stacks-network/bitcoin/releases/download/v25.2/bitcoin-25.2-x86_64-linux-gnu.tar.gz -o /tmp/bitcoin-25.2-x86_64-linux-gnu.tar.gz
RUN tar -xzvf /tmp/bitcoin-25.2-x86_64-linux-gnu.tar.gz -C /tmp

# Run an build that we'll cache the result of and then build the code
RUN cargo build --features monitoring_prom,slog_json --bin stacks-node --bin stacks-signer

FROM debian:bookworm-slim AS stacks-node
RUN apt-get update \
    && apt-get install -y ca-certificates --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir /data
COPY --from=builder /code/stacks-core/target/debug/stacks-node /usr/local/bin/stacks-node
COPY --from=builder /tmp/bitcoin-25.2/bin/bitcoin-cli /usr/bin/bitcoin-cli
STOPSIGNAL SIGTERM

FROM debian:bookworm-slim AS stacks-signer
RUN apt-get update \
    && apt-get install -y ca-certificates --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir /data
COPY --from=builder /code/stacks-core/target/debug/stacks-signer /usr/local/bin/stacks-signer
STOPSIGNAL SIGTERM
