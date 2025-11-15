# Jenkins CI/CD Pipeline Setup for VoteX

This document provides instructions for setting up the Jenkins CI/CD pipeline that mirrors the GitHub Actions workflow.

## Prerequisites

1. **Jenkins Server** (version 2.400+)
2. **Docker** installed on Jenkins agent
3. **AWS CLI** installed on Jenkins agent
4. **Git** installed on Jenkins agent

## Required Jenkins Plugins

Install the following plugins from Jenkins > Manage Jenkins > Plugin Manager:

1. **Docker Pipeline** - For Docker operations
2. **AWS Steps** - For AWS operations (optional, we use AWS CLI)
3. **Pipeline** - Core pipeline functionality
4. **Git** - For source code management
5. **Credentials Binding** - For secure credential handling
6. **Email Extension** - For email notifications
7. **Timestamper** - For build timestamps

## Jenkins Credentials Setup

Navigate to Jenkins > Manage Jenkins > Credentials > System > Global credentials

Add the following credentials:

### 1. Docker Hub Credentials
- **Kind**: Username with password
- **ID**: `docker-username`
- **Username**: Your Docker Hub username
- **Password**: Your Docker Hub password

### 2. Docker Hub Password (Secret Text)
- **Kind**: Secret text
- **ID**: `docker-password`
- **Secret**: Your Docker Hub password

### 3. AWS Access Key ID
- **Kind**: Secret text
- **ID**: `aws-access-key-id`
- **Secret**: Your AWS access key ID

### 4. AWS Secret Access Key
- **Kind**: Secret text
- **ID**: `aws-secret-access-key`
- **Secret**: Your AWS secret access key

### 5. EC2 SSH Private Key
- **Kind**: Secret text
- **ID**: `ec2-ssh-private-key`
- **Secret**: Your EC2 private key (entire content including BEGIN/END lines)

## Jenkins Job Configuration

### Step 1: Create New Pipeline Job

1. Click **New Item**
2. Enter name: `VoteX-Deploy-Pipeline`
3. Select **Pipeline**
4. Click **OK**

### Step 2: Configure Pipeline

#### General Settings
- ✅ **Discard old builds**: Keep last 10 builds
- ✅ **GitHub project**: `https://github.com/Thanu10ekoon/DevOps_VoteX`

#### Build Triggers
Choose one or more:
- ✅ **Poll SCM**: `H/5 * * * *` (check every 5 minutes)
- ✅ **GitHub hook trigger for GITScm polling** (requires webhook setup)
- ✅ **Trigger builds remotely** (optional)

#### Pipeline Configuration
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/Thanu10ekoon/DevOps_VoteX.git`
- **Credentials**: Add your GitHub credentials if private repo
- **Branch Specifier**: `*/main`
- **Script Path**: `Jenkinsfile`

### Step 3: Configure Email Notifications (Optional)

1. Go to **Manage Jenkins** > **Configure System**
2. Find **Extended E-mail Notification** section
3. Configure SMTP server settings:
   - SMTP server: `smtp.gmail.com` (for Gmail)
   - SMTP port: `587`
   - Use TLS: ✅
   - Credentials: Add Gmail app password
4. Set **Default Recipients**: Your email address

### Step 4: Add Environment Variables

In the pipeline job configuration, add these environment variables:

1. Go to pipeline configuration
2. Check **This project is parameterized**
3. Add **String Parameter**:
   - Name: `DEVELOPER_EMAIL`
   - Default Value: `your-email@example.com`
   - Description: Email for deployment notifications

## Jenkins Agent Requirements

Ensure your Jenkins agent has the following installed:

### 1. Docker with Buildx
```bash
# Verify Docker
docker --version

# Install Docker Buildx (if not present)
mkdir -p ~/.docker/cli-plugins/
wget -O ~/.docker/cli-plugins/docker-buildx \
  https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-amd64
chmod +x ~/.docker/cli-plugins/docker-buildx
docker buildx version
```

### 2. AWS CLI
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### 3. Ansible
```bash
# The pipeline installs Ansible automatically
# But you can pre-install it:
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible
ansible --version
```

### 4. Git
```bash
sudo apt-get install -y git
git --version
```

## GitHub Webhook Setup (Optional)

To trigger Jenkins builds automatically on Git push:

### 1. In GitHub Repository
1. Go to **Settings** > **Webhooks** > **Add webhook**
2. **Payload URL**: `http://your-jenkins-server:8080/github-webhook/`
3. **Content type**: `application/json`
4. **Which events**: "Just the push event"
5. **Active**: ✅
6. Click **Add webhook**

### 2. In Jenkins
1. Install **GitHub Plugin**
2. Go to **Manage Jenkins** > **Configure System**
3. Find **GitHub** section
4. Add GitHub server
5. Configure credentials

## Pipeline Stages

The Jenkinsfile includes the following stages (mirroring GitHub Actions):

1. **Checkout Code** - Clone repository
2. **Setup Docker Buildx** - Configure multi-platform builds
3. **Login to Docker Hub** - Authenticate with Docker registry
4. **Build and Push Client Image** - Build React frontend
5. **Build and Push Server Image** - Build Node.js backend
6. **Configure AWS Credentials** - Setup AWS CLI
7. **Get EC2 Instance IP** - Retrieve target EC2 instance
8. **Setup SSH Key** - Configure SSH access
9. **Install Ansible** - Install automation tool
10. **Install Ansible Docker Collection** - Add Docker modules
11. **Create Ansible Inventory** - Generate inventory file
12. **Update Docker Compose Configuration** - Update image references
13. **Deploy with Ansible** - Execute deployment
14. **Deployment Summary** - Display deployment info

## Running the Pipeline

### Manual Trigger
1. Go to your Jenkins job
2. Click **Build Now**
3. Monitor console output

### Automatic Trigger
- Push to `main` branch triggers automatic build (if webhook configured)
- SCM polling triggers build when changes detected

## Pipeline Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    JENKINS PIPELINE                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Checkout Code                                            │
│     └─> Clone from GitHub repository                         │
│                                                               │
│  2. Setup Docker Buildx                                      │
│     └─> Configure multi-platform builds                      │
│                                                               │
│  3. Login to Docker Hub                                      │
│     └─> Authenticate with registry                           │
│                                                               │
│  4. Build & Push Images (Parallel)                           │
│     ├─> Client: votex-client:latest                         │
│     └─> Server: votex-server:latest                         │
│                                                               │
│  5. Configure AWS                                            │
│     └─> Setup credentials and CLI                            │
│                                                               │
│  6. Get EC2 IP                                               │
│     └─> Query AWS for running instance                       │
│                                                               │
│  7. Setup SSH                                                │
│     └─> Configure key and known_hosts                        │
│                                                               │
│  8. Install Ansible                                          │
│     └─> Install automation framework                         │
│                                                               │
│  9. Deploy with Ansible                                      │
│     ├─> Pull Docker images                                   │
│     ├─> Stop old containers                                  │
│     └─> Start new containers                                 │
│                                                               │
│  10. Deployment Summary                                      │
│      └─> Display URLs and health check                       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Monitoring and Logs

### View Build Progress
- Click on build number in Jenkins
- Select **Console Output**
- Watch real-time logs

### Build Artifacts
- Docker images pushed to Docker Hub
- Deployment status in EC2 instance
- Ansible playbook execution logs

### Post-Build Actions
- ✅ Success: Email notification sent
- ❌ Failure: Email notification with error details
- 🧹 Cleanup: Credentials and temporary files removed

## Troubleshooting

### Docker Permission Issues
```bash
# Add Jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### AWS CLI Not Found
```bash
# Install AWS CLI on Jenkins agent
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### SSH Connection Failed
- Verify EC2 security group allows port 22 from Jenkins IP
- Check SSH private key format (PEM)
- Ensure Ubuntu user has correct permissions

### Ansible Errors
```bash
# Manually test Ansible connection
ansible -i ansible/inventory votex_servers -m ping --private-key ~/.ssh/votex_key
```

## Comparison: GitHub Actions vs Jenkins

| Feature | GitHub Actions | Jenkins |
|---------|---------------|---------|
| **Trigger** | Push to main | Push/SCM poll/Webhook |
| **Environment** | GitHub runners | Self-hosted agent |
| **Secrets** | GitHub Secrets | Jenkins Credentials |
| **Stages** | Jobs | Stages |
| **Notifications** | GitHub UI | Email + UI |
| **Logs** | GitHub Actions tab | Console Output |
| **Cost** | Free tier (2000 min/month) | Self-hosted (free) |

## Security Best Practices

1. ✅ Use Jenkins Credentials for sensitive data
2. ✅ Limit credential access to specific jobs
3. ✅ Clean up SSH keys and AWS credentials after use
4. ✅ Use HTTPS for Jenkins server
5. ✅ Enable CSRF protection
6. ✅ Regular security updates
7. ✅ Audit build logs regularly

## Maintenance

### Regular Tasks
- Update Jenkins and plugins monthly
- Review and rotate credentials quarterly
- Clean up old builds and artifacts
- Monitor disk space on Jenkins server
- Review security advisories

### Backup Strategy
- Backup Jenkins home directory
- Export job configurations
- Store credentials securely
- Document custom configurations

## Support

For issues or questions:
- Check Jenkins console logs
- Review Ansible playbook output
- Verify EC2 instance status
- Check Docker Hub for pushed images
- Review GitHub repository for code changes

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)
