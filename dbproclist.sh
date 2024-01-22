#!/bin/bash

# MySQL Connection Information
MYSQL_HOST="your_mysql_host"
MYSQL_PORT="your_mysql_port"
MYSQL_USER="your_mysql_user"
MYSQL_PASSWORD="your_mysql_password"

# MySQL Query
MYSQL_QUERY="show processlist;"

# Execute MySQL Query
#MYSQL_RESULT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "$MYSQL_QUERY")
MYSQL_RESULT=$(mysql -e "$MYSQL_QUERY")

# Check for errors
if [ $? -ne 0 ]; then
  echo "Error executing MySQL query."
  exit 1
fi

# Print processes with execution time greater than 500
#echo "$MYSQL_RESULT" | grep -v 'Binlog Dump' | grep -v 'Sleep' | grep -v 'Reading from net' | awk '$6 > 0 { print $0 }'
#echo "$MYSQL_RESULT" | grep -v 'Binlog Dump' | grep -v 'Sleep' | grep -v 'Reading from net' | awk '$6 > 0 { print $0 }' | sed '1d'
#echo "$MYSQL_RESULT" | grep -v 'Binlog Dump' | grep -v 'Sleep' | grep -v 'Reading from net' | sed '1d' | awk '$6 > 0 { print $0 }' | sed 's/$/<br>/'
proclist=$(echo "$MYSQL_RESULT" | grep -v 'Binlog Dump' | grep -vi 'close stmt' | grep -vi "unauthenticated" | grep -v "Waiting for master to send event" | grep -v "Reading from net" | grep -v 'Sleep' | sed '1d' | awk '$6 > 100 { print $0 }' | sed 's/\(.*\)\.ap-southeast-2\.compute\.internal/\1/' | sed 's/$/<br>/')
#echo "$MYSQL_RESULT" | grep -v 'Sleep' | sed '1d' | awk '$6 > 0 { print $0 }' | sed 's/$/<br>/'
if [ "$proclist" = "" ]; then
        THRESHOLD=100
        process_count=$(echo "$MYSQL_RESULT" | grep -c "^[[:space:]]*[0-9]")
        if [ "$process_count" -gt "$THRESHOLD" ]; then
                echo "Too many mysql process($process_count)"
        else
                echo "Mysql process list are good"
        fi
else
        echo $proclist
fi
