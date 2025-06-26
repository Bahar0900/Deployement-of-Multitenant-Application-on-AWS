# 🚀 Multi-Tenant Application on AWS with Flask and Citus

A comprehensive step-by-step guide to deploy a scalable, distributed multi-tenant application using **Flask** and **Citus (PostgreSQL)** on **AWS** infrastructure.

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

The system is a multi-tier distributed application with the following components:

- **Frontend Gateway**: Application Load Balancer (HTTP listener)  
- **Web App**: Flask (Dockerized, Private Subnet)  
- **Database Layer**: Citus (Master + Worker Nodes)  
- **Security Layer**: Bastion Host (for private instance access)  
- **Networking**: Custom VPC with isolated public and private subnets  

---

## 🗺️ AWS Architecture Design

![Image note found](https://github.com/poridhioss/Deployement-of-Multitenant-Application-on-AWS/blob/26aee9c9e9d9eed749122df86e57493e36931787/images/awsfinannnaalll.drawio.svg)

### VPC Details

| Component        | CIDR Block     | Availability Zone | Notes                         |
|------------------|----------------|-------------------|-------------------------------|
| Public Subnet A  | 10.0.1.0/24    | ap-southeast-1a   | NAT Gateway, ALB              |
| Public Subnet B  | 10.0.2.0/24    | ap-southeast-1b   | Bastion Host                  |
| Private Subnet A | 10.0.3.0/24    | ap-southeast-1a   | Flask App                     |
| Private Subnet B | 10.0.4.0/24    | ap-southeast-1b   | Citus Master                  |
| Private Subnet C | 10.0.5.0/24    | ap-southeast-1c   | Citus Worker                  |

- Internet Gateway: Attached to VPC  
- NAT Gateway: Located in Public Subnet A  
- Route Tables: Configured for public and private subnets  

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

### Step 5: Set Up SSH Key Pair

```bash
ssh-keygen -t rsa -b 2048 -f app-key-pair
cat app-key-pair.pub
```

Update the `public_key` field in your Pulumi `aws.ec2.KeyPair` resource with the copied value.

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
