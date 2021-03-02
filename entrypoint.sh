#!/bin/bash

TZ=${TZ:-UTC}

EJTSERVER_VERSION=${EJTSERVER_VERSION:-1.14}
EJTSERVER_DOWNLOAD_BASEURL=${EJTSERVER_DOWNLOAD_BASEURL:-https://licenseserver.ej-technologies.com}
EJTSERVER_DISPLAY_HOSTNAMES=${EJTSERVER_DISPLAY_HOSTNAMES:-false}
EJTSERVER_LOG_LEVEL=${EJTSERVER_LOG_LEVEL:-INFO}

EJTSERVER_PATH="/opt/ejtserver"
EJTSERVER_TARBALL="ejtserver_unix_${EJTSERVER_VERSION//./_}.tar.gz"
EJTSERVER_DOWNLOAD_URL="${EJTSERVER_DOWNLOAD_BASEURL}/${EJTSERVER_TARBALL}"
EJTSERVER_ADDRESS="0.0.0.0"
EJTSERVER_PORT=11862

# From https://github.com/docker-library/mariadb/blob/master/docker-entrypoint.sh#L21-L41
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

if [ -n "${PGID}" ] && [ "${PGID}" != "$(id -g ejt)" ]; then
  echo "Switching to PGID ${PGID}..."
  sed -i -e "s/^ejt:\([^:]*\):[0-9]*/ejt:\1:${PGID}/" /etc/group
  sed -i -e "s/^ejt:\([^:]*\):\([0-9]*\):[0-9]*/ejt:\1:\2:${PGID}/" /etc/passwd
fi
if [ -n "${PUID}" ] && [ "${PUID}" != "$(id -u ejt)" ]; then
  echo "Switching to PUID ${PUID}..."
  sed -i -e "s/^ejt:\([^:]*\):[0-9]*:\([0-9]*\)/ejt:\1:${PUID}:\2/" /etc/passwd
fi

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# Download ejtserver tarball
file_env 'EJT_ACCOUNT_USERNAME'
file_env 'EJT_ACCOUNT_PASSWORD'
if [ -f "/data/${EJTSERVER_TARBALL}" ]; then
  echo "ejtserver already downloaded in /data/${EJTSERVER_TARBALL}. Skipping download..."
else
  echo "Downloading ejtserver ${EJTSERVER_VERSION} from ${EJTSERVER_DOWNLOAD_URL}..."
  if [ ! -z "${EJT_ACCOUNT_USERNAME}" ]; then
    dlErrorMsg=$(curl --location --fail --silent --show-error --output "/data/${EJTSERVER_TARBALL}" --user "${EJT_ACCOUNT_USERNAME}:${EJT_ACCOUNT_PASSWORD}" "${EJTSERVER_DOWNLOAD_URL}" 2>&1)
  else
    dlErrorMsg=$(curl --location --fail --silent --show-error --output "/data/${EJTSERVER_TARBALL}" "${EJTSERVER_DOWNLOAD_URL}" 2>&1)
  fi
  if [ ! -z "${dlErrorMsg}" ]; then
    echo "FATAL: ${dlErrorMsg}"
    exit 1
  fi
fi
unset EJT_ACCOUNT_USERNAME
unset EJT_ACCOUNT_PASSWORD

# Install
echo "Installing ejtserver ${EJTSERVER_VERSION}..."
rm -rf ${EJTSERVER_PATH}/*
tar -xzf "/data/${EJTSERVER_TARBALL}" --strip 1 -C ${EJTSERVER_PATH}
chmod a+x ${EJTSERVER_PATH}/bin/admin ${EJTSERVER_PATH}/bin/ejtserver*
rm -f ${EJTSERVER_PATH}/*.txt

# Init ejtserver
echo "Initializing license server..."
touch /data/ip.txt /data/users.txt
ln -sf /data/ip.txt ${EJTSERVER_PATH}/ip.txt
ln -sf /data/users.txt ${EJTSERVER_PATH}/users.txt

# Check licenses
echo "Checking licenses..."
if [ -z "$EJTSERVER_LICENSES" ]; then
  echo "FATAL: At least one license is required to start the license server"
  exit 1
fi

# Insert licenses
echo "Inserting licenses..."
file_env 'EJTSERVER_LICENSES'
> ${EJTSERVER_PATH}/license.txt
for EJTSERVER_LICENSE in $(echo ${EJTSERVER_LICENSES} | tr "," "\n"); do
  echo "${EJTSERVER_LICENSE}" >> ${EJTSERVER_PATH}/license.txt
done
unset EJTSERVER_LICENSES

# Configure
echo "Configuring license server..."
cat > ${EJTSERVER_PATH}/bin/ejtserver.vmoptions <<EOL
-Dejtserver.port=${EJTSERVER_PORT}
-Dejtserver.ip=${EJTSERVER_ADDRESS}
-Dejt.displayHostNames=${EJTSERVER_DISPLAY_HOSTNAMES}
EOL

# Log level
echo "Setting log level of license server to $EJTSERVER_LOG_LEVEL..."
cat > ${EJTSERVER_PATH}/log4j.properties <<EOL
log4j.rootLogger=${EJTSERVER_LOG_LEVEL}, stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=[%p] - %d{ISO8601} - %m%n
EOL

echo "Fixing perms..."
chown -R ejt:ejt /data "${EJTSERVER_PATH}"

exec gosu ejt:ejt "$@"
