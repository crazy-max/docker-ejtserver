FROM openjdk:8-jre-alpine
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
  EJTSERVER_VERSION="1.13" \
  EJTSERVER_SHA256="2bd1c14de396f635be6163d612a4e5f9676ca4ad04562bd8033d12697ca10444" \
  USERNAME="docker" \
  UID=1000 GID=1000

RUN apk --update --no-cache add -t build-dependencies ca-certificates libressl tar wget \
  && apk --no-cache add supervisor tzdata \
  && mkdir -p ${EJTSERVER_PATH} \
  && wget -q "https://dl.bintray.com/crazy/tools/ejtserver_unix_${EJTSERVER_VERSION//./_}.tar.gz" \
    -O "/tmp/ejtserver.tar.gz" \
  && echo "$EJTSERVER_SHA256  /tmp/ejtserver.tar.gz" | sha256sum -c - | grep OK \
  && tar -xzf "/tmp/ejtserver.tar.gz" --strip 1 -C ${EJTSERVER_PATH} \
  && chmod a+x $EJTSERVER_PATH/bin/admin $EJTSERVER_PATH/bin/ejtserver* \
  && ln -sf "$EJTSERVER_PATH/bin/admin" "/usr/local/bin/admin" \
  && ln -sf "$EJTSERVER_PATH/bin/ejtserver" "/usr/local/bin/ejtserver" \
  && rm -f $EJTSERVER_PATH/*.txt \
  && apk del build-dependencies \
  && rm -rf /var/cache/apk/* /tmp/*

ADD entrypoint.sh /entrypoint.sh
ADD assets /

RUN chmod a+x /entrypoint.sh

EXPOSE 11862
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]
