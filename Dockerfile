# Find eligible builder and runner images on Docker Hub. Pick a specific
# temporary tag, not "latest", for reproducibility.
#
#   https://hub.docker.com/r/hexpm/elixir/tags?name=1.19.5-erlang-27.3.4-debian-trixie
#   https://hub.docker.com/_/debian?tab=tags&name=trixie-slim
#
# This file was based on the output of `mix phx.gen.release --docker`.

ARG ELIXIR_VERSION=1.19.5
ARG OTP_VERSION=27.3.4
ARG DEBIAN_VERSION=trixie-20250428-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ===========
# Build stage
# ===========
FROM ${BUILDER_IMAGE} AS builder

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV="prod"

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

COPY assets assets

# Compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# ==========
# App stage
# ==========
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# Set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/fretboard ./

USER nobody

# If using an environment that doesn't automatically reap zombie processes
# (e.g. Docker), it is advised to add an init process such as tini via
# `apt-get install tini` inside the build stage and adding an entrypoint:
#
#     ENTRYPOINT ["/tini", "--"]
#
# See https://github.com/krallin/tini for details.

CMD ["/app/bin/server"]
