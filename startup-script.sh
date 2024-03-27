#!/bin/bash

FILE_PATH="/etc/environment"

# Export env variables only when file doesn't exist
if [[ ! -e $FILE_PATH || ! -s $FILE_PATH ]]; then
    echo "MYSQL_HOST=${mysql_host}" | sudo tee -a /etc/environment
    echo "MYSQL_USER=${mysql_user}" | sudo tee -a /etc/environment
    echo "MYSQL_PASSWORD=${mysql_password}" | sudo tee -a /etc/environment
    echo "MYSQL_DB=${mysql_db}" | sudo tee -a /etc/environment
    echo "LOG_FILE=${log_file}" | sudo tee -a /etc/environment
    echo "GCP_PROJECT_ID=${gcp_project_id}" | sudo tee -a /etc/environment
    echo "PUBSUB_TOPIC_ID=${gcp_pubsub_topic_id}" | sudo tee -a /etc/environment
fi

sudo touch /var/log/start_up_executed
