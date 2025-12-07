# 🚀 VoteX Oracle Cloud Infrastructure Deployment Guide

Complete step-by-step guide to deploy VoteX on Oracle Cloud's **Always Free** tier using Terraform and GitHub Actions.

---

## 📑 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Oracle Cloud Account Setup](#oracle-cloud-account-setup)
3. [Generate OCI API Keys](#generate-oci-api-keys)
4. [SSH Key Generation](#ssh-key-generation)
5. [Install Terraform in WSL](#install-terraform-in-wsl)
6. [Configure Terraform](#configure-terraform)
7. [Deploy Infrastructure with Terraform](#deploy-infrastructure-with-terraform)
8. [GitHub Secrets Configuration](#github-secrets-configuration)
9. [Trigger Deployment](#trigger-deployment)
10. [Verify Deployment](#verify-deployment)
11. [Troubleshooting](#troubleshooting)
12. [Cost Information](#cost-information)

---

## 1. Prerequisites

### What You Need:
- ✅ Oracle Cloud account (free tier)
- ✅ WSL Ubuntu on Windows
- ✅ GitHub account with VoteX repository
- ✅ Docker Hub account
- ✅ Basic command line knowledge

---

## 2. Oracle Cloud Account Setup

### Step 2.1: Create Oracle Cloud Account

1. **Visit**: https://www.oracle.com/cloud/free/
2. **Click**: "Start for free"
3. **Fill in details**:
   - Choose your country
   - Enter name and email address
   - Create a strong password
4. **Verify email** and **phone number**
5. **Add payment method**: Credit card required (won't be charged for free tier)
6. **Complete registration**

### Step 2.2: Sign In to OCI Console

1. Go to: https://cloud.oracle.com/
2. Enter your **Cloud Account Name** (tenancy name)
3. Click **Continue**
4. Sign in with your credentials

### Step 2.3: Collect Required OCIDs

You'll need 4 OCIDs - follow these steps:

#### a) Get Tenancy OCID
```
OCI Console → Click Profile Icon (top right) → Tenancy: <your-tenancy-name>
```
- Copy the **OCID** (looks like: `ocid1.tenancy.oc1..aaaaaaaXXXXXX`)
- **Save it** - you'll need this multiple times

#### b) Get User OCID
```
OCI Console → Click Profile Icon → User Settings
```
- Under **User Information**, copy the **OCID**
- Format: `ocid1.user.oc1..aaaaaaaXXXXXX`

#### c) Get Compartment OCID
```
OCI Console → Identity & Security → Compartments
```
- Click on **(root)** compartment or create a new one
- Copy the **OCID**
- **Note**: You can use **Tenancy OCID** as compartment OCID for root

#### d) Note Your Region
```
OCI Console → Top right corner
```
- Your region is displayed (e.g., `US East (Ashburn)`)
- **Region Identifier**: `us-ashburn-1`

**Available Free Tier Regions**:
- `us-ashburn-1` (US East - Ohio)
- `us-phoenix-1` (US West - Phoenix)
- `uk-london-1` (UK - London)
- `eu-frankfurt-1` (Germany - Frankfurt)
- `ap-mumbai-1` (India - Mumbai)
- `ap-seoul-1` (South Korea - Seoul)
- `ap-tokyo-1` (Japan - Tokyo)
- `ap-sydney-1` (Australia - Sydney)

---

## 3. Generate OCI API Keys

### Step 3.1: Open WSL Ubuntu Terminal

In Windows PowerShell:
```powershell
wsl
```

### Step 3.2: Create OCI Directory

```bash
mkdir -p ~/.oci
cd ~/.oci
```

### Step 3.3: Generate API Key Pair

```bash
# Generate private key (no passphrase - press Enter when prompted)
openssl genrsa -out oci_api_key.pem 2048

# Generate public key from private key
openssl rsa -pubout -in oci_api_key.pem -out oci_api_key_public.pem

# Set proper permissions
chmod 600 oci_api_key.pem
chmod 644 oci_api_key_public.pem
```

### Step 3.4: Display Public Key

```bash
cat oci_api_key_public.pem
```

**Copy the entire output** including:
```
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END PUBLIC KEY-----
```

### Step 3.5: Upload Public Key to OCI Console

1. **Go to**: OCI Console → Profile Icon → **User Settings**
2. Scroll down to **API Keys** section
3. Click **Add API Key**
4. Select **Paste Public Key**
5. Paste the entire public key content
6. Click **Add**
7. **Copy the Fingerprint** shown (format: `aa:bb:cc:dd:ee:ff:...`)
   - **Save this fingerprint** - you'll need it for Terraform

---

## 4. SSH Key Generation

### Step 4.1: Generate SSH Key for VM Access

In WSL terminal:

```bash
cd ~/.ssh

# Generate SSH key pair (no passphrase)
ssh-keygen -t rsa -b 4096 -f votex_oci_key -N ""

# Set permissions
chmod 600 votex_oci_key
chmod 644 votex_oci_key.pub

# Verify keys created
ls -la votex_oci_key*
```

### Step 4.2: View Public Key

```bash
cat ~/.ssh/votex_oci_key.pub
```

**Save this** - you'll need it for Terraform configuration.

---

## 5. Install Terraform in WSL

### Step 5.1: Install Terraform

```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Terraform
sudo apt update
sudo apt install terraform -y
```

### Step 5.2: Verify Installation

```bash
terraform --version
```

Expected output:
```
Terraform v1.6.x
```

---

## 6. Configure Terraform

### Step 6.1: Navigate to Terraform Directory

```bash
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX/terraform-oci"
```

### Step 6.2: Create terraform.tfvars File

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### Step 6.3: Fill in Your Values

Replace the placeholders with your actual values:

```hcl
# OCI Authentication
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaXXXXXXXXXXXX"  # From Step 2.3.a
user_ocid        = "ocid1.user.oc1..aaaaaaaXXXXXXXXXXXX"      # From Step 2.3.b
fingerprint      = "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55"     # From Step 3.5
private_key_path = "~/.oci/oci_api_key.pem"                   # Created in Step 3.3
compartment_ocid = "ocid1.tenancy.oc1..aaaaaaaXXXXXXXXXXXX"  # Use tenancy_ocid or compartment OCID

# Region
region = "us-ashburn-1"  # Change to your preferred region

# Instance Shape
instance_shape = "VM.Standard.E2.1.Micro"  # Always Free AMD (1 OCPU, 1GB RAM)
# Alternative: "VM.Standard.A1.Flex"       # Always Free ARM (up to 4 OCPU, 24GB RAM)

# SSH Key
ssh_public_key_path = "~/.ssh/votex_oci_key.pub"
```

**Save and exit**: Press `Ctrl+X`, then `Y`, then `Enter`

---

## 7. Deploy Infrastructure with Terraform

### Step 7.1: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
...
Terraform has been successfully initialized!
```

### Step 7.2: Validate Configuration

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### Step 7.3: Preview Changes

```bash
terraform plan
```

Review the planned infrastructure:
- VCN (Virtual Cloud Network)
- Internet Gateway
- Route Table
- Subnet
- Security List
- Compute Instance

### Step 7.4: Deploy Infrastructure

```bash
terraform apply
```

- Review the plan
- Type `yes` when prompted
- Wait 2-5 minutes for deployment

### Step 7.5: Save Output Values

```bash
terraform output
```

**IMPORTANT**: Copy these values:

```bash
# Get instance public IP
terraform output instance_public_ip

# Get SSH connection command
terraform output ssh_connection

# Get URLs
terraform output frontend_url
terraform output backend_url
```

**Save the IP address** - you'll need it for GitHub secrets!

Example output:
```
instance_public_ip = "150.136.24.95"
ssh_connection = "ssh -i ~/.ssh/votex_oci_key ubuntu@150.136.24.95"
frontend_url = "http://150.136.24.95:3000"
backend_url = "http://150.136.24.95:4000"
```

### Step 7.6: Test SSH Connection

```bash
# Use the ssh_connection command from output
ssh -i ~/.ssh/votex_oci_key ubuntu@YOUR_INSTANCE_IP

# Check if cloud-init is still running (it may take 5-10 minutes)
cloud-init status

# You can logout - Ansible will install Docker if it's not ready yet
exit
```

**Note**: Don't worry if Docker isn't installed yet! The Ansible playbook will automatically:
- ✅ Check if Docker is installed
- ✅ Install Docker if missing
- ✅ Install Docker Compose if missing
- ✅ Configure firewall rules
- ✅ Deploy your application

This makes the deployment robust and ensures Docker is always properly installed.

---

## 8. GitHub Secrets Configuration

### Step 8.1: Go to GitHub Repository Settings

1. Open your browser
2. Navigate to: `https://github.com/Thanu10ekoon/DevOps_VoteX`
3. Click **Settings**
4. Click **Secrets and variables** → **Actions**
5. Click **New repository secret**

### Step 8.2: Add Required Secrets

Add these **5 secrets** one by one:

#### Secret 1: DOCKER_USERNAME
```
Name: DOCKER_USERNAME
Value: your-dockerhub-username
```
Example: `thanujaya10`

#### Secret 2: DOCKER_PASSWORD
```
Name: DOCKER_PASSWORD
Value: your-dockerhub-access-token
```

**How to get Docker Hub Access Token**:
1. Go to: https://hub.docker.com/settings/security
2. Click **New Access Token**
3. Name: `GitHub Actions VoteX`
4. Permissions: **Read, Write, Delete**
5. Generate and **copy the token**
6. Paste as secret value

#### Secret 3: OCI_INSTANCE_IP
```
Name: OCI_INSTANCE_IP
Value: YOUR_INSTANCE_PUBLIC_IP
```

Get the IP from:
```bash
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX/terraform-oci"
terraform output instance_public_ip
```

Example: `150.136.24.95`

#### Secret 4: OCI_SSH_PRIVATE_KEY
```
Name: OCI_SSH_PRIVATE_KEY
Value: <entire private key content>
```

Get the private key:
```bash
cat ~/.ssh/votex_oci_key
```

**Copy EVERYTHING** including headers:
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAACFwAAAA
...
(many lines)
...
-----END OPENSSH PRIVATE KEY-----
```

Paste the entire content as the secret value.

#### Secret 5: MYSQL_ROOT_PASSWORD (Optional)
```
Name: MYSQL_ROOT_PASSWORD
Value: your-secure-mysql-password
```

Example: `VoteX_Secure_2024!`

### Step 8.3: Verify All Secrets

You should have **5 secrets**:
- ✅ DOCKER_USERNAME
- ✅ DOCKER_PASSWORD
- ✅ OCI_INSTANCE_IP
- ✅ OCI_SSH_PRIVATE_KEY
- ✅ MYSQL_ROOT_PASSWORD

---

## 9. Trigger Deployment

### Option 1: Push to Main Branch (Automatic)

In WSL terminal:

```bash
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX"

# Add all changes
git add .

# Commit changes
git commit -m "Deploy to Oracle Cloud Infrastructure"

# Push to GitHub
git push origin main
```

This will automatically trigger the GitHub Actions workflow.

### Option 2: Manual Trigger

1. Go to GitHub repository
2. Click **Actions** tab
3. Click **Deploy VoteX to Oracle Cloud** workflow
4. Click **Run workflow** button
5. Select branch: `main`
6. Click **Run workflow**

### Step 9.1: Monitor Deployment

1. Click on the running workflow
2. Watch the progress:
   - **Build and Push Docker Images** (3-5 minutes)
   - **Deploy to Oracle Cloud** (2-3 minutes)

### Step 9.2: Check for Success

Look for:
- ✅ Green checkmarks on all steps
- 🎉 Deployment success message
- URLs displayed in the summary

---

## 10. Verify Deployment

### Step 10.1: Open Frontend

In your browser, navigate to:
```
http://YOUR_INSTANCE_IP:3000
```

Example: `http://150.136.24.95:3000`

You should see the VoteX login page!

### Step 10.2: Test Backend API

```
http://YOUR_INSTANCE_IP:4000/api/health
```

Expected response:
```json
{
  "status": "OK",
  "timestamp": "2024-12-05T10:30:00.000Z"
}
```

### Step 10.3: Test Full Functionality

1. **Register** a new account
2. **Login** with credentials
3. **Create a poll**
4. **Vote** on a poll
5. **View results**

### Step 10.4: Verify Containers Running

SSH into the instance:

```bash
ssh -i ~/.ssh/votex_oci_key ubuntu@YOUR_INSTANCE_IP

# Check running containers
docker ps

# Expected output: 3 containers running
# - votex-client
# - votex-server
# - votex-db

# Check logs
docker logs votex-server
docker logs votex-client

# Exit
exit
```

---

## 11. Troubleshooting

### Issue 1: Cannot Connect to Frontend

**Problem**: Browser shows "Can't reach this page"

**Solution**:
```bash
# SSH into instance
ssh -i ~/.ssh/votex_oci_key ubuntu@YOUR_INSTANCE_IP

# Check iptables rules
sudo iptables -L -n | grep 3000

# If missing, add rule
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 3000 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 4000 -j ACCEPT
sudo netfilter-persistent save

# Restart Docker containers
cd ~/votex
docker-compose down
docker-compose up -d
```

### Issue 2: OCI Dashboard Shows Instance Stopped

**Problem**: Instance appears stopped in OCI Console

**Solution**:
```bash
# In WSL, run Terraform again
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX/terraform-oci"
terraform apply
```

Or start from OCI Console:
```
Compute → Instances → votex-server → More Actions → Start
```

### Issue 3: GitHub Actions Deployment Fails

**Problem**: Deployment fails at "Deploy with Ansible" step

**Solutions**:
1. **Check SSH connection**:
   ```bash
   ssh -i ~/.ssh/votex_oci_key ubuntu@YOUR_IP
   ```

2. **Verify GitHub secrets** are correct:
   - OCI_INSTANCE_IP matches `terraform output`
   - OCI_SSH_PRIVATE_KEY is complete with headers
   - DOCKER credentials are valid

3. **Check instance firewall**:
   ```bash
   ssh -i ~/.ssh/votex_oci_key ubuntu@YOUR_IP
   sudo iptables -L -n
   ```

### Issue 4: Terraform Apply Fails

**Problem**: "Error: 400-InvalidParameter"

**Solution**: Check terraform.tfvars:
- All OCIDs are correct
- Fingerprint matches the one in OCI Console
- API key file exists at specified path
- Region is valid

### Issue 5: Database Connection Error

**Problem**: Backend shows database connection errors

**Solution**:
```bash
# SSH to instance
ssh -i ~/.ssh/votex_oci_key ubuntu@YOUR_IP

# Check if all containers are running
docker ps

# Restart MySQL container if needed
docker restart votex-db

# Wait 30 seconds, then restart backend
docker restart votex-server
```

### Common Commands

```bash
# View all Terraform outputs
terraform output

# Destroy infrastructure (if needed)
terraform destroy

# SSH to instance
ssh -i ~/.ssh/votex_oci_key ubuntu@$(terraform output -raw instance_public_ip)

# View container logs
docker logs votex-server -f
docker logs votex-client -f
docker logs votex-db -f

# Restart all containers
docker-compose restart

# View running processes
docker ps
```

---

## 12. Cost Information

### Oracle Cloud Always Free Tier Includes:

#### Compute (Choose One):
- **Option 1**: 2x VM.Standard.E2.1.Micro (AMD)
  - 1 OCPU, 1GB RAM each
  - Good for development

- **Option 2**: 4x VM.Standard.A1.Flex (ARM)
  - Up to 4 OCPUs, 24GB RAM total
  - **More powerful!** Recommended
  - Can create 1 instance with 4 OCPU + 24GB RAM
  - Or 2 instances with 2 OCPU + 12GB RAM each

#### Storage:
- 200 GB Block Volume (total across all volumes)
- 10 GB Object Storage

#### Networking:
- 10 TB outbound data transfer per month
- All inbound data transfer (free)

### VoteX Resource Usage:

**Current Setup (VM.Standard.E2.1.Micro)**:
- 1 Compute instance
- 50 GB boot volume
- Minimal outbound traffic (< 100 GB/month)
- **100% FREE** ✅

**Upgrade Option (VM.Standard.A1.Flex)**:
- Change `instance_shape` to `VM.Standard.A1.Flex` in terraform.tfvars
- Configure 2-4 OCPUs and 12-24 GB RAM
- Still **100% FREE** ✅

### No Charges For:
- ✅ Compute instances (within free tier)
- ✅ Block storage (up to 200GB)
- ✅ VCN and networking
- ✅ Load balancers (2 free)
- ✅ Public IP addresses
- ✅ Inbound data transfer

---

## 📚 Additional Resources

### OCI Documentation:
- [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm)
- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Compute Instances](https://docs.oracle.com/en-us/iaas/Content/Compute/home.htm)

### VoteX Documentation:
- Main README: `../README.md`
- Backup Info: `../backup/BACKUP_INFO.txt`
- GitHub Actions: `../.github/workflows/deploy-oci.yml`

### Support:
- Check GitHub Actions logs for deployment issues
- Review Ansible playbook output
- SSH to instance for debugging
- Check OCI Console for instance status

---

## 🎯 Quick Reference Commands

```bash
# Navigate to Terraform directory
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX/terraform-oci"

# Initialize Terraform
terraform init

# Plan infrastructure
terraform plan

# Deploy infrastructure
terraform apply

# Get outputs
terraform output

# SSH to instance
ssh -i ~/.ssh/votex_oci_key ubuntu@$(terraform output -raw instance_public_ip)

# Destroy infrastructure
terraform destroy
```

---

## ✅ Deployment Checklist

- [ ] Oracle Cloud account created
- [ ] Collected all OCIDs (tenancy, user, compartment)
- [ ] Generated OCI API keys
- [ ] Uploaded public key to OCI Console
- [ ] Generated SSH key pair
- [ ] Installed Terraform in WSL
- [ ] Created terraform.tfvars with correct values
- [ ] Ran `terraform apply` successfully
- [ ] Saved instance public IP
- [ ] Added all 5 GitHub secrets
- [ ] Pushed code to GitHub or triggered workflow
- [ ] Verified frontend accessible
- [ ] Verified backend health endpoint
- [ ] Tested full application functionality

---

**🎉 Congratulations! Your VoteX application is now running on Oracle Cloud's Always Free tier!**

Access your application at: `http://YOUR_INSTANCE_IP:3000`
