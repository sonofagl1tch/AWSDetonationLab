#!/bin/bash
#https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-create-and-update-a-trail-by-using-the-aws-cli.html
#
#The create-subscription command creates a trail. You can also use this command to create an Amazon S3 bucket for log file delivery and an Amazon SNS topic for notifications. The create-subscription command also starts logging for the trail that it creates.

aws cloudtrail create-subscription --name=awsdetonatonlab-trail --s3-new-bucket=aws-detonatonlab-1234567890 --s3-prefix=detonation-lab --sns-new-topic=awscloudtrail-detonatonlab-log-deliverytopic
