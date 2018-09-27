#!/bin/bash
# install wazuh server
# Wazuh documentation - https://documentation.wazuh.com/current/installation-guide/installing-wazuh-server/index.html
#######################################
# Versions to install
ELASTIC_VERSION=6.4.0
WAZUH_VERSION=3.6
WAZUH_PATCH=1
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
yum install wazuh-api -y -q -e 0
## check the service status
chkconfig --add wazuh-api
chkconfig wazuh-api on
service wazuh-api start
#######################################
# Installing Filebeat
# In a single-host architecture (where Wazuh server and Elastic Stack are installed in the same system), the installation of Filebeat is not needed since Logstash will be able to read the event/alert data directly from the local filesystem without the assistance of a forwarder.
#######################################
# Installing Elastic Stack
## install Oracle Java JRE 8
curl -Lo jre-8-linux-x64.rpm --header "Cookie: oraclelicense=accept-securebackup-cookie" "https://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jre-8u181-linux-x64.rpm"
## install the RPM package using yum
yum install jre-8-linux-x64.rpm -y -q -e 0
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
curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/$WAZUH_VERSION.$WAZUH_PATCH/extensions/logstash/01-wazuh-local.conf
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
/usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-$WAZUH_VERSION._$ELASTIC_VERSION.zip
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

cat > /var/ossec/etc/ossec.conf <<\EOF 
<!--
  Wazuh - Manager - Default configuration for amzn 2
  More info at: https://documentation.wazuh.com
  Mailing list: https://groups.google.com/forum/#!forum/wazuh
-->

<ossec_config>
  <global>
    <jsonout_output>yes</jsonout_output>
    <alerts_log>yes</alerts_log>
    <logall>no</logall>
    <logall_json>no</logall_json>
    <email_notification>no</email_notification>
    <smtp_server>smtp.example.wazuh.com</smtp_server>
    <email_from>ossecm@example.wazuh.com</email_from>
    <email_to>recipient@example.wazuh.com</email_to>
    <email_maxperhour>12</email_maxperhour>
    <queue_size>131072</queue_size>
  </global>

  <alerts>
    <log_alert_level>3</log_alert_level>
    <email_alert_level>12</email_alert_level>
  </alerts>

  <!-- Choose between "plain", "json", or "plain,json" for the format of internal logs -->
  <logging>
    <log_format>plain</log_format>
  </logging>

  <remote>
    <connection>secure</connection>
    <port>1514</port>
    <protocol>udp</protocol>
    <queue_size>131072</queue_size>
  </remote>

  <!-- Policy monitoring -->
  <rootcheck>
    <disabled>no</disabled>
    <check_unixaudit>yes</check_unixaudit>
    <check_files>yes</check_files>
    <check_trojans>yes</check_trojans>
    <check_dev>yes</check_dev>
    <check_sys>yes</check_sys>
    <check_pids>yes</check_pids>
    <check_ports>yes</check_ports>
    <check_if>yes</check_if>

    <!-- Frequency that rootcheck is executed - every 12 hours -->
    <frequency>43200</frequency>

    <rootkit_files>/var/ossec/etc/rootcheck/rootkit_files.txt</rootkit_files>
    <rootkit_trojans>/var/ossec/etc/rootcheck/rootkit_trojans.txt</rootkit_trojans>

    <system_audit>/var/ossec/etc/rootcheck/system_audit_rcl.txt</system_audit>
    <system_audit>/var/ossec/etc/rootcheck/system_audit_ssh.txt</system_audit>

    <skip_nfs>yes</skip_nfs>
  </rootcheck>

  <wodle name="open-scap">
    <disabled>yes</disabled>
    <timeout>1800</timeout>
    <interval>1d</interval>
    <scan-on-start>yes</scan-on-start>
  </wodle>

  <wodle name="cis-cat">
    <disabled>yes</disabled>
    <timeout>1800</timeout>
    <interval>1d</interval>
    <scan-on-start>yes</scan-on-start>

    <java_path>wodles/java</java_path>
    <ciscat_path>wodles/ciscat</ciscat_path>
  </wodle>

  <!-- Osquery integration -->
  <wodle name="osquery">
    <disabled>yes</disabled>
    <run_daemon>yes</run_daemon>
    <log_path>/var/log/osquery/osqueryd.results.log</log_path>
    <config_path>/etc/osquery/osquery.conf</config_path>
    <add_labels>yes</add_labels>
  </wodle>

  <!-- System inventory -->
  <wodle name="syscollector">
    <disabled>no</disabled>
    <interval>1h</interval>
    <scan_on_start>yes</scan_on_start>
    <hardware>yes</hardware>
    <os>yes</os>
    <network>yes</network>
    <packages>yes</packages>
    <ports all="no">yes</ports>
    <processes>yes</processes>
  </wodle>

  <wodle name="vulnerability-detector">
    <disabled>yes</disabled>
    <interval>1m</interval>
    <run_on_start>yes</run_on_start>
    <feed name="ubuntu-18">
      <disabled>yes</disabled>
      <update_interval>1h</update_interval>
    </feed>
    <feed name="redhat-7">
      <disabled>yes</disabled>
      <update_interval>1h</update_interval>
    </feed>
    <feed name="debian-9">
      <disabled>yes</disabled>
      <update_interval>1h</update_interval>
    </feed>
  </wodle>
  
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
  <bucket type="custom">
   <name>vpcflowlogging</name>
   <path>flowlogs</path>
   <access_key>insert_access_key</access_key>
   <secret_key>insert_secret_key</secret_key>
  </bucket>
 </wodle>

  <!-- File integrity monitoring -->
  <syscheck>
    <disabled>no</disabled>

    <!-- Frequency that syscheck is executed default every 12 hours -->
    <frequency>43200</frequency>

    <scan_on_start>yes</scan_on_start>

    <!-- Generate alert when new file detected -->
    <alert_new_files>yes</alert_new_files>

    <!-- Don't ignore files that change more than 'frequency' times -->
    <auto_ignore frequency="10" timeframe="3600">no</auto_ignore>

    <!-- Directories to check  (perform all possible verifications) -->
    <directories check_all="yes">/etc,/usr/bin,/usr/sbin</directories>
    <directories check_all="yes">/bin,/sbin,/boot</directories>

    <!-- Files/directories to ignore -->
    <ignore>/etc/mtab</ignore>
    <ignore>/etc/hosts.deny</ignore>
    <ignore>/etc/mail/statistics</ignore>
    <ignore>/etc/random-seed</ignore>
    <ignore>/etc/random.seed</ignore>
    <ignore>/etc/adjtime</ignore>
    <ignore>/etc/httpd/logs</ignore>
    <ignore>/etc/utmpx</ignore>
    <ignore>/etc/wtmpx</ignore>
    <ignore>/etc/cups/certs</ignore>
    <ignore>/etc/dumpdates</ignore>
    <ignore>/etc/svc/volatile</ignore>
    <ignore>/sys/kernel/security</ignore>
    <ignore>/sys/kernel/debug</ignore>

    <!-- Check the file, but never compute the diff -->
    <nodiff>/etc/ssl/private.key</nodiff>

    <skip_nfs>yes</skip_nfs>

    <!-- Remove not monitored files -->
    <remove_old_diff>yes</remove_old_diff>

    <!-- Allow the system to restart Auditd after installing the plugin -->
    <restart_audit>yes</restart_audit>
  </syscheck>

  <!-- Active response -->
  <global>
    <white_list>127.0.0.1</white_list>
    <white_list>^localhost.localdomain$</white_list>
    <white_list>172.16.0.2</white_list>
  </global>

  <command>
    <name>disable-account</name>
    <executable>disable-account.sh</executable>
    <expect>user</expect>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>restart-ossec</name>
    <executable>restart-ossec.sh</executable>
    <expect></expect>
  </command>

  <command>
    <name>firewall-drop</name>
    <executable>firewall-drop.sh</executable>
    <expect>srcip</expect>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>host-deny</name>
    <executable>host-deny.sh</executable>
    <expect>srcip</expect>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>route-null</name>
    <executable>route-null.sh</executable>
    <expect>srcip</expect>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>win_route-null</name>
    <executable>route-null.cmd</executable>
    <expect>srcip</expect>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>win_route-null-2012</name>
    <executable>route-null-2012.cmd</executable>
    <expect>srcip</expect>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>netsh</name>
    <executable>netsh.cmd</executable>
    <expect>srcip</expect>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>netsh-win-2016</name>
    <executable>netsh-win-2016.cmd</executable>
    <expect>srcip</expect>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <!--
  <active-response>
    active-response options here
  </active-response>
  -->

  <!-- Log analysis -->
  <localfile>
    <log_format>command</log_format>
    <command>df -P</command>
    <frequency>360</frequency>
  </localfile>

  <localfile>
    <log_format>full_command</log_format>
    <command>netstat -tulpn | sed 's/\([[:alnum:]]\+\)\ \+[[:digit:]]\+\ \+[[:digit:]]\+\ \+\(.*\):\([[:digit:]]*\)\ \+\([0-9\.\:\*]\+\).\+\ \([[:digit:]]*\/[[:alnum:]\-]*\).*/\1 \2 == \3 == \4 \5/' | sort -k 4 -g | sed 's/ == \(.*\) ==/:\1/' | sed 1,2d</command>
    <alias>netstat listening ports</alias>
    <frequency>360</frequency>
  </localfile>

  <localfile>
    <log_format>full_command</log_format>
    <command>last -n 20</command>
    <frequency>360</frequency>
  </localfile>

  <ruleset>
    <!-- Default ruleset -->
    <decoder_dir>ruleset/decoders</decoder_dir>
    <rule_dir>ruleset/rules</rule_dir>
    <rule_exclude>0215-policy_rules.xml</rule_exclude>
    <list>etc/lists/audit-keys</list>
    <list>etc/lists/amazon/aws-sources</list>
    <list>etc/lists/amazon/aws-eventnames</list>

    <!-- User-defined ruleset -->
    <decoder_dir>etc/decoders</decoder_dir>
    <rule_dir>etc/rules</rule_dir>
  </ruleset>

  <!-- Configuration for ossec-authd
    To enable this service, run:
    ossec-control enable auth
  -->
  <auth>
    <disabled>no</disabled>
    <port>1515</port>
    <use_source_ip>yes</use_source_ip>
    <force_insert>yes</force_insert>
    <force_time>0</force_time>
    <purge>yes</purge>
    <use_password>no</use_password>
    <limit_maxagents>yes</limit_maxagents>
    <ciphers>HIGH:!ADH:!EXP:!MD5:!RC4:!3DES:!CAMELLIA:@STRENGTH</ciphers>
    <!-- <ssl_agent_ca></ssl_agent_ca> -->
    <ssl_verify_host>no</ssl_verify_host>
    <ssl_manager_cert>/var/ossec/etc/sslmanager.cert</ssl_manager_cert>
    <ssl_manager_key>/var/ossec/etc/sslmanager.key</ssl_manager_key>
    <ssl_auto_negotiate>no</ssl_auto_negotiate>
  </auth>

  <cluster>
    <name>wazuh</name>
    <node_name>node01</node_name>
    <node_type>master</node_type>
    <key></key>
    <port>1516</port>
    <bind_addr>0.0.0.0</bind_addr>
    <nodes>
        <node>NODE_IP</node>
    </nodes>
    <hidden>no</hidden>
    <disabled>yes</disabled>
  </cluster>

</ossec_config>

<ossec_config>
  <localfile>
    <log_format>audit</log_format>
    <location>/var/log/audit/audit.log</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/ossec/logs/active-responses.log</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/messages</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/secure</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/maillog</location>
  </localfile>

</ossec_config>
EOF
