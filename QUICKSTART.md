# Quick Reference - VoteX DevOps Pipeline

## 🚀 Quick Start Commands (WSL Ubuntu)

### Initial Setup
```bash
# Install prerequisites
sudo apt update
sudo apt install unzip -y

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# Configure AWS
aws configure
```

### Generate SSH Keys
```bash
cd ~/.ssh
ssh-keygen -t rsa -b 4096 -f votex_key -N ""
cat votex_key      # Copy for GitHub Secret
cat votex_key.pub  # Used by Terraform
```

### Deploy Infrastructure
```bash
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX/terraform"
terraform init
terraform plan
terraform apply  # Type 'yes'
```

### Push to GitHub (Triggers Pipeline)
```bash
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX"
git init
git remote add origin https://github.com/YOUR_USERNAME/DevOps_VoteX.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

### Connect to EC2
```bash
ssh -i ~/.ssh/votex_key ubuntu@<EC2_PUBLIC_IP>
```

### Check Deployment on EC2
```bash
sudo docker ps
cd votex
sudo docker compose logs -f
```

### Destroy Everything
```bash
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX/terraform"
terraform destroy  # Type 'yes'
```

## 📝 Required GitHub Secrets

| Name | Value |
|------|-------|
| `AWS_ACCESS_KEY_ID` | From IAM user |
| `AWS_SECRET_ACCESS_KEY` | From IAM user |
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub token |
| `EC2_SSH_PRIVATE_KEY` | Content of ~/.ssh/votex_key |

## 🔗 Access URLs

- Frontend: http://\<EC2_IP\>:3000
- Backend: http://\<EC2_IP\>:4000
- Health: http://\<EC2_IP\>:4000/api/health

## 🛠️ Troubleshooting

```bash
# Check AWS identity
aws sts get-caller-identity

# Get EC2 IP
aws ec2 describe-instances --filters "Name=tag:Name,Values=votex-server" --query "Reservations[0].Instances[0].PublicIpAddress" --output text

# SSH with verbose
ssh -v -i ~/.ssh/votex_key ubuntu@<EC2_IP>

# Reinitialize database on EC2
ssh -i ~/.ssh/votex_key ubuntu@<EC2_IP>
cd votex
sudo docker compose down -v
sudo docker compose up -d
```

## 📦 Project Structure

```
VoteX/
├── .github/workflows/
│   └── deploy.yml          # CI/CD pipeline
├── terraform/
│   ├── main.tf             # Infrastructure definition
│   ├── variables.tf        # Configuration variables
│   └── outputs.tf          # Output values
├── ansible/
│   ├── playbook.yml        # Deployment automation
│   ├── inventory           # Server list
│   └── ansible.cfg         # Ansible config
├── client/                 # React frontend
├── server/                 # Node.js backend
├── db/init.sql            # Database schema
├── docker-compose.yml     # Container orchestration
└── Pipe.md               # Full guide
```

## ⚡ Pipeline Flow

1. **Code Push** → GitHub
2. **Build** → Docker images (client, server)
3. **Push** → Docker Hub
4. **Deploy** → Ansible pulls images to EC2
5. **Run** → docker compose starts services

## 💰 Cost Alert

- **t3.micro**: FREE for 12 months (750 hours/month)
- Already configured in `terraform/variables.tf`
- Remember to destroy resources when done: `terraform destroy`

## 📞 Support

See `Pipe.md` for detailed instructions and troubleshooting.
