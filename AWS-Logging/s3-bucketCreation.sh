#!/bin/bash
#create s3 bucket
#https://docs.aws.amazon.com/cli/latest/reference/s3api/create-bucket.html
#
S3_BUCKET="aws-detonatonlab-1234567890"

#if bucket exists just create subscription, if not, also create bucket
if aws s3 ls "s3://$S3_BUCKET" 2>&1 | grep -q 'NoSuchBucket'
then
  echo "bucket exists already"
else
  aws s3api create-bucket --bucket $S3_BUCKET --region us-east-1
