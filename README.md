# AWS Detonation Lab
These scripts can be used as proof-of-concept to generate a detonation lab via a cloudformation template. There are also scripts for adding wazuh agents to the target systems as well as scripts to generate attacks on them that will be seen by AWS logging systems such as GuardDuty, VPC flow, Route53 DNS, Macie, CloudTrail, and other systems. 

All of these logs can be configured to send to the Kibana instance running on the Wazuh server for usage in threat hunting and incident investigation and response.

This cloudformation template and guard duty alert generation scripts are based on the [GuardDuty-Tester.template](https://github.com/awslabs/amazon-guardduty-tester/blob/master/guardduty-tester.template) uses AWS CloudFormation to create an isolated environment with a bastion host, a redTeam EC2 instance that you can ssh into, and two target EC2 instances. 

Then you can run [guardduty_tester.sh](https://github.com/awslabs/amazon-guardduty-tester/blob/master/guardduty_tester.sh) that starts interaction between the redTeam EC2 instance and the target Windows EC2 instance and the target Linux EC2 instance to simulate five types of common attacks that GuardDuty is built to detect and notify you about with generated findings.

For more information please refer to the [wiki](https://github.com/sonofagl1tch/AWSDetonationLab/wiki) 

## Thank you for your contributions
Special thanks to [Marta](https://github.com/mgmacias95) and [Danny](https://github.com/randoh) for their contributions to this project.

## Video presentations using this project 
[Who Done It: Gaining Visibility and Accountability in the Cloud](https://youtu.be/x4OJx2M52iI) - SANS Threat Hunting Summit 2018
