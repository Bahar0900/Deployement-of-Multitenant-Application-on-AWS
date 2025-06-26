# 🚀 Multi-Tenant Application on AWS with Flask and Citus

Welcome to this comprehensive guide for deploying a scalable, distributed multi-tenant application on AWS using Flask and Citus (PostgreSQL).  By leveraging AWS's powerful infrastructure, Flask's lightweight web framework, and Citus's distributed database capabilities, you'll create a multi-tenant system capable of handling multiple organizations efficiently.

In this guide, we will walk you through the entire deployment process, from setting up a secure VPC architecture to launching EC2 instances for the application and database layers. You'll configure an Application Load Balancer (ALB) for external access, deploy Docker-based services for Flask and Citus, and test the application using curl commands. Additionally, you'll learn how to securely access internal components via a Bastion Host and manage infrastructure as code using Pulumi. Whether you're building a SaaS platform or a multi-tenant application, this guide provides a clear, actionable blueprint to get you up and running.

By the end of this tutorial, you'll have a fully functional, scalable multi-tenant application deployed on AWS, complete with a distributed PostgreSQL database powered by Citus and a Flask-based API, ready to serve multiple tenants securely and efficiently.
---

## 📚 Overview

This guide covers the following steps:

- Setting up a secure VPC architecture  
- Launching EC2 instances for application and database layers  
- Configuring an Internet-facing Application Load Balancer  
- Initializing Docker-based services for Flask and Citus  
- Testing endpoints using `curl`  
- Accessing internal components securely via a Bastion Host  

---

## 🧩 System Overview
![Image note found](https://github.com/poridhioss/Deployement-of-Multitenant-Application-on-AWS/blob/f07757cb2b5810dafce76986314b7894ef127b47/images/citus%20updated_again.drawio.svg)


This project uses a distributed PostgreSQL architecture with Citus and Docker containers, integrated with a Flask web application. Below are the key components:

### 🔹 Client
- Sends HTTP POST requests to the backend API to create notes.
- Receives JSON responses indicating successful note creation.

### 🔹 Flask App (`web:5000`)
- Acts as the web server and API layer.
- Receives requests from the client.
- Interacts with the database to insert and retrieve notes.

### 🔹 Citus Overlay Network
A virtual Docker network that contains the following components:

#### 🟩 Citus Coordinator Container (`citus-master:5432`)
- Hosted on `rpi-01`.
- Handles SQL requests from the Flask app.
- Distributes data and queries across Citus Worker containers.

#### 🟨 Citus Worker Containers
- Multiple containers that store distributed shards of the data.
- Connected to the Coordinator via Docker overlay network.
- Help scale out PostgreSQL horizontally.

#### 🔸 Docker Daemons
- Each host runs a Docker Daemon to manage container lifecycles. 

---
We are going to deploy this system in AWS.

## 🗺️ AWS Architecture Design

![Image note found](https://github.com/poridhioss/Deployement-of-Multitenant-Application-on-AWS/blob/26aee9c9e9d9eed749122df86e57493e36931787/images/awsfinannnaalll.drawio.svg)

### VPC Details

- VPC with 2 Availability Zones  
- 2 Public Subnets  
- 3 Private Subnets  
- 1 Internet Gateway  
- 1 NAT Gateway  
- 1 Application Load Balancer  
- Route Tables for Public and Private Subnets  

---

## 🛠️ Prerequisites

- ✅ AWS Account with CLI credentials  
- ✅ AWS CLI installed  
- ✅ SSH Key Pair  
- ✅ WSL or Git Bash (for script execution)  
- ✅ Git installed  

---

## ⚙️ Configuring AWS CLI

Run the following command:

```bash
aws configure
```

Provide the following details:

- **AWS Access Key ID**: Obtain from AWS Console  
- **AWS Secret Access Key**: Obtain from AWS Console  
- **Default Region Name**: `ap-southeast-1`  
- **Default Output Format**: `json` (or your preference)  

---

## 🧱 Infrastructure Setup

### Step 1: Set Up Project Directory and Virtual Environment

```bash
mkdir pulumi
cd pulumi
sudo apt update
sudo apt install python3.8-venv -y
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### Step 2: Install Pulumi

On Windows (using Chocolatey):

```bash
choco install pulumi -y
```

On Linux/macOS: Follow the [Pulumi Installation Guide](https://www.pulumi.com/docs/get-started/install/).

Verify installation:

```bash
pulumi version
```

### Step 3: Initialize a Pulumi Project

```bash
pulumi login
pulumi new aws-python
```

- Accept default options  
- Set AWS region to `ap-southeast-1`  

### Step 4: Configure Infrastructure

Replace the contents of `__main__.py` with the Pulumi code for VPC, subnets, EC2, etc.
```bash
import pulumi
import pulumi_aws as aws
import base64

# Configuration variables
config = pulumi.Config()
region = "ap-southeast-1"
vpc_cidr = "10.0.0.0/16"
your_ip = "Your IP"  #curl ifconfig.me to know your ip
instance_type = "t2.micro"
ami_id = "ami-047126e50991d067b"  # Ubuntu 20.04 LTS for ap-southeast-1

# PASTE YOUR PUBLIC KEY CONTENT HERE
public_key_content = """ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLMY5LbNGocjJNdynt0rmvnG0FhSE9+j6ikxRUTk55mqk484wHx4iYM3SrXSGz4Z/2AhiK0h1ama+ZP4OmEkNV1qwN/GOZWPnCClqp6JL73LXexqkRF6cg52fiJZqz2zNLXp/5QaTkjXamKWxSqN/MLWKJldeKDFBvTdFQNwuBH/KFVVnSc+2mW6RgUP3wuBWuWeAk0hXF5zkgSkA+NfVJLbcC2oaUGucobA+D7npx3ergT0RQ8+K66TTN4PZ2ugTTfrjBqkGExIKRS3fNCM43RAF6bk6cNKDR8Y1EghLk10fcSb+WwXXW6Bot9DjdDezMrA0idz1HnoZhTw578cpd root@2159e3577ee4ef88
"""

# Create AWS Key Pair from your public key
key_pair = aws.ec2.KeyPair("app-key-pair",
    key_name="app-key-pair",
    public_key=public_key_content,
    tags={"Name": "AppKeyPair"}
)

# Create VPC
vpc = aws.ec2.Vpc("myapp-vpc",
    cidr_block=vpc_cidr,
    enable_dns_hostnames=True,
    enable_dns_support=True,
    tags={"Name": "MyAppVPC"}
)

# Create Internet Gateway
igw = aws.ec2.InternetGateway("myapp-igw",
    vpc_id=vpc.id,
    tags={"Name": "MyAppIGW"}
)

# Create Subnets (only using ap-southeast-1a and ap-southeast-1b)
public_subnet_a = aws.ec2.Subnet("public-subnet-a",
    vpc_id=vpc.id,
    cidr_block="10.0.1.0/24",
    availability_zone="ap-southeast-1a",
    map_public_ip_on_launch=True,
    tags={"Name": "PublicSubnetA"}
)

public_subnet_b = aws.ec2.Subnet("public-subnet-b",
    vpc_id=vpc.id,
    cidr_block="10.0.2.0/24",
    availability_zone="ap-southeast-1b",
    map_public_ip_on_launch=True,
    tags={"Name": "PublicSubnetB"}
)

private_subnet_a = aws.ec2.Subnet("private-subnet-a",
    vpc_id=vpc.id,
    cidr_block="10.0.3.0/24",
    availability_zone="ap-southeast-1a",
    tags={"Name": "PrivateSubnetA"}
)

private_subnet_b = aws.ec2.Subnet("private-subnet-b",
    vpc_id=vpc.id,
    cidr_block="10.0.4.0/24",
    availability_zone="ap-southeast-1b",
    tags={"Name": "PrivateSubnetB"}
)

# Create Elastic IP for NAT Gateway
eip = aws.ec2.Eip("nat-eip",
    domain="vpc",
    tags={"Name": "MyAppNATEIP"}
)

# Create NAT Gateway
nat_gateway = aws.ec2.NatGateway("myapp-nat",
    allocation_id=eip.id,
    subnet_id=public_subnet_a.id,
    tags={"Name": "MyAppNAT"}
)

# Create Route Tables
public_route_table = aws.ec2.RouteTable("public-route-table",
    vpc_id=vpc.id,
    tags={"Name": "PublicRouteTable"}
)

private_route_table = aws.ec2.RouteTable("private-route-table",
    vpc_id=vpc.id,
    tags={"Name": "PrivateRouteTable"}
)

# Create Routes
public_route = aws.ec2.Route("public-route",
    route_table_id=public_route_table.id,
    destination_cidr_block="0.0.0.0/0",
    gateway_id=igw.id
)

private_route = aws.ec2.Route("private-route",
    route_table_id=private_route_table.id,
    destination_cidr_block="0.0.0.0/0",
    nat_gateway_id=nat_gateway.id
)

# Associate Route Tables with Subnets
public_rt_association_a = aws.ec2.RouteTableAssociation("public-rt-assoc-a",
    subnet_id=public_subnet_a.id,
    route_table_id=public_route_table.id
)

public_rt_association_b = aws.ec2.RouteTableAssociation("public-rt-assoc-b",
    subnet_id=public_subnet_b.id,
    route_table_id=public_route_table.id
)

private_rt_association_a = aws.ec2.RouteTableAssociation("private-rt-assoc-a",
    subnet_id=private_subnet_a.id,
    route_table_id=private_route_table.id
)

private_rt_association_b = aws.ec2.RouteTableAssociation("private-rt-assoc-b",
    subnet_id=private_subnet_b.id,
    route_table_id=private_route_table.id
)

# Create Security Groups
lb_security_group = aws.ec2.SecurityGroup("security-load-balancer",
    name="security-load-balancer",
    description="Load Balancer Security Group",
    vpc_id=vpc.id,
    ingress=[
        aws.ec2.SecurityGroupIngressArgs(
            protocol="tcp",
            from_port=80,
            to_port=80,
            cidr_blocks=["0.0.0.0/0"]
        ),
        aws.ec2.SecurityGroupIngressArgs(
            protocol="tcp",
            from_port=443,
            to_port=443,
            cidr_blocks=["0.0.0.0/0"]
        )
    ],
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            protocol="-1",
            from_port=0,
            to_port=0,
            cidr_blocks=["0.0.0.0/0"]
        )
    ],
    tags={"Name": "LoadBalancerSG"}
)

bastion_security_group = aws.ec2.SecurityGroup("security-bastion",
    name="security-bastion",
    description="Bastion Security Group",
    vpc_id=vpc.id,
    ingress=[
        aws.ec2.SecurityGroupIngressArgs(
            protocol="tcp",
            from_port=22,
            to_port=22,
            cidr_blocks=[your_ip]
        )
    ],
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            protocol="-1",
            from_port=0,
            to_port=0,
            cidr_blocks=["0.0.0.0/0"]
        )
    ],
    tags={"Name": "BastionSG"}
)

flask_security_group = aws.ec2.SecurityGroup("security-flask-app",
    name="security-flask-app",
    description="Flask App Security Group",
    vpc_id=vpc.id,
    ingress=[
        aws.ec2.SecurityGroupIngressArgs(
            protocol="tcp",
            from_port=5000,
            to_port=5000,
            security_groups=[lb_security_group.id]
        ),
        aws.ec2.SecurityGroupIngressArgs(
            protocol="tcp",
            from_port=22,
            to_port=22,
            security_groups=[bastion_security_group.id]
        )
    ],
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            protocol="-1",
            from_port=0,
            to_port=0,
            cidr_blocks=["0.0.0.0/0"]
        )
    ],
    tags={"Name": "FlaskAppSG"}
)

citus_master_security_group = aws.ec2.SecurityGroup("security-citus-master",
    name="security-citus-master",
    description="Citus Master Security Group",
    vpc_id=vpc.id,
    tags={"Name": "CitusMasterSG"}
)

citus_worker_security_group = aws.ec2.SecurityGroup("security-citus-worker",
    name="security-citus-worker",
    description="Citus Worker Security Group",
    vpc_id=vpc.id,
    tags={"Name": "CitusWorkerSG"}
)

# Add ingress rules for Citus security groups
citus_master_ingress_flask = aws.ec2.SecurityGroupRule("citus-master-ingress-flask",
    type="ingress",
    from_port=5432,
    to_port=5432,
    protocol="tcp",
    source_security_group_id=flask_security_group.id,
    security_group_id=citus_master_security_group.id
)

citus_master_ingress_worker = aws.ec2.SecurityGroupRule("citus-master-ingress-worker",
    type="ingress",
    from_port=5432,
    to_port=5432,
    protocol="tcp",
    source_security_group_id=citus_worker_security_group.id,
    security_group_id=citus_master_security_group.id
)

citus_master_ingress_ssh = aws.ec2.SecurityGroupRule("citus-master-ingress-ssh",
    type="ingress",
    from_port=22,
    to_port=22,
    protocol="tcp",
    source_security_group_id=bastion_security_group.id,
    security_group_id=citus_master_security_group.id
)

citus_worker_ingress_master = aws.ec2.SecurityGroupRule("citus-worker-ingress-master",
    type="ingress",
    from_port=5432,
    to_port=5432,
    protocol="tcp",
    source_security_group_id=citus_master_security_group.id,
    security_group_id=citus_worker_security_group.id
)

citus_worker_ingress_ssh = aws.ec2.SecurityGroupRule("citus-worker-ingress-ssh",
    type="ingress",
    from_port=22,
    to_port=22,
    protocol="tcp",
    source_security_group_id=bastion_security_group.id,
    security_group_id=citus_worker_security_group.id
)

# Add egress rules for Citus security groups
citus_master_egress = aws.ec2.SecurityGroupRule("citus-master-egress",
    type="egress",
    from_port=0,
    to_port=0,
    protocol="-1",
    cidr_blocks=["0.0.0.0/0"],
    security_group_id=citus_master_security_group.id
)

citus_worker_egress = aws.ec2.SecurityGroupRule("citus-worker-egress",
    type="egress",
    from_port=0,
    to_port=0,
    protocol="-1",
    cidr_blocks=["0.0.0.0/0"],
    security_group_id=citus_worker_security_group.id
)

# User data script for private subnet instances
user_data_script = """#!/bin/bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
"""

# Launch EC2 Instances

# 1. Bastion Host in Public Subnet B
bastion_instance = aws.ec2.Instance("bastion-host",
    ami=ami_id,
    instance_type=instance_type,
    key_name=key_pair.key_name,
    vpc_security_group_ids=[bastion_security_group.id],
    subnet_id=public_subnet_b.id,
    associate_public_ip_address=True,
    tags={"Name": "Bastion-Host"}
)

# 2. Flask App in Private Subnet A
flask_instance = aws.ec2.Instance("flask-app",
    ami=ami_id,
    instance_type=instance_type,
    key_name=key_pair.key_name,
    vpc_security_group_ids=[flask_security_group.id],
    subnet_id=private_subnet_a.id,
    associate_public_ip_address=False,
    user_data=user_data_script,
    tags={"Name": "Flask-App"}
)

# 3. Citus Master in Private Subnet A (same AZ as Flask for better performance)
citus_master_instance = aws.ec2.Instance("citus-master",
    ami=ami_id,
    instance_type=instance_type,
    key_name=key_pair.key_name,
    vpc_security_group_ids=[citus_master_security_group.id],
    subnet_id=private_subnet_a.id,
    associate_public_ip_address=False,
    user_data=user_data_script,
    tags={"Name": "Citus-Master"}
)

# 4. Citus Worker in Private Subnet B
citus_worker_instance = aws.ec2.Instance("citus-worker",
    ami=ami_id,
    instance_type=instance_type,
    key_name=key_pair.key_name,
    vpc_security_group_ids=[citus_worker_security_group.id],
    subnet_id=private_subnet_b.id,
    associate_public_ip_address=False,
    user_data=user_data_script,
    tags={"Name": "Citus-Worker"}
)

# Create Target Group for ALB
target_group = aws.lb.TargetGroup("flask-target-group",
    name="flasktargetgroup",
    port=5000,
    protocol="HTTP",
    vpc_id=vpc.id,
    target_type="instance",
    health_check=aws.lb.TargetGroupHealthCheckArgs(
        path="/",
        protocol="HTTP",
        port="5000",
        interval=30,
        timeout=5,
        healthy_threshold=2,
        unhealthy_threshold=2
    ),
    tags={"Name": "FlaskTargetGroup"}
)

# Register Flask App instance with Target Group
target_group_attachment = aws.lb.TargetGroupAttachment("flask-target-attachment",
    target_group_arn=target_group.arn,
    target_id=flask_instance.id,
    port=5000
)

# Create Application Load Balancer
alb = aws.lb.LoadBalancer("myapp-alb",
    name="myapp-alb",
    load_balancer_type="application",
    internal=False,
    ip_address_type="ipv4",
    subnets=[public_subnet_a.id, public_subnet_b.id],
    security_groups=[lb_security_group.id],
    tags={"Name": "MyAppALB"}
)

# Create ALB Listener
alb_listener = aws.lb.Listener("myapp-alb-listener",
    load_balancer_arn=alb.arn,
    port=80,
    protocol="HTTP",
    default_actions=[aws.lb.ListenerDefaultActionArgs(
        type="forward",
        target_group_arn=target_group.arn
    )]
)

# Export important values
pulumi.export("vpc_id", vpc.id)
pulumi.export("internet_gateway_id", igw.id)
pulumi.export("public_subnet_a_id", public_subnet_a.id)
pulumi.export("public_subnet_b_id", public_subnet_b.id)
pulumi.export("private_subnet_a_id", private_subnet_a.id)
pulumi.export("private_subnet_b_id", private_subnet_b.id)
pulumi.export("nat_gateway_id", nat_gateway.id)
pulumi.export("public_route_table_id", public_route_table.id)
pulumi.export("private_route_table_id", private_route_table.id)
pulumi.export("lb_security_group_id", lb_security_group.id)
pulumi.export("bastion_security_group_id", bastion_security_group.id)
pulumi.export("flask_security_group_id", flask_security_group.id)
pulumi.export("citus_master_security_group_id", citus_master_security_group.id)
pulumi.export("citus_worker_security_group_id", citus_worker_security_group.id)
pulumi.export("key_pair_name", key_pair.key_name)
pulumi.export("bastion_instance_id", bastion_instance.id)
pulumi.export("flask_instance_id", flask_instance.id)
pulumi.export("citus_master_instance_id", citus_master_instance.id)
pulumi.export("citus_worker_instance_id", citus_worker_instance.id)
pulumi.export("bastion_public_ip", bastion_instance.public_ip)
pulumi.export("alb_arn", alb.arn)
pulumi.export("alb_dns_name", alb.dns_name)
pulumi.export("target_group_arn", target_group.arn)
pulumi.export("alb_listener_arn", alb_listener.arn)
pulumi.export("ssh_command", pulumi.Output.concat(
    "ssh -i /root/code/pulumi/app-key-pair ubuntu@", bastion_instance.public_ip
))
pulumi.export("application_url", pulumi.Output.concat("http://", alb.dns_name))
```

### Step 5: Set Up SSH Key Pair

```bash
ssh-keygen -t rsa -b 2048 -f app-key-pair
cat app-key-pair.pub
```
Update the Your iP variable with you ip.You can get it by (ifconfig.me)
Update the `public_key_content` variable in your Pulumi `main.py` resource with the copied value.

### Step 6: Install Dependencies

Create `requirements.txt`:

```
pulumi>=3.0.0
pulumi_aws>=6.0.0
```

Install with:

```bash
pip install -r requirements.txt
```

### Step 7: Deploy the Pulumi Stack

```bash
pulumi up --yes
```

Expected Output:
![Image note found](https://github.com/poridhioss/Deployement-of-Multitenant-Application-on-AWS/blob/f07757cb2b5810dafce76986314b7894ef127b47/images/citus%20updated_again.drawio.svg)
![Image note found](https://github.com/poridhioss/Deployement-of-Multitenant-Application-on-AWS/blob/f07757cb2b5810dafce76986314b7894ef127b47/images/citus%20updated_again.drawio.svg)
![Image note found](https://github.com/poridhioss/Deployement-of-Multitenant-Application-on-AWS/blob/f07757cb2b5810dafce76986314b7894ef127b47/images/citus%20updated_again.drawio.svg)
![Image note found](https://github.com/poridhioss/Deployement-of-Multitenant-Application-on-AWS/blob/f07757cb2b5810dafce76986314b7894ef127b47/images/citus%20updated_again.drawio.svg)
![Image note found](https://github.com/poridhioss/Deployement-of-Multitenant-Application-on-AWS/blob/f07757cb2b5810dafce76986314b7894ef127b47/images/citus%20updated_again.drawio.svg)

Pulumi will:

- Create networking and compute resources  
- Set up security groups  
- Launch EC2 instances with Docker  



Verify outputs:

```bash
pulumi stack output
```

Example:

```
OUTPUT              VALUE
key_pair_name       app-key-pair
web_public_ip       18.138.254.251
```

---

## 🔧 Updating or Destroying Infrastructure

- To update:  
  ```bash
  pulumi up
  ```

- To refresh Pulumi state:  
  ```bash
  pulumi refresh
  ```

- To destroy resources:  
  ```bash
  pulumi destroy
  ```

---

## 🔑 SSH Access and Deployment

### Step 1: SSH to Bastion Host

```bash
scp -i app-key-pair app-key-pair ubuntu@<bastion_public_ip>:/home/ubuntu/
ssh -i app-key-pair ubuntu@<bastion_public_ip>
```

### Step 2: Citus Worker Setup

On Bastion Host:

```bash
chmod 400 ~/app-key-pair
ssh -i ~/app-key-pair ubuntu@<citus_worker_private_ip>
```

Inside Worker Instance:

```bash
git clone https://github.com/Bahar0900/Deployement-of-Multitenant-Application-on-AWS.git
cd Deployement-of-Multitenant-Application-on-AWS
docker-compose -f docker-compose-worker.yml up -d
```

### Step 3: Citus Master Setup

From Bastion Host:

```bash
ssh -i ~/app-key-pair ubuntu@<citus_master_private_ip>
```

Inside Master Instance:

```bash
git clone https://github.com/Bahar0900/Deployement-of-Multitenant-Application-on-AWS.git
cd Deployement-of-Multitenant-Application-on-AWS
nano docker-entrypoint-initdb.d/init-cluster.sh  # Edit IPs
chmod +x docker-entrypoint-initdb.d/init-cluster.sh
docker-compose -f docker-compose-master.yml up -d
```

Verify:

```bash
docker ps -a
```

Expected:

```
CONTAINER ID   IMAGE                  STATUS                PORTS
xxxxx          citusdata/citus:11.2   Up (healthy)          5432->5432/tcp
```

### Step 4: Flask Application Setup

From Bastion Host:

```bash
ssh -i ~/app-key-pair ubuntu@<flask_app_private_ip>
```

Inside Flask Instance:

```bash
git clone https://github.com/Bahar0900/Deployement-of-Multitenant-Application-on-AWS.git
cd Deployement-of-Multitenant-Application-on-AWS
nano docker-compose-flask.yml  # Replace CITUS_MASTER_PRIVATE_IP
nano config.py                 # Replace localhost with CITUS_MASTER_PRIVATE_IP
docker-compose -f docker-compose-flask.yml up -d
```

---

## 🔍 Final Testing

### Test via Browser

Open:

```text
http://<ALB_DNS_NAME>
```

Expected: Flask application home page.

---

### API Testing via curl

#### Register a User

```bash
curl -X POST "http://<ALB_DNS_NAME>/register" \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=newuser&email=newuser@example.com&password=Password123&tenant_name=NewOrg"
```

#### Login

```bash
curl -X POST "http://<ALB_DNS_NAME>/login" \
-H "Content-Type: application/x-www-form-urlencoded" -c cookies.txt \
-d "email=newuser@example.com&password=Password123"
```

#### Create a Note

```bash
curl -X POST "http://<ALB_DNS_NAME>/notes" \
-H "Content-Type: application/x-www-form-urlencoded" -b cookies.txt \
-d "content=This is my first note"
```

#### Retrieve Notes

```bash
curl -X GET "http://<ALB_DNS_NAME>/notes" -b cookies.txt
```

#### Logout

```bash
curl -b cookies.txt "http://<ALB_DNS_NAME>/logout"
```

---

## ✅ Final Notes

- Use `http://<ALB_DNS_NAME>` for external access.  
- Use **private IPs** for internal access from Bastion.  
- Ensure Flask app listens on port **5000** inside the container.  

---

**🎉 Deployment Complete!**  
You have successfully launched a production-ready multi-tenant Flask application with Citus on AWS.
