#!/bin/bash
# install wazuh on ubuntu
# Ubuntu Server 16.04 LTS (HVM), SSD Volume Type - ami-759bc50a
###############################################################
# Adding Wazuh Repositories
apt-get update -y
apt-get install curl apt-transport-https lsb-release -y
#If the /usr/bin/python file doesn’t exist (like in Ubuntu 16.04 LTS or later), create a symlink to Python
if [ ! -f /usr/bin/python ]; then ln -s /usr/bin/python3 /usr/bin/python; fi
#Install the GPG key:
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
#Add the repository:
echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
#update package info
apt-get update -y
##########################
#Installing the Wazuh Manager
apt-get install wazuh-manager -y
##########################
#Installing the Wazuh API
curl -sL https://deb.nodesource.com/setup_8.x | bash -
apt-get install nodejs -y
apt-get install wazuh-api -y
##########################
#Install Elastic Stack with Debian packages
add-apt-repository ppa:webupd8team/java -y
apt-get update -y
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
apt-get install oracle-java8-installer -y
apt-get install curl apt-transport-https -y
curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-6.x.list
apt-get update -y
#Install the Elasticsearch package
apt-get install elasticsearch=6.3.2 -y
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service
##########################
#wait until elasticsearch comes up before continuing 
# ES_URL=${ES_URL:-'http://localhost:9200'}
# ES_USER=${ES_USER:-kibana}
# ES_PASSWORD=${ES_PASSWORD:-changeme}
# until curl -u ${ES_USER}:${ES_PASSWORD} -XGET "${ES_URL}"; do
#   service elasticsearch restart
#   sleep 5
# done
# >&2 echo "Elastic is up - executing commands"
##########################
#Load the Wazuh template for Elasticsearch
curl https://raw.githubusercontent.com/wazuh/wazuh/3.5/extensions/elasticsearch/wazuh-elastic6-template-alerts.json | curl -XPUT 'http://localhost:9200/_template/wazuh' -H 'Content-Type: application/json' -d @-
##########################
#Install the logstash
apt-get install logstash=1:6.3.2-1 -y
curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/3.5/extensions/logstash/01-wazuh-local.conf
usermod -a -G ossec logstash
systemctl daemon-reload
systemctl enable logstash.service
systemctl start logstash.service
##########################
#Install the Kibana
apt-get install kibana=6.3.2 -y
export NODE_OPTIONS="--max-old-space-size=3072"
/usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-3.5.0_6.3.2.zip
##  Kibana will only listen on the loopback interface (localhost) by default. To set up Kibana to listen on all interfaces, edit the file /etc/kibana/kibana.yml uncommenting the setting server.host. Change the value to:
sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana.service
#Disable the Elasticsearch repository:
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/elastic-6.x.list
apt-get update -y
##########################
#confugure wazuh api 
#curl -X POST "localhost:9200/.wazuh/wazuh-configuration" -H 'Content-Type: application/json' -d' {"took":0,"timed_out":false,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0},"hits":{"total":1,"max_score":1.0,"hits":[{"_index":".wazuh","_type":"wazuh-configuration","_score":1.0,"_source":{"api_user":"wazuh","api_password":"d2F6dWg=","url":"http://172.16.0.21","api_port":"55000","insecure":"true","component":"API","cluster_info":{"manager":"ip-172-16-0-21.ec2.internal","cluster":"Disabled","status":"disabled"},"extensions":{"audit":true,"pci":true,"oscap":true,"aws":false,"virustotal":false}}}]}}'
API_PROTOCOL=${API_PROTOCOL:-http}
HOSTNAME=${HOSTNAME:-"$(hostname -f)"}
API_SERVER=${API_SERVER:-"$(hostname -i)"}
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
    "url": "'${API_PROTOCOL}'://'${API_SERVER}'",
    "api_port": "'${API_PORT}'",
    "insecure": "true",
    "component": "API",
    "active": true,
    "extensions": {
        "oscap": true,
        "audit": true,
        "pci": true
    },
    "cluster_info": {
        "node": "wazuh-manager-master",
        "cluster": "wazuh",
        "manager": "'${HOSTNAME}'",
        "status": "enabled"
    }
}
'
#######################################











