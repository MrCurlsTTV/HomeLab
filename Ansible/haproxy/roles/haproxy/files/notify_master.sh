#!/bin/bash

# This script is executed when the node becomes the MASTER

# Log the event
logger -t keepalived "Node became MASTER"

# Check if HAProxy is running
if ! systemctl is-active --quiet haproxy; then
    logger -t keepalived "HAProxy is not running on master, starting it"
    systemctl start haproxy
fi

# Optionally send notification
# mail -s "HAProxy: Node $(hostname) became MASTER" admin@example.com < /dev/null

exit 0 