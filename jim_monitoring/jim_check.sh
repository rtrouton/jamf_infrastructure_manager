#!/bin/bash

# Automatically restart the Jamf Infrastructure Manager (JIM) if it stops running

jim_port=8636

# Verify if the JIM is running  on the assigned port.

listencheck=$(/bin/netstat -ln | /bin/grep ":$jim_port " | /usr/bin/wc -l)

# If the listencheck returns 0, then the JIM process is not running on its assigned port.
# Stop the process then restart the process and send a report via email.

if [[ "$listencheck" == 0 ]]; then
    # Stop the JIM processes

    service jamf-im stop

    # Wait 5 seconds for JIM process to fully stop

    sleep 5

    # Start the JIM processes

    service jamf-im start

    # Pause for 10 seconds to allow the JIM process to start.
    sleep 10
    /usr/local/bin/jim_report.sh
fi