#!/bin/bash
#These are the changes required to the wazuh server configuration to allow for the ingestion of cloudTrail logs
# this script assumes that you already setup cloudTrail and are sending logs to the s3 bucket "aws-detonatonlab-1234567890"
# https://documentation.wazuh.com/current/amazon/installation.html#create-an-iam-user

#https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create.html
#policy name: Access-s3-cloudTrail-wazuh
cat <<EOF > Access-s3-cloudTrail-wazuh.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::aws-detonatonlab-1234567890",
                "arn:aws:s3:::aws-detonatonlab-1234567890/*"
            ]
        }
    ]
}
EOF
#create wazuh access policy to cloudTrail
##https://docs.aws.amazon.com/cli/latest/reference/iam/create-policy.html
aws iam create-policy --policy-name Access-s3-cloudTrail-wazuh --policy-document Access-s3-cloudTrail-wazuh.json


#Create an IAM User
#user name: wazuh-user
aws iam create-user --user-name wazuh-user
aws iam create-access-key --user-name wazuh-user

#attach policy to user
aws iam attach-user-policy --policy-arn arn:aws:iam::1234567890:policy/wazuh-read-cloudTrail --user-name wazuh-user