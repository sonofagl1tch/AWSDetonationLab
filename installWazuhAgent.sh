#!/bin/bash
# install wazuh server
# Wazuh documentation - https://documentation.wazuh.com/current/installation-guide/installing-wazuh-agent/wazuh_agent_rpm.html#wazuh-agent-rpm
#######################################
#sleep timer for if you want this script to run on instance creation. the server takes 5+ minutes to intall.
#sleep 10m
# Adding the Wazuh repository
cat > /etc/yum.repos.d/wazuh.repo <<\EOF
[wazuh_repo]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/3.x/yum/
protect=1
EOF

# Installing Wazuh agent
yum install wazuh-agent -y -q -e 0

# register agent
# https://raw.githubusercontent.com/wazuh/wazuh-api/3.2/examples/api-register-agent.sh
# Connection variables
API_IP="172.16.0.21"
API_PORT="55000"
PROTOCOL="http"
USER="wazuh"
PASSWORD="wazuh"

if [ "$#" = "0" ]; then
  AGENT_NAME=$(hostname)
else
  AGENT_NAME=$1
fi

# Adding agent and getting Id from manager
echo ""
echo "Adding agent:"
echo "curl -s -u $USER:**** -k -X POST -d 'name=$AGENT_NAME' $PROTOCOL://$API_IP:$API_PORT/agents"
API_RESULT=$(curl -s -u $USER:"$PASSWORD" -k -X POST -d 'name='$AGENT_NAME $PROTOCOL://$API_IP:$API_PORT/agents)
echo -e $API_RESULT | grep -q "\"error\":0" 2>&1

if [ "$?" != "0" ]; then
  echo -e $API_RESULT | sed -rn 's/.*"message":"(.+)".*/\1/p'
  exit 1
fi
# Get agent id and agent key
AGENT_ID=$(echo $API_RESULT | cut -d':' -f 4 | cut -d ',' -f 1)
AGENT_KEY=$(echo $API_RESULT | cut -d':' -f 5 | cut -d '}' -f 1)

echo "Agent '$AGENT_NAME' with ID '$AGENT_ID' added."
echo "Key for agent '$AGENT_ID' received."

# Importing key
echo ""
echo "Importing authentication key:"
echo "y" | /var/ossec/bin/manage_agents -i $AGENT_KEY

# fix bad ossec config
sed -i "s/MANAGER_IP/172.16.0.21/" /var/ossec/etc/ossec.conf

# Restarting agent
echo ""
echo "Restarting:"
echo ""
/var/ossec/bin/ossec-control restart

exit 0
