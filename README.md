# Deployment Guide: Multi-Tenant Application on AWS with Flask and Citus

A complete step-by-step guide to deploy a scalable, distributed multi-tenant application using Flask and Citus (PostgreSQL) on AWS infrastructure.

---

## 📚 Overview

This guide walks you through:

- Setting up a secure VPC architecture
- Launching EC2 instances for application and database layers
- Configuring an Internet-facing Load Balancer
- Initializing Docker-based services for Flask and Citus
- Testing endpoints using `curl`
- Accessing internal components securely via a Bastion Host

---

## 📑 Index

1. **System Overview**
2. **AWS Architecture Design**
3. **Prerequisites**
4. **Configuring AWS CLI**
5. **Step-by-Step Setup**
   - VPC & Subnet Setup
   - EC2 & Key Pair Configuration
   - Load Balancer Setup
6. **SSH Access to Instances**
7. **Citus Worker Setup**
8. **Citus Master Setup**
9. **Flask Application Setup**
10. **Testing the Application**
11. **API Testing with `curl`**

---

## 🧩 System Overview

The system is a multi-tier distributed application with the following components:

- **Frontend Gateway:** Application Load Balancer (HTTP listener)
- **Web App:** Flask (Dockerized, Private Subnet)
- **Database Layer:** Citus (Master + Worker Nodes)
- **Security Layer:** Bastion Host (for private instance access)
- **Networking:** Custom VPC with isolated public and private subnets

---

## 🗺️ AWS Architecture Design

![AWS Architecture Diagram](https://github.com/Bahar0900/Deployement-of-Multitenant-Application-on-AWS/blob/202bc538dc1422559f97476c93c0c3544cd7fdc3/images/AWSAPP.drawio.svg)

### VPC Details

| Component | CIDR Block | AZ | Notes |
|----------|------------|----|-------|
| Public Subnet A | `10.0.1.0/24` | `us-east-1a` | NAT, ALB |
| Public Subnet B | `10.0.2.0/24` | `us-east-1b` | Bastion Host |
| Private Subnet A | `10.0.3.0/24` | `us-east-1a` | Flask App |
| Private Subnet B | `10.0.4.0/24` | `us-east-1b` | Citus Master |
| Private Subnet C | `10.0.5.0/24` | `us-east-1c` | Citus Worker |

- Internet Gateway: Attached to VPC
- NAT Gateway: Located in Public Subnet A
- Route Tables: Public and Private

### Security Groups Summary

| Group | Inbound | Outbound |
|-------|---------|----------|
| Load Balancer | HTTP/HTTPS from all | HTTP (5000) to Flask |
| Bastion Host | SSH from your IP | SSH to internal |
| Flask App | HTTP from LB, SSH from Bastion | PostgreSQL to Citus |
| Citus Master | PostgreSQL from Flask & Worker, SSH from Bastion | PostgreSQL to Worker |
| Citus Worker | PostgreSQL from Master, SSH from Bastion | PostgreSQL to Master |

---

## 🛠️ Prerequisites

- ✅ AWS Account with CLI credentials
- ✅ AWS CLI Installed
- ✅ SSH Key Pair
- ✅ WSL or Git Bash (for script execution)
- ✅ Git Installed

---

## ⚙️ Configuring AWS CLI

```bash
aws configure
```

Respond to prompts:

- **Access Key ID**: From AWS Console
- **Secret Key**: From AWS Console
- **Region**: `ap-southeast-1`
- **Output Format**: `json` (or your preference)

---

## 🧱 Infrastructure Setup

### 🔨 Step 1: Create VPC

1. Save the VPC setup script to a file called `vpcconfigure.txt`. Paste the given content there and save it.
```bash
#!/bin/bash

# Set variables
REGION="ap-southeast-1"
VPC_CIDR="10.0.0.0/16"
YOUR_IP="103.151.130.65/32"

echo "Creating VPC infrastructure..."

# Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.VpcId' --output text --region $REGION)
if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
    echo "Failed to create VPC"
    exit 1
fi
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=MyAppVPC --region $REGION
echo "VPC created: $VPC_ID"

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text --region $REGION)
if [ -z "$IGW_ID" ] || [ "$IGW_ID" == "None" ]; then
    echo "Failed to create Internet Gateway"
    exit 1
fi
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=MyAppIGW --region $REGION
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region $REGION
echo "Internet Gateway created: $IGW_ID"

# Create Subnets with correct availability zones for ap-southeast-1
PUBLIC_A_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone ap-southeast-1a --query 'Subnet.SubnetId' --output text --region $REGION)
if [ -z "$PUBLIC_A_ID" ] || [ "$PUBLIC_A_ID" == "None" ]; then
    echo "Failed to create Public Subnet A"
    exit 1
fi
aws ec2 create-tags --resources $PUBLIC_A_ID --tags Key=Name,Value=PublicSubnetA --region $REGION

PUBLIC_B_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone ap-southeast-1b --query 'Subnet.SubnetId' --output text --region $REGION)
if [ -z "$PUBLIC_B_ID" ] || [ "$PUBLIC_B_ID" == "None" ]; then
    echo "Failed to create Public Subnet B"
    exit 1
fi
aws ec2 create-tags --resources $PUBLIC_B_ID --tags Key=Name,Value=PublicSubnetB --region $REGION

PRIVATE_A_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --availability-zone ap-southeast-1a --query 'Subnet.SubnetId' --output text --region $REGION)
if [ -z "$PRIVATE_A_ID" ] || [ "$PRIVATE_A_ID" == "None" ]; then
    echo "Failed to create Private Subnet A"
    exit 1
fi
aws ec2 create-tags --resources $PRIVATE_A_ID --tags Key=Name,Value=PrivateSubnetA --region $REGION

PRIVATE_B_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 --availability-zone ap-southeast-1b --query 'Subnet.SubnetId' --output text --region $REGION)
if [ -z "$PRIVATE_B_ID" ] || [ "$PRIVATE_B_ID" == "None" ]; then
    echo "Failed to create Private Subnet B"
    exit 1
fi
aws ec2 create-tags --resources $PRIVATE_B_ID --tags Key=Name,Value=PrivateSubnetB --region $REGION

PRIVATE_C_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.5.0/24 --availability-zone ap-southeast-1c --query 'Subnet.SubnetId' --output text --region $REGION)
if [ -z "$PRIVATE_C_ID" ] || [ "$PRIVATE_C_ID" == "None" ]; then
    echo "Failed to create Private Subnet C"
    exit 1
fi
aws ec2 create-tags --resources $PRIVATE_C_ID --tags Key=Name,Value=PrivateSubnetC --region $REGION

echo "Subnets created successfully"

# Create NAT Gateway
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text --region $REGION)
if [ -z "$EIP_ALLOC" ] || [ "$EIP_ALLOC" == "None" ]; then
    echo "Failed to allocate Elastic IP"
    exit 1
fi

NAT_ID=$(aws ec2 create-nat-gateway --subnet-id $PUBLIC_A_ID --allocation-id $EIP_ALLOC --query 'NatGateway.NatGatewayId' --output text --region $REGION)
if [ -z "$NAT_ID" ] || [ "$NAT_ID" == "None" ]; then
    echo "Failed to create NAT Gateway"
    exit 1
fi
aws ec2 create-tags --resources $NAT_ID --tags Key=Name,Value=MyAppNAT --region $REGION
echo "NAT Gateway created: $NAT_ID"

# Wait for NAT Gateway to be available
echo "Waiting for NAT Gateway to be available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_ID --region $REGION

# Create Route Tables
PUBLIC_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text --region $REGION)
if [ -z "$PUBLIC_RT_ID" ] || [ "$PUBLIC_RT_ID" == "None" ]; then
    echo "Failed to create Public Route Table"
    exit 1
fi
aws ec2 create-tags --resources $PUBLIC_RT_ID --tags Key=Name,Value=PublicRouteTable --region $REGION

PRIVATE_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text --region $REGION)
if [ -z "$PRIVATE_RT_ID" ] || [ "$PRIVATE_RT_ID" == "None" ]; then
    echo "Failed to create Private Route Table"
    exit 1
fi
aws ec2 create-tags --resources $PRIVATE_RT_ID --tags Key=Name,Value=PrivateRouteTable --region $REGION

# Create Routes
aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION
aws ec2 create-route --route-table-id $PRIVATE_RT_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_ID --region $REGION

# Associate Route Tables
aws ec2 associate-route-table --subnet-id $PUBLIC_A_ID --route-table-id $PUBLIC_RT_ID --region $REGION
aws ec2 associate-route-table --subnet-id $PUBLIC_B_ID --route-table-id $PUBLIC_RT_ID --region $REGION
aws ec2 associate-route-table --subnet-id $PRIVATE_A_ID --route-table-id $PRIVATE_RT_ID --region $REGION
aws ec2 associate-route-table --subnet-id $PRIVATE_B_ID --route-table-id $PRIVATE_RT_ID --region $REGION
aws ec2 associate-route-table --subnet-id $PRIVATE_C_ID --route-table-id $PRIVATE_RT_ID --region $REGION

echo "Route tables configured"

# Create Security Groups
LB_SG_ID=$(aws ec2 create-security-group --group-name security-load-balancer --description "Load Balancer Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text --region $REGION)
if [ -z "$LB_SG_ID" ] || [ "$LB_SG_ID" == "None" ]; then
    echo "Failed to create Load Balancer Security Group"
    exit 1
fi

BASTION_SG_ID=$(aws ec2 create-security-group --group-name security-bastion --description "Bastion Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text --region $REGION)
if [ -z "$BASTION_SG_ID" ] || [ "$BASTION_SG_ID" == "None" ]; then
    echo "Failed to create Bastion Security Group"
    exit 1
fi

FLASK_SG_ID=$(aws ec2 create-security-group --group-name security-flask-app --description "Flask App Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text --region $REGION)
if [ -z "$FLASK_SG_ID" ] || [ "$FLASK_SG_ID" == "None" ]; then
    echo "Failed to create Flask App Security Group"
    exit 1
fi

CITUS_MASTER_SG_ID=$(aws ec2 create-security-group --group-name security-citus-master --description "Citus Master Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text --region $REGION)
if [ -z "$CITUS_MASTER_SG_ID" ] || [ "$CITUS_MASTER_SG_ID" == "None" ]; then
    echo "Failed to create Citus Master Security Group"
    exit 1
fi

CITUS_WORKER_SG_ID=$(aws ec2 create-security-group --group-name security-citus-worker --description "Citus Worker Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text --region $REGION)
if [ -z "$CITUS_WORKER_SG_ID" ] || [ "$CITUS_WORKER_SG_ID" == "None" ]; then
    echo "Failed to create Citus Worker Security Group"
    exit 1
fi

echo "Security groups created"

# Configure Security Group Rules
echo "Configuring security group rules..."

# Load Balancer SG
aws ec2 authorize-security-group-ingress --group-id $LB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $LB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $REGION

# Bastion SG
aws ec2 authorize-security-group-ingress --group-id $BASTION_SG_ID --protocol tcp --port 22 --cidr $YOUR_IP --region $REGION

# Flask App SG
aws ec2 authorize-security-group-ingress --group-id $FLASK_SG_ID --protocol tcp --port 5000 --source-group $LB_SG_ID --region $REGION
aws ec2 authorize-security-group-ingress --group-id $FLASK_SG_ID --protocol tcp --port 22 --source-group $BASTION_SG_ID --region $REGION

# Citus Master SG
aws ec2 authorize-security-group-ingress --group-id $CITUS_MASTER_SG_ID --protocol tcp --port 5432 --source-group $FLASK_SG_ID --region $REGION
aws ec2 authorize-security-group-ingress --group-id $CITUS_MASTER_SG_ID --protocol tcp --port 5432 --source-group $CITUS_WORKER_SG_ID --region $REGION
aws ec2 authorize-security-group-ingress --group-id $CITUS_MASTER_SG_ID --protocol tcp --port 22 --source-group $BASTION_SG_ID --region $REGION

# Citus Worker SG
aws ec2 authorize-security-group-ingress --group-id $CITUS_WORKER_SG_ID --protocol tcp --port 5432 --source-group $CITUS_MASTER_SG_ID --region $REGION
aws ec2 authorize-security-group-ingress --group-id $CITUS_WORKER_SG_ID --protocol tcp --port 22 --source-group $BASTION_SG_ID --region $REGION

echo "Security group rules configured successfully"

# Output important IDs
echo ""
echo "=== SETUP COMPLETE ==="
echo "Region: $REGION"
echo "VPC ID: $VPC_ID"
echo "Internet Gateway ID: $IGW_ID"
echo ""
echo "=== SUBNETS ==="
echo "Public Subnet A (ap-southeast-1a): $PUBLIC_A_ID"
echo "Public Subnet B (ap-southeast-1b): $PUBLIC_B_ID"
echo "Private Subnet A (ap-southeast-1a): $PRIVATE_A_ID"
echo "Private Subnet B (ap-southeast-1b): $PRIVATE_B_ID"
echo "Private Subnet C (ap-southeast-1c): $PRIVATE_C_ID"
echo ""
echo "=== NETWORKING ==="
echo "NAT Gateway ID: $NAT_ID"
echo "Public Route Table ID: $PUBLIC_RT_ID"
echo "Private Route Table ID: $PRIVATE_RT_ID"
echo ""
echo "=== SECURITY GROUPS ==="
echo "Load Balancer SG: $LB_SG_ID"
echo "Bastion SG: $BASTION_SG_ID"
echo "Flask App SG: $FLASK_SG_ID"
echo "Citus Master SG: $CITUS_MASTER_SG_ID"
echo "Citus Worker SG: $CITUS_WORKER_SG_ID"
echo ""
echo "Infrastructure setup completed successfully!"
```
3. Make it executable:

```bash
chmod +x vpcconfigure.txt
```

3. Run it:

```bash
./vpcconfigure.txt
```

> This script sets up the VPC, subnets, route tables, NAT gateway, and all required security groups.

---

## 🚀 Launching EC2 & Load Balancer

### 🔨 Step 2: Launch EC2 Instances

1. Create a file `EC2instances.txt` and paste the EC2 deployment script.
```bash
  #!/bin/bash

# Prevent Git Bash path conversion on Windows
export MSYS_NO_PATHCONV=1

# Set variables
REGION="ap-southeast-1"
INSTANCE_TYPE="t2.micro"
AMI_ID="ami-047126e50991d067b"  # Ubuntu 20.04 LTS for ap-southeast-1
KEY_NAME="autogenerated-myapp-keypair"
PC_DIRECTORY="C:\poriditasks\flastcitusapp"  # Change this to your PC directory path

# User data script for private subnet instances
USER_DATA=$(cat <<'EOF'
#!/bin/bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
newgrp docker

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
EOF
)

# Encode user data to base64
USER_DATA_B64=$(echo "$USER_DATA" | base64 -w 0)

echo "Starting EC2 instances and ALB setup..."

# Get the VPC and subnet IDs from the previous script output
# You should replace these with actual IDs from your infrastructure setup
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=MyAppVPC" --query 'Vpcs[0].VpcId' --output text --region $REGION)
PUBLIC_B_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PublicSubnetB" --query 'Subnets[0].SubnetId' --output text --region $REGION)
PRIVATE_A_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PrivateSubnetA" --query 'Subnets[0].SubnetId' --output text --region $REGION)
PRIVATE_B_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PrivateSubnetB" --query 'Subnets[0].SubnetId' --output text --region $REGION)
PRIVATE_C_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PrivateSubnetC" --query 'Subnets[0].SubnetId' --output text --region $REGION)
PUBLIC_A_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PublicSubnetA" --query 'Subnets[0].SubnetId' --output text --region $REGION)

# Get Security Group IDs
BASTION_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=security-bastion" --query 'SecurityGroups[0].GroupId' --output text --region $REGION)
FLASK_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=security-flask-app" --query 'SecurityGroups[0].GroupId' --output text --region $REGION)
CITUS_MASTER_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=security-citus-master" --query 'SecurityGroups[0].GroupId' --output text --region $REGION)
CITUS_WORKER_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=security-citus-worker" --query 'SecurityGroups[0].GroupId' --output text --region $REGION)
LB_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=security-load-balancer" --query 'SecurityGroups[0].GroupId' --output text --region $REGION)

echo "Retrieved infrastructure IDs"
echo "VPC ID: $VPC_ID"

# Create Key Pair (only if it doesn't exist)
if ! aws ec2 describe-key-pairs --key-names $KEY_NAME --region $REGION >/dev/null 2>&1; then
    echo "Creating key pair: $KEY_NAME"
    aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text --region $REGION > "${PC_DIRECTORY}/${KEY_NAME}.pem"
    chmod 400 "${PC_DIRECTORY}/${KEY_NAME}.pem"
    echo "Key pair saved to: ${PC_DIRECTORY}/${KEY_NAME}.pem"
else
    echo "Key pair $KEY_NAME already exists"
fi

echo "Launching EC2 instances..."

# 1. Launch Bastion Host in Public Subnet B
echo "Launching Bastion Host..."
BASTION_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $BASTION_SG_ID \
    --subnet-id $PUBLIC_B_ID \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Bastion-Host}]' \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region $REGION)

if [ -z "$BASTION_INSTANCE_ID" ] || [ "$BASTION_INSTANCE_ID" == "None" ]; then
    echo "Failed to launch Bastion Host"
    exit 1
fi
echo "Bastion Host launched: $BASTION_INSTANCE_ID"

# 2. Launch Flask App in Private Subnet A
echo "Launching Flask App..."
FLASK_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $FLASK_SG_ID \
    --subnet-id $PRIVATE_A_ID \
    --no-associate-public-ip-address \
    --user-data "$USER_DATA_B64" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Flask-App}]' \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region $REGION)

if [ -z "$FLASK_INSTANCE_ID" ] || [ "$FLASK_INSTANCE_ID" == "None" ]; then
    echo "Failed to launch Flask App"
    exit 1
fi
echo "Flask App launched: $FLASK_INSTANCE_ID"

# 3. Launch Citus Master in Private Subnet B
echo "Launching Citus Master..."
CITUS_MASTER_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $CITUS_MASTER_SG_ID \
    --subnet-id $PRIVATE_B_ID \
    --no-associate-public-ip-address \
    --user-data "$USER_DATA_B64" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Citus-Master}]' \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region $REGION)

if [ -z "$CITUS_MASTER_INSTANCE_ID" ] || [ "$CITUS_MASTER_INSTANCE_ID" == "None" ]; then
    echo "Failed to launch Citus Master"
    exit 1
fi
echo "Citus Master launched: $CITUS_MASTER_INSTANCE_ID"

# 4. Launch Citus Worker in Private Subnet C
echo "Launching Citus Worker..."
CITUS_WORKER_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $CITUS_WORKER_SG_ID \
    --subnet-id $PRIVATE_C_ID \
    --no-associate-public-ip-address \
    --user-data "$USER_DATA_B64" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Citus-Worker}]' \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region $REGION)

if [ -z "$CITUS_WORKER_INSTANCE_ID" ] || [ "$CITUS_WORKER_INSTANCE_ID" == "None" ]; then
    echo "Failed to launch Citus Worker"
    exit 1
fi
echo "Citus Worker launched: $CITUS_WORKER_INSTANCE_ID"

# Wait for instances to be running
echo "Waiting for instances to be in running state..."
aws ec2 wait instance-running --instance-ids $BASTION_INSTANCE_ID $FLASK_INSTANCE_ID $CITUS_MASTER_INSTANCE_ID $CITUS_WORKER_INSTANCE_ID --region $REGION

echo "All instances are now running!"

# Create Target Group for ALB
echo "Creating Target Group..."

# Define health check path to avoid Git Bash path conversion
HEALTH_CHECK_PATH="/"

TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name flasktargetgroup \
    --protocol HTTP \
    --port 5000 \
    --vpc-id $VPC_ID \
    --target-type instance \
    --health-check-path "$HEALTH_CHECK_PATH" \
    --health-check-protocol HTTP \
    --health-check-port 5000 \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 2 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region $REGION)

if [ -z "$TARGET_GROUP_ARN" ] || [ "$TARGET_GROUP_ARN" == "None" ]; then
    echo "Failed to create Target Group"
    exit 1
fi
echo "Target Group created: $TARGET_GROUP_ARN"

# Register Flask App instance with Target Group
echo "Registering Flask App instance with Target Group..."
aws elbv2 register-targets \
    --target-group-arn $TARGET_GROUP_ARN \
    --targets Id=$FLASK_INSTANCE_ID \
    --region $REGION

# Create Application Load Balancer
echo "Creating Application Load Balancer..."
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name myapp-alb \
    --subnets $PUBLIC_A_ID $PUBLIC_B_ID \
    --security-groups $LB_SG_ID \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4 \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text \
    --region $REGION)

if [ -z "$ALB_ARN" ] || [ "$ALB_ARN" == "None" ]; then
    echo "Failed to create Application Load Balancer"
    exit 1
fi
echo "Application Load Balancer created: $ALB_ARN"

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $ALB_ARN \
    --query 'LoadBalancers[0].DNSName' \
    --output text \
    --region $REGION)

# Create Listener for ALB
echo "Creating ALB Listener..."
LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
    --query 'Listeners[0].ListenerArn' \
    --output text \
    --region $REGION)

if [ -z "$LISTENER_ARN" ] || [ "$LISTENER_ARN" == "None" ]; then
    echo "Failed to create ALB Listener"
    exit 1
fi
echo "ALB Listener created: $LISTENER_ARN"

# Wait for ALB to be active
echo "Waiting for Application Load Balancer to be active..."
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN --region $REGION

echo ""
echo "=== EC2 INSTANCES AND ALB SETUP COMPLETE ==="
echo ""
echo "=== EC2 INSTANCES ==="
echo "Bastion Host: $BASTION_INSTANCE_ID"
echo "Flask App: $FLASK_INSTANCE_ID"
echo "Citus Master: $CITUS_MASTER_INSTANCE_ID"
echo "Citus Worker: $CITUS_WORKER_INSTANCE_ID"
echo ""
echo "=== APPLICATION LOAD BALANCER ==="
echo "ALB ARN: $ALB_ARN"
echo "ALB DNS Name: $ALB_DNS"
echo "Target Group ARN: $TARGET_GROUP_ARN"
echo "Listener ARN: $LISTENER_ARN"
echo ""
echo "=== SSH ACCESS ==="
echo "Key pair saved to: ${PC_DIRECTORY}/${KEY_NAME}.pem"
echo "To SSH to Bastion Host:"

# Get Bastion public IP
BASTION_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $BASTION_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region $REGION)

echo "ssh -i ${PC_DIRECTORY}/${KEY_NAME}.pem ubuntu@${BASTION_PUBLIC_IP}"
echo ""
echo "=== APPLICATION ACCESS ==="
echo "Your Flask application will be accessible at: http://${ALB_DNS}"
echo ""
echo "Note: Make sure your Flask application is configured to listen on port 5000"
echo "and is accessible from within the VPC for the health checks to pass."
echo ""
echo "Setup completed successfully!"
```
3. Edit the `PC_DIRECTORY` variable to where your `.pem` file should be saved.
4. Run the script:

```bash
chmod +x EC2instances.txt
./EC2instances.txt
```

> This launches:
- Bastion Host (Public B)
- Flask App (Private A)
- Citus Master (Private B)
- Citus Worker (Private C)
- Also creates Target Group and ALB

---

## 🔑 SSH Access and Deployment

### 🧭 Step 3: SSH to Bastion Host

1. Navigate to `.pem` file folder.
2. On Windows, secure the file:

```cmd
icacls autogenerated-myapp-keypair.pem /inheritance:r
icacls autogenerated-myapp-keypair.pem /grant:r "%username%:F"
```

3. Upload key to Bastion:

```bash
scp -i autogenerated-myapp-keypair.pem autogenerated-myapp-keypair.pem ubuntu@<bastion_public_ip>:/home/ubuntu/
```

4. SSH to Bastion:

```bash
ssh -i autogenerated-myapp-keypair.pem ubuntu@<bastion_public_ip>
```

---

## 🛠️ Step 4: Citus Worker Setup

On the **Bastion Host**:

```bash
chmod 400 ~/autogenerated-myapp-keypair.pem
ssh -i ~/autogenerated-myapp-keypair.pem ubuntu@<citus_worker_private_ip>
```

Inside the Worker:

```bash
git clone https://github.com/Bahar0900/Deployement-of-Multitenant-Application-on-AWS.git
cd MultiTenant-Application-with-Flask-and-Citus
docker-compose -f docker-compose-worker.yml up -d
```

---

## 🧠 Step 5: Citus Master Setup

SSH from Bastion:

```bash
ssh -i ~/autogenerated-myapp-keypair.pem ubuntu@<citus_master_private_ip>
```

Inside the Master:

```bash
git clone https://github.com/Bahar0900/Deployement-of-Multitenant-Application-on-AWS.git
cd MultiTenant-Application-with-Flask-and-Citus
nano docker-entrypoint-initdb.d/init-cluster.sh
# Set Master and Worker private IPs
chmod +x docker-entrypoint-initdb.d/init-cluster.sh
docker-compose -f docker-compose-master.yml up -d
```

---

## 🐍 Step 6: Flask Application Setup

SSH from Bastion:

```bash
ssh -i ~/autogenerated-myapp-keypair.pem ubuntu@<flask_app_private_ip>
```

Inside Flask App Instance:

```bash
git clone https://github.com/Bahar0900/Deployement-of-Multitenant-Application-on-AWS.git
cd MultiTenant-Application-with-Flask-and-Citus
nano docker-compose-flask.yml   # Replace CITUS_MASTER_PRIVATE_IP
nano config.py                  # Replace localhost with CITUS_MASTER_PRIVATE_IP
docker-compose -f docker-compose-flask.yml up -d
```

---

## 🔍 Final Testing

### 🌐 Test via Browser

Open:

```
http://<ALB_DNS_NAME>
```

Expected: Flask application home page.

---

## 🧪 API Testing via Curl

**Register:**

```bash
curl -X POST http://<flask_app_private_ip>:5000/register \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=newuser&email=newuser@example.com&password=Password123&tenant_name=NewOrg"
```

**Login:**

```bash
curl -X POST http://<flask_app_private_ip>:5000/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -c cookies.txt \
  -d "email=newuser@example.com&password=Password123"
```

**Create Note:**

```bash
curl -X POST http://<flask_app_private_ip>:5000/notes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -b cookies.txt \
  -d "content=This is my first note"
```

**Retrieve Notes:**

```bash
curl -X GET http://<flask_app_private_ip>:5000/notes -b cookies.txt
```

**Logout:**

```bash
curl -b cookies.txt http://<flask_app_private_ip>:5000/logout
```

---

## ✅ Final Notes

- For external access, use `http://<ALB_DNS_NAME>`.
- For internal testing from Bastion, use private IPs.
- Ensure Flask listens on port `5000`.

---

> Deployment complete! You’ve successfully launched a production-ready multi-tenant Flask app with Citus on AWS.

