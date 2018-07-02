#Download the CloudWatch agent
$url = "https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/AmazonCloudWatchAgent.zip"
$output = "C:\Users\Administrator\Desktop\AmazonCloudWatchAgent.zip"
Invoke-WebRequest -Uri $url -OutFile $output

#unzip CloudWatch agent
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "C:\Users\Administrator\Desktop\AmazonCloudWatchAgent.zip" "C:\Users\Administrator\Desktop\AmazonCloudWatchAgent"

#change to directory
Set-Location -Path "C:\Users\Administrator\Desktop\AmazonCloudWatchAgent"

#Install the package
#On a server running Windows Server, open PowerShell, change to the directory containing the unzipped package, and use the install.ps1 script to install it.
.\install.ps1

#Modify the Common Configuration and Named Profile for CloudWatch Agent
C:\Users\Administrator\Documents\cloudwatchconfig.json

$config = '{
  "logs": {
    "logs_collected": {
      "windows_events": {
        "collect_list": [{
            "event_format": "xml",
            "event_levels": [
              "VERBOSE",
              "INFORMATION",
              "WARNING",
              "ERROR",
              "CRITICAL"
            ],
            "event_name": "System",
            "log_group_name": "detonationLab-windows"
          },
          {
            "event_format": "xml",
            "event_levels": [
              "VERBOSE",
              "INFORMATION",
              "WARNING",
              "ERROR",
              "CRITICAL"
            ],
            "event_name": "Security",
            "log_group_name": "detonationLab-windows"
          },
          {
            "event_format": "xml",
            "event_levels": [
              "VERBOSE",
              "INFORMATION",
              "WARNING",
              "ERROR",
              "CRITICAL"
            ],
            "event_name": "Application",
            "log_group_name": "detonationLab-windows"
          }
        ]
      }
    }
  },
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
      "ImageId": "${aws:ImageId}",
      "InstanceId": "${aws:InstanceId}",
      "InstanceType": "${aws:InstanceType}"
    },
    "metrics_collected": {
      "TCPv4": {
        "measurement": [
          "Connections Established"
        ],
        "metrics_collection_interval": 60
      },
      "TCPv6": {
        "measurement": [
          "Connections Established"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}'
$config | ConvertTo-Json -depth 100 | Out-File "C:\Users\Administrator\Documents\cloudwatchconfig.json"

#On a server running Windows Server, type the following if you saved the configuration file on the local computer
amazon-cloudwatch-agent-ctl.ps1 -a fetch-config -m ec2 -c file:"C:\Users\Administrator\Documents\cloudwatchconfig.json" -s