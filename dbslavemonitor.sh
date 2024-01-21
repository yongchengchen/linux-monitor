#!/bin/bash

# MySQL Connection Parameters
MYSQL_USER="your_mysql_user"
MYSQL_PASSWORD="your_mysql_password"
MYSQL_HOST="your_mysql_host"
MYSQL_PORT="your_mysql_port"

# Thresholds
MAX_SECONDS_BEHIND_MASTER=300

# MySQL query to get replication status
QUERY="SHOW SLAVE STATUS\G"

# Run MySQL query
#RESULT=$(mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" -e "${QUERY}")
RESULT=$(mysql -e "${QUERY}")

# Check if the query was successful
if [ $? -ne 0 ]; then
    echo "Error executing MySQL query. Check MySQL credentials and connectivity."
    exit 1
fi

# Check if there are errors in replication
ERRORS=$(echo "${RESULT}" | grep "Last_Errno:" | awk '{print $2}')
if [ "${ERRORS}" -ne 0 ]; then
    echo "Replication error detected. Last error code: ${ERRORS}"
    # Add your alerting mechanism here (e.g., send an email, call an API, etc.)
fi

# Check if slave is behind master
SECONDS_BEHIND_MASTER=$(echo "${RESULT}" | grep "Seconds_Behind_Master:" | awk '{print $2}')
if [ "${SECONDS_BEHIND_MASTER}" -gt "${MAX_SECONDS_BEHIND_MASTER}" ]; then
    echo "Slave is behind master by ${SECONDS_BEHIND_MASTER} seconds (threshold: ${MAX_SECONDS_BEHIND_MASTER} seconds)"
    # Add your alerting mechanism here (e.g., send an email, call an API, etc.)
fi

# If everything is fine, print OK
echo "Replication status is OK"

exit 0
