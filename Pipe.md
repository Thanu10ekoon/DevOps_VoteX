    # VoteX DevOps Pipeline Setup Guide

Complete step-by-step guide to set up CI/CD pipeline with Terraform, GitHub Actions, Docker Hub, and Ansible for deploying VoteX to AWS EC2.

---

## 📋 Prerequisites

- AWS Account
- Docker Hub Account
- GitHub Account
- WSL Ubuntu terminal on Windows
- Git installed

---

## 🔑 Step 1: AWS Setup

### 1.1 Create AWS Account
1. Go to https://aws.amazon.com/
2. Click "Create an AWS Account"
3. Follow the registration process (requires credit card)

### 1.2 Create IAM User for Terraform/GitHub Actions

1. Log in to AWS Console
2. Go to **IAM** service
3. Click **Users** → **Create user**
4. Username: `votex-deployer`
5. Click **Next**
6. Select **Attach policies directly**
7. Add these policies:
   - `AmazonEC2FullAccess`
   - `AmazonVPCFullAccess`
8. Click **Next** → **Create user**

### 1.3 Create Access Keys

1. Click on the user `votex-deployer`
2. Go to **Security credentials** tab
3. Scroll to **Access keys** → Click **Create access key**
4. Select **Command Line Interface (CLI)**
5. Check "I understand" → **Next** → **Create access key**
6. **IMPORTANT**: Copy and save:
   - Access Key ID
   - Secret Access Key
   
   ⚠️ You won't see the secret again!

---

## 🐳 Step 2: Docker Hub Setup

### 2.1 Create Docker Hub Account
1. Go to https://hub.docker.com/
2. Click **Sign Up**
3. Create account (free tier is sufficient)

### 2.2 Create Access Token

1. Log in to Docker Hub
2. Click your username (top right) → **Account Settings**
3. Go to **Security** tab
4. Click **New Access Token**
5. Description: `votex-github-actions`
6. Access permissions: **Read, Write**
7. Click **Generate**
8. **IMPORTANT**: Copy and save the access token

---

## 🔐 Step 3: Generate SSH Key Pair

In your WSL Ubuntu terminal:

```bash
# Navigate to SSH directory
cd ~/.ssh

# Generate SSH key pair (press Enter for all prompts)
ssh-keygen -t rsa -b 4096 -f votex_key -N ""

# This creates two files:
# - votex_key (private key)
# - votex_key.pub (public key)

# View the private key (you'll need this for GitHub Secrets)
cat votex_key

# View the public key (Terraform will use this)
cat votex_key.pub
```

**Save both keys in a secure location!**

---

## 🌐 Step 4: Configure AWS CLI in WSL

### 4.1 Install AWS CLI

```bash
# Update system
sudo apt update

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

### 4.2 Configure AWS Credentials

```bash
aws configure
```

Enter the values:
- **AWS Access Key ID**: (from Step 1.3)
- **AWS Secret Access Key**: (from Step 1.3)
- **Default region name**: `eu-west-1`
- **Default output format**: `json`

---

## 🏗️ Step 5: Deploy Infrastructure with Terraform

### 5.1 Navigate to Project

```bash
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX"
```

### 5.2 Install Terraform

```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install
sudo apt update
sudo apt install terraform -y

# Verify installation
terraform --version
```

### 5.3 Initialize and Deploy

```bash
cd terraform

# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Deploy infrastructure (type 'yes' when prompted)
terraform apply

# Save the output
# Copy the EC2 Public IP address shown in the output
```

**Expected Output:**
```
instance_public_ip = "x.x.x.x"
ssh_connection_command = "ssh -i ~/.ssh/votex_key ubuntu@x.x.x.x"
```

### 5.4 Test SSH Connection

```bash
# Wait 2-3 minutes for instance to fully boot, then:
ssh -i ~/.ssh/votex_key ubuntu@<EC2_PUBLIC_IP>

# If connected successfully, exit:
exit
```

---

## 🔄 Step 6: Setup GitHub Repository

### 6.1 Create GitHub Repository

1. Go to https://github.com/
2. Click **New repository** (green button)
3. Repository name: `DevOps_VoteX`
4. Set to **Public** or **Private**
5. **Do NOT** initialize with README
6. Click **Create repository**

### 6.2 Add GitHub Secrets

1. Go to your repository on GitHub
2. Click **Settings** tab
3. In left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret** for each of the following:

| Secret Name | Value | Where to Get It |
|-------------|-------|-----------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | Step 1.3 |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | Step 1.3 |
| `DOCKER_USERNAME` | Your Docker Hub username | Step 2.1 |
| `DOCKER_PASSWORD` | Your Docker Hub access token | Step 2.2 |
| `EC2_SSH_PRIVATE_KEY` | Content of `~/.ssh/votex_key` | Step 3 |

**To get private key content:**
```bash
cat ~/.ssh/votex_key
```
Copy the entire output including `-----BEGIN ... KEY-----` and `-----END ... KEY-----`

---

## 📦 Step 7: Push Code to GitHub

In your WSL terminal:

```bash
# Navigate to project directory
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX"

# Initialize git (if not already done)
git init

# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/DevOps_VoteX.git

# Check git status
git status

# Stage all files
git add .

# Commit
git commit -m "Initial commit: VoteX with CI/CD pipeline"

# Push to GitHub (this will trigger the pipeline!)
git push -u origin main
```

**If you get authentication error:**
1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token → Check `repo` scope → Generate
3. Use the token as password when pushing

---

## 🚀 Step 8: Monitor Deployment

### 8.1 Watch GitHub Actions

1. Go to your repository on GitHub
2. Click **Actions** tab
3. You should see a workflow running: "Deploy VoteX to AWS"
4. Click on it to see real-time logs
5. Wait for both jobs to complete (green checkmarks):
   - ✅ Build and Push Docker Images (~5-10 mins)
   - ✅ Deploy to EC2 (~3-5 mins)

### 8.2 Check Deployment Status

After pipeline completes:

```bash
# SSH into EC2
ssh -i ~/.ssh/votex_key ubuntu@<EC2_PUBLIC_IP>

# Check running containers
sudo docker ps

# Check logs
cd votex
sudo docker compose logs -f

# Exit (Ctrl+C to stop logs, then):
exit
```

---

## ✅ Step 9: Access Your Application

### 9.1 Application URLs

Replace `<EC2_PUBLIC_IP>` with your instance IP from Step 5.3:

- **Frontend (VoteX App)**: http://\<EC2_PUBLIC_IP\>:3000
- **Backend API**: http://\<EC2_PUBLIC_IP\>:4000
- **Health Check**: http://\<EC2_PUBLIC_IP\>:4000/api/health

### 9.2 Test the Application

1. Open http://\<EC2_PUBLIC_IP\>:3000 in browser
2. Click **Register** → Create an account
3. **Login** with your credentials
4. You should see the Dashboard
5. Click **Create Poll** → Make a test poll
6. **Vote** on your poll
7. View results!

---

## 🔄 Step 10: Making Updates

### 10.1 Automatic Deployment

Any push to `main` branch triggers the pipeline:

```bash
# Make your changes to code
# Example: Edit client/src/App.js

# Commit and push
git add .
git commit -m "Update: improved dashboard UI"
git push origin main

# Pipeline automatically:
# 1. Builds new Docker images
# 2. Pushes to Docker Hub
# 3. Deploys to EC2
# 4. Restarts containers
```

### 10.2 Manual Deployment Trigger

1. Go to GitHub → **Actions** tab
2. Click **Deploy VoteX to AWS** workflow
3. Click **Run workflow** dropdown → **Run workflow**

---

## 🛠️ Troubleshooting

### Docker Build Fails in GitHub Actions

**Check:**
- Docker Hub credentials in GitHub Secrets
- Dockerfile syntax
- Network connectivity

**View logs:**
- GitHub Actions tab → Click failed workflow → Expand failed step

### Terraform Apply Fails

**Common issues:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check region
aws configure get region

# If key pair already exists, destroy and recreate:
terraform destroy
terraform apply
```

### Cannot Connect to EC2

**Check security group:**
```bash
# Ensure ports are open
aws ec2 describe-security-groups --group-names votex-security-group
```

**Check instance status:**
```bash
# Verify instance is running
aws ec2 describe-instances --filters "Name=tag:Name,Values=votex-server" --query "Reservations[0].Instances[0].State.Name"
```

### Application Not Accessible

**SSH into EC2 and check:**
```bash
ssh -i ~/.ssh/votex_key ubuntu@<EC2_PUBLIC_IP>

# Check Docker status
sudo systemctl status docker

# Check containers
sudo docker ps

# Check logs
cd votex
sudo docker compose logs

# Restart if needed
sudo docker compose down
sudo docker compose up -d
```

### Database Errors

**Reinitialize database:**
```bash
# SSH into EC2
ssh -i ~/.ssh/votex_key ubuntu@<EC2_PUBLIC_IP>

cd votex
sudo docker compose down -v
sudo docker compose up -d

# Wait for services to start
sudo docker compose logs -f
```

---

## 🧹 Cleanup (Delete All Resources)

### To Avoid AWS Charges:

```bash
# In WSL, navigate to terraform directory
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX/terraform"

# Destroy all AWS resources
terraform destroy

# Type 'yes' when prompted
```

This will delete:
- EC2 instance
- Elastic IP
- Security Group
- Key Pair

**Docker Hub images will remain** (you can delete manually if needed)

---

## 📊 Cost Estimate

**AWS Free Tier:**
- ✅ **t3.micro** (750 hours/month free for 12 months)
- ✅ 30 GB EBS storage (free)
- ✅ This setup uses **t3.micro** - completely FREE for first year!

**Instance Details:**
- Type: t3.micro
- vCPUs: 2
- Memory: 1 GiB
- Cost: $0 (free tier) for first 12 months

**Docker Hub:**
- Free tier: 1 private repository, unlimited public
- No charges for this project

---

## 📚 Additional Commands

### View Terraform State

```bash
cd terraform
terraform show
terraform state list
```

### Get EC2 IP Programmatically

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=votex-server" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text
```

### View Docker Hub Images

```bash
# List repositories
curl -s "https://hub.docker.com/v2/repositories/YOUR_DOCKER_USERNAME/" | jq .

# Or visit: https://hub.docker.com/repositories/YOUR_DOCKER_USERNAME
```

### Ansible Manual Run

```bash
cd ansible

# Update inventory with EC2 IP
echo "[votex_servers]" > inventory
echo "<EC2_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/votex_key" >> inventory

# Run playbook
ansible-playbook -i inventory playbook.yml -v
```

---

## 🎯 Summary Checklist

- [ ] AWS Account created
- [ ] IAM user with access keys created
- [ ] Docker Hub account and access token created
- [ ] SSH key pair generated
- [ ] AWS CLI configured
- [ ] Terraform installed
- [ ] EC2 instance deployed with Terraform
- [ ] GitHub repository created
- [ ] GitHub Secrets configured (5 secrets)
- [ ] Code pushed to GitHub
- [ ] Pipeline executed successfully
- [ ] Application accessible at EC2 IP

---

## 🆘 Getting Help

**Common Issues:**
1. **GitHub Actions fails**: Check Secrets are correct
2. **Can't SSH to EC2**: Wait 2-3 minutes after terraform apply
3. **App not loading**: Check docker containers are running
4. **Database errors**: Run `docker compose down -v && docker compose up -d`

**Logs to Check:**
- GitHub Actions: Repository → Actions tab
- EC2: `ssh` into instance → `sudo docker compose logs`
- Terraform: Output in terminal during `terraform apply`

---

## 🎉 Congratulations!

You now have a fully automated DevOps pipeline that:
- ✅ Builds Docker images on code push
- ✅ Pushes to Docker Hub
- ✅ Deploys to AWS EC2
- ✅ Uses Infrastructure as Code (Terraform)
- ✅ Automates deployment (Ansible)
- ✅ Implements CI/CD (GitHub Actions)

**Next Steps:**
- Add HTTPS with Let's Encrypt
- Set up monitoring with CloudWatch
- Add staging environment
- Implement blue-green deployment
- Add automated testing in pipeline
