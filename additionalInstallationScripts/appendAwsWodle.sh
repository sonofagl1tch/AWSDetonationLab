#!/bin/bash

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
    <bucket type="custom">
      <name>vpcflowlogging</name>
      <path>flowlogs</path>
      <access_key>insert_access_key</access_key>
      <secret_key>insert_secret_key</secret_key>
    </bucket>
  </wodle>
</ossec_config>
EOF