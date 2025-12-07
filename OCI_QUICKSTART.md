# 🚀 Oracle Cloud Deployment - Quick Start

This is a condensed quick-start guide. For detailed instructions, see [OCI_SETUP.md](OCI_SETUP.md).

---

## 📋 What Was Done

### Backup Created
All AWS deployment files have been moved to `backup/` folder:
- `backup/terraform-aws/` - Original AWS Terraform files
- `backup/ansible-aws/` - Original AWS Ansible files  
- `backup/deploy-aws.yml` - Original AWS GitHub Actions workflow
- `backup/BACKUP_INFO.txt` - Restore instructions

### New Oracle Cloud Files Created
- `terraform-oci/` - Terraform configuration for OCI
- `ansible-oci/` - Ansible playbook for OCI deployment
- `.github/workflows/deploy-oci.yml` - GitHub Actions for OCI
- `OCI_SETUP.md` - Complete setup guide

---

## ⚡ Quick Setup Steps

### 1. WSL Ubuntu Commands

```bash
# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# Generate OCI API keys
mkdir -p ~/.oci && cd ~/.oci
openssl genrsa -out oci_api_key.pem 2048
openssl rsa -pubout -in oci_api_key.pem -out oci_api_key_public.pem
chmod 600 oci_api_key.pem
cat oci_api_key_public.pem  # Copy this to OCI Console

# Generate SSH keys
cd ~/.ssh
ssh-keygen -t rsa -b 4096 -f votex_oci_key -N ""
cat votex_oci_key.pub  # You'll need this for Terraform

# Navigate to project
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX/terraform-oci"

# Configure Terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Fill in your OCIDs

# Deploy infrastructure
terraform init
terraform validate
terraform plan
terraform apply  # Type 'yes' when prompted

# Get instance IP
terraform output instance_public_ip  # SAVE THIS!
```

---

### 2. Oracle Cloud Dashboard Steps

#### A. Sign Up
1. Go to https://www.oracle.com/cloud/free/
2. Create free account
3. Verify email and phone
4. Add payment method (won't be charged)

#### B. Get Tenancy OCID
```
Profile Icon → Tenancy: <name> → Copy OCID
```

#### C. Get User OCID
```
Profile Icon → User Settings → Copy OCID
```

#### D. Add API Key
```
Profile Icon → User Settings → API Keys → Add API Key
→ Paste public key from ~/.oci/oci_api_key_public.pem
→ Copy the fingerprint shown
```

#### E. Get Compartment OCID
```
Identity & Security → Compartments → Copy OCID
(Or use Tenancy OCID for root compartment)
```

---

### 3. GitHub Secrets Configuration

Go to: `https://github.com/Thanu10ekoon/DevOps_VoteX/settings/secrets/actions`

Add these 5 secrets:

| Secret Name | How to Get | Example |
|-------------|------------|---------|
| `DOCKER_USERNAME` | Your Docker Hub username | `thanujaya10` |
| `DOCKER_PASSWORD` | Docker Hub → Settings → Security → New Access Token | `dckr_pat_...` |
| `OCI_INSTANCE_IP` | `terraform output instance_public_ip` | `150.136.24.95` |
| `OCI_SSH_PRIVATE_KEY` | `cat ~/.ssh/votex_oci_key` (entire content) | `-----BEGIN OPENSSH...` |
| `MYSQL_ROOT_PASSWORD` | Create a strong password | `VoteX_Secure_2024!` |

---

### 4. Deploy Application

```bash
# In project root
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX"

# Commit and push
git add .
git commit -m "Deploy to Oracle Cloud"
git push origin main
```

**Or** manually trigger in GitHub:
```
Actions → Deploy VoteX to Oracle Cloud → Run workflow
```

---

## 🌐 Access Your Application

After successful deployment:

- **Frontend**: `http://YOUR_INSTANCE_IP:3000`
- **Backend**: `http://YOUR_INSTANCE_IP:4000`
- **Health Check**: `http://YOUR_INSTANCE_IP:4000/api/health`

Replace `YOUR_INSTANCE_IP` with the IP from `terraform output`.

---

## 🔧 Terraform Configuration File

Edit `terraform-oci/terraform.tfvars`:

```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaXXXX"     # From OCI Console
user_ocid        = "ocid1.user.oc1..aaaaaaXXXX"        # From OCI Console
fingerprint      = "aa:bb:cc:dd:ee:ff:00:11:22:33"    # From API Key upload
private_key_path = "~/.oci/oci_api_key.pem"           # Generated in WSL
compartment_ocid = "ocid1.tenancy.oc1..aaaaaaXXXX"    # Same as tenancy or compartment OCID
region           = "us-ashburn-1"                      # Your preferred region

# Always Free Options:
# VM.Standard.E2.1.Micro - AMD (1 OCPU, 1GB RAM)
# VM.Standard.A1.Flex - ARM (up to 4 OCPU, 24GB RAM) - More powerful!
instance_shape = "VM.Standard.E2.1.Micro"

ssh_public_key_path = "~/.ssh/votex_oci_key.pub"
```

---

## 📊 Always Free Resources

Oracle Cloud Always Free tier includes:

### Compute (Choose One):
- **2x VM.Standard.E2.1.Micro** (AMD): 1 OCPU, 1GB RAM each
- **Up to 4x VM.Standard.A1.Flex** (ARM): Total 4 OCPUs, 24GB RAM

### Storage:
- 200 GB total Block Volume storage
- 10 GB Object Storage

### Networking:
- 10 TB outbound transfer/month
- Unlimited inbound transfer

**VoteX uses only 1 instance + 50GB storage = 100% FREE!** ✅

---

## 🐛 Quick Troubleshooting

### Can't access frontend?
```bash
# SSH to instance
ssh -i ~/.ssh/votex_oci_key ubuntu@YOUR_IP

# Fix firewall
sudo iptables -I INPUT 6 -p tcp --dport 3000 -j ACCEPT
sudo iptables -I INPUT 6 -p tcp --dport 4000 -j ACCEPT
sudo netfilter-persistent save

# Restart containers
cd ~/votex
docker-compose restart
```

### Terraform fails?
- Check all OCIDs are correct
- Verify API key fingerprint matches
- Ensure `~/.oci/oci_api_key.pem` exists
- Try different region

### GitHub Actions fails?
- Verify all 5 secrets are set correctly
- Check `OCI_SSH_PRIVATE_KEY` includes headers
- Ensure `OCI_INSTANCE_IP` is correct
- Test SSH manually: `ssh -i ~/.ssh/votex_oci_key ubuntu@YOUR_IP`

---

## 📁 File Structure

```
VoteX/
├── backup/
│   ├── terraform-aws/      # Original AWS Terraform
│   ├── ansible-aws/        # Original AWS Ansible
│   ├── deploy-aws.yml      # Original AWS workflow
│   └── BACKUP_INFO.txt     # Restore instructions
│
├── terraform-oci/          # NEW: OCI Terraform config
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── cloud-init.yaml
│   └── terraform.tfvars.example
│
├── ansible-oci/            # NEW: OCI Ansible playbook
│   ├── playbook.yml
│   └── inventory.example
│
├── .github/workflows/
│   └── deploy-oci.yml      # NEW: OCI deployment workflow
│
├── OCI_SETUP.md            # NEW: Detailed setup guide
└── OCI_QUICKSTART.md       # NEW: This file
```

---

## ⚙️ Useful Commands

```bash
# Terraform commands
cd terraform-oci
terraform init              # Initialize
terraform plan              # Preview changes
terraform apply             # Deploy
terraform output            # Show all outputs
terraform destroy           # Delete everything

# Get specific outputs
terraform output instance_public_ip
terraform output ssh_connection
terraform output frontend_url

# SSH to instance
ssh -i ~/.ssh/votex_oci_key ubuntu@$(terraform output -raw instance_public_ip)

# Docker commands (on instance)
docker ps                   # List containers
docker logs votex-server    # View backend logs
docker logs votex-client    # View frontend logs
docker-compose restart      # Restart all containers
docker-compose down && docker-compose up -d  # Full restart
```

---

## 🔄 Restore AWS Deployment

If you want to go back to AWS:

```bash
# In project root
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX"

# Delete OCI files
rm -rf terraform-oci ansible-oci
rm .github/workflows/deploy-oci.yml

# Restore AWS files
mv backup/terraform-aws terraform
mv backup/ansible-aws ansible
mv backup/deploy-aws.yml .github/workflows/deploy.yml

# Update GitHub secrets back to AWS values
# Then deploy as before
```

See `backup/BACKUP_INFO.txt` for details.

---

## 📖 Full Documentation

For complete step-by-step instructions with screenshots and detailed explanations, see:

**[OCI_SETUP.md](OCI_SETUP.md)** - Complete Oracle Cloud deployment guide

---

## ✅ Deployment Checklist

- [ ] Created Oracle Cloud free account
- [ ] Generated OCI API keys in WSL
- [ ] Uploaded public key to OCI Console
- [ ] Generated SSH keys
- [ ] Installed Terraform
- [ ] Created terraform.tfvars with correct values
- [ ] Ran `terraform apply`
- [ ] Added 5 GitHub secrets
- [ ] Pushed to GitHub or triggered workflow
- [ ] Verified application is accessible

---

**Need help?** Check [OCI_SETUP.md](OCI_SETUP.md) for detailed troubleshooting and step-by-step guides!
