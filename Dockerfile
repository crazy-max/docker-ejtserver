# syntax=docker/dockerfile:experimental
FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.10

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM:-linux/amd64}, building for ${TARGETPLATFORM:-linux/amd64}\n$(uname -a)\n"

# https://raw.githubusercontent.com/AdoptOpenJDK/openjdk-docker/master/12/jre/alpine/Dockerfile.hotspot.releases.full
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apk add --no-cache --virtual .build-deps curl binutils \
  && GLIBC_VER="2.29-r0" \
  && ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" \
  && GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-9.1.0-2-x86_64.pkg.tar.xz" \
  && GCC_LIBS_SHA256="91dba90f3c20d32fcf7f1dbe91523653018aa0b8d2230b00f822f6722804cf08" \
  && ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-3-x86_64.pkg.tar.xz" \
  && ZLIB_SHA256=17aede0b9f8baa789c5aa3f358fbf8c68a5f1228c5e6cba1a5dd34102ef4d4e5 \
  && curl -LfsS https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
  && SGERRAND_RSA_SHA256="823b54589c93b02497f1ba4dc622eaef9c813e6b0f0ebbb2f771e32adf9f4ef2" \
  && echo "${SGERRAND_RSA_SHA256} */etc/apk/keys/sgerrand.rsa.pub" | sha256sum -c - \
  && curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/glibc-${GLIBC_VER}.apk \
  && apk add /tmp/glibc-${GLIBC_VER}.apk \
  && curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk > /tmp/glibc-bin-${GLIBC_VER}.apk \
  && apk add /tmp/glibc-bin-${GLIBC_VER}.apk \
  && curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk > /tmp/glibc-i18n-${GLIBC_VER}.apk \
  && apk add /tmp/glibc-i18n-${GLIBC_VER}.apk \
  && /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true \
  && echo "export LANG=$LANG" > /etc/profile.d/locale.sh \
  && curl -LfsS ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz \
  && echo "${GCC_LIBS_SHA256} */tmp/gcc-libs.tar.xz" | sha256sum -c - \
  && mkdir /tmp/gcc \
  && tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc \
  && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
  && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
  && curl -LfsS ${ZLIB_URL} -o /tmp/libz.tar.xz \
  && echo "${ZLIB_SHA256} */tmp/libz.tar.xz" | sha256sum -c - \
  && mkdir /tmp/libz \
  && tar -xf /tmp/libz.tar.xz -C /tmp/libz \
  && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
  && apk del --purge .build-deps glibc-i18n \
  && rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar.xz /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

ENV JAVA_VERSION jdk-12.0.2+10

RUN set -eux; \
  apk add --virtual .fetch-deps curl; \
  ARCH="$(apk --print-arch)"; \
  case "${ARCH}" in \
   aarch64|arm64) \
     ESUM='df8f75fda5430bb99d12316811e2fdb084cd88084a0cbabaa0ae0574cbcd007c'; \
     BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk-12.0.2%2B10/OpenJDK12U-jre_aarch64_linux_hotspot_12.0.2_10.tar.gz'; \
     ;; \
   ppc64el|ppc64le) \
     ESUM='3a8554c1cc340b31c55698a4946d2d9039121f509e2e4be33fae39e5fb452698'; \
     BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk-12.0.2%2B10/OpenJDK12U-jre_ppc64le_linux_hotspot_12.0.2_10.tar.gz'; \
     ;; \
   s390x) \
     ESUM='d17d686927bc67edda26516198e57e67246036b1e5452d70ca6038a9d228039e'; \
     BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk-12.0.2%2B10/OpenJDK12U-jre_s390x_linux_hotspot_12.0.2_10.tar.gz'; \
     ;; \
   amd64|x86_64) \
     ESUM='1e43c4129272d49f7d3c25b6054d5f1140a7168864d9a9b965f9295adc62e44b'; \
     BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk-12.0.2%2B10/OpenJDK12U-jre_x64_linux_hotspot_12.0.2_10.tar.gz'; \
     ;; \
   *) \
     echo "Unsupported arch: ${ARCH}"; \
     exit 1; \
     ;; \
  esac; \
  curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
  echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
  mkdir -p /opt/java/openjdk; \
  cd /opt/java/openjdk; \
  tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
  apk del --purge .fetch-deps; \
  rm -rf /var/cache/apk/*; \
  rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
  PATH="/opt/java/openjdk/bin:$PATH"

LABEL maintainer="CrazyMax" \
  org.label-schema.name="ejtserver" \
  org.label-schema.description="EJT License Server" \
  org.label-schema.url="https://github.com/crazy-max/docker-ejtserver" \
  org.label-schema.vcs-url="https://github.com/crazy-max/docker-ejtserver" \
  org.label-schema.vendor="CrazyMax" \
  org.label-schema.schema-version="1.0"

ENV TZ="UTC"

COPY entrypoint.sh /entrypoint.sh

RUN apk --update --no-cache add \
    curl \
    shadow \
    tar \
    tzdata \
  && chmod a+x /entrypoint.sh \
  && mkdir -p /data /opt/ejtserver \
  && addgroup -g 1000 ejt \
  && adduser -u 1000 -G ejt -h /data -s /sbin/nologin -D ejt \
  && chown -R ejt. /data /opt/ejtserver \
  && ln -sf /opt/ejtserver/bin/admin /usr/local/bin/admin \
  && ln -sf /opt/ejtserver/bin/ejtserver /usr/local/bin/ejtserver \
  && rm -rf /var/cache/apk/* /tmp/*

USER ejt

EXPOSE 11862
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/local/bin/ejtserver", "start-launchd" ]

HEALTHCHECK --interval=10s --timeout=5s \
  CMD ejtserver status || exit 1
