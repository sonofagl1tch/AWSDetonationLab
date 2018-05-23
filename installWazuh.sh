#!/bin/bash
# install wazuh server
# Wazuh documentation - https://documentation.wazuh.com/current/installation-guide/installing-wazuh-server/index.html
#######################################
# Install Wazuh server on CentOS/RHEL/Fedora.
## set up the repository
cat > /etc/yum.repos.d/wazuh.repo <<\EOF
[wazuh_repo]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/3.x/yum/
protect=1
EOF
## Installing the Wazuh Manager
yum install wazuh-manager -y -q -e 0
## check the service status
service wazuh-manager status
#######################################
# Installing the Wazuh API
## NodeJS >= 4.6.1 is required in order to run the Wazuh API.
## add the official NodeJS repository
#curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
wget https://rpm.nodesource.com/setup_6.x
bash setup_6.x
## install NodeJS
yum install nodejs -y -q -e 0
## install Python if lower than 2.7
python --version
## Install the Wazuh API
yum install wazuh-api -y -q -e 0
## check the service status
service wazuh-api status
#######################################
# Installing Filebeat
# In a single-host architecture (where Wazuh server and Elastic Stack are installed in the same system), the installation of Filebeat is not needed since Logstash will be able to read the event/alert data directly from the local filesystem without the assistance of a forwarder.
#######################################
# Installing Elastic Stack
## install Oracle Java JRE 8
curl -Lo jre-8-linux-x64.rpm --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u172-b11/a58eab1ec242421181065cdc37240b08/jre-8u172-linux-x64.rpm"
## install the RPM package using yum
yum install jre-8-linux-x64.rpm
## Install the Elastic repository and its GPG key
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/elastic.repo << EOF
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
## Install the Elasticsearch package
yum install elasticsearch-6.2.4 -y -q -e 0
## Enable and start the Elasticsearch service
chkconfig --add elasticsearch
service elasticsearch start
## Load the Wazuh template for Elasticsearch:
curl https://raw.githubusercontent.com/wazuh/wazuh/3.2/extensions/elasticsearch/wazuh-elastic6-template-alerts.json | curl -XPUT 'http://localhost:9200/_template/wazuh' -H 'Content-Type: application/json' -d @-
#######################################
# Install the Logstash package
yum install logstash-6.2.4 -y -q -e 0
## Download the Wazuh configuration file for Logstash
## Local configuration (only in a single-host architecture)
curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/3.2/extensions/logstash/01-wazuh-local.conf
## Because the Logstash user needs to read the alerts.json file, please add it to OSSEC group by running
usermod -a -G ossec logstash
## Follow the next steps if you use CentOS-6/RHEL-6 or Amazon AMI (logstash uses Upstart like a service manager and needs to be fixed, see this bug):
## Edit the file /etc/logstash/startup.options changing line 30 from LS_GROUP=logstash to LS_GROUP=ossec.
sed -i 's/LS_GROUP=logstash/LS_GROUP=ossec/' /etc/logstash/startup.options
## Update the service with the new parameters by running the command /usr/share/logstash/bin/system-install
/usr/share/logstash/bin/system-install
## Restart Logstash.
## force install a SysV init script by running: /usr/share/logstash/bin/system-install /etc/logstash/startup.options sysv as root
/usr/share/logstash/bin/system-install /etc/logstash/startup.options sysv
service logstash restart
## Enable and start the Logstash service
chkconfig --add logstash
#service logstash start
#######################################
# install Kibana
yum install kibana-6.2.4 -y -q -e 0
## Install the Wazuh App plugin for Kibana
## Increase the default Node.js heap memory limit to prevent out of memory errors when installing the Wazuh App. Set the limit as follows
export NODE_OPTIONS="--max-old-space-size=3072"
## Install the Wazuh App
/usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-3.2.2_6.2.4.zip
##  Kibana will only listen on the loopback interface (localhost) by default. To set up Kibana to listen on all interfaces, edit the file /etc/kibana/kibana.yml uncommenting the setting server.host. Change the value to:
sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
## Enable and start the Kibana service
chkconfig --add kibana
service kibana start
#######################################
# Disable the Elasticsearch repository
# It is recommended that the Elasticsearch repository be disabled in order to prevent an upgrade to a newer Elastic Stack version due to the possibility of undoing changes with the App.
sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/elastic.repo
#######################################
# next steps is to configure wazuh
## https://documentation.wazuh.com/current/installation-guide/installing-elastic-stack/connect_wazuh_app.html
