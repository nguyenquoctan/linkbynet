#!/bin/bash

if [ -f "/etc/environment" ]; then
    echo "Source /etc/environment"
    . /etc/environment
fi

basedir=$(dirname $0)

# Set default username if not override
USER_NAME="${USER_NAME:-default}"

# Insert username into pwd
if ! whoami &> /dev/null; then
  if [ -w "/etc/passwd" ]; then
    echo "${USER_NAME}:x:$(id -u):0:${USER_NAME} user:${USER_HOME}:/sbin/bash" >> /etc/passwd
  fi
fi

echo "USER_NAME: $(id)"

echo "TZ: ${TZ}"

# Loop on WAIT_FOR_IT_LIST
if [ -n "${WAIT_FOR_IT_LIST}" ]; then
	for hostport in $(echo "${WAIT_FOR_IT_LIST}" | sed -e 's/,/ /g'); do
		${basedir}/wait-for-it.sh -s -t 0 ${hostport}
	done
else
	echo "No WAIT_FOR_IT_LIST"
fi

# Apache - User
export APACHE_RUN_USER="${USER_NAME}"
echo "APACHE_RUN_USER: ${APACHE_RUN_USER}"

# Apache - Syslog
if ls -1 /etc/apache2/conf-enabled/ | grep -q '^syslog.conf$'; then
	# APACHE_SYSLOG_HOST not defined but SYSLOG_HOST is
	if [ -n "${SYSLOG_HOST}" -a -z "${APACHE_SYSLOG_HOST}" ]; then
		export APACHE_SYSLOG_HOST=${SYSLOG_HOST}
	fi
	if [ -n "${SYSLOG_PORT}" -a -z "${APACHE_SYSLOG_PORt}" ]; then
		export APACHE_SYSLOG_PORT=${SYSLOG_PORT}
	fi
	echo "APACHE Syslog enabled"
	echo "APACHE_SYSLOG_HOST: ${APACHE_SYSLOG_HOST}"
	echo "APACHE_SYSLOG_PORT: ${APACHE_SYSLOG_PORT}"
	echo "APACHE_SYSLOG_PROGNAME: ${APACHE_SYSLOG_PROGNAME}"
fi

echo "APACHE_REMOTE_IP_HEADER: ${APACHE_REMOTE_IP_HEADER}"
echo "APACHE_REMOTE_IP_TRUSTED_PROXY: ${APACHE_REMOTE_IP_TRUSTED_PROXY}"
echo "APACHE_REMOTE_IP_INTERNAL_PROXY: ${APACHE_REMOTE_IP_INTERNAL_PROXY}"

exec $@