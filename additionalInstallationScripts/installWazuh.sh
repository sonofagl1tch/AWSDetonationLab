#!/bin/bash
# install wazuh server
# Wazuh documentation - https://documentation.wazuh.com/current/installation-guide/installing-wazuh-server/index.html
#######################################

# Versions to install
ELASTIC_VERSION=6.6.0
WAZUH_VERSION=3.8
WAZUH_PATCH=$WAZUH_VERSION.2
WAZUH_PACKAGE=$WAZUH_PATCH-1

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
yum install wazuh-manager-$WAZUH_PACKAGE -y -q -e 0
## check the service status
#service wazuh-manager status
chkconfig --add wazuh-manager
chkconfig wazuh-manager on
service wazuh-manager start
#######################################
# Installing the Wazuh API
## NodeJS >= 4.6.1 is required in order to run the Wazuh API.
## add the official NodeJS repository
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
## install NodeJS
yum install nodejs -y -q -e 0
## install Python if lower than 2.7
#python --version
## Install the Wazuh API
yum install wazuh-api-$WAZUH_PACKAGE -y -q -e 0
## check the service status
chkconfig --add wazuh-api
chkconfig wazuh-api on
service wazuh-api start
#######################################
cat >> /var/ossec/etc/ossec.conf <<\EOF
<ossec_config>
  <wodle name="aws-s3">
    <disabled>no</disabled>
    <interval>10m</interval>
    <run_on_start>yes</run_on_start>
    <skip_on_error>yes</skip_on_error>
    <bucket type="cloudtrail">
      <name>cloudtraillogging</name>
      <access_key>insert_access_key</access_key>
      <secret_key>insert_secret_key</secret_key>
    </bucket>
    <bucket type="custom">
      <name>guarddutylogging</name>
      <path>firehose</path>
      <access_key>insert_access_key</access_key>
      <secret_key>insert_secret_key</secret_key>
    </bucket>
    <bucket type="custom">
      <name>iamlogging</name>
      <path>firehose</path>
      <access_key>insert_access_key</access_key>
      <secret_key>insert_secret_key</secret_key>
    </bucket>
    <bucket type="custom">
      <name>inspectorlogging</name>
      <path>firehose</path>
      <access_key>insert_access_key</access_key>
      <secret_key>insert_secret_key</secret_key>
    </bucket>
    <bucket type="custom">
      <name>macielogging</name>
      <path>firehose</path>
      <access_key>insert_access_key</access_key>
      <secret_key>insert_secret_key</secret_key>
    </bucket>
    <bucket type="vpcflow">
      <name>vpcflowlogging</name>
      <access_key>insert_access_key</access_key>
      <secret_key>insert_secret_key</secret_key>
    </bucket>
  </wodle>
</ossec_config>
EOF
# silent alerts from virus total that aren't showing malware files
cat >> /var/ossec/etc/rules/local_rules.xml << \EOF
<group name="virustotal,">
  <rule id="87103" level="1" overwrite="yes">
    <if_sid>87100</if_sid>
    <field name="virustotal.found">0</field>
    <description>VirusTotal: Alert - No records in VirusTotal database</description>
  </rule>

  <rule id="87104" level="1" overwrite="yes">
    <if_sid>87100</if_sid>
    <field name="virustotal.found">1</field>
    <field name="virustotal.malicious">0</field>
    <description>VirusTotal: Alert - $(virustotal.source.file) - No positives found</description>
  </rule>
</group>
EOF
# configure real time monitoring in:
# - home directories under linux agents
# - desktop, documents, downloads, startup programs and userdata under windows agents
cat > /var/ossec/etc/shared/default/agent.conf << \EOF
<agent_config os="Linux">
  <syscheck>
    <directories check_all="yes" realtime="yes" recursion_level="4">/home</directories>
  </syscheck>
</agent_config>
<agent_config os="Windows">
  <syscheck>
    <directories check_all="yes" realtime="yes" recursion_level="2">C:\Users\Administrator\Desktop</directories>
    <directories check_all="yes" realtime="yes" recursion_level="2">C:\Users\Administrator\Downloads</directories>
    <directories check_all="yes" realtime="yes" recursion_level="2">C:\Users\Administrator\Documents</directories>
    <directories check_all="yes" realtime="yes" recursion_level="4">%APPDATA%</directories>
  </syscheck>
</agent_config>
EOF
# the integrator is used to run the virus total integration and must be enabled
/var/ossec/bin/ossec-control enable integrator
#######################################
# Installing Filebeat
# In a single-host architecture (where Wazuh server and Elastic Stack are installed in the same system), the installation of Filebeat is not needed since Logstash will be able to read the event/alert data directly from the local filesystem without the assistance of a forwarder.
#######################################
# Installing Elastic Stack
## install Oracle Java JRE 8
wget --no-check-certificate -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://javadl.oracle.com/webapps/download/AutoDL?BundleId=235716_2787e4a523244c269598db4e85c51e0c -O jre-8u191-linux-x64.rpm
## install the RPM package using yum
yum install jre-8u191-linux-x64.rpm -y -q -e 0
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
yum install elasticsearch-$ELASTIC_VERSION -y -q -e 0
#service elasticsearch restart
sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml
## Enable and start the Elasticsearch service
chkconfig --add elasticsearch
chkconfig elasticsearch on
service elasticsearch start
#wait until elasticsearch comes up before continuing 
ES_URL=${ES_URL:-'http://localhost:9200'}
ES_USER=${ES_USER:-kibana}
ES_PASSWORD=${ES_PASSWORD:-changeme}
until curl -u ${ES_USER}:${ES_PASSWORD} -XGET "${ES_URL}"; do
  >&2 echo "Elastic is unavailable - sleeping for 5 seconds"
  sleep 5
done
>&2 echo "Elastic is up - executing commands"
## Load the Wazuh template for Elasticsearch:
curl https://raw.githubusercontent.com/wazuh/wazuh/$WAZUH_VERSION/extensions/elasticsearch/wazuh-elastic6-template-alerts.json | curl -XPUT 'http://localhost:9200/_template/wazuh' -H 'Content-Type: application/json' -d @-
#######################################
# Install the Logstash package
yum install logstash-$ELASTIC_VERSION -y -q -e 0
## Download the Wazuh configuration file for Logstash
## Local configuration (only in a single-host architecture)
curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/$WAZUH_VERSION/extensions/logstash/01-wazuh-local.conf
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
chkconfig logstash on
service logstash start
#######################################
# install Kibana
yum install kibana-$ELASTIC_VERSION -y -q -e 0
## Install the Wazuh App plugin for Kibana
## Increase the default Node.js heap memory limit to prevent out of memory errors when installing the Wazuh App. Set the limit as follows
export NODE_OPTIONS="--max-old-space-size=3072"
## Install the Wazuh App
sudo -u kibana NODE_OPTIONS="--max-old-space-size=3072" /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-$(echo $WAZUH_PATCH)_$(echo $ELASTIC_VERSION).zip
##  Kibana will only listen on the loopback interface (localhost) by default. To set up Kibana to listen on all interfaces, edit the file /etc/kibana/kibana.yml uncommenting the setting server.host. Change the value to:
sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
## Enable and start the Kibana service
chkconfig --add kibana
chkconfig kibana on
service kibana start
#######################################
# Disable the Elasticsearch repository
# It is recommended that the Elasticsearch repository be disabled in order to prevent an upgrade to a newer Elastic Stack version due to the possibility of undoing changes with the App.
sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/elastic.repo
#######################################
# set user for wazuh
cd /var/ossec/api/configuration/auth
node htpasswd -c user wazuh -b wazuh
service wazuh-manager restart
service wazuh-api restart
##########################
#confugure wazuh api 
#curl -X POST "localhost:9200/.wazuh/wazuh-configuration" -H 'Content-Type: application/json' -d' {"took":0,"timed_out":false,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0},"hits":{"total":1,"max_score":1.0,"hits":[{"_index":".wazuh","_type":"wazuh-configuration","_score":1.0,"_source":{"api_user":"wazuh","api_password":"d2F6dWg=","url":"http://172.16.0.21","api_port":"55000","insecure":"true","component":"API","cluster_info":{"manager":"ip-172-16-0-21.ec2.internal","cluster":"Disabled","status":"disabled"},"extensions":{"audit":true,"pci":true,"oscap":true,"aws":false,"virustotal":false}}}]}}'
API_PROTOCOL=${API_PROTOCOL:-http}
HOSTNAME=${HOSTNAME:-"$(hostname -f)"}
API_SERVER=${API_SERVER:-"localhost"}
API_URL=${API_PROTOCOL}://${API_SERVER}
API_PORT=${API_PORT:-55000}
API_USER=${API_USER:-wazuh}
API_PASS=${API_PASS:-wazuh}
API_PASS_BASE64=$(echo -n ${API_PASS} | base64)
ES_URL=${ES_URL:-'http://localhost:9200'}
ES_USER=${ES_USER:-kibana}
ES_PASSWORD=${ES_PASSWORD:-changeme}
until curl -u ${ES_USER}:${ES_PASSWORD} -XGET "${ES_URL}"; do
  >&2 echo "Elastic is unavailable - sleeping for 5 seconds"
  sleep 5
done
>&2 echo "Elastic is up - executing commands"
# sleep 5
echo -e "\nSetting Wazuh API credentials into the Wazuh Kibana application"
# The Wazuh Kibana application configuration is the document with the ID 1513629884013, don't change that!
curl -s -u ${ES_USER}:${ES_PASSWORD} -XPOST "${ES_URL}/.wazuh/wazuh-configuration/1513629884013" -H 'Content-Type: application/json' -H "Accept: application/json" -d'
{
    "api_user": "'${API_USER}'",
    "api_password": "'${API_PASS_BASE64}'",
    "url": "'${API_URL}'",
    "api_port": "'${API_PORT}'",
    "insecure" : "true",
    "component" : "API",
    "cluster_info" : {
        "manager" : "'${HOSTNAME}'",
        "cluster" : "Disabled",
        "status" : "disabled",
        "node" : "node01"
    },
    "extensions" : {
        "audit" : true,
        "pci" : true,
        "gdpr" : true,
        "oscap" : true,
        "ciscat" : false,
        "aws" : false,
        "virustotal" : false
    }
}
'
#######################################
#set default kibana index to wazuh alerts
K_URL=${K_URL:-'localhost:5601/api/kibana/settings/defaultIndex'}
K_USER=${K_USER:-elastic}
K_PASSWORD=${K_PASSWORD:-changeme}
curl -X POST -H "Content-Type: application/json" -H "kbn-xsrf: true" -d '{"value":"wazuh-alerts-3.x-*"}' "http://${K_USER}:${K_PASSWORD}@${K_URL}"
#######################################
#wait until elasticsearch comes up before continuing 
ES_URL=${ES_URL:-'http://localhost:9200'}
ES_USER=${ES_USER:-kibana}
ES_PASSWORD=${ES_PASSWORD:-changeme}
until curl -u ${ES_USER}:${ES_PASSWORD} -XGET "${ES_URL}"; do
  service elasticsearch restart
  sleep 5
done
>&2 echo "Elastic is up - executing commands"
#######################################
# next steps is to configure wazuh
## https://documentation.wazuh.com/current/installation-guide/installing-elastic-stack/connect_wazuh_app.html
