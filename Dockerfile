# syntax=docker/dockerfile:experimental
FROM --platform=${TARGETPLATFORM:-linux/amd64} adoptopenjdk:12-jre-hotspot

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM:-linux/amd64}, building for ${TARGETPLATFORM:-linux/amd64}\n$(uname -a)\n"

LABEL maintainer="CrazyMax" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="ejtserver" \
  org.label-schema.description="EJT License Server" \
  org.label-schema.version=$VERSION \
  org.label-schema.url="https://github.com/crazy-max/docker-ejtserver" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/crazy-max/docker-ejtserver" \
  org.label-schema.vendor="CrazyMax" \
  org.label-schema.schema-version="1.0"

ENV TZ="UTC"

COPY entrypoint.sh /entrypoint.sh

RUN apt-get update \
  && apt-get install -y \
    bash \
    curl \
    tar \
    tzdata \
  && chmod a+x /entrypoint.sh \
  && mkdir -p /data /opt/ejtserver \
  && groupadd -f -g 1000 ejt \
  && useradd -o -s /bin/bash -d /data -u 1000 -g 1000 -m ejt \
  && chown -R ejt. /data /opt/ejtserver \
  && ln -sf /opt/ejtserver/bin/admin /usr/local/bin/admin \
  && ln -sf /opt/ejtserver/bin/ejtserver /usr/local/bin/ejtserver \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER ejt

EXPOSE 11862
WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/local/bin/ejtserver", "start-launchd" ]

HEALTHCHECK --interval=10s --timeout=5s \
  CMD ejtserver status || exit 1
