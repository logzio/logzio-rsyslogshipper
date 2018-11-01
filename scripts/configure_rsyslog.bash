#!/bin/bash


# ---------------------------------------- 
# User input variables
# ---------------------------------------- 

# The rsyslog service name
RSYSLOG_SERVICE_NAME="rsyslog"

# The rsyslog conf directory
RSYSLOG_CONF_DIR="/etc/rsyslog.d"

# Logzio conf's directory path
LOGZ_CONF_DIR="/root/files"

# the user's authentication token, this is a mandatory input
USER_TOKEN=${1}

# Logzio - shared directory
LOGZ_SHARED_DIR=${2}

if [[ $LOGZ_SHARED_DIR == "" ]]; then
    LOGZ_SHARED_DIR="/var/log/logzio"
fi

# The log file path
FILE_PATH=${LOGZ_SHARED_DIR}

if [[ ! -z "${3}" ]]; then
	FILE_PATH=${LOGZ_SHARED_DIR}/${3}
fi

# The log file type
FILE_TAG=${4}

# The log file content
FILE_CONTENT=${5}

# Configure listener protocol
LISTENER_PROTOCOL=${6}

# Logzio - spool directory
LOGZ_SPOOL_DIR="${LOGZ_SHARED_DIR}/spool/rsyslog"

# Configure listener host name
LISTENER_HOST="${LISTENER_HOST:=listener.logz.io}"

# Configure listener port
if [[ $FILE_CONTENT == 'json' ]]; then
	LISTENER_PORT="5050"
else
	FILE_CONTENT='text'
	LISTENER_PORT="5000"
fi

if [[ $LISTENER_PROTOCOL == "" ]]; then
	LISTENER_PROTOCOL="tcp"
fi

# ---------------------------------------- 
# accept a command as an argument, on error
# exit with status code on error
# ---------------------------------------- 
function execute {
	echo "[DEBUG]" "Running command: $@"
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "[ERROR]" "Occurred while executing: $@" >&2
        exit $status
    fi
}

# ----------------------------------------
# validate network connectivity to logzio 
# listener servers
# ----------------------------------------
function validate_network_connectivity {
	# will hold the network connectivity status final result.
 	local status=0
	
	echo "[INFO]" "Checking if ${LISTENER_HOST} is reachable via ${LISTENER_PORT} port, using netcat. This may take some time...."
	echo "test" | nc ${LISTENER_HOST} ${LISTENER_PORT}
	status=$?
	
	if [ $status -ne 0 ]; then
		echo "[ERROR]" "Please check your network and firewall settings to the following ip's on port ${LISTENER_PORT}."
	    nslookup ${LISTENER_HOST} | grep Address
        exit 1
    else
    	echo "[INFO]" "Host: '${LISTENER_HOST}' is reachable via port '${LISTENER_PORT}'."
    fi
}


# ---------------------------------------- 
# check if a path is a directory
# ---------------------------------------- 
function is_directory {
	local path=$1

	if [[ -d $path ]]; then
		return 0
	fi

	return 1
}

# ---------------------------------------- 
# check if a path is a file
# ---------------------------------------- 
function is_file {
	local path=$1

	if [[ -f $path ]]; then
		return 0
	fi

	if [[ -L $path ]]; then
		return 0
	fi

	return 1	
}

# ---------------------------------------- 
# check if a path is a file with wild card
# ---------------------------------------- 
function is_wildcard_file {
		for f in $1; do

		    ## Check if the glob gets expanded to existing files.
		    ## If not, f here will be exactly the pattern above
		    ## and the exists test will evaluate to false.
		    [ -e "$f" ] && echo "exist" || echo "false"

		    ## This is all we needed to know, so we can break after the first iteration
		    break
		done
}

# ---------------------------------------- 
# validate that the file name dose not contain spaces
# and that it exist under the specified path
# ---------------------------------------- 
function validate_file_path {
	pattern=" |'"
	if [[ $FILE_PATH =~ $pattern ]]; then
		echo "[ERROR]" "White spaces are not allowed, File path: $FILE_PATH"
		exit 1
	fi
}

# ---------------------------------------- 
# validate that the file exist and valid
# ---------------------------------------- 
function validate_file {
	local file_dir_path=${FILE_PATH%/*}
	echo "file_dir_path: $file_dir_path"

	if is_file "$FILE_PATH";then
		echo "[INFO]" "Monitoring file: $FILE_PATH"

	elif is_directory "$FILE_PATH"; then
		FILE_PATH=${FILE_PATH%/}
		FILE_PATH="$FILE_PATH/*"
		echo "[INFO]" "Monitoring file: $FILE_PATH"

	elif is_wildcard_file "$FILE_PATH"; then
		echo "[INFO]" "Monitoring wildcard file: $FILE_PATH"

	else
		echo "[ERROR]" "Cannot access $FILE_PATH: No such file or directory"
		exit 1
	fi

	validate_file_path "$FILE_PATH"
}


function add_rsyslog_conf {
	# location of logzio rsyslog template file
	local rsyslog_tmplate=$LOGZ_CONF_DIR/${FILE_CONTENT}-file.conf
	local path_hash=$(echo -n "$FILE_PATH" | md5sum | tr . '_' | tr - '_' | tr -d ' ')
	local rsyslog_conf_file=$RSYSLOG_CONF_DIR/${FILE_TAG}_${path_hash}.conf
	local rsyslog_tmp_file=${rsyslog_conf_file}.tmp

	execute cp -f $rsyslog_tmplate $rsyslog_tmp_file

	echo "[DEBUG]" "Log conf file template path: ${rsyslog_tmp_file}"

	execute sed -i "s|USER_TOKEN|${USER_TOKEN}|g" ${rsyslog_tmp_file}
	execute sed -i "s|LOGZ_SPOOL_DIR|${LOGZ_SPOOL_DIR}|g" ${rsyslog_tmp_file}
	execute sed -i "s|FILE_PATH|${FILE_PATH}|g" ${rsyslog_tmp_file}
	execute sed -i "s|FILE_TAG|${FILE_TAG}|g" ${rsyslog_tmp_file}
	execute sed -i "s|LISTENER_HOST|${LISTENER_HOST}|g" ${rsyslog_tmp_file}
	execute sed -i "s|LISTENER_PORT|${LISTENER_PORT}|g" ${rsyslog_tmp_file}
	execute sed -i "s|LISTENER_PROTOCOL|${LISTENER_PROTOCOL}|g" ${rsyslog_tmp_file}

	echo "[INFO]" "Adding rsyslog config at: ${rsyslog_conf_file}"
	execute mv ${rsyslog_tmp_file} ${rsyslog_conf_file}

	execute chmod o+w ${rsyslog_conf_file}
}


# ---------------------------------------- 
# restart rsyslog and reload configuration
# ---------------------------------------- 
function service_restart {
	echo "[INFO]" "Restarting the $RSYSLOG_SERVICE_NAME service."
	
	if [[ $(ps -A | grep /usr/sbin/rsyslogd | wc -l) -gt 1 ]]; then
		echo "[INFO] $RSYSLOG_SERVICE_NAME is Running, shutting down.."
		ps -A | grep /usr/sbin/rsyslogd | head -1 | awk '{print $1}' | xargs kill -9
	fi

	execute /usr/sbin/rsyslogd

	if [ $? -ne 0 ]; then
		echo "[WARNING]" "$RSYSLOG_SERVICE_NAME did not restart. Please try to restart $RSYSLOG_SERVICE_NAME manually."
	fi
}

function create_logz_dirs {
	execute mkdir -p $LOGZ_SHARED_DIR
	execute mkdir -p $LOGZ_SPOOL_DIR
}


# ---------------------------------------- 
# script arguments
# ----------------------------------------
if [[ $USER_TOKEN == "" ]] || [[ $FILE_PATH == "" ]] || [[ $FILE_TAG == "" ]]; then
	echo "[ERROR] One of the arguments are missing 'USER TOKEN', 'FILE PATH', 'FILE TYPE' "
	exit 1
fi

# ---------------------------------------- 
# run script
# ----------------------------------------
validate_file

create_logz_dirs

add_rsyslog_conf

service_restart

exit 0