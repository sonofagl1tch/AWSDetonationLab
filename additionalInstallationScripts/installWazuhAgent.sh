#!/bin/bash
# install wazuh server
# Wazuh documentation - https://documentation.wazuh.com/current/installation-guide/installing-wazuh-agent/wazuh_agent_rpm.html#wazuh-agent-rpm
#######################################
#sleep timer for if you want this script to run on instance creation. the server takes 5+ minutes to intall.
#sleep 10m

WAZUH_VERSION=3.8
WAZUH_PATCH=$WAZUH_VERSION.2
WAZUH_PACKAGE=$WAZUH_PATCH-1

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
yum install wazuh-agent-$WAZUH_PACKAGE -y -q -e 0

# register agent
MANAGER_IP="172.16.0.21"
  
until /var/ossec/bin/agent-auth -m $MANAGER_IP; do
  echo "Wazuh manager is unavailable - sleeping for 5 seconds"
  sleep 5
done

# set up manager ip in the ossec.conf file before restarting
sed -i "s/MANAGER_IP/$MANAGER_IP/" /var/ossec/etc/ossec.conf

service wazuh-agent restart

echo "Agent sucessfully registered"
