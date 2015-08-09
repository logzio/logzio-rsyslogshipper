#!/usr/bin/python

import json
import subprocess
from subprocess import Popen
import os.path
import sys

if 'MONITOR_CONF_FILE_PATH' in os.environ:
    print "found MONITOR_CONF_FILE_PATH env var"
else:
    print "MONITOR_CONF_FILE_PATH env var is missing"
    sys.exit()

PATH=os.environ['MONITOR_CONF_FILE_PATH']

if os.path.isfile(PATH) and os.access(PATH, os.R_OK):
    print "Conf file exists and is readable"
else:
    print "Conf file either is missing or is not readable"
    sys.exit()

with open("test.json") as json_file:
    json_data = json.load(json_file)


for i in json_data['files']:
    if 'path' in i:
        path = i['path']
    else:
        print "In valid conf: missing path to file"

    if 'tag' in i:
        tag = i['tag']
    else:
        print "In valid conf: missing tag of file"

    if 'codec' in i:
        codec = i['codec']
    else:
        codec = ""

    if 'protocol' in i:
        protocol = i['protocol']
    else:
        protocol = ""

    print "calling to script with params... path:", path, "tag:", tag, "codec:", codec, "protocol:", protocol
    Popen('./configure_rsyslog.bash %s %s' % (str(path),str(tag),), shell=True)

