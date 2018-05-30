# AWS Detonation Lab
These scripts can be used as proof-of-concept to generate a detonation lab via a cloudformation template. There are also scripts for a adding wazuh agents to the target systems as well as scripts to generate attacks on them that will be seen by AWS logging systems such as guardDuty, VPC flow, Route53 DNS, Macie, CloudTrail, and other systems. All of these logs can be configured to send to the kibana instance running on the wazuh server for usage in threat hunting and incident investigation and response.

This cloudformation template is and guard duty alert generation scripts are based on  [guardduty-tester.template](https://github.com/awslabs/amazon-guardduty-tester/blob/master/guardduty-tester.template) uses AWS CloudFormation to create an isolated environment with a bastion host, a redTeam EC2 instance that you can ssh into, and two target EC2 instances. 

Then you can run [guardduty_tester.sh](https://github.com/awslabs/amazon-guardduty-tester/blob/master/guardduty_tester.sh) that starts interaction between the redTeam EC2 instance and the target Windows EC2 instance and the target Linux EC2 instance to simulate five types of common attacks that GuardDuty is built to detect and notify you about with generated findings. 

## Prerequisites

1. You must enable GuardDuty in the same account and region where you want to run the Amazon GuardDuty Tester script. For more information about enabling GuardDuty, see https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html#guardduty_enable-gd.

2. You must generate a new or use an existing EC2 key pair in each region where you want to run these scripts. This EC2 keypair is used as a parameter in the guardduty-tester.template script that you use in Step 1 to create a new CloudFormation stack. For more information about generating EC2 key pairs, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html.


# getting started
This process will walk you through getting the core detonation lab automatically configured and additional processes for setting up each item


## create detonation lab

1. Create a new CloudFormation stack using awsDetonationLab.template at https://console.aws.amazon.com/cloudformation
   1. For detailed directions about creating a stack, see https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html.
2. Before you run awsDetonationLab.template , modify it with values for the following parameters: Stack Name to identify your new stack, Availability Zone where you want to run the stack, and Key Pair that you can use to launch the EC2 instances. Then you can use the corresponding private key to SSH into the EC2 instances.
   1. awsDetonationLab.template takes around 10 minutes to run and complete. It creates your environment and copies guardduty_tester.sh onto your redTeam EC2 instance.
3. Click the checkbox next to your running CloudFormation stack created in the step above. In the displayed set of tabs, select the Output tab. Note the IP addresses assigned to the bastion host and the redTeam EC2 instance. You need both of these IP addresses in order to ssh into the redTeam EC2 instance.

4. Create the following entry in your ~/.ssh/config file to login to your instance through the bastion host:</br>
```
Host bastion
    HostName <EXTERNAL IP FOR BASTION HOST>
    User ec2-user
    IdentityFile <SSH KEY>
Host redTeam
    ForwardAgent yes
    HostName 172.16.0.20
    User ec2-user
    IdentityFile ~/.ssh/<SSH KEY>
    ProxyCommand ssh bastion nc %h %p
    ServerAliveInterval 240
Host wazuh
    ForwardAgent yes
    HostName 172.16.0.21
    User ec2-user
    IdentityFile ~/.ssh/<SSH KEY>
    ProxyCommand ssh bastion nc %h %p
    ServerAliveInterval 240
Host linuxClient
    ForwardAgent yes
    HostName 172.16.0.22
    User ec2-user
    IdentityFile ~/.ssh/<SSH KEY>
    ProxyCommand ssh bastion nc %h %p
    ServerAliveInterval 240
Host windows
    ForwardAgent yes
    HostName 172.16.0.23
    User Administrator
    IdentityFile ~/.ssh/<SSH KEY>
    ProxyCommand ssh bastion nc %h %p
    ServerAliveInterval 240
```

For more details on configuring and connecting through bastion hosts you can check out this article:
https://aws.amazon.com/blogs/security/securely-connect-to-linux-instances-running-in-a-private-amazon-vpc/
5. setup RoyalTSX or other preferred client to use the bastion host as a secure gateway to tunnel RDP through SSH
   1. Example RoyalTSX required elemenets 
   ![Example RoyalTSX required elemenets](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/RoyalTSX-Config/1-RoyalTSX-requiredDocument.png "1-RoyalTSX-requiredDocument")
   2. RDP connection Settings 
   ![RDP connection Settings](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/RoyalTSX-Config/2-RDP-connnectionSettings.png "2-RDP-connnectionSettings")
   3. RDP credentials 
   ![RDP credentials](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/RoyalTSX-Config/3-RDP-credentials.png "3-RDP-credentials")
   4. RDP secure gateway 
   ![RDP secure gateway](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/RoyalTSX-Config/4-RDP-secureGateway.png "4-RDP-secureGateway")
   5. bastion credentials 
   ![bastion credentials](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/RoyalTSX-Config/5-bastion-%20credential.png "5-bastion-%20credential")
   6. bastion key 
   ![bastion key](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/RoyalTSX-Config/6-bastion-key.png "6-bastion-key")
   7. secure gateway config 
   ![secure gateway config](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/RoyalTSX-Config/7-secureGateway-config.png "7-secureGateway-config")
   8. secure gateway credentials 
   ![secure gateway credentials](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/RoyalTSX-Config/8-secureGateway-credentials.png "8-secureGateway-credentials")
   


## run guardduty testing script
This will generate guardduty alerts. Once connected to the redTeam instance, there is a single script that you can run:
`$ ./guardduty_tester.sh` to initiate interaction between your redTeam and target EC2 instances, simulate attacks, and generate GuardDuty Findings.


# Setting up logging for detonation lab
This section will go over the steps required to enable logging for the detonation lab

## GuardDuty
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html#guardduty_enable-gd
### enable guardDuty
1. The IAM identity (user, role, group) that you use to enable GuardDuty must have the required permissions. To grant the permissions required to enable GuardDuty, attach the following policy to an IAM user, group, or role https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/awsPermissions/IAM-guardDuty-enablePermissions.json
   1. Replace the sample account ID in the example below with your actual AWS account ID.
2. Use the credentials of the IAM identity from step 1 to sign in to the GuardDuty console. When you open the GuardDuty console for the first time, choose Get Started, and then choose Enable GuardDuty.


# get logging into SIEM
TBD