The `jim_check.sh` script monitors the Jamf Infrastructure Manager (JIM) by checking to see if the port used by the JIM is active on localhost. If not, JIM is stopped and started and then `jim_report.sh` sends an report to a Slack channel.

Scripts available in this repo:

* `jim_check.sh` - monitors the JIM and restarts it if needed.
* `jim_report.sh` - sends a report to a designated Slack channel
* `install_jim_check_scripts_and_crontab.sh` - installs `jim_check.sh` and `jim_report.sh` into `/usr/local/bin` and sets up a crontab entry to execute the `jim_check.sh` script every ten minmutes.