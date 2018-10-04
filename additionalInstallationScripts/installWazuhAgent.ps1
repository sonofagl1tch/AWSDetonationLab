# Download agent
$url = "https://packages.wazuh.com/3.x/windows/wazuh-agent-3.6.1-1.msi"
$output = "C:\Users\Administrator\Desktop\wazuh-agent-3.6.1-1.msi"
Invoke-WebRequest -Uri $url -OutFile $output

$wazuh_manager = "172.16.0.21"

# check whether ossec-auth is up in the manager
Do {
    $connection = Test-NetConnection $wazuh_manager -Port 1515
    Write-Output "Connection result: " + $connection.TcpTestSucceeded 
} While (!$connection.TcpTestSucceeded)

Write-Output "Wazuh manager has port 1515 opened. Connecting..."

# install agent and register agent
Start-Process "msiexec.exe" -ArgumentList "C:\Users\Administrator\Desktop\wazuh-agent-3.6.1-1.msi /q ADDRESS=$wazuh_manager AUTHD_SERVER=$wazuh_manager AGENT_NAME="windowsVictim"" -Wait -NoNewWindow 