# Forgejo Actions CI image for the Elixir game servers
# (BlackLobster, high_level_alchemy, AstralOdyssey).
#
# Superset so a SINGLE `elixir` runner label covers all three:
#   - nodejs/npm                    -> Phoenix/LiveView asset steps
#   - build-essential + libbz2-dev  -> bcrypt_elixir / bzip2 / crc NIFs
#   - rust/cargo                    -> rustler NIFs (AstralOdyssey's isotope_118)
# Pushed as sickday/elixir:ci (see .github/workflows/ci-images.yml).
#
# Also built per-Elixir-version for libraries that support a range rather than a
# single pinned version (isotope_118 supports ~> 1.18):
#   sickday/elixir:ci       -> Elixir 1.20.0 / OTP 29   (the game servers)
#   sickday/elixir:ci-1.19  -> Elixir 1.19.5 / OTP 28
#   sickday/elixir:ci-1.18  -> Elixir 1.18.4 / OTP 27
#
# The version-specific tags use hexpm/elixir rather than the official image
# because `elixir:1.18.4-otp-27` is Debian bookworm, whose `nodejs` is 18 —
# too old for `actions/checkout@v4`, which declares `using: node20`. Forgejo
# does not inject a node binary into custom containers. The hexpm trixie
# variants ship node 20.
#
# Pinned (not `:latest`): `:latest` floats to in-dev Elixir releases whose new
# warnings break `mix compile --warnings-as-errors`. Bump deliberately and keep
# in sync with each app's Dockerfile + local dev toolchain.
ARG BASE_IMAGE=elixir:1.20.0-otp-29
FROM ${BASE_IMAGE}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs npm \
        build-essential \
        libbz2-dev \
        git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Rust toolchain, system-wide, for rustler-backed NIFs. World-readable so the
# job container's user (root by default, but defensively any user) can use it.
# rustup `stable` rather than Debian's `rustc`: rustler 0.38 requires rustc
# >= 1.91 and distro packages lag well behind that.
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
