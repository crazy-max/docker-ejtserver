#!/bin/sh

TZ=${TZ:-"UTC"}
EJTSERVER_VERSION="1.13"
EJTSERVER_DL_BASEURL=${EJTSERVER_DL_BASEURL:-"https://licenseserver.ej-technologies.com"}
EJTSERVER_TARBALL="ejtserver_unix_${EJTSERVER_VERSION//./_}.tar.gz"
EJTSERVER_DL_URL="${EJTSERVER_DL_BASEURL}/${EJTSERVER_TARBALL}"
EJTSERVER_ADDRESS="0.0.0.0"
EJTSERVER_PORT=11862
EJTSERVER_DISPLAY_HOSTNAMES=${EJTSERVER_DISPLAY_HOSTNAMES:-"false"}
LOG_LEVEL=${LOG_LEVEL:-"INFO"}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# Create docker user
echo "Creating ${USERNAME} user and group (uid=${UID} ; gid=${GID})..."
addgroup -g ${GID} ${USERNAME}
adduser -D -s /bin/sh -G ${USERNAME} -u ${UID} ${USERNAME}

# Init
echo "Initializing files and folders..."
mkdir -p /data /var/log/supervisord
chown -R ${USERNAME}. /data ${EJTSERVER_PATH}

# Download ejtserver tarball
if [ -f "/data/${EJTSERVER_TARBALL}" ]; then
  echo "ejtserver already downloaded in /data/${EJTSERVER_TARBALL}. Skipping download..."
else
  echo "Downloading ejtserver ${EJTSERVER_VERSION} from ${EJTSERVER_DL_URL}..."
  if [ ! -z "${EJTSERVER_DL_USERNAME}" ]; then
    dlErrorMsg=$(curl --location --fail --silent --show-error --output "/data/${EJTSERVER_TARBALL}" --user "${EJTSERVER_DL_USERNAME}:${EJTSERVER_DL_PASSWORD}" "${EJTSERVER_DL_URL}" 2>&1)
  else
    dlErrorMsg=$(curl --location --fail --silent --show-error --output "/data/${EJTSERVER_TARBALL}" "${EJTSERVER_DL_URL}" 2>&1)
  fi
  if [ ! -z "${dlErrorMsg}" ]; then
    echo "FATAL: ${dlErrorMsg}"
    exit 1
  fi
fi

# Install
echo "Installing ejtserver ${EJTSERVER_VERSION}..."
rm -rf ${EJTSERVER_PATH}/*
tar -xzf "/data/${EJTSERVER_TARBALL}" --strip 1 -C ${EJTSERVER_PATH}
chmod a+x ${EJTSERVER_PATH}/bin/admin ${EJTSERVER_PATH}/bin/ejtserver*
ln -sf "$EJTSERVER_PATH/bin/admin" "/usr/local/bin/admin"
ln -sf "$EJTSERVER_PATH/bin/ejtserver" "/usr/local/bin/ejtserver"
rm -f ${EJTSERVER_PATH}/*.txt

# Init ejtserver
echo "Initializing ejtserver..."
touch /data/ip.txt
touch /data/users.txt
touch /data/license.txt
ln -sf /data/ip.txt ${EJTSERVER_PATH}/ip.txt
ln -sf /data/license.txt ${EJTSERVER_PATH}/license.txt
ln -sf /data/users.txt ${EJTSERVER_PATH}/users.txt

# Configure
echo "Configuring ejtserver..."
cat > ${EJTSERVER_PATH}/bin/ejtserver.vmoptions <<EOL
-Dejtserver.port=${EJTSERVER_PORT}
-Dejtserver.ip=${EJTSERVER_ADDRESS}
-Dejt.displayHostNames=${EJTSERVER_DISPLAY_HOSTNAMES}
EOL

# Log level
echo "Setting log level of ejtserver to $LOG_LEVEL..."
cat > ${EJTSERVER_PATH}/log4j.properties <<EOL
log4j.rootLogger=${LOG_LEVEL}, stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=[%p] - %d{ISO8601} - %m%n
EOL

# Fix perms
echo "Fixing permissions..."
chown -R ${USERNAME}. /data ${EJTSERVER_PATH}

# Check licenses
echo "Check ejtserver licenses..."
if [ ! -s "/data/license.txt" ]; then
  echo "FATAL: No licenses were found in license.txt"
  exit 1
fi

exec "$@"
