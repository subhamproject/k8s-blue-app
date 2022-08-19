#!/usr/bin/env bash

TAG=${BRANCH_NAME}-$(python version.py)
LATEST_TAG=${BRANCH_NAME}-latest
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
REPO=${GIT_URL##*/}
REPO=${REPO%.git}

grep 'region' ~/.aws/config > /dev/null 2>&1 || aws configure set default.region $REGION

REGISTRY="$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password | docker login -u AWS --password-stdin "https://$REGISTRY"
[ $? -eq 0 ] && docker push $REGISTRY/$REPO:$TAG && docker push $REGISTRY/$REPO:$LATEST_TAG
