# 🚀 Deployment Guide: Multi-Tenant Flask App with Citus on AWS

A comprehensive, step-by-step guide for deploying a scalable, multi-tenant application using Flask and Citus (PostgreSQL) on AWS via Pulumi and Docker.

---

## 📚 Overview

This guide covers:

- Designing a secure VPC network with public and private subnets  
- Launching EC2 instances for your app and database  
- Setting up an internet-facing Application Load Balancer (ALB)  
- Deploying Flask and Citus services using Docker  
- Using `curl` to validate API endpoints  
- Securing private instances via a Bastion host

---

## 🧩 System Architecture

Your deployment includes:

- **Frontend:** ALB with HTTP listener  
- **Web Tier:** Flask application in a private subnet  
- **Database Tier:** Citus with a master and multiple workers  
- **Security:** Bastion host for secure internal access  
- **Networking:** Custom VPC with isolated subnets

---

## 🗺️ AWS Network Layout

![AWS Architecture Diagram](https://github.com/Bahar0900/Deployment-of-Multitenant-Application-on-AWS/blob/main/images/AWSAPP.drawio.svg)

| Subnet              | CIDR Block     | Availability Zone   | Role                  |
|--------------------|----------------|---------------------|------------------------|
| Public Subnet A    | 10.0.1.0/24    | ap-southeast-1a     | NAT + ALB              |
| Public Subnet B    | 10.0.2.0/24    | ap-southeast-1b     | Bastion Host           |
| Private Subnet A   | 10.0.3.0/24    | ap-southeast-1a     | Flask App              |
| Private Subnet B   | 10.0.4.0/24    | ap-southeast-1b     | Citus Master           |
| Private Subnet C   | 10.0.5.0/24    | ap-southeast-1c     | Citus Worker(s)        |

- Internet Gateway attached to VPC  
- NAT Gateway in Public Subnet A  
- Route tables configured for internet access and isolation

---

## 🛠️ Prerequisites

- AWS account and credentials configured via AWS CLI  
- SSH key pair generated  
- WSL, Git Bash, or similar shell  
- Git installed on your dev machine

---

## ⚙️ AWS CLI Setup

1. Run `aws configure` and input your credentials:  
   - Region: `ap-southeast-1`  
   - Output format: `json`

2. Create a project workspace and virtual environment:

   ```bash
   mkdir pulumi
   cd pulumi
   sudo apt update
   sudo apt install python3.8-venv -y
   python3 -m venv venv
   source venv/bin/activate
   ```

3. Install Pulumi:

   - **macOS/Linux**: Follow the official installation guide.  
   - **Windows (via Chocolatey)**:
     ```bash
     choco install pulumi -y
     ```
   - Verify:
     ```bash
     pulumi version
     ```

4. Initialize Pulumi project:
   ```bash
   pulumi login
   pulumi new aws-python
   ```
   - Accept defaults and choose `ap-southeast-1` region.

---

## 🧩 Infrastructure Setup (`__main__.py`)

Replace your `__main__.py` with Pulumi code that:

- Creates a VPC, subnets, IGW, NAT gateway, and route tables  
- Defines Security Groups for ALB, Bastion, Flask, and Citus  
- Launches EC2 instances for Bastion, Flask, and Citus nodes  
- Sets up an ALB with target groups and listener  
- Outputs key connection details (e.g. SSH commands, ALB URL)

---

## 🔐 SSH Key Pair

Generate your key pair:

```bash
ssh-keygen -t rsa -b 2048 -f app-key-pair
```

Add the public key to Pulumi:

```python
with open("app-key-pair.pub") as f:
    key = aws.ec2.KeyPair("app-key-pair", public_key=f.read())
```

**Security tip**: add `app-key-pair*` to `.gitignore` and never commit private keys.

---

## 📦 Dependencies

Create `requirements.txt`:

```
pulumi>=3.0.0
pulumi_aws>=6.0.0
```

Install with:
```bash
pip install -r requirements.txt
```

---

## 🚀 Deploy Infrastructure

Deploy with Pulumi:

```bash
pulumi up --yes
```

**What happens:**

- VPC, subnets, route tables, IGW, and NAT gateway are created  
- Security groups are defined  
- Bastion, Flask, and Citus EC2 instances are launched; Docker & Docker Compose are installed via user data  
- ALB is created and configured  
- SSH commands and ALB DNS are outputted for you

View outputs using:

```bash
pulumi stack output
```

---

## 🔁 Updating & Tearing Down

- To update infrastructure:
  ```bash
  pulumi up
  ```
- To refresh state (if manual changes occurred):
  ```bash
  pulumi refresh
  ```
- To destroy all resources:
  ```bash
  pulumi destroy
  ```

---

## ✅ Best Practices

- Use version control (e.g. Git)  
- Maintain separate stacks (dev/staging/prod)  
- Store secrets securely using Pulumi  
- Modularize Pulumi code for reusability  
- Tag AWS resources for billing and management  
- Test changes in non-prod environments first

---

## 🛠️ Troubleshooting

1. **Chocolatey not found (Windows)**:
   - Run PowerShell as Admin and install from Chocolatey site.

2. **Invalid Pulumi token**:
   - Re-login via `pulumi login`

3. **SSH issues**:
   - Ensure your key is added to Pulumi and EC2 Security Groups restrict to your IP.

4. **“No instances” in AWS Console**:
   - Confirm you're viewing `ap-southeast-1` region.

5. **Docker container exits immediately**:
   - Check logs with:
     ```bash
     docker logs <container_id>
     # or
     cat /var/log/cloud-init-output.log
     ```

6. **No internet access inside EC2**:
   - Ensure NAT gateway is properly associated with private subnet route table.

---

## 💯 Access & Deployment Post-Setup

### SSH into Bastion:
```bash
ssh -i app-key-pair ubuntu@<BastionPublicIP>
```

### On Bastion, SSH into Citus Worker:
```bash
ssh -i app-key-pair ubuntu@<WorkerPrivateIP>
cd ~/Deployment-of-Multitenant-Application-on-AWS
docker-compose -f docker-compose-worker.yml up -d
```

### On Bastion, SSH into Citus Master:
```bash
ssh -i app-key-pair ubuntu@<MasterPrivateIP>
cd ~/Deployment-of-Multitenant-Application-on-AWS
chmod +x docker-entrypoint-initdb.d/init-cluster.sh
docker-compose -f docker-compose-master.yml up -d
```

Check container status:
```bash
docker ps -a
```

### On Bastion, SSH into Flask App:
```bash
ssh -i app-key-pair ubuntu@<FlaskAppPrivateIP>
cd ~/Deployment-of-Multitenant-Application-on-AWS
docker-compose -f docker-compose-flask.yml up -d
```

---

## 🔍 Testing the Deployment

### Browser
Open:  
```
http://<Your_ALB_DNS>
```
Expect: Flask application homepage.

### API via `curl`
```bash
curl -X POST "http://<ALB_DNS>/register" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=newuser&email=newuser@example.com&password=Password123&tenant_name=NewOrg"

curl -X POST "http://<ALB_DNS>/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -c cookies.txt \
  -d "email=newuser@example.com&password=Password123"

curl -X POST "http://<ALB_DNS>/notes" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -b cookies.txt \
  -d "content=This is my first note"

curl -X GET "http://<ALB_DNS>/notes" \
  -b cookies.txt

curl -X GET "http://<ALB_DNS>/logout" \
  -b cookies.txt
```

---

## ✅ Final Notes

- Use `http://<ALB_DNS>` for external access  
- Use Bastion for all internal communication  
- Ensure Flask listens on port `5000`

> 🎉 Deployment complete! You've setup a production-ready, containerized, multi-tenant Flask app backed by distributed Citus on AWS.

