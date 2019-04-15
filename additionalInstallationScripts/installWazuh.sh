#!/bin/bash
# install wazuh server
# Wazuh documentation - https://documentation.wazuh.com/current/installation-guide/installing-wazuh-server/index.html
#######################################

# Versions to install
ELASTIC_VERSION=6.6.1
WAZUH_VERSION=3.8
WAZUH_PATCH=$WAZUH_VERSION.2
WAZUH_PACKAGE=$WAZUH_PATCH-1
WAZUH_MANAGER_PKG="wazuh-manager"
WAZUH_API_PKG="wazuh-api"
ELASTIC_PKG="elasticsearch"
LOGSTASH_PKG="logstash"
KIBANA_PKG="kibana"

# Configuration variables
PKG_MANAGER=""
PKG_INSTALL=""
PKG_OPTIONS=""
OS_FAMILY=""
REPO_FILE=""

set_global_parameters() {
    if command -v apt-get > /dev/null 2>&1 ; then
        PKG_MANAGER="apt-get"
        PKG_OPTIONS="-y"
        OS_FAMILY="Debian"
        REPO_FILE="/etc/apt/sources.list.d/wazuh.list"
        ELASTIC_REPO_FILE="/etc/apt/sources.list.d/elastic-6.x.list"
        WAZUH_MANAGER_PKG="${WAZUH_MANAGER_PKG}=${WAZUH_PACKAGE}"
        WAZUH_API_PKG="${WAZUH_API_PKG}=${WAZUH_PACKAGE}"
        ELASTIC_PKG="${ELASTIC_PKG}=${ELASTIC_VERSION}"
        LOGSTASH_PKG="${LOGSTASH_PKG}=1:${ELASTIC_VERSION}-1"
        KIBANA_PKG="${KIBANA_PKG}=${ELASTIC_VERSION}"

    elif command -v yum > /dev/null 2>&1 ; then
        PKG_MANAGER="yum"
        PKG_OPTIONS="-y -q -e 0"
        OS_FAMILY="RHEL"
        REPO_FILE="/etc/yum.repos.d/wazuh.repo"
        ELASTIC_REPO_FILE="/etc/yum.repos.d/elastic.repo"
        WAZUH_MANAGER_PKG="${WAZUH_MANAGER_PKG}-${WAZUH_PACKAGE}"
        WAZUH_API_PKG="${WAZUH_API_PKG}-${WAZUH_PACKAGE}"
        ELASTIC_PKG="${ELASTIC_PKG}-${ELASTIC_VERSION}"
        LOGSTASH_PKG="${LOGSTASH_PKG}-${ELASTIC_VERSION}"
        KIBANA_PKG="${KIBANA_PKG}-${ELASTIC_VERSION}"
    elif command -v zypper > /dev/null 2>&1 ; then
        PKG_MANAGER="zypper"
        PKG_OPTIONS="-y -l"
        OS_FAMILY="SUSE"
        REPO_FILE="/etc/zypp/repos.d/wazuh.repo"
        ELASTIC_REPO_FILE="/etc/zypp/repos.d/elastic.repo"
        WAZUH_MANAGER_PKG="${WAZUH_MANAGER_PKG}-${WAZUH_PACKAGE}"
        WAZUH_API_PKG="${WAZUH_API_PKG}-${WAZUH_PACKAGE}"
        ELASTIC_PKG="${ELASTIC_PKG}-${ELASTIC_VERSION}"
        LOGSTASH_PKG="${LOGSTASH_PKG}-${ELASTIC_VERSION}"
        KIBANA_PKG="${KIBANA_PKG}-${ELASTIC_VERSION}"
    fi

    PKG_INSTALL="${PKG_MANAGER} install"

    return 0
}

install_dependencies() {
    ## RHEL/CentOS/Fedora/Amazon/SUSE based OS
    if [ "${OS_FAMILY}" == "RHEL" ] || [ "${OS_FAMILY}" == "SUSE" ]; then
        ${PKG_INSTALL} ${PKG_OPTIONS} openssl wget python-pip
    ## Debian/Ubuntu based OS
    else
        ${PKG_MANAGER} update
        ${PKG_INSTALL} ${PKG_OPTIONS} curl apt-transport-https lsb-release \
        openssl software-properties-common dirmngr python-pip
    fi
    pip install boto3 requests
}

add_nodejs_repository() {
  if [ "${OS_FAMILY}" == "RHEL" ]; then
    curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
  elif [ "${OS_FAMILY}" == "SUSE" ]; then
    ${PKG_MANAGER} addrepo http://download.opensuse.org/distribution/leap/15.0/repo/oss/ node8
    ${PKG_MANAGER} --gpg-auto-import-keys refresh
  else
    curl -sL https://deb.nodesource.com/setup_8.x | bash -
  fi
}

add_wazuh_repository() {
    # Add Wazuh Repository
    ## RHEL/CentOS/Fedora/Amazon/SUSE based OS
    if [ "${OS_FAMILY}" == "RHEL" ] || [ "${OS_FAMILY}" == "SUSE" ]; then
        rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
        echo -ne "[wazuh_repo]\ngpgcheck=1\ngpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=Wazuh epository\nbaseurl=https://packages.wazuh.com/3.x/yum/\nprotect=1" > ${REPO_FILE}

    ## Debian/Ubuntu based OS
    else
        curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
        echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee -a ${REPO_FILE}
        ${PKG_MANAGER} update
    fi
}

install_wazuh() {
    # Install the Wazuh Manager and enable integrator module
    ${PKG_INSTALL} ${PKG_OPTIONS} ${WAZUH_MANAGER_PKG}
    # The auth module only needs to be enabled in
    # versions prior to v3.8.0
    if [[ ${WAZUH_VERSION} < "3.8" ]]; then
        /var/ossec/bin/ossec-control enable auth
    fi
    /var/ossec/bin/ossec-control enable integrator

    # Restart the Wazuh Manager
    ## Check for systemd
    if command -v systemctl >/dev/null; then
        systemctl restart wazuh-manager > /dev/null 2>&1
    ## Check for SysV
    elif command -v service >/dev/null; then
        service wazuh-manager restart > /dev/null 2>&1
    ## Check for upstart
    elif command -v update-rc.d >/dev/null; then
        ## Check for RHEL based OS
        if [ -f /etc/rc.d/init.d/wazuh-manager ]; then
            /etc/init.d/wazuh-manager restart > /dev/null 2>&1
        ## Check for SUSE
        elif [ -f /etc/init.d/wazuh-manager ]; then
            /etc/rc.d/init.d/wazuh-manager restart > /dev/null 2>&1
        fi
    fi

    # Install NodeJS and Wazuh API
    ${PKG_INSTALL} ${PKG_OPTIONS} nodejs
    ${PKG_INSTALL} ${PKG_OPTIONS} ${WAZUH_API_PKG}
}

add_aws_config() {
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
    <service type="inspector">
        <access_key>insert_access_key</access_key>
        <secret_key>insert_secret_key</secret_key>
    </service>
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
}

add_custom_rules() {
    # This rules will silent the alerts from non malware files
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
}

setup_agent_fim() {
    # Configure real time monitoring in:
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
}

setup_wazuh_api() {
    cd /var/ossec/api/configuration/auth
    node htpasswd -c user wazuh -b wazuh
    # Restart the Wazuh Manager
    ## Check for systemd
    if command -v systemctl >/dev/null; then
        systemctl restart wazuh-api > /dev/null 2>&1
    ## Check for SysV
    elif command -v service >/dev/null; then
        service wazuh-api restart > /dev/null 2>&1
    ## Check for upstart
    elif command -v update-rc.d >/dev/null; then
        ## Check for RHEL based OS
        if [ -f /etc/rc.d/init.d/wazuh-api ]; then
            /etc/init.d/wazuh-api restart > /dev/null 2>&1
        ## Check for SUSE
        elif [ -f /etc/init.d/wazuh-api ]; then
            /etc/rc.d/init.d/wazuh-api restart > /dev/null 2>&1
        fi
    fi
}

add_custom_config() {
    add_aws_config
    add_custom_rules
    setup_agent_fim
}

install_java() {
    ## RHEL/CentOS/Fedora based OS
    if [ "${OS_FAMILY}" == "RHEL" ] || [ "${OS_FAMILY}" == "SUSE" ]; then
        ## install Oracle Java JRE 8
        wget --no-check-certificate -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://javadl.oracle.com/webapps/download/AutoDL?BundleId=235716_2787e4a523244c269598db4e85c51e0c -O jre-8u191-linux-x64.rpm

        ## install the RPM package using yum
        ${PKG_INSTALL} ${PKG_OPTIONS} jre-8u191-linux-x64.rpm
    else
        ${PKG_MANAGER} update
        ${PKG_INSTALL} ${PKG_OPTIONS} openjdk-8-jre
    fi
}

add_elastic_repository() {
    ## RHEL/CentOS/Fedora based OS
    if [ "${OS_FAMILY}" == "RHEL" ] || [ "${OS_FAMILY}" == "SUSE" ]; then
        ## Install the Elastic repository and its GPG key
        rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
        echo -ne "[elasticsearch-6.x]\nname=Elasticsearch repository for 6.x packages\nbaseurl=https://artifacts.elastic.co/packages/6.x/yum\ngpgcheck=1\ngpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch\nenabled=1\nautorefresh=1\ntype=rpm-md" > ${ELASTIC_REPO_FILE}

    ## Debian/Ubuntu based OS
    else
        curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
        echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee -a ${ELASTIC_REPO_FILE}
        ${PKG_MANAGER} update
    fi
}

wait_elastic_component() {
    query="$@"
    until ${query}; do
    >&2 echo "Elastic component is unavailable - sleeping for 5 seconds"
    sleep 5
    done
    >&2 echo "Elastic component is up - executing commands"
}

install_elastic() {
    # Install elasticsearch package and enable its service
    ${PKG_INSTALL} ${PKG_OPTIONS} ${ELASTIC_PKG}
    # Set up network.host value in elasticsearch configuration file
    sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml
    # Enable and start Elasticsearch service
    ## Check for systemd
    if command -v systemctl >/dev/null; then
        systemctl daemon-reload > /dev/null 2>&1
        systemctl enable elasticsearch.service > /dev/null 2>&1
        systemctl start elasticsearch.service > /dev/null 2>&1
    ## Check for SysV
    elif command -v service >/dev/null; then
        chkconfig --add elasticsearch > /dev/null 2>&1
        chkconfig elasticsearch on > /dev/null 2>&1
        service elasticsearch start > /dev/null 2>&1
    fi

    # Wait until elasticsearch comes up before continuing
    ES_URL=${ES_URL:-'http://localhost:9200'}
    ES_USER=${ES_USER:-kibana}
    ES_PASSWORD=${ES_PASSWORD:-changeme}
    ES_QUERY="curl -u ${ES_USER}:${ES_PASSWORD} -XGET ${ES_URL}"
    wait_elastic_component ${ES_QUERY}
    # Load the Wazuh template for Elasticsearch
    curl https://raw.githubusercontent.com/wazuh/wazuh/$WAZUH_VERSION/extensions/elasticsearch/wazuh-elastic6-template-alerts.json | curl -XPUT 'http://localhost:9200/_template/wazuh' -H 'Content-Type: application/json' -d @-
}

install_logstash() {
    ${PKG_INSTALL} ${PKG_OPTIONS} ${LOGSTASH_PKG}

    ## Download the Wazuh configuration file for Logstash
    ## Local configuration (only in a single-host architecture)
    curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/$WAZUH_VERSION/extensions/logstash/01-wazuh-local.conf

    ## Because the Logstash user needs to read the alerts.json file, please add it to OSSEC group by running
    usermod -a -G ossec logstash

    # Enable and start Logstash service
    ## Check for systemd
    if command -v systemctl >/dev/null; then
        systemctl daemon-reload > /dev/null 2>&1
        systemctl enable logstash.service > /dev/null 2>&1
        systemctl start logstash.service > /dev/null 2>&1
    ## Check for SysV
    elif command -v service >/dev/null; then
        ## Follow the next steps if you use CentOS-6/RHEL-6 or Amazon AMI (logstash uses Upstart like a service manager and needs to be fixed, see this bug):
        ## Edit the file /etc/logstash/startup.options changing line 30 from LS_GROUP=logstash to LS_GROUP=ossec.
        sed -i 's/LS_GROUP=logstash/LS_GROUP=ossec/' /etc/logstash/startup.options
        ## Update the service with the new parameters by running the command /usr/share/logstash/bin/system-install
        /usr/share/logstash/bin/system-install
        ## Force install a SysV init script by running: /usr/share/logstash/bin/system-install /etc/logstash/startup.options sysv as root
        /usr/share/logstash/bin/system-install /etc/logstash/startup.options sysv
        ## Enable and start Logstash
        chkconfig --add logstash > /dev/null 2>&1
        chkconfig logstash on > /dev/null 2>&1
        service logstash start > /dev/null 2>&1
    fi
}

install_kibana() {
    # install Kibana
    ${PKG_INSTALL} ${PKG_OPTIONS} ${KIBANA_PKG}

    ## Install the Wazuh App plugin for Kibana
    sudo -u kibana NODE_OPTIONS="--max-old-space-size=3072" /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-$(echo $WAZUH_PATCH)_$(echo $ELASTIC_VERSION).zip

    ##  Kibana will only listen on the loopback interface (localhost) by default. To set up Kibana to listen on all interfaces, edit the file /etc/kibana/kibana.yml uncommenting the setting server.host. Change the value to:
    sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml

    # Enable and start Kibana service
    ## Check for systemd
    if command -v systemctl >/dev/null; then
        systemctl daemon-reload > /dev/null 2>&1
        systemctl enable kibana.service > /dev/null 2>&1
        systemctl start kibana.service > /dev/null 2>&1
    ## Check for SysV
    elif command -v service >/dev/null; then
        chkconfig --add kibana > /dev/null 2>&1
        chkconfig kibana on > /dev/null 2>&1
        service kibana start > /dev/null 2>&1
    fi
}

disable_elastic_repository() {
    # Disable the Elasticsearch repository
    # It is recommended that the Elasticsearch repository be disabled in order to prevent an upgrade to a newer Elastic Stack version due to the possibility of undoing changes with the App.

    ## RHEL/CentOS/Fedora based OS
    if [ "${OS_FAMILY}" == "RHEL" ] || [ "${OS_FAMILY}" == "SUSE" ]; then
        sed -i "s/^enabled=1/enabled=0/" ${ELASTIC_REPO_FILE}
    else
        sed -i "s/^deb/#deb/" ${ELASTIC_REPO_FILE}
        ${PKG_MANAGER} update
    fi
}

configure_wazuh_api() {
    # Set up Wazuh API parameters
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
    ES_QUERY="curl -u ${ES_USER}:${ES_PASSWORD} -XGET ${ES_URL}"
    # Wait until Elasticsearch is up and running.
    wait_elastic_component "${ES_QUERY}"
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
    wait_elastic_component ${ES_QUERY}
}

configure_kibana() {
    # Kibana settings
    KIBANA_BASE_URL='localhost:5601'
    KIBANA_USER='elastic'
    KIBANA_PASSWORD='changeme'

    check_kibana_service_availability="curl -u ${KIBANA_USER}:${KIBANA_PASSWORD} -XGET ${KIBANA_BASE_URL}"

    # Wait until Kibana service is avilable.
    wait_elastic_component "${check_kibana_service_availability}"
    check_kibana_status="${check_kibana_service_availability} --fail"
    wait_elastic_component "${check_kibana_status}"
    echo "Kibana is up"

    KIBANA_INDEX_URL="${KIBANA_BASE_URL}/api/kibana/settings/defaultIndex"

    # Set default kibana index to wazuh alerts
    curl --fail -X POST -H "Content-Type: application/json" -H "kbn-xsrf: true" -d '{"value":"wazuh-alerts-3.x-*"}' "http://${KIBANA_USER}:${KIBANA_PASSWORD}@${KIBANA_INDEX_URL}"

    # Import AWS Detonation lab dashboards
    KIBANA_DASHBOARDS_URL="${KIBANA_BASE_URL}/api/kibana/dashboards/import"
    curl -sO https://raw.githubusercontent.com/sonofagl1tch/AWSDetonationLab/master/KibanaAdditionalConfigs/Kibana-Visualizations.json
    curl -sO https://raw.githubusercontent.com/sonofagl1tch/AWSDetonationLab/master/KibanaAdditionalConfigs/Kibana-Dashboard.json
    curl -X POST -H "Content-Type: application/json" -H "kbn-xsrf: true" "http://${KIBANA_USER}:${KIBANA_PASSWORD}@${KIBANA_DASHBOARDS_URL}" -d @Kibana-Dashboard.json
    curl -X POST -H "Content-Type: application/json" -H "kbn-xsrf: true" "http://${KIBANA_USER}:${KIBANA_PASSWORD}@${KIBANA_DASHBOARDS_URL}" -d @Kibana-Visualizations.json
}

main() {
    set_global_parameters
    install_dependencies
    add_nodejs_repository
    add_wazuh_repository
    install_wazuh
    setup_wazuh_api
    add_custom_config
    install_java
    add_elastic_repository
    install_elastic
    install_logstash
    install_kibana
    disable_elastic_repository
    configure_wazuh_api
    configure_kibana
}

main

#######################################
# next steps is to configure wazuh
## https://documentation.wazuh.com/current/installation-guide/installing-elastic-stack/connect_wazuh_app.html
