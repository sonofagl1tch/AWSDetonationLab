#!/bin/bash
#create s3 bucket
#https://docs.aws.amazon.com/cli/latest/reference/s3api/create-bucket.html
#
#replace the strings in this array with the names of the s3 buckets you want to create for this
buckets=(cloudTrail macie vpcflow route53 guardDuty)

#if bucket exists just create subscription, if not, also create bucket
for S3_BUCKET in ${buckets[*]}
do
  if aws s3 ls "s3://$S3_BUCKET" 2>&1 | grep -q 'NoSuchBucket'
  then
    echo "bucket exists already"
  else
    aws s3api create-bucket --bucket $S3_BUCKET --region us-east-1
done