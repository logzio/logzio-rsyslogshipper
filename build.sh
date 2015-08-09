#!/bin/bash

export TAG="logzio/logzio-rsyslogshipper:latest"

docker build -t $TAG ./

echo "Built: $TAG"
