# Forgejo Actions CI image for the Elixir game servers
# (BlackLobster, high_level_alchemy, AstralOdyssey).
#
# Superset so a SINGLE `elixir` runner label covers all three:
#   - nodejs/npm                    -> Phoenix/LiveView asset steps
#   - build-essential + libbz2-dev  -> bcrypt_elixir / bzip2 / crc NIFs
#   - rust/cargo                    -> rustler NIFs (AstralOdyssey's isotope_118)
# Pushed as sickday/elixir:ci (see .github/workflows/ci-images.yml).
FROM elixir:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs npm \
        build-essential \
        libbz2-dev \
        git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Rust toolchain, system-wide, for rustler-backed NIFs. World-readable so the
# job container's user (root by default, but defensively any user) can use it.
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --default-toolchain stable --profile minimal --no-modify-path \
    && chmod -R a+rwX "$CARGO_HOME" "$RUSTUP_HOME" \
    && rustc --version && cargo --version

# Docker CLI (+ buildx) so CI container-publish jobs can `docker build`/`push`
# against the runner HOST's daemon (its socket is mounted into jobs). CLI only,
# no daemon shipped here.
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin \
    && rm -rf /var/lib/apt/lists/*

# Pre-seed hex + rebar so jobs don't re-bootstrap them on every run.
RUN mix local.hex --force && mix local.rebar --force
