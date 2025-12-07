# 📁 Oracle Cloud Deployment - Files Created

## ✅ Summary

Successfully migrated VoteX from AWS EC2 to Oracle Cloud Infrastructure (OCI) with complete backup of original AWS files.

---

## 📦 Created Files and Folders

### 1. Backup Folder (`backup/`)

All AWS files safely backed up:

```
backup/
├── terraform-aws/              # Original AWS Terraform configuration
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── ansible-aws/                # Original AWS Ansible playbook
│   ├── playbook.yml
│   └── inventory.example
├── deploy-aws.yml              # Original GitHub Actions workflow
└── BACKUP_INFO.txt            # Restore instructions
```

---

### 2. Oracle Cloud Terraform (`terraform-oci/`)

Terraform configuration for OCI Always Free tier:

```
terraform-oci/
├── main.tf                     # OCI resources (VCN, subnet, instance)
├── variables.tf                # Input variables (OCIDs, region, etc.)
├── outputs.tf                  # Outputs (IP, URLs, SSH command)
├── cloud-init.yaml            # VM initialization (Docker, firewall)
└── terraform.tfvars.example   # Configuration template
```

**Features**:
- VCN with public subnet
- Internet Gateway
- Security Lists (ports 22, 3000, 4000)
- Compute instance (VM.Standard.E2.1.Micro or VM.Standard.A1.Flex)
- Ubuntu 22.04
- Auto-installs Docker and Docker Compose

---

### 3. Ansible Configuration (`ansible-oci/`)

Automated deployment for OCI:

```
ansible-oci/
├── playbook.yml               # Deployment playbook
└── inventory.example          # Inventory template
```

**Playbook tasks**:
- Wait for cloud-init
- Setup Docker
- Copy docker-compose.yml
- Pull Docker images
- Deploy application
- Health check verification

---

### 4. GitHub Actions Workflow

```
.github/workflows/
└── deploy-oci.yml             # CI/CD pipeline for Oracle Cloud
```

**Pipeline stages**:
1. Build Docker images (client + server)
2. Push to Docker Hub
3. Deploy to OCI with Ansible

---

### 5. Documentation Files

```
OCI_SETUP.md                   # Complete setup guide (500+ lines)
OCI_QUICKSTART.md              # Quick reference (200+ lines)
OCI_MIGRATION_SUMMARY.md       # Migration summary
```

#### OCI_SETUP.md Contents:
1. Prerequisites
2. Oracle Cloud Account Setup
3. Generate OCI API Keys
4. SSH Key Generation
5. Install Terraform in WSL
6. Configure Terraform
7. Deploy Infrastructure
8. GitHub Secrets Configuration
9. Trigger Deployment
10. Verify Deployment
11. Troubleshooting
12. Cost Information

---

## 🚀 How to Use These Files

### Step 1: Setup Oracle Cloud (OCI Dashboard)

1. Create free account at https://www.oracle.com/cloud/free/
2. Get OCIDs (Tenancy, User, Compartment)
3. Generate and upload API key
4. Save fingerprint

### Step 2: Setup WSL Ubuntu

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

# Generate SSH keys
cd ~/.ssh
ssh-keygen -t rsa -b 4096 -f votex_oci_key -N ""

# Configure Terraform
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX/terraform-oci"
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Fill in your values

# Deploy
terraform init
terraform apply
terraform output instance_public_ip  # Save this!
```

### Step 3: Configure GitHub Secrets

Add 5 secrets to GitHub repository:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `OCI_INSTANCE_IP`
- `OCI_SSH_PRIVATE_KEY`
- `MYSQL_ROOT_PASSWORD`

### Step 4: Deploy

```bash
git add .
git commit -m "Deploy to Oracle Cloud"
git push origin main
```

---

## 📚 Documentation Guide

| File | When to Use |
|------|-------------|
| `OCI_SETUP.md` | First time setup - detailed step-by-step guide |
| `OCI_QUICKSTART.md` | Quick reference for experienced users |
| `OCI_MIGRATION_SUMMARY.md` | Overview of what changed from AWS |
| `backup/BACKUP_INFO.txt` | How to restore AWS deployment |

---

## 🔄 Restore AWS Deployment

If needed, restore AWS files:

```bash
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX"

# Remove OCI files
rm -rf terraform-oci ansible-oci
rm .github/workflows/deploy-oci.yml

# Restore AWS files
mv backup/terraform-aws terraform
mv backup/ansible-aws ansible
mv backup/deploy-aws.yml .github/workflows/deploy.yml
```

See `backup/BACKUP_INFO.txt` for full instructions.

---

## 💡 Key Differences: AWS vs OCI

| Aspect | AWS | Oracle Cloud |
|--------|-----|--------------|
| **Free Tier Duration** | 12 months | **Forever** |
| **Compute** | t3.micro (2 vCPU, 1GB) | E2.1.Micro (1 OCPU, 1GB) or A1.Flex (4 OCPU, 24GB) |
| **Storage** | 30GB | 200GB |
| **Network** | 15GB outbound | 10TB outbound |
| **Auth** | Access keys | OCIDs + API key |
| **Terraform Provider** | `aws` | `oci` |

---

## ✅ Verification Checklist

After deployment:

- [ ] Terraform applied successfully
- [ ] Instance created in OCI Console
- [ ] Public IP obtained
- [ ] SSH connection works
- [ ] GitHub secrets configured
- [ ] GitHub Actions workflow succeeded
- [ ] Frontend accessible at http://IP:3000
- [ ] Backend health check at http://IP:4000/api/health
- [ ] Application fully functional

---

## 🆘 Need Help?

1. **First time?** → Start with `OCI_SETUP.md`
2. **Quick setup?** → Use `OCI_QUICKSTART.md`
3. **Understanding changes?** → Read `OCI_MIGRATION_SUMMARY.md`
4. **Restore AWS?** → See `backup/BACKUP_INFO.txt`
5. **Troubleshooting?** → `OCI_SETUP.md` Section 11

---

## 📊 File Statistics

- **Total files created**: 15
- **Documentation**: 4 comprehensive guides
- **Terraform files**: 5
- **Ansible files**: 2
- **GitHub Actions**: 1
- **Backup files**: 3 + BACKUP_INFO.txt

---

**Status**: ✅ All files created successfully and ready for deployment!

**Next Step**: Open `OCI_SETUP.md` and start from Section 1!
