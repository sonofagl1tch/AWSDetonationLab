## AWS Detonation Lab

These scripts can be used as proof-of-concept to generate a detonation lab via a cloudformation template. There are also scripts for a adding wazuh agents to the target systems as well as scripts to generate attacks on them that will be seen by AWS logging systems such as guardDuty, VPC flow, Route53 DNS, Macie, CloudTrail, and other systems. All of these logs can be configured to send to the kibana instance running on the wazuh server for usage in threat hunting and incident investigation and response.

This cloudformation template is and guard duty alert generation scripts are based on  [guardduty-tester.template](https://github.com/awslabs/amazon-guardduty-tester/blob/master/guardduty-tester.template) uses AWS CloudFormation to create an isolated environment with a bastion host, a tester EC2 instance that you can ssh into, and two target EC2 instances. 

Then you can run [guardduty_tester.sh](https://github.com/awslabs/amazon-guardduty-tester/blob/master/guardduty_tester.sh) that starts interaction between the tester EC2 instance and the target Windows EC2 instance and the target Linux EC2 instance to simulate five types of common attacks that GuardDuty is built to detect and notify you about with generated findings. 

