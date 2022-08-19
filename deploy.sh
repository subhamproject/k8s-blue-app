#!/usr/bin/env bash

TAG=${BRANCH_NAME}-$(python version.py)
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
REPO=${GIT_URL##*/}
REPO=${REPO%.git}

CLUSTER=$(aws eks list-clusters --region $REGION --query clusters[0] --output text)

export KUBECONFIG=/tmp/kubeconfig && CLUSTER_ARN=$(aws eks --region $REGION describe-cluster --name $CLUSTER|jq -r '.cluster.arn')

if [[ $(kubectl config current-context) != "$CLUSTER_ARN" ]];then
export KUBECONFIG=/tmp/kubeconfig && aws eks update-kubeconfig --name $CLUSTER --region $REGION
else
echo "Skipping updating kube config - already exist"
fi

REGISTRY="$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.${REGION}.amazonaws.com"

export IMAGE_NAME="${REGISTRY}/${REPO}:${TAG}"
export DEPLOY_NAME="$(echo $REPO|cut -d'-' -f2-)"
export ACM_ARN="$(aws --region $REGION acm list-certificates|jq -r '.CertificateSummaryList[].CertificateArn')"


if kubectl get deploy $DEPLOY_NAME -o jsonpath="{..image}"  &> /dev/null;then
CURRENT_IMAGE=$(kubectl get deploy $DEPLOY_NAME -o jsonpath="{..image}" |xargs)
else
echo "No such Deployment with name $DEPLOY_NAME found - creating now"
fi


if [[ $CURRENT_IMAGE != $IMAGE_NAME ]];then
echo "Deploying image: $IMAGE_NAME"
envsubst < deployment.yaml |kubectl apply -f -
fi

if ! kubectl get svc ${DEPLOY_NAME}-service > /dev/null 2>&1 ;then
envsubst < service.yaml | kubectl apply -f -
fi


if ! kubectl get ingress ${DEPLOY_NAME}-ingress > /dev/null 2>&1 ;then
envsubst < ingress.yaml | kubectl apply -f -
fi
