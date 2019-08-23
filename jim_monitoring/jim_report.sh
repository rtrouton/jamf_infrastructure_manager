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
