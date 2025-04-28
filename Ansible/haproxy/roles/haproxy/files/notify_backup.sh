#!/bin/bash

# This script is executed when the node becomes a BACKUP

# Log the event
logger -t keepalived "Node became BACKUP"

# HAProxy can remain running on the backup node as well,
# it just won't receive traffic since it doesn't have the VIP

# Optionally send notification
# mail -s "HAProxy: Node $(hostname) became BACKUP" admin@example.com < /dev/null

exit 0 