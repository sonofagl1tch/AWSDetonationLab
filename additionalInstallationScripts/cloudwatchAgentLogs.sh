#!/bin/bash
#this script will install the cloudwatch agent, create a cloudwatch log group for the agent to write to and start the logging

#create cloudwatch log group, IAM role, and IAM policy
#this is done in the cloudformation template

#Update your Amazon Linux instance to pick up the latest changes in the package repositories.
sudo yum update -y -q -e 0

#Install the awslogs package. This is the recommended method for installing awslogs on Amazon Linux instances.
sudo yum install awslogs -y -q -e 0

#Start the awslogs service.
sudo systemctl start awslogsd

#Run the following command to start the awslogs service at each system boot.
sudo systemctl enable awslogsd.service

#configure logging agent
cat > /etc/awslogs/awslogs.conf << EOF
#
# ------------------------------------------
# CLOUDWATCH LOGS AGENT CONFIGURATION FILE
# ------------------------------------------
#
# --- DESCRIPTION ---
#
# NOTE: A running agent must be stopped and restarted for configuration changes to take effect.
#
# --- CLOUDWATCH LOGS DOCUMENTATION ---
# https://aws.amazon.com/documentation/cloudwatch/
#
# --- CLOUDWATCH LOGS CONSOLE ---
# --- AGENT COMMANDS ---
# To check or change the running status of the CloudWatch Logs Agent, use the following:
#
# To check running status: service awslogs status
# To stop the agent: service awslogs stop
# To start the agent: service awslogs start
# To start the agent on server startup: chkconfig awslogs on
#
# --- AGENT LOG OUTPUT ---
# You can find logs for the agent in /var/log/awslogs.log
#

# ------------------------------------------
# CONFIGURATION DETAILS
# ------------------------------------------

[general]
# Path to the CloudWatch Logs agent's state file. The agent uses this file to maintain
# client side state across its executions.
state_file = /var/lib/awslogs/agent-state

## Each log file is defined in its own section. The section name doesn't
## matter as long as its unique within this file.
#[kern.log]
#
## Path of log file for the agent to monitor and upload.
#file = /var/log/kern.log
#
## Name of the destination log group.
#log_group_name = kern.log
#log_stream_name = {instance_id} # Defaults to ec2 instance id
#
## Format specifier for timestamp parsing. Here are some sample formats:
## Use '%b %d %H:%M:%S' for syslog (Apr 24 08:38:42)
## Use '%d/%b/%Y:%H:%M:%S' for apache log (10/Oct/2000:13:55:36)
## Use '%Y-%m-%d %H:%M:%S' for rails log (2008-09-08 11:52:54)
#datetime_format = %b %d %H:%M:%S # Specification details in the table below.
#
## A batch is buffered for buffer-duration amount of time or 32KB of log events.
## Defaults to 5000 ms and its minimum value is 5000 ms.
#buffer_duration = 5000
#
# Use 'end_of_file' to start reading from the end of the file.
# Use 'start_of_file' to start reading from the beginning of the file.
#initial_position = start_of_file
#
## Encoding of file
#encoding = utf-8 # Other supported encodings include: ascii, latin-1
#
#
#
# Following table documents the detailed datetime format specification:
# ----------------------------------------------------------------------------------------------------------------------
# Directive     Meaning                                                                                 Example
# ----------------------------------------------------------------------------------------------------------------------
# %a            Weekday as locale's abbreviated name.                                                   Sun, Mon, ..., Sat (en_US)
# ----------------------------------------------------------------------------------------------------------------------
#  %A           Weekday as locale's full name.                                                          Sunday, Monday, ..., Saturday (en_US)
# ----------------------------------------------------------------------------------------------------------------------
#  %w           Weekday as a decimal number, where 0 is Sunday and 6 is Saturday.                       0, 1, ..., 6
# ----------------------------------------------------------------------------------------------------------------------
#  %d           Day of the month as a zero-padded decimal numbers.                                      01, 02, ..., 31
# ----------------------------------------------------------------------------------------------------------------------
#  %b           Month as locale's abbreviated name.                                                     Jan, Feb, ..., Dec (en_US)
# ----------------------------------------------------------------------------------------------------------------------
#  %B           Month as locale's full name.                                                            January, February, ..., December (en_US)
# ----------------------------------------------------------------------------------------------------------------------
#  %m           Month as a zero-padded decimal number.                                                  01, 02, ..., 12
# ----------------------------------------------------------------------------------------------------------------------
#  %y           Year without century as a zero-padded decimal number.                                   00, 01, ..., 99
# ----------------------------------------------------------------------------------------------------------------------
#  %Y           Year with century as a decimal number.                                                  1970, 1988, 2001, 2013
# ----------------------------------------------------------------------------------------------------------------------
#  %H           Hour (24-hour clock) as a zero-padded decimal number.                                   00, 01, ..., 23
# ----------------------------------------------------------------------------------------------------------------------
#  %I           Hour (12-hour clock) as a zero-padded decimal numbers.                                  01, 02, ..., 12
# ----------------------------------------------------------------------------------------------------------------------
#  %p           Locale's equivalent of either AM or PM.                                                 AM, PM (en_US)
# ----------------------------------------------------------------------------------------------------------------------
#  %M           Minute as a zero-padded decimal number.                                                 00, 01, ..., 59
# ----------------------------------------------------------------------------------------------------------------------
#  %S           Second as a zero-padded decimal numbers.                                                00, 01, ..., 59
# ----------------------------------------------------------------------------------------------------------------------
#  %f           Microsecond as a decimal number, zero-padded on the left.                               000000, 000001, ..., 999999
# ----------------------------------------------------------------------------------------------------------------------
#  %z           UTC offset in the form +HHMM or -HHMM (empty string if the the object is naive).        (empty), +0000, -0400, +1030
# ----------------------------------------------------------------------------------------------------------------------
#  %j           Day of the year as a zero-padded decimal number.                                        001, 002, ..., 365
# ----------------------------------------------------------------------------------------------------------------------
#  %U           Week number of the year (Sunday as the first day of the week) as a zero padded          00, 01, ..., 53
#               decimal number. All days in a new year preceding the first Sunday are considered
#               to be in week 0.
# ----------------------------------------------------------------------------------------------------------------------
#  %W           Week number of the year (Monday as the first day of the week) as a decimal number.      00, 01, ..., 53
#               All days in a new year preceding the first Monday are considered to be in week 0.
# ----------------------------------------------------------------------------------------------------------------------
#  %c           Locale's appropriate date and time representation.                                      Tue Aug 16 21:30:00 1988 (en_US)
# ----------------------------------------------------------------------------------------------------------------------


[/var/log/messages]
datetime_format = %b %d %H:%M:%S
file = /var/log/messages
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/auth.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/auth.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/secure]
datetime_format = %b %d %H:%M:%S
file = /var/log/secure
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/boot.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/boot.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/dmesg]
datetime_format = %b %d %H:%M:%S
file = /var/log/dmesg
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/kern.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/kern.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/faillog]
datetime_format = %b %d %H:%M:%S
file = /var/log/faillog
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/cron]
datetime_format = %b %d %H:%M:%S
file = /var/log/cron
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/yum.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/yum.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/maillog]
datetime_format = %b %d %H:%M:%S
file = /var/log/maillog
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/mail.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/mail.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/httpd]
datetime_format = %b %d %H:%M:%S
file = /var/log/httpd
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/mysqld.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/mysqld.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/mysql.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/mysql.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/btmp]
datetime_format = %b %d %H:%M:%S
file = /var/log/btmp
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/auth.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/auth.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/daemon.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/daemon.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/lastlog]
datetime_format = %b %d %H:%M:%S
file = /var/log/lastlog
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/user.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/user.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/wtmp]
datetime_format = %b %d %H:%M:%S
file = /var/log/wtmp
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/utmp]
datetime_format = %b %d %H:%M:%S
file = /var/log/utmp
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/audit]
datetime_format = %b %d %H:%M:%S
file = /var/log/audit
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux

[/var/log/sssd]
datetime_format = %b %d %H:%M:%S
file = /var/log/sssd
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = detonationLab-linux
EOF


#restart cloudwatch agent
sudo systemctl restart awslogsd