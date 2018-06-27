# Download agent
$url = "https://packages.wazuh.com/3.x/windows/wazuh-agent-3.3.0-1.msi"
$output = "C:\Users\Administrator\Desktop\wazuh-agent-3.3.0-1.msi"
Invoke-WebRequest -Uri $url -OutFile $output

# install agent
C:\Users\Administrator\Desktop\wazuh-agent-3.3.0-1.msi /q

# add firwall rules to allow wazuh agent traffic
#New-NetFirewallRule -DisplayName "Allow Wazuh Agent Traffic UDP 514" -Direction Outbound -LocalPort 1514 -Protocol UDP -Action Allow
#New-NetFirewallRule -DisplayName "Allow Wazuh Agent Traffic TCP 55000" -Direction Outbound -LocalPort 55000 -Protocol TCP -Action Allow

# sleep for 2 minutes to allow for wazuh agent to finish installing
Start-Sleep -s 120

# sleep for 10 seconds to allow for wazuh server to finish installing
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
Write-Host $HTTP_Status


# https://raw.githubusercontent.com/wazuh/wazuh-api/3.2/examples/api-register-agent.ps1
###
#  Powershell script for registering agents automatically with the API
#  Copyright (C) 2017 Wazuh, Inc. All rights reserved.
#  Wazuh.com
#
#  This program is a free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public
#  License (version 2) as published by the FSF - Free Software
#  Foundation.
###

function Ignore-SelfSignedCerts {
    add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class PolicyCert : ICertificatePolicy {
            public PolicyCert() {}
            public bool CheckValidationResult(
                ServicePoint sPoint, X509Certificate cert,
                WebRequest wRequest, int certProb) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = new-object PolicyCert
}

function req($method, $resource, $params){
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
    $url = $base_url + $resource;

    try{
        return Invoke-WebRequest -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method $method -Uri $url -Body $params
    }catch{
        return $_.Exception
    }

}

# Configuration
$base_url = "http://172.16.0.21:55000"
$username = "wazuh"
$password = "wazuh"
#$agent_name = $env:computername
$agent_name = "windowsVictim"
$path = "C:\Program Files (x86)\ossec-agent\"
$config = "C:\Program Files (x86)\ossec-agent\ossec.conf"
$wazuh_manager = "172.16.0.21"
Ignore-SelfSignedCerts

# Test API integration to make sure IE has run through initial startup dialogue - This can be a problem with new servers.

try{
    $testresponse = req -method "GET" -resource "/manager/info?pretty" | ConvertFrom-Json | select -expand data -ErrorAction Stop -ErrorVariable geterr

    Write-Output "The Wazuh manager is contactable via the API, the response is: `n $($testresponse)"
    }catch{
    Write-Host -ForegroundColor Red "IE has not had it's initial startup dialogue dismissed, please complete this step and try again. Script will exit. Error: $($geterr)`n .Please Run OSSEC_AgentConfig Separately once you correct the error."
    Exit
    }

# Test for agent already existing in manager

$agentexist = req -method "GET" -resource "/agents?pretty" -params @{search=$agent_name} # searches for the agent based on the env variable name

$agentinfo = $agentexist.Content | ConvertFrom-Json | select -expand data | select totalitems

$agentexistid = $agentexist.Content | ConvertFrom-Json | select -expand data | select -expand items | select id # expands the embedded JSON items to retrieve the agent ID

# If agent does not already exist proceed to create agent and register the agent key

if ($agentinfo.totalitems -lt 1){

# Adding agent and getting Id from manager

Write-Output "`r`nAdding agent:"
$response = req -method "POST" -resource "/agents" -params @{name=$agent_name} | ConvertFrom-Json
If ($response.error -ne '0') {
  Write-Output "ERROR: $($response.message)"
  Exit
}
$agent_id = $response.data
Write-Output "Agent '$($agent_name)' with ID '$($agent_id)' added."

# Getting agent key from manager

Write-Output "`r`nGetting agent key:"
$response = req -method "GET" -resource "/agents/$($agent_id)/key" | ConvertFrom-Json
If ($response.error -ne '0') {
  Write-Output "ERROR: $($response.message)"
  Exit
}
$agent_key = $response.data
Write-Output "Key for agent '$($agent_id)' received."

# Importing key

Write-Output "`r`nImporting authentication key:"
echo "y" | & "$($path)manage_agents.exe" "-i $($agent_key)" "y`r`n"

# Restarting agent

Write-Output "`r`nRestarting:"
$srvName = "OssecSvc"

Write-Output "Stopping service."
Stop-Service $srvName
$srvStat = Get-Service $srvName
Write-Output "$($srvName) is now $($srvStat.status)"

Start-Sleep -s 10

Add-Content $config "`n<ossec_config>   <client>      <server-ip>$($wazuh_manager)</server-ip>   </client> </ossec_config>"

Start-Sleep -s 10

Write-Output "Starting service."
Start-Service $srvName
$srvStat = Get-Service $srvName
Write-Output "$($srvName) is now $($srvStat.status)"
}
Else{

# If agent is found in manager by name it will retrieve the key and configure the agent

$response = req -method "GET" -resource "/agents/$($agentexistid.id)/key" | ConvertFrom-Json
# Key received from manager
$agent_key = $response.data
# Importing agent key from manager
Write-Output "`r`nImporting authentication key:"
echo "y" | & "$($path)manage_agents.exe" "-i $($agent_key)" "y`r`n"

Write-Output "`r`nRestarting:"
$srvName = "OssecSvc"

Write-Output "Stopping service."
Stop-Service $srvName
$srvStat = Get-Service $srvName
Write-Output "$($srvName) is now $($srvStat.status)"

Start-Sleep -s 10

Add-Content $config "`n<ossec_config>   <client>      <server-ip>$($wazuh_manager)</server-ip>   </client> </ossec_config>"

Start-Sleep -s 10

Write-Output "Starting service."
Start-Service $srvName
$srvStat = Get-Service $srvName
Write-Output "$($srvName) is now $($srvStat.status)"


}
