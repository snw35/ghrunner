FROM nvidia/cuda:13.0.2-base-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

COPY docker-entrypoint.sh /docker-entrypoint.sh

WORKDIR /opt

ENV GHRUNNER_VERSION=2.332.0
ENV GHRUNNER_URL=https://github.com/actions/runner/releases/download/v${GHRUNNER_VERSION}
ENV GHRUNNER_FILENAME=actions-runner-linux-x64-${GHRUNNER_VERSION}.tar.gz
ENV GHRUNNER_SHA256=f2094522a6b9afeab07ffb586d1eb3f190b6457074282796c497ce7dce9e0f2a

RUN apt-get update \
    && apt-get install -y \
        bash \
        ca-certificates \
        curl \
        jq \
    && mkdir actions-runner \
    && cd actions-runner \
    && curl -O -L $GHRUNNER_URL/$GHRUNNER_FILENAME \
    && echo "$GHRUNNER_SHA256  ./$GHRUNNER_FILENAME" | sha256sum -c - \
    && tar xzf ./$GHRUNNER_FILENAME \
    && rm -f ./$GHRUNNER_FILENAME \
    && useradd -l -m -s /bin/bash runner \
    && /opt/actions-runner/bin/installdependencies.sh \
    && chown -R runner:runner /opt/actions-runner \
    && chmod +x /docker-entrypoint.sh

COPY docker.sources /etc/apt/sources.list.d/docker.sources

ENV DOCKER_VERSION=5:29.2.1-1~ubuntu.22.04~jammy

RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && apt update \
    && apt install -y docker-ce=$DOCKER_VERSION docker-ce-cli=$DOCKER_VERSION containerd.io docker-buildx-plugin docker-compose-plugin

WORKDIR /opt/actions-runner

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/opt/actions-runner/run.sh"]
