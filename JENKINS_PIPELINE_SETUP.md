# VoteX Jenkins Pipeline Setup Guide

Complete step-by-step guide to set up CI/CD pipeline with Jenkins for deploying VoteX to AWS EC2.

---

## 📋 Prerequisites

- AWS EC2 instance (already created with Terraform)
- Docker Hub Account
- GitHub Account
- Jenkins server (can be local or on another EC2 instance)
- All the same AWS credentials and SSH keys from GitHub Actions setup

---

## 🔧 Part 1: Install Jenkins

### Option 1: Install Jenkins on Ubuntu (EC2 or Local VM)

```bash
# Update system
sudo apt update

# Install Java (Jenkins requirement)
sudo apt install -y openjdk-17-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check status
sudo systemctl status jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Option 2: Install Jenkins using Docker

```bash
# Create volume for Jenkins data
docker volume create jenkins_home

# Run Jenkins container
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --restart unless-stopped \
  jenkins/jenkins:lts

# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## 🌐 Part 2: Initial Jenkins Setup

### 2.1 Access Jenkins Web Interface

1. Open browser and go to: `http://<JENKINS_SERVER_IP>:8080`
   - If local: `http://localhost:8080`
   - If EC2: `http://<EC2_PUBLIC_IP>:8080`

2. Paste the initial admin password from Step 1

3. Click **Install suggested plugins** (wait for installation)

4. Create First Admin User:
   - Username: `admin` (or your choice)
   - Password: (set a strong password)
   - Full name: Your name
   - Email: your email
   
5. Jenkins URL: Keep default or customize

6. Click **Start using Jenkins**

---

## 🔌 Part 3: Install Required Jenkins Plugins

1. Go to **Dashboard** → **Manage Jenkins** → **Plugins**

2. Click **Available plugins** tab

3. Search and install these plugins:
   - ✅ **Docker Pipeline** (for Docker commands)
   - ✅ **Amazon Web Services SDK** (for AWS CLI)
   - ✅ **Pipeline** (should be pre-installed)
   - ✅ **Git** (should be pre-installed)
   - ✅ **Credentials Binding** (should be pre-installed)
   - ✅ **Email Extension** (for notifications - optional)

4. Check **Restart Jenkins when installation is complete**

5. Wait for Jenkins to restart

---

## 🔐 Part 4: Configure Jenkins Credentials

### 4.1 Add Docker Hub Credentials

1. Go to **Dashboard** → **Manage Jenkins** → **Credentials**

2. Click **System** → **Global credentials (unrestricted)**

3. Click **Add Credentials**

4. Configure:
   - Kind: **Username with password**
   - Scope: **Global**
   - Username: `<YOUR_DOCKER_HUB_USERNAME>`
   - Password: `<YOUR_DOCKER_HUB_ACCESS_TOKEN>`
   - ID: `docker-username`
   - Description: `Docker Hub Username`

5. Click **Create**

6. **Repeat** for Docker password:
   - Kind: **Secret text**
   - Secret: `<YOUR_DOCKER_HUB_ACCESS_TOKEN>`
   - ID: `docker-password`
   - Description: `Docker Hub Password`

### 4.2 Add AWS Credentials

1. Click **Add Credentials** again

2. AWS Access Key:
   - Kind: **Secret text**
   - Secret: `<YOUR_AWS_ACCESS_KEY_ID>`
   - ID: `aws-access-key-id`
   - Description: `AWS Access Key ID`

3. Click **Create**

4. **Add** AWS Secret Key:
   - Kind: **Secret text**
   - Secret: `<YOUR_AWS_SECRET_ACCESS_KEY>`
   - ID: `aws-secret-access-key`
   - Description: `AWS Secret Access Key`

### 4.3 Add EC2 SSH Private Key

1. Click **Add Credentials**

2. Configure:
   - Kind: **Secret text**
   - Secret: (Paste the **entire** private key content from `~/.ssh/votex_key`)
   - ID: `ec2-ssh-private-key`
   - Description: `EC2 SSH Private Key`

3. Click **Create**

**Summary - You should have 5 credentials:**
- ✅ `docker-username`
- ✅ `docker-password`
- ✅ `aws-access-key-id`
- ✅ `aws-secret-access-key`
- ✅ `ec2-ssh-private-key`

---

## 🛠️ Part 5: Install Required Tools on Jenkins Server

### 5.1 SSH into Jenkins Server

```bash
# If Jenkins is on EC2
ssh -i <key> ubuntu@<JENKINS_SERVER_IP>

# If Jenkins is in Docker container
docker exec -it -u root jenkins bash
```

### 5.2 Install Docker (if not already installed)

```bash
# Update packages
sudo apt-get update

# Install dependencies
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add Jenkins user to Docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

### 5.3 Install AWS CLI

```bash
# Download AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Install unzip if needed
sudo apt-get install -y unzip

# Unzip and install
unzip awscliv2.zip
sudo ./aws/install

# Verify
aws --version
```

### 5.4 Install Ansible

```bash
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible

# Verify
ansible --version
```

### 5.5 Install Git (if not already installed)

```bash
sudo apt-get install -y git

# Verify
git --version
```

---

## 📦 Part 6: Create Jenkins Pipeline Job

### 6.1 Create New Pipeline

1. Go to **Jenkins Dashboard**

2. Click **New Item**

3. Enter item name: `VoteX-Deploy-AWS`

4. Select **Pipeline**

5. Click **OK**

### 6.2 Configure Pipeline

#### General Section:
- ✅ Check **GitHub project**
- Project url: `https://github.com/Thanu10ekoon/DevOps_VoteX/`

#### Build Triggers:
- ✅ Check **Poll SCM**
- Schedule: `H/5 * * * *` (polls GitHub every 5 minutes)
  - Or use `* * * * *` for every minute (more frequent)

**Alternative:** Set up GitHub webhook (see Part 8)

#### Pipeline Section:
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: `https://github.com/Thanu10ekoon/DevOps_VoteX.git`
- Credentials: None (for public repo)
- Branches to build: `*/main`
- Script Path: `Jenkinsfile`

#### Advanced Settings (Optional):
- Lightweight checkout: ✅ Check this for faster cloning

### 6.3 Save Pipeline

Click **Save**

---

## 🚀 Part 7: Run the Pipeline

### 7.1 Manual Trigger

1. Go to your pipeline: **Dashboard** → **VoteX-Deploy-AWS**

2. Click **Build Now** (left sidebar)

3. Click on the build number (e.g., **#1**) that appears

4. Click **Console Output** to watch real-time logs

### 7.2 Monitor Pipeline Stages

You should see these stages:
1. ✅ Checkout Code
2. ✅ Setup Docker Buildx
3. ✅ Login to Docker Hub
4. ✅ Build and Push Client Image
5. ✅ Build and Push Server Image
6. ✅ Configure AWS Credentials
7. ✅ Get EC2 Instance IP
8. ✅ Setup SSH Key
9. ✅ Install Ansible
10. ✅ Install Ansible Docker Collection
11. ✅ Create Ansible Inventory
12. ✅ Update Docker Compose Configuration
13. ✅ Deploy with Ansible
14. ✅ Deployment Summary

### 7.3 Check Results

After successful build:
- ✅ Check **Console Output** - should show "SUCCESS"
- ✅ Check **Build History** - green checkmark ✅
- ✅ Open application: `http://<EC2_IP>:3000`

---

## 🔔 Part 8: Setup GitHub Webhook (Automatic Triggers)

### 8.1 Configure Jenkins

1. Go to **Manage Jenkins** → **Configure System**

2. Find **GitHub** section

3. Click **Advanced**

4. Check **Specify another hook URL for GitHub configuration**

5. Note the URL format: `http://<JENKINS_URL>/github-webhook/`

### 8.2 Configure GitHub Repository

1. Go to your GitHub repository: `https://github.com/Thanu10ekoon/DevOps_VoteX`

2. Click **Settings** → **Webhooks** → **Add webhook**

3. Configure:
   - Payload URL: `http://<JENKINS_PUBLIC_IP>:8080/github-webhook/`
   - Content type: `application/json`
   - Secret: (leave empty or set if needed)
   - Which events: **Just the push event**
   - Active: ✅ Check

4. Click **Add webhook**

5. Test: Push a commit to `main` branch - pipeline should auto-trigger!

**Note:** If Jenkins is on localhost, use **ngrok** or **serveo** to expose it:
```bash
# Using ngrok (install first)
ngrok http 8080

# Use the ngrok URL in GitHub webhook
```

---

## 🔄 Part 9: Making Updates (CI/CD Workflow)

### Automatic Deployment (with webhook):

```bash
# Make changes to your code
# Example: Edit client/src/App.js

# Commit and push
git add .
git commit -m "Update: improved dashboard UI"
git push origin main

# Jenkins will automatically:
# 1. Detect the push (via webhook or polling)
# 2. Build new Docker images
# 3. Push to Docker Hub
# 4. Deploy to EC2
# 5. Restart containers
```

### Manual Deployment:

1. Go to **Dashboard** → **VoteX-Deploy-AWS**
2. Click **Build Now**
3. Monitor in **Console Output**

---

## 🎨 Part 10: Pipeline Visualization

### 10.1 View Pipeline Stages

1. Go to your pipeline job

2. Click on a build number

3. Click **Pipeline Steps** or **Pipeline Overview**

4. You'll see a visual representation of:
   - ✅ Each stage
   - ⏱️ Duration
   - 📊 Success/Failure status
   - 📝 Logs for each stage

### 10.2 Blue Ocean UI (Optional - Better Visualization)

1. Install **Blue Ocean** plugin:
   - **Manage Jenkins** → **Plugins** → Search "Blue Ocean" → **Install**

2. After restart, click **Open Blue Ocean** (left sidebar)

3. Much better visual pipeline representation!

---

## 🛠️ Part 11: Troubleshooting

### Issue: Docker permission denied

```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# If using Docker container for Jenkins
docker exec -u root jenkins usermod -aG docker jenkins
docker restart jenkins
```

### Issue: AWS CLI not found

```bash
# Install AWS CLI on Jenkins server
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Issue: Ansible not found

```bash
# SSH into Jenkins server
sudo apt-get update
sudo apt-get install -y ansible
```

### Issue: SSH connection fails

**Check:**
1. EC2 Security Group allows SSH (port 22) from Jenkins server IP
2. SSH key in Jenkins credentials is correct
3. Test manually:
   ```bash
   ssh -i ~/.ssh/votex_key ubuntu@<EC2_IP>
   ```

### Issue: Pipeline fails at "Build and Push" stage

**Check:**
1. Docker Hub credentials are correct
2. Jenkins server has internet access
3. Docker daemon is running: `sudo systemctl status docker`

### View Jenkins Logs

```bash
# On Ubuntu
sudo journalctl -u jenkins -f

# In Docker
docker logs -f jenkins
```

---

## 📊 Part 12: Comparison - Jenkins vs GitHub Actions

| Feature | GitHub Actions | Jenkins |
|---------|---------------|---------|
| **Setup** | No setup needed | Requires server installation |
| **Cost** | Free for public repos, limited minutes for private | Free (you pay for server) |
| **Maintenance** | Managed by GitHub | You manage updates |
| **Flexibility** | Limited to GitHub runners | Full control over environment |
| **Plugins** | Marketplace actions | Extensive plugin ecosystem |
| **Security** | Secrets managed by GitHub | You manage credentials |
| **Speed** | Fast (dedicated runners) | Depends on your server |
| **Visibility** | Great UI in GitHub | Needs Blue Ocean for best UI |

---

## ✅ Pipeline Success Checklist

After running the pipeline, verify:

- [ ] All 14 stages completed successfully ✅
- [ ] Docker images pushed to Docker Hub
  - Check: `https://hub.docker.com/u/<USERNAME>`
  - Should see `votex-client:latest` and `votex-server:latest`
- [ ] Application accessible at `http://<EC2_IP>:3000`
- [ ] Backend API responding at `http://<EC2_IP>:4000/api/health`
- [ ] Database container running: SSH into EC2 → `docker ps`
- [ ] No errors in Console Output
- [ ] Build marked as **SUCCESS** (green checkmark)

---

## 🔐 Part 13: Secure Jenkins

### 13.1 Enable CSRF Protection

1. **Manage Jenkins** → **Configure Global Security**
2. Check **Prevent Cross Site Request Forgery exploits**
3. Save

### 13.2 Configure Matrix-based Security

1. **Manage Jenkins** → **Configure Global Security**
2. Authorization: **Matrix-based security**
3. Add your admin user with all permissions
4. Save

### 13.3 Enable HTTPS (Optional but Recommended)

```bash
# Generate SSL certificate (self-signed for testing)
sudo openssl req -newkey rsa:2048 -nodes -keyout /etc/ssl/private/jenkins.key \
  -x509 -days 365 -out /etc/ssl/certs/jenkins.crt

# Configure Jenkins to use HTTPS
# Edit /etc/default/jenkins or docker run command to add:
# --httpPort=-1 --httpsPort=8443 --httpsCertificate=/etc/ssl/certs/jenkins.crt --httpsPrivateKey=/etc/ssl/private/jenkins.key
```

---

## 🎉 Congratulations!

You now have a fully automated Jenkins CI/CD pipeline that:
- ✅ Builds Docker images on code push
- ✅ Pushes to Docker Hub
- ✅ Deploys to AWS EC2
- ✅ Uses Infrastructure as Code (Terraform)
- ✅ Automates deployment (Ansible)
- ✅ Runs on your own Jenkins server

**Next Steps:**
- Set up email notifications (configure Email Extension plugin)
- Add automated testing stages
- Implement blue-green deployment
- Set up monitoring with Prometheus/Grafana
- Add Slack notifications for build status
