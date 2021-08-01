FROM crazymax/yasu:latest AS yasu
FROM adoptopenjdk:11-jre-hotspot

ENV TZ="UTC" \
  PUID="1000" \
  PGID="1000"

COPY entrypoint.sh /entrypoint.sh
COPY --from=yasu / /

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
