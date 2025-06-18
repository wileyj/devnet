FROM rust:1.86.0-slim-bookworm AS builder

RUN apt-get update && apt-get install -y \
    make \
    git \
    pkg-config \
    libssl-dev \
    mold

# The *mold* and *sccache* are used to reduce build time
# I'm not sure if it works
RUN cargo install sccache
ENV RUSTC_WRAPPER="/usr/local/cargo/bin/sccache"
ENV RUSTFLAGS="-C link-arg=-fuse-ld=mold"

# This will be overridden by the value from docker-compose
ARG STACKS_CORE_BASE_BRANCH=main

RUN echo "Building Stacks Core from branch: $STACKS_CORE_BASE_BRANCH"

# Clone the specified branch from GitHub
RUN git clone --branch $STACKS_CORE_BASE_BRANCH --single-branch --depth=1 https://github.com/stacks-network/stacks-core.git /code/stacks-core
WORKDIR /code/stacks-core

# Build initial version to cache dependencies
RUN cargo build --bin stacks-node --bin stacks-signer

# Build with the code from the specified branch
RUN cargo build --bin stacks-node --bin stacks-signer

FROM debian:bookworm-slim AS stacks-node
RUN apt-get update \
    && apt-get install -y ca-certificates --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir /data
COPY --from=builder /code/stacks-core/target/debug/stacks-node /usr/local/bin/stacks-node

FROM debian:bookworm-slim AS stacks-signer
RUN apt-get update \
    && apt-get install -y ca-certificates --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir /data
COPY --from=builder /code/stacks-core/target/debug/stacks-signer /usr/local/bin/stacks-signer
