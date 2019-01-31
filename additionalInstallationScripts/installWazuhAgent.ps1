# Download agent
$url = "https://packages.wazuh.com/3.x/windows/wazuh-agent-3.8.2-1.msi"
$output = "C:\Users\Administrator\Desktop\wazuh-agent-3.8.2-1.msi"
Invoke-WebRequest -Uri $url -OutFile $output

$wazuh_manager = "172.16.0.21"

# install agent and register agent
C:\Users\Administrator\Desktop\wazuh-agent-3.8.2-1.msi /q ADDRESS=$wazuh_manager

$wazuh_path = "C:\Program Files (x86)\ossec-agent"
$agent_auth_path = "$wazuh_path\agent-auth.exe"

# wait until the wazuh agent is installed, i.e. the ossec-agent directory exists
do {
    Write-Output "Wazuh agent is still not installed"
    Start-Sleep 10
} while (![System.IO.File]::Exists($agent_auth_path))

Write-Output "Wazuh agent is installed"

$n_retries = 0 # number of times the agent has attempt to register
$max_retries = 5 # maximum number of allowed attemps

do {
    $agent_auth = Start-Process -FilePath $agent_auth_path -ArgumentList "-m $wazuh_manager -A windowsVictim" -WorkingDirectory $wazuh_path -PassThru
    Wait-Process -InputObject $agent_auth
    $n_retries++
    if ($agent_auth.ExitCode -ne 0) {
        Write-Output "Could not register agent. Sleeping for 10 seconds."
        Start-Sleep 10
    }
} while ($agent_auth.ExitCode -ne 0 -and $n_retries -le $max_retries)

$final_msg = If ($n_retries -le $max_retries) {"yay!"} Else {"fuck!"}
Write-Output $final_msg

Restart-Service -Name wazuh