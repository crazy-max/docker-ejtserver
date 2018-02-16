#!/bin/sh

TZ=${TZ:-"UTC"}
EJTSERVER_VERSION="1.13"
EJTSERVER_DOWNLOAD_BASEURL=${EJTSERVER_DOWNLOAD_BASEURL:-"https://licenseserver.ej-technologies.com"}
EJTSERVER_TARBALL="ejtserver_unix_${EJTSERVER_VERSION//./_}.tar.gz"
EJTSERVER_DOWNLOAD_URL="${EJTSERVER_DOWNLOAD_BASEURL}/${EJTSERVER_TARBALL}"
EJTSERVER_ADDRESS="0.0.0.0"
EJTSERVER_PORT=11862
EJTSERVER_DISPLAY_HOSTNAMES=${EJTSERVER_DISPLAY_HOSTNAMES:-"false"}
EJTSERVER_LOG_LEVEL=${EJTSERVER_LOG_LEVEL:-"INFO"}

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
mkdir -p /data
chown -R ${USERNAME}. /data ${EJTSERVER_PATH}

# Download ejtserver tarball
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

# Install
echo "Installing ejtserver ${EJTSERVER_VERSION}..."
rm -rf ${EJTSERVER_PATH}/*
tar -xzf "/data/${EJTSERVER_TARBALL}" --strip 1 -C ${EJTSERVER_PATH}
chmod a+x ${EJTSERVER_PATH}/bin/admin ${EJTSERVER_PATH}/bin/ejtserver*
ln -sf "$EJTSERVER_PATH/bin/admin" "/usr/local/bin/admin"
ln -sf "$EJTSERVER_PATH/bin/ejtserver" "/usr/local/bin/ejtserver"
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
> ${EJTSERVER_PATH}/license.txt
for EJTSERVER_LICENSE in $(echo ${EJTSERVER_LICENSES} | tr "," "\n"); do
  echo "${EJTSERVER_LICENSE}" >> ${EJTSERVER_PATH}/license.txt
done

# Configure
echo "Configuring license server..."
cat > ${EJTSERVER_PATH}/bin/ejtserver.vmoptions <<EOL
-Dejtserver.port=${EJTSERVER_PORT}
-Dejtserver.ip=${EJTSERVER_ADDRESS}
-Dejt.displayHostNames=${EJTSERVER_DISPLAY_HOSTNAMES}
EOL

# Log level
echo "Setting log level of license server to $LOG_LEVEL..."
cat > ${EJTSERVER_PATH}/log4j.properties <<EOL
log4j.rootLogger=${EJTSERVER_LOG_LEVEL}, stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=[%p] - %d{ISO8601} - %m%n
EOL

# Fix perms
echo "Fixing permissions..."
chown -R ${USERNAME}. /data ${EJTSERVER_PATH}

exec "$@"
