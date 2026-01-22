FROM debian:trixie-20260112-slim

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /opt

ENV GHRUNNER_VERSION=2.331.0
ENV GHRUNNER_URL=https://github.com/actions/runner/releases/download/v${GHRUNNER_VERSION}
ENV GHRUNNER_FILENAME=actions-runner-linux-x64-${GHRUNNER_VERSION}.tar.gz
ENV GHRUNNER_SHA256=5fcc01bd546ba5c3f1291c2803658ebd3cedb3836489eda3be357d41bfcf28a7

RUN apt-get update \
    && apt-get install -y \
        bash \
        ca-certificates \
        curl \
    && mkdir actions-runner \
    && cd actions-runner \
    && curl -O -L $GHRUNNER_URL/$GHRUNNER_FILENAME \
    && echo "$GHRUNNER_SHA256  ./$GHRUNNER_FILENAME" | sha256sum -c - \
    && tar xzf ./$GHRUNNER_FILENAME \
    && rm -f ./$GHRUNNER_FILENAME \
    && useradd -l -m -s /bin/bash runner \
    && /opt/actions-runner/bin/installdependencies.sh \
    && chown -R runner:runner /opt/actions-runner \
    && apt-get purge wget

USER runner
WORKDIR /opt/actions-runner

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/opt/actions-runner/run.sh"]
