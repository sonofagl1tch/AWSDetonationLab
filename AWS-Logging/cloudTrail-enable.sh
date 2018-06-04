#!/bin/bash
#https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-create-and-update-a-trail-by-using-the-aws-cli.html
#
#The create-subscription command creates a trail. You can also use this command to create an Amazon S3 bucket for log file delivery and an Amazon SNS topic for notifications. The create-subscription command also starts logging for the trail that it creates.

S3_BUCKET="aws-detonatonlab-1234567890"

#if bucket exists just create subscription, if not, also create bucket
if aws s3 ls "s3://$S3_BUCKET" 2>&1 | grep -q 'NoSuchBucket'
then
  aws cloudtrail create-subscription --name=awsdetonatonlab-trail --s3-prefix=detonation-lab --sns-new-topic=awscloudtrail-detonatonlab-log-deliverytopic
else
  aws cloudtrail create-subscription --name=awsdetonatonlab-trail --s3-new-bucket=$S3_BUCKET --s3-prefix=detonation-lab --sns-new-topic=awscloudtrail-detonatonlab-log-deliverytopic