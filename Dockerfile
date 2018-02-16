FROM openjdk:8-jre-alpine3.7
MAINTAINER CrazyMax <crazy-max@users.noreply.github.com>

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="ejtserver" \
  org.label-schema.description="EJT License Server image based on Alpine Linux" \
  org.label-schema.version=$VERSION \
  org.label-schema.url="https://github.com/crazy-max/docker-ejtserver" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/crazy-max/docker-ejtserver" \
  org.label-schema.vendor="CrazyMax" \
  org.label-schema.schema-version="1.0"

ENV EJTSERVER_PATH="/opt/ejtserver" \
  USERNAME="docker" \
  UID=1000 GID=1000

ADD entrypoint.sh /entrypoint.sh

RUN apk --update --no-cache add curl tar tzdata \
  && mkdir -p ${EJTSERVER_PATH} \
  && chmod a+x /entrypoint.sh \
  && rm -rf /var/cache/apk/* /tmp/*

EXPOSE 11862
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/local/bin/ejtserver", "start-launchd" ]
