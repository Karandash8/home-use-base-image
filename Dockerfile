FROM ubuntu:noble as build

# Arguments
ARG TARGETOS=linux
ARG TARGETARCH=arm64
ARG TARGETPLATFORM
ARG RUNNER_VERSION=2.317.0
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.6.0

RUN apt-get update && apt-get install --no-install-recommends -y \
  ca-certificates \
  curl \
  unzip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /actions-runner
RUN export RUNNER_ARCH=${TARGETARCH} \
    && if [ "$RUNNER_ARCH" = "amd64" ]; then export RUNNER_ARCH=x64 ; fi \
    && curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-${TARGETOS}-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz

RUN curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm runner-container-hooks.zip


FROM ubuntu:noble

# Install software
RUN apt-get update && apt-get install --no-install-recommends -y \
  software-properties-common

# Configure git-core/ppa based on guidance here:  https://git-scm.com/download/linux
RUN add-apt-repository ppa:git-core/ppa

RUN apt-get update && apt-get install --no-install-recommends -y \
  ca-certificates \
  git \
  sudo \
  && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --uid 1001 runner \
    && usermod -aG sudo runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

WORKDIR /home/runner

COPY --chown=runner:runner --from=build /actions-runner .

USER runner
