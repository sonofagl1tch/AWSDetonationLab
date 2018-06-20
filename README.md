# AWS Detonation Lab
These scripts can be used as proof-of-concept to generate a detonation lab via a cloudformation template. There are also scripts for a adding wazuh agents to the target systems as well as scripts to generate attacks on them that will be seen by AWS logging systems such as GuardDuty, VPC flow, Route53 DNS, Macie, CloudTrail, and other systems. 

All of these logs can be configured to send to the Kibana instance running on the Wazuh server for usage in threat hunting and incident investigation and response.

This cloudformation template and guard duty alert generation scripts are based on the [GuardDuty-Tester.template](https://github.com/awslabs/amazon-guardduty-tester/blob/master/guardduty-tester.template) uses AWS CloudFormation to create an isolated environment with a bastion host, a redTeam EC2 instance that you can ssh into, and two target EC2 instances. 

Then you can run [guardduty_tester.sh](https://github.com/awslabs/amazon-guardduty-tester/blob/master/guardduty_tester.sh) that starts interaction between the redTeam EC2 instance and the target Windows EC2 instance and the target Linux EC2 instance to simulate five types of common attacks that GuardDuty is built to detect and notify you about with generated findings.

# todo List (AKA things i still need to automate)
- add additional sources to kibana
  - cloudtrail
    - https://documentation.wazuh.com/current/amazon/installation.html
  - Macie
  - guardduty
  - IAM
  - Inspector
  - vpcflow
    - get vpcflow into wazuh
      - https://aws.amazon.com/blogs/aws/cloudwatch-logs-subscription-consumer-elasticsearch-kibana-dashboards/
      - autoload their kibana dashboards
        - https://app.logz.io/#/dashboard/apps
- VirusTotal integration
  - https://documentation.wazuh.com/3.x/user-manual/capabilities/virustotal-scan/index.html
  
# Things that cannot go into the cloudformation template and why
- cloudwatch event Rules
  - cloudformation does not support this feature currently
- route53 DNS
  - currently requires a public domain to be registered to be used so i cut it for cost reasons

# Getting Started
This process will walk you through getting the core detonation lab automatically configured and additional processes for setting up each item

## Prerequisites

- Setup and enable AWS logging sources: 
  - enable guardDuty 
    - https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html
  - enable Macie
    - https://docs.aws.amazon.com/macie/latest/userguide/macie-setting-up.html
  - enable IAM 
    - on by default. just needs cloudwatch event rule to forward them.
  - enable Inspector
    - https://docs.aws.amazon.com/inspector/latest/userguide/inspector_settingup.html 
- Setup cloudwatch event rules to forward service events to firehose for GuardDuty, Macie, IAM, Inspector
  - https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#rules
  - create rule
  - Event Source
    - Event pattern
    - Service Name
      - GuardDuty
    - Event Type
      - All
  - Targets
    - Add Target
      - Kinesis Stream
        - "awsDetonationLab-v72-FirehosedeliverystreamGuardDu-15YBFKIAFRMHU"
      - Configure input
        - Matched Event
      - Create a new role for this specific resource
        - keep default name, just add "GuardDuty" to the end of it
  - configure details
  - Name
    - awsDetonationLab-v72-CloudWatchToKinesis-GuardDuty
  - Description
    - Put whatever you want here
  - create rule

## Topologies
### All
![All](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/Topology/Topology-All.png "All")

### CloudTrail
![CloudTrail](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/Topology/Topology-cloudTrail.png "CloudTrail")

### Macie
![Macie](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/Topology/Topology-macie.png "Macie")

### GuardDuty
![GuardDuty](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/Topology/Topology-guardduty.png "GuardDuty")

### IAM
![IAM](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/Topology/Topology-IAM.png "IAM")

### Inspector
![Inspector](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/Topology/Topology-Inspector.png "Inspector")

### VPCFlow
![VPCFlow](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/Topology/Topology-vpcflow.png "VPCFlow")

### Wazuh
![Wazuh](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/Topology/Topology-wazuh.png "Wazuh")


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

![DetonationLab Created](https://github.com/sonofagl1tch/AWSDetonationLab/blob/master/images/detonationLab-created.png "detonationLab-created")

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

## EDR Logs
For EDR I am using Wazuh which is based on OSSEC. "Wazuh is a free, open-source host-based intrusion detection system. It performs log analysis, integrity checking, Windows registry monitoring, rootkit detection, time-based alerting, and active response." you can find more information about them at https://documentation.wazuh.com/current/index.html
### forward kibana console
`ssh -L 8080:localhost:5601 wazuh -N`

### what do I do if the clients have not automatically joined the server?
1. Test to see if the server is running. Both clients have service checks built into them and can be stuck waiting for the server to come up.
   1. `ssh wazuh`
   2. `sudo service elasticsearch start`
   3. `sudo service logstash start`
   4. `sudo service kibana start`
   5. `curl -XGET http://172.16.0.21:9200`
     1. if this comes back with something like the following then you're good to go on the server side
    ```
    {
      "name" : "rFj3Puu",
      "cluster_name" : "elasticsearch",
      "cluster_uuid" : "mOotI9kLSDKgeqWrNkC5ww",
      "version" : {
        "number" : "6.2.4",
        "build_hash" : "ccec39f",
        "build_date" : "2018-04-12T20:37:28.497551Z",
        "build_snapshot" : false,
        "lucene_version" : "7.2.1",
        "minimum_wire_compatibility_version" : "5.6.0",
        "minimum_index_compatibility_version" : "5.0.0"
      },
      "tagline" : "You Know, for Search"
    }
    ```
2. Test on the client side
   1. For Linux: `curl -XGET http://172.16.0.21:9200`
     1. if this comes back with something like the following then you're good to go on the server side
    ```
    {
      "name" : "rFj3Puu",
      "cluster_name" : "elasticsearch",
      "cluster_uuid" : "mOotI9kLSDKgeqWrNkC5ww",
      "version" : {
        "number" : "6.2.4",
        "build_hash" : "ccec39f",
        "build_date" : "2018-04-12T20:37:28.497551Z",
        "build_snapshot" : false,
        "lucene_version" : "7.2.1",
        "minimum_wire_compatibility_version" : "5.6.0",
        "minimum_index_compatibility_version" : "5.0.0"
      },
      "tagline" : "You Know, for Search"
    }
    ```
  2. For Windows: 
  ```
  $HTTP_Status = 0
  do{
      #To check whether it is operational, you should use the following example code:
      # First we create the request.
      $HTTP_Request = [System.Net.WebRequest]::Create('http://172.16.0.21:9200')
      # We then get a response from the site.
      $HTTP_Response = $HTTP_Request.GetResponse()
      # We then get the HTTP code as an integer.
      $HTTP_Status = [int]$HTTP_Response.StatusCode
      If ($HTTP_Status -ne 200) {
          Write-Host "The Site may be down, please check!"
          Start-Sleep -s 10
      }
      # Finally, we clean up the http request by closing it.
      $HTTP_Response.Close()
  } until ($HTTP_Status -eq 200)
  Write-Host "Connection Successful: $HTTP_Status"
  ```
3. connect client to server manually
   1. Linux: `sudo bash installWazuh`
   2. Windows: `C:\Users\Administrator\Desktop\testConnextion.ps1`

# Getting Logs Into SIEM.
- setup AWS log ingestion on Wazuh server (ELK)
  - https://github.com/sonofagl1tch/AWSDetonationLab/tree/master/Wazuh-configurations/runOnWazuh

# additional considerations
creating an AMI with encrypted volumes. I do this and modify the cloudformation template included in this repo to point to my private AMI versions for usage so all systems have full disk encryption.
1. In the source account, create an EBS-backed custom AMI starting from a public AWS AMI in the source region.
2. Add your encrypted EBS snapshots to the custom AMI, and give the target account access to the KMS encryption keys.
3. Share your encrypted snapshots with the target account.
4. Copy the snapshots to the target region and reencrypt them using the target account’s KMS encryption keys in the target region.
5. Have the target account create an AMI using the encrypted EBS snapshots in the target region. 

`aws ec2 copy-image --source-region us-east-1 --source-image-id ami-123abc456 --region us-east-1 --name "windows2k16-encrypted" --encrypted`
