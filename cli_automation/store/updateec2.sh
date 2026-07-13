
#./updateec2.sh "us-east-1" "vpc-0d042064853ae377c" "subnet-0388a25e301b2bb57" "sg-01d2edae5c94c0866" "hazarath" "ami-0ecb62995f68bb549" "t3.micro"

# if [[ $# -ne 7 ]]; then
#     echo "This script needs 7 arguments"
#     echo ./reusableec2.sh "<region>" "<vpc-id>" "<subnet-id>" "<security-group-id>" "<key-name>" "<ami-id>" "<instance-type>"
#     exit 1
# fi

# --region
REGION="us-east-1"


# This script will not
# --vpc-id
VPC_ID="vpc-0d042064853ae377c"
# --subnet-id
SUBNET_ID="subnet-0388a25e301b2bb57"
# --sg-ids
SECURITY_GROUP_IDS="sg-01d2edae5c94c0866"
# --key-name
KEY_NAME="hazarath"
## --ami
AMI_ID="ami-0ecb62995f68bb549"
## --instance-type
INSTANCE_TYPE="t3.micro"

while [[ $# -ne 0 ]]; do
    case "$1" in
        --region)
            REGION=$2
            shift
            shift
            ;;
        --vpc-id)
            VPC_ID=$2
            shift
            shift
            ;;
        --subnet-id)
            SUBNET_ID=$2
            shift
            shift
            ;;
        --sg-ids)
            SECURITY_GROUP_IDS="$2"
            shift
            shift
            ;;
        --key-name)
            KEY_NAME=$2
            shift
            shift
            ;;
        --ami)
            AMI_ID=$2
            shift
            shift
            ;;
        --instance-type)
            INSTANCE_TYPE=$2
            shift
            shift
            ;;

        *)
            echo "Usage:updateec2.sh --region <region-value> --vpc-id <your-vpc-id> --subnet-id <your-subnet-id>"
            exit 0
            ;;
esac

done
AZ="${REGION}a"

echo "aws ec2 run-instances \
    --instance-type ${INSTANCE_TYPE} \
    --key-name ${KEY_NAME} \
    --security-group-ids ${SECURITY_GROUP_IDS} \
    --subnet-id ${SUBNET_ID} \
    --image-id ${AMI_ID} \
    --region ${REGION} \
"


 # Create an ec2 instance
aws ec2 run-instances \
    --instance-type ${INSTANCE_TYPE} \
    --key-name ${KEY_NAME} \
    --security-group-ids ${SECURITY_GROUP_IDS} \
    --subnet-id ${SUBNET_ID} \
    --image-id ${AMI_ID} \
    --region ${REGION}
