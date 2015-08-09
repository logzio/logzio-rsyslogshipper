#!/bin/bash

function cleanup() {
	echo "stoping rsyslog, bay bay..."
	ps -A | grep /usr/sbin/rsyslogd | head -1 | awk '{print $1}' | xargs kill
}

# Trap and do manual cleanup
trap cleanup HUP INT QUIT KILL TERM

echo "LOGZIO_USER_TOKEN: $LOGZIO_USER_TOKEN"

if [[ $LOGZIO_USER_TOKEN == "" ]]; then
	echo "[ERROR] 'LOGZIO_USER_TOKEN' environment variable must be set"
	exit 1
fi

if [[ $MONITOR_FILE_TYPE == "" ]]; then
	echo "[ERROR] 'MONITOR_FILE_TYPE' environment variable must be set"
	exit 1
fi

# configure rsyslog && start service in background
/root/configure_rsyslog.bash "${LOGZIO_USER_TOKEN}" "${MONITOR_FILE_PATH}" "${MONITOR_FILE_TYPE}" "${CODEC}" 

#if [[ $MONITOR_CONF_FILE_PATH == "" ]]; then
#	# configure rsyslog && start service in background
#	/root/configure_rsyslog.bash "${LOGZIO_USER_TOKEN}" "${MONITOR_FILE_PATH}" "${MONITOR_FILE_TYPE}" "${CODEC}" 
#else
#	# read params from conf file
#	/root/conf_parser.py
#fi


if [[ $? -eq 1 ]]; then
	echo "[ERROR]" "Fail to configure rsyslog."
	exit 1
fi

# very sleepy process to keep the container up and running
while true; do
	sleep 3600
done

# stop service
cleanup

