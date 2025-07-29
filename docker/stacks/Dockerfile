FROM rust:bookworm AS builder

# RUN apt-get update && apt-get install -y \
#     git \
#     libclang-dev \
#     llvm \
#     make \
#     pkg-config \
#     libssl-dev
# git \
# make \
# git \
# pkg-config \
# libssl-dev
RUN apt-get update && apt-get install -y git libclang-dev llvm

# git \
# make \
# git \
# pkg-config \
# libssl-dev

# # The *mold* and *sccache* are used to reduce build time
# # I'm not sure if it works
# RUN cargo install sccache
# ENV RUSTC_WRAPPER="/usr/local/cargo/bin/sccache"
# ENV RUSTFLAGS="-C link-arg=-fuse-ld=mold"

# This will be overridden by the value from docker-compose
ARG STACKS_CORE_BASE_BRANCH=main

RUN echo "Building Stacks Core from branch: $STACKS_CORE_BASE_BRANCH"

# Clone the specified branch from GitHub
RUN git clone --branch $STACKS_CORE_BASE_BRANCH --single-branch --depth=1 https://github.com/stacks-network/stacks-core.git /code/stacks-core
WORKDIR /code/stacks-core

# Build initial version to cache dependencies
RUN rustup toolchain install stable
# RUN cargo build --bin stacks-node --bin stacks-signer
## release build
# RUN cargo build --features monitoring_prom,slog_json --release --bin stacks-node --bin stacks-signer
## debug build
RUN cargo build --features monitoring_prom,slog_json --bin stacks-node
# Build stacks-signer
# RUN cargo build --bin stacks-node --bin stacks-signer
RUN cargo build --features monitoring_prom,slog_json --bin stacks-signer

FROM debian:bookworm-slim AS stacks-node
RUN apt-get update \
    && apt-get install -y ca-certificates curl jq --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir /data
COPY --from=builder /code/stacks-core/target/debug/stacks-node /usr/local/bin/stacks-node

FROM debian:bookworm-slim AS stacks-signer
RUN apt-get update \
    && apt-get install -y ca-certificates curl jq --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir /data
COPY --from=builder /code/stacks-core/target/debug/stacks-signer /usr/local/bin/stacks-signer

