#!/bin/sh

TZ=${TZ:-"UTC"}
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

# Init EJT License Server
echo "Initializing..."
if [ ! -f "/data/ip.txt" ]; then
  touch /data/ip.txt
  ln -sf /data/ip.txt ${EJTSERVER_PATH}/ip.txt
fi
if [ ! -f "/data/users.txt" ]; then
  touch /data/users.txt
  ln -sf /data/users.txt ${EJTSERVER_PATH}/users.txt
fi
if [ ! -f "/data/license.txt" ]; then
  touch /data/license.txt
  ln -sf /data/license.txt ${EJTSERVER_PATH}/license.txt
fi

# Configure
echo "Configuring..."
cat > ${EJTSERVER_PATH}/bin/ejtserver.vmoptions <<EOL
-Dejtserver.port=${EJTSERVER_PORT}
-Dejtserver.ip=${EJTSERVER_ADDRESS}
-Dejt.displayHostNames=${EJTSERVER_DISPLAY_HOSTNAMES}
EOL

# Log level
echo "Setting log level to $LOG_LEVEL..."
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
echo "Check licenses..."
if [ ! -s "/data/license.txt" ]; then
  echo "FATAL: No licenses were found in license.txt"
  exit 1
fi

exec "$@"
