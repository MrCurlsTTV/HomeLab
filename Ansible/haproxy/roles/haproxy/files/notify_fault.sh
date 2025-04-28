#!/bin/bash

# This script is executed when the node enters a FAULT state

# Log the event
logger -t keepalived "Node entered FAULT state"

# Try to restart HAProxy
logger -t keepalived "Attempting to restart HAProxy"
systemctl restart haproxy

# Optionally send notification
# mail -s "HAProxy: Node $(hostname) entered FAULT state" admin@example.com < /dev/null

exit 0 