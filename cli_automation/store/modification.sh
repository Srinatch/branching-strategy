#!/bin/bash

#./updateec2.sh "us-east-1" "vpc-0d042064853ae377c" "subnet-0388a25e301b2bb57" "sg-01d2edae5c94c0866" "hazarath" "ami-0ecb62995f68bb549" "t3.micro"

if [[ $# -ne 7 ]]; then
    echo "This script needs 7 arguments"
    echo ./reusableec2.sh "<region>" "<vpc-id>" "<subnet-id>" "<security-group-id>" "<key-name>" "<ami-id>" "<instance-type>"
    exit 1
fi

REGION=$1
#"us-east-1a"
AZ="${REGION}a"

# This script will not 
# create vpc, rather uses existing one
VPC_ID=$2
#"vpc-0d042064853ae377c"
# create subnet rather uses exiting one
SUBNET_ID=$3
#"subnet-0388a25e301b2bb57"
# create security groups rather uses existing
SECURITY_GROUP_IDS=$4
#"sg-01d2edae5c94c0866"
# create key pairs rather uses existing keys
KEY_NAME=$5
#"hazarath"

# will create ec2 instance of AMI of your choice
AMI_ID=$6
#"ami-0ecb62995f68bb549"
INSTANCE_TYPE=$7
#"t3.micro"

echo "aws ec2 run-instances \
    --instance-type ${INSTANCE_TYPE} \
    --key-name ${KEY_NAME} \
    --security-group-ids ${SECURITY_GROUP_IDS} \
    --subnet-id ${SUBNET_ID} \
    --image-id ${AMI_ID} \
    --region ${REGION}
"


# Create an ec2 instance
aws ec2 run-instances \
    --instance-type ${INSTANCE_TYPE} \
    --key-name ${KEY_NAME} \
    --security-group-ids ${SECURITY_GROUP_IDS} \
    --subnet-id ${SUBNET_ID} \
    --image-id ${AMI_ID}\
    --region ${REGION}
