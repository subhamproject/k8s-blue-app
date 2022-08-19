#!/bin/bash
#https://blog.omerh.me/post/2019/05/28/accessing-eks-from-ec2-instance-profile/

ACCOUNT_ID=$(aws sts get-caller-identity|jq -r '.Account')

cat > assume-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF


aws iam create-role --role-name full-eks-access-role \
  --description "Accessing all of account EKS cluster API endpoints" \
  --assume-role-policy-document file://assume-policy.json

cat > eks-full.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy --policy-name eks-full-access \
  --description "EKS Full access policy" \
  --policy-document file://eks-full.json


aws iam attach-role-policy --role-name full-eks-access-role \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/eks-full-access


aws iam create-instance-profile --instance-profile-name Jenkins

aws iam add-role-to-instance-profile --role-name full-eks-access-role --instance-profile-name Jenkins

aws ec2 associate-iam-instance-profile \
  --instance-id i-0b6a7addaeaac9916 \
  --iam-instance-profile Name=Jenkins \



eksctl create iamidentitymapping \
  --cluster eks-cluster  \
  --arn arn:aws:iam::707015264015:role/full-eks-access-role \
  --username jenkins \
  --group devops \
  --group system:masters

#curl -o aws-auth-cm.yaml https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/aws-auth-cm.yaml


# pip
#curl https://bootstrap.pypa.io/get-pip.py | sudo python3

# awscli
#sudo pip install --upgrade awscli

# kubectl - with an install script I made
#curl https://raw.githubusercontent.com/omerh/scripts/master/upgrade_kubectl.sh | sudo bash

# aws-iam-authenticator
#curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
#chmod +x ./aws-iam-authenticator
#sudo mv ./aws-iam-authenticator /usr/local/bin/


#aws eks --region <your region> update-kubeconfig --name <eks cluster name>


#kubectl get node
