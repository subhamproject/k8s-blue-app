#!/usr/bin/env bash

[ $(sudo rpm -qa|grep jq|wc -l) -eq 0 ] && sudo yum install jq -y

TAG=${BRANCH_NAME}-$(python version.py) 
LATEST_TAG=${BRANCH_NAME}-latest
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
REPO=${GIT_URL##*/}
REPO=${REPO%.git}

grep 'region' ~/.aws/config > /dev/null 2>&1 || aws configure set default.region $REGION

REGISTRY="$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.${REGION}.amazonaws.com"
docker build -t $REGISTRY/$REPO:$TAG .
docker tag $REGISTRY/$REPO:$TAG  $REGISTRY/$REPO:$LATEST_TAG

