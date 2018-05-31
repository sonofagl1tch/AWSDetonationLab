# AWS Detonation Lab
These scripts can be used as proof-of-concept to generate a detonation lab via a cloudformation template. There are also scripts for a adding wazuh agents to the target systems as well as scripts to generate attacks on them that will be seen by AWS logging systems such as GuardDuty, VPC flow, Route53 DNS, Macie, CloudTrail, and other systems. 

All of these logs can be configured to send to the Kibana instance running on the Wazuh server for usage in threat hunting and incident investigation and response.

This cloudformation template and guard duty alert generation scripts are based on the [GuardDuty-Tester.template](https://github.com/awslabs/amazon-guardduty-tester/blob/master/guardduty-tester.template) uses AWS CloudFormation to create an isolated environment with a bastion host, a redTeam EC2 instance that you can ssh into, and two target EC2 instances. 

Then you can run [guardduty_tester.sh](https://github.com/awslabs/amazon-guardduty-tester/blob/master/guardduty_tester.sh) that starts interaction between the redTeam EC2 instance and the target Windows EC2 instance and the target Linux EC2 instance to simulate five types of common attacks that GuardDuty is built to detect and notify you about with generated findings.

# Getting Started

This process will walk you through getting the core detonation lab automatically configured and additional processes for setting up each item

## Prerequisites

Before you do anything, you have to enable GuardDuty in the same account and region where you want to run the Amazon GuardDuty Tester script. What happens if you don't? Stuff will be broken. Do it now, go ahead, we'll wait. 

For more information about enabling GuardDuty, see the [GuardDuty Setup Guide](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html#guardduty_enable-gd).


### Enabling GuardDuty

1. The IAM identity (user, role, group) that you use to enable GuardDuty must have the required permissions. To grant the permissions required to enable GuardDuty, attach [this policy](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/awsPermissions/IAM-guardDuty-enablePermissions.json) to an IAM user, group, or role. 

2. Replace the sample account ID in the example below with your actual AWS account ID.

3. Use the credentials of the IAM identity from Step 1 to sign in to the GuardDuty console. When you open the GuardDuty console for the first time, choose **Get Started** and then choose **Enable GuardDuty**.

4. You must generate a new or use an existing EC2 key pair in each region where you want to run these scripts. This EC2 keypair is used as a parameter in the guardduty-tester.template script that you use in Step 1 to create a new CloudFormation stack. 

For more information about generating EC2 key pairs, see [this AWS document on key pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).


## Create Your Detonation Lab

1. Create a new CloudFormation stack 
  * Upload our **awsDetonationLab.template** file during the Stack Setup on the [CloudFormation console](https://console.aws.amazon.com/cloudformation)
  
  * **NOTE:** If the upload fails for some reason, copy/paste the contents into a text editor like SublimeText, Save As **awsDetonationLab.template** and try again.

  * Before you run **awsDetonationLab.template** you need to modify it with values for the following parameters: 
      * Stack Name to identify your new stack.
      * Availability Zone where you want to run the stack.
      * Key Pair that you can use to launch the EC2 instances. Then you can use the corresponding private key to SSH into the EC2 instances.
  
  * This step takes around **10 minutes** to complete.
  
  * It creates your environment and copies **guardduty_tester.sh** onto your redTeam EC2 instance.
  
  * For detailed directions about creating a stack, see the [Create Stack guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html).

*INSERT SCREEN SHOT OF EC2 CONSOLE SHOWING ALL THE NEW INSTANCES*

5. After the build has completed, click the checkbox next to your running CloudFormation stack created in the step above. In the displayed set of tabs,
  * Select the **Output** tab.
  * Note the IP addresses assigned to the **bastion host** and the **redTeam EC2 instance**. 
  * You need both of these IP addresses in order to ssh into the redTeam EC2 instance.

6. Create an ssh config file to accessing servers. **The config file isn't created automatically, you may not have one, so make one.** Create the following entry in your ~/.ssh/config file to login to your instance through the bastion host:</br>

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

For more details on configuring and connecting through bastion hosts you can check out [this article](https://aws.amazon.com/blogs/security/securely-connect-to-linux-instances-running-in-a-private-amazon-vpc/).

Setup RoyalTSX or your preferred client to use the bastion host as a secure gateway to tunnel RDP through SSH. 

Select **File > New Document**

Right Click your folder **Add > Credential > Credential**

 * **Bastion Credentials**
   ![bastion credentials](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/RoyalTSX-Config/5-bastion-%20credential.png "5-bastion-%20credential")
   
   In that same window, click **Private Key File**
   
   * **Bastion Key**
   ![bastion key](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/RoyalTSX-Config/6-bastion-key.png "6-bastion-key")
   
   Back to your folder, **Right Click > Add > Secure Gateway**
   
   * **Secure Gateway Config**
   ![secure gateway config](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/RoyalTSX-Config/7-secureGateway-config.png "7-secureGateway-config")
   
   In that same window, click **Credentials
   
   * **Secure Gateway Credentials**
   ![secure gateway credentials](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/RoyalTSX-Config/8-secureGateway-credentials.png "8-secureGateway-credentials")
   
   Back out to your folder, **Right Click > Add > RDP Session**

   * **RDP connection Settings** 
   ![RDP connection Settings](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/RoyalTSX-Config/2-RDP-connnectionSettings.png "2-RDP-connnectionSettings")
   
   * **RDP Credentials**
   ![RDP credentials](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/RoyalTSX-Config/3-RDP-credentials.png "3-RDP-credentials")
   
   * **RDP Secure Gateway**
   ![RDP secure gateway](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/RoyalTSX-Config/4-RDP-secureGateway.png "4-RDP-secureGateway")
   
  
   
   When you're done, your Connections list should look like this. 
   
    **Example RoyalTSX required elemenets**
   ![Example RoyalTSX required elemenets](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/RoyalTSX-Config/1-RoyalTSX-requiredDocument.png "1-RoyalTSX-requiredDocument")


## Connect To redTeam Instance & Run GuardDuty Testing Script

To connect to your redTeam instance, through your Bastion host, from a command prompt (this is where the **/.ssh/config** file you created back in Step 3 comes into play).

`$ ssh redTeam`

Once connected to the redTeam instance, there is a single script that you can run that will generate GuardDuty alerts:

`$ ./guardduty_tester.sh` 

This will initiate interaction between your redTeam and target EC2 instances, simulate attacks, and generate GuardDuty Findings.

![GuardDutyFindings Example](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/guardDutyFindings-example.png "guardDutyFindings-example")


# Setup Logging for Detonation Lab.
This section will go over the steps required to enable logging for the detonation lab. To Be Completed.

# Getting Logs Into SIEM.
This section will go over the steps required to enable logging into SIEM. To Be Completed.