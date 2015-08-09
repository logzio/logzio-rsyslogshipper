#!/bin/bash

#export TAG="registry.internal.logz.io:5000/logzio-rsyslog-shipper:latest"
export TAG="logzio/logzio-rsyslogshipper:latest"

docker build -t $TAG ./

echo "Built: $TAG"