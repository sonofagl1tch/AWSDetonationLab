#!/bin/bash

#get VPC ID of AWS Detonation Lab
#aws ec2 describe-vpcs 
#--query 'Vpcs[?Tags[?Key==`Name`]|[?Value==`awsdetonationlab`]].VpcId' 
#----output text
vpcid=$(aws ec2 describe-vpcs --query 'Vpcs[?Tags[?Key==`Name`]|[?Value==`awsdetonationlab`]].VpcId' --output text)

#use vpcid from above to create a vpcflow log
#aws ec2 create-flow-logs 
#--resource-type VPC 
#--resource-ids $vpcid 
#--traffic-type ALL 
#--log-group-name awsDetonationLab-Flow 
#--deliver-logs-permission-arn arn:aws:iam::963894186934:role/VPC-Flow-Logs
aws ec2 create-flow-logs --resource-type VPC --resource-ids $vpcid --traffic-type ALL --log-group-name awsDetonationLab-Flow --deliver-logs-permission-arn arn:aws:iam::963894186934:role/VPC-Flow-Logs