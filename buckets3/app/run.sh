#!/usr/bin/env bashio

CRON_TASK=$(bashio::config 'schedule')
BACKUP_AT_START=$(bashio::config 'run_backup_at_startup')
cronjob2=""

# run app immediately if first run detected
if [ "$BACKUP_AT_START" == "true" ]; then
  cronjob2="@reboot /usr/bin/bashio /usr/src/app/main.sh > /proc/1/fd/1 2>/proc/1/fd/2"
fi

# apply cron schedule to crontab file
bashio::log.info "Using cron schedule: $CRON_TASK"
rm /etc/crontabs/root
cronjob="$CRON_TASK /usr/bin/bashio /usr/src/app/main.sh > /proc/1/fd/1 2>/proc/1/fd/2"
echo -e "$cronjob\n$cronjob2\n" >>/etc/crontabs/root

# start crond with log level 8 in foreground, output to stderr
crond -f -d 8
