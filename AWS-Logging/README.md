Before you do anything, you have to enable GuardDuty in the same account and region where you want to run the Amazon GuardDuty Tester script. What happens if you don't? Stuff will be broken. Do it now, go ahead, we'll wait. 

For more information about enabling GuardDuty, see the [GuardDuty Setup Guide](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html#guardduty_enable-gd).


# Enabling GuardDuty

1. The IAM identity (user, role, group) that you use to enable GuardDuty must have the required permissions. To grant the permissions required to enable GuardDuty, attach [this policy](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/awsPermissions/IAM-guardDuty-enablePermissions.json) to an IAM user, group, or role. 

2. Replace the sample account ID in the example below with your actual AWS account ID.

3. Use the credentials of the IAM identity from Step 1 to sign in to the GuardDuty console. When you open the GuardDuty console for the first time, choose **Get Started** and then choose **Enable GuardDuty**.

4. You must generate a new or use an existing EC2 key pair in each region where you want to run these scripts. This EC2 keypair is used as a parameter in the guardduty-tester.template script that you use in Step 1 to create a new CloudFormation stack. 

For more information about generating EC2 key pairs, see [this AWS document on key pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).

# Enabling CloudTrail
1. https://documentation.wazuh.com/current/amazon/index.html
  1. https://documentation.wazuh.com/current/amazon/use-cases/ec2.html
  2. https://documentation.wazuh.com/current/amazon/use-cases/vpc.html
  3. https://documentation.wazuh.com/current/amazon/use-cases/iam.html

# Enabling Macie

# Enabling VPC Flow

# Enabling Route53 DNS

# Enabling Route53 DNS