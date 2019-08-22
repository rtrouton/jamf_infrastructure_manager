#!/bin/bash

# Create scripts to monitor and report on a Jamf Infrastructure Manager (JIM).
# You will need to define the following variables in the scripts being installed:
#
# jim_log_lines (currently set to 60)
# jim_port (currently set to 8636)
# slack_webhook (currently set to nothing)

# Create /usr/local/bin if it doesn't exist

if [[ ! -d  /usr/local/bin ]]; then
    /usr/bin/mkdir -p /usr/local/bin
fi


# Write jim_check and jim_report scripts into /usr/local/bin

cat > /usr/local/bin/jim_check.sh << 'JIMCheck'
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
JIMCheck

cat > /usr/local/bin/jim_report.sh << 'JIMReport'
#!/bin/bash

# This script will send a specified number of the last lines
# of /var/log/jamf-im.log. To set the number of lines, use the
# jim_log_lines variable below.
#
# For example, setting the jim_log_lines as shown below will send
# the last 60 lines of the log:
#
# jim_log_lines=60

jim_log_lines=60

# Set the port number that the Jamf Infrastructure Manager is using
# to communicate with the Jamf Pro server.

jim_port=8636

# You'll need to set up a Slack webhook to receive the information being sent by the script. 
# If you need help with configuring a Slack webhook, please see the links below:
#
# https://api.slack.com/incoming-webhooks
# https://get.slack.help/hc/en-us/articles/115005265063-Incoming-WebHooks-for-Slack
#
# Once a Slack webhook is available, the slack_webhook variable should look similar
# to this:
# slack_webhook="https://hooks.slack.com/services/XXXXXXXXX/YYYYYYYYY/ZZZZZZZZZZ" 

slack_webhook=""

# That should be it for the necessary configuration part. The rest can be pretty much as-is
# if your Jamf Infrastructure Manager is running on Linux.

name=$(hostname)
logs="/tmp/JIM-restart.txt"
ipaddress=$(ifconfig eth0 | grep "inet" | awk '{print $2}' | head -1)

# Set script exit status

exit_error=0

# Function for sending multi-line output to a Slack webhook. Original script from here:
# 
# http://blog.getpostman.com/2015/12/23/stream-any-log-file-to-slack-using-curl/

SendToSlack(){

cat "$1" | while read LINE; do
  (echo "$LINE" | grep -e "$3") && curl -X POST --silent --data-urlencode "payload={\"text\": \"$(echo $LINE | sed "s/\"/'/g")\"}" "$2";
done

}

# Give an introduction.
echo "-----------------------------------------------------------------------" >> $logs
echo "----- Hi. You are receiving this because the"  >> $logs
echo "----- Jamf Infrastructure Manager restarted."  >> $logs
echo "----- Report is for $name ($ipaddress). " >> $logs
echo "-----------------------------------------------------------------------" >> $logs
echo " " >> $logs
echo " " >> $logs

# This reports on the JIM process after the restart.
echo "REPORT ON JIM PROCESS" >> $logs
echo "--------------------------------" >> $logs
echo "PROCESS ID:" >> $logs
processcheck=$(ps aux | grep '[j]amf-im')
echo "$processcheck" >> $logs
echo " " >> $logs
echo "NETSTAT LISTENING CHECK:" >> $logs
listencheck=$(netstat --listening --numeric-ports | grep "$jim_port")
echo "$listencheck" >> $logs
echo " " >> $logs
echo " " >> $logs

# This tails /var/log/jamf-im.log and hopefully catches the problem.
echo "LAST $jim_log_lines LINES OF THE JAMF-IM LOG" >> $logs
echo "--------------------------------" >> $logs
tail -"$jim_log_lines" /var/log/jamf-im.log  >> $logs
echo " " >> $logs
echo " " >> $logs

SendToSlack "$logs" ${slack_webhook}

# Get rid of the files.
rm "$logs"

exit "$exit_error"
JIMReport

# Set correct permissions on the jim_check
# and jim_report scripts

/bin/chmod 755 /usr/local/bin/jim_check.sh
/bin/chmod 755 /usr/local/bin/jim_report.sh

# Create root crontab entry to run database backup

# Export existing crontab

temp_crontab=/tmp/crontab_export

/bin/crontab -l > "$temp_crontab"

# Export new crontab entry to exported crontab file
/bin/echo "## Check JIM service every ten minutes to make sure it's running and restart it if it isn't." >> "$temp_crontab"
/bin/echo "*/10 * * * * /usr/local/bin/jim_check.sh 2>&1" >> "$temp_crontab"

# Install new cron file using exported crontab file

/bin/crontab "$temp_crontab"

# Remove exported crontab file

/bin/rm "$temp_crontab"