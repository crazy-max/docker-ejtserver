FROM openjdk:8-jre-alpine3.9

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

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

COPY entrypoint.sh /entrypoint.sh

RUN apk --update --no-cache add \
    curl shadow tar tzdata \
  && mkdir -p /opt/ejtserver \
  && chmod a+x /entrypoint.sh \
  && addgroup -g 1000 ejt \
  && adduser -u 1000 -G ejt -h /data -s /sbin/nologin -D ejt \
  && rm -rf /var/cache/apk/* /tmp/*

EXPOSE 11862
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/local/bin/ejtserver", "start-launchd" ]
