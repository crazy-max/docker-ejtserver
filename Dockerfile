# syntax=docker/dockerfile:experimental
FROM --platform=${TARGETPLATFORM:-linux/amd64} adoptopenjdk:12-jre-hotspot as suexec

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM:-linux/amd64}, building for ${TARGETPLATFORM:-linux/amd64}\n$(uname -a)\n"

RUN  apt-get update \
  && apt-get install -y --no-install-recommends \
    gcc \
    libc-dev \
  && curl -o /usr/local/bin/su-exec.c https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c \
  && gcc -Wall /usr/local/bin/su-exec.c -o/usr/local/bin/su-exec \
  && chown root:root /usr/local/bin/su-exec \
  && chmod 0755 /usr/local/bin/su-exec

FROM --platform=${TARGETPLATFORM:-linux/amd64} adoptopenjdk:12-jre-hotspot

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="CrazyMax" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.url="https://github.com/crazy-max/docker-ejtserver" \
  org.opencontainers.image.source="https://github.com/crazy-max/docker-ejtserver" \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.revision=$VCS_REF \
  org.opencontainers.image.vendor="CrazyMax" \
  org.opencontainers.image.title="EJT License Server" \
  org.opencontainers.image.description="EJT License Server" \
  org.opencontainers.image.licenses="MIT"

ENV TZ="UTC" \
  PUID="1000" \
  PGID="1000"

COPY entrypoint.sh /entrypoint.sh
COPY --from=suexec /usr/local/bin/su-exec /usr/local/bin/su-exec

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    curl \
    tar \
    tzdata \
  && chmod a+x /entrypoint.sh \
  && mkdir -p /data /opt/ejtserver \
  && groupadd -f -g ${PGID} ejt \
  && useradd -o -s /bin/bash -d /data -u ${PUID} -g ejt -m ejt \
  && chown -R ejt. /data /opt/ejtserver \
  && ln -sf /opt/ejtserver/bin/admin /usr/local/bin/admin \
  && ln -sf /opt/ejtserver/bin/ejtserver /usr/local/bin/ejtserver \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 11862
WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/local/bin/ejtserver", "start-launchd" ]

HEALTHCHECK --interval=10s --timeout=5s \
  CMD ejtserver status || exit 1
