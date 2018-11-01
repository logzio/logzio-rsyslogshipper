logzio-rsyslogshipper
=========================

A lightweight Docker image that runs rsyslog to monitor a running host logs files and ship them over to [Logz.io](https://logz.io).

The image based on Alpine Linux distribution and have Rsyslog 8.9 installed

## Requirements
 - A valid [Logz.io](https://logz.io) customer authentication token 


## How to use this image

The following environment variables are available:

**LOGZIO_USER_TOKEN**

	A valid Logz.io customer authentication token. (required)


**LISTENER_HOST**

	The Logz.io listener address. (optional)


**MONITOR_FILE_TYPE**

	The log type that is being sent. This enables better parsing of your log data. (required)


**MONITOR_FILE_PATH**

	File path to monitor. The file path is **relative** to the mounted/mapped folder.
	If missing, the value will default to the mounted folder.
	The path can be to a single file or directory. wildcards are allowed only on the file name. 
	for more details please see Rsyslog documentation 

**SHARED_DIR**

    The path to use as the shared directory for logzio. This must be a **absolute** path.
    This path has the **MONITOR_FILE_PATH** variable appended to it when searching for logs.
    By default, this is `/var/log/logzio`.

**CODEC**

	The file content codec, currntly support text and json, Default to text.




##### Host file mapping

In order to ship a log file, it has to be mapped to the running container.
This is performed with the -v option

`-v <log file or directory to ship>:/var/log/logzio`
 
 
 
##### Run it

``` bash
docker run \
	-d \
	--name rsyslog-shipper \
	-v /PATH/TO/FOLDER:/var/log/logzio \
	-e LOGZIO_USER_TOKEN="USER_TOKEN" \
	-e LISTENER_HOST="LISTENER_ADDRESS" \
	-e MONITOR_FILE_PATH="PATH_TO_LOG_FILE" \
	-e MONITOR_FILE_TYPE="FILE_TYPE" \
	-e CODEC="FILE_CODEC" \
	logzio/logzio-rsyslog-shipper:latest
```


## Exemple

This example monitor all files under the mounted folder. 

All file are assumed to be plain text log files.  

``` bash
docker run \
	-d \
	--name rsyslog-shipper \
	-v /var/logs/apache2:/var/log/logzio \
	-e LOGZIO_USER_TOKEN="USER_TOKEN" \
	-e LISTENER_HOST="listener.logz.io" \
	-e MONITOR_FILE_TYPE="apache" \
	logzio/logzio-rsyslog-shipper:latest
```



This example monitor the myapp log files, The path to the files is **relative to the SHARED_DIR variable.**

All file are assumed to be a json log files.

``` bash
docker run \
	-d \
	--name rsyslog-shipper \
	-v /home/ubuntu/myapp:/var/log/logzio \
	-e LOGZIO_USER_TOKEN="USER_TOKEN" \
	-e LISTENER_HOST="listener-eu.logz.io" \
	-e MONITOR_FILE_PATH="logs/*.json" \
	-e MONITOR_FILE_TYPE="myapp" \
	-e CODEC="json" \
	logzio/logzio-rsyslog-shipper:latest
```

All files are within a different shared folder.

``` bash
docker run \
	-d \
	--name rsyslog-shipper \
	-v /home/ubuntu/myapp:/var/log/mylogs \
	-e LOGZIO_USER_TOKEN="USER_TOKEN" \
	-e LISTENER_HOST="listener-eu.logz.io" \
	-e MONITOR_FILE_PATH="logs/*.json" \
	-e MONITOR_FILE_TYPE="myapp" \
    -e SHARED_DIR="/var/log/mylogs" \
	-e CODEC="json" \
	logzio/logzio-rsyslog-shipper:latest
```

