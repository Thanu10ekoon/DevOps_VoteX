# Oracle Cloud Migration Summary

**Date**: December 5, 2025
**Migration**: AWS EC2 → Oracle Cloud Infrastructure (OCI)

---

## 📦 What Was Done

### 1. Backup Created ✅

All AWS deployment files backed up to `backup/` folder:

```
backup/
├── terraform-aws/          # Original AWS Terraform configuration
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── ansible-aws/            # Original AWS Ansible playbook
│   ├── playbook.yml
│   └── inventory.example
│
├── deploy-aws.yml          # Original GitHub Actions workflow for AWS
└── BACKUP_INFO.txt         # Instructions to restore AWS deployment
```

### 2. Oracle Cloud Infrastructure Files Created ✅

**New Terraform Configuration** (`terraform-oci/`):
- `main.tf` - OCI resources (VCN, subnet, security lists, compute instance)
- `variables.tf` - Input variables for OCI authentication and configuration
- `outputs.tf` - Output values (IP, URLs, SSH command)
- `cloud-init.yaml` - VM initialization script (installs Docker, configures firewall)
- `terraform.tfvars.example` - Template for configuration values

**New Ansible Configuration** (`ansible-oci/`):
- `playbook.yml` - Deployment automation for OCI instance
- `inventory.example` - Inventory file template

**New GitHub Actions Workflow**:
- `.github/workflows/deploy-oci.yml` - CI/CD pipeline for Oracle Cloud

**Documentation**:
- `OCI_SETUP.md` - Complete step-by-step setup guide (12 sections, 500+ lines)
- `OCI_QUICKSTART.md` - Quick reference guide
- `OCI_MIGRATION_SUMMARY.md` - This file

---

## 🔄 Migration Changes

| Aspect | AWS EC2 | Oracle Cloud |
|--------|---------|--------------|
| **Provider** | Amazon Web Services | Oracle Cloud Infrastructure |
| **Instance Type** | t3.micro (2 vCPU, 1GB RAM) | VM.Standard.E2.1.Micro (1 OCPU, 1GB RAM) |
| **Free Tier** | 750 hours/month (12 months) | **Always Free** (forever!) |
| **Alternative** | - | VM.Standard.A1.Flex (4 OCPU, 24GB RAM) - ARM |
| **Networking** | VPC, Security Groups | VCN, Security Lists |
| **Region** | eu-west-1 (Ireland) | Configurable (us-ashburn-1, etc.) |
| **Authentication** | Access Key + Secret Key | Tenancy OCID + User OCID + API Key |
| **Terraform** | `aws` provider | `oci` provider |
| **Cost** | Free for 1 year | **Free forever** |

---

## 📋 Oracle Cloud Always Free Tier

### What You Get (Forever):

#### Compute:
- **Option 1**: 2x VM.Standard.E2.1.Micro (AMD)
  - 1 OCPU, 1GB RAM each
  
- **Option 2**: 4x VM.Standard.A1.Flex (ARM) - **Recommended!**
  - Up to 4 OCPUs total
  - Up to 24GB RAM total
  - Can configure as: 1x (4 OCPU, 24GB) or 2x (2 OCPU, 12GB) or 4x (1 OCPU, 6GB)

#### Storage:
- 200 GB total Block Volume storage
- 10 GB Object Storage

#### Database:
- 2 Autonomous Databases (20GB each)

#### Networking:
- 10 TB outbound data transfer/month
- Unlimited inbound transfer

**VoteX Usage**: 1 instance + 50GB storage = **100% FREE forever!** ✅

---

## 🚀 Quick Start Commands

### In WSL Ubuntu:

```bash
# 1. Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# 2. Generate OCI API keys
mkdir -p ~/.oci && cd ~/.oci
openssl genrsa -out oci_api_key.pem 2048
openssl rsa -pubout -in oci_api_key.pem -out oci_api_key_public.pem
chmod 600 oci_api_key.pem
cat oci_api_key_public.pem  # Upload to OCI Console

# 3. Generate SSH keys
cd ~/.ssh
ssh-keygen -t rsa -b 4096 -f votex_oci_key -N ""

# 4. Configure Terraform
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX/terraform-oci"
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Fill in OCIDs

# 5. Deploy
terraform init
terraform apply

# 6. Get IP
terraform output instance_public_ip
```

---

## 🌐 In Oracle Cloud Dashboard:

### Required Steps:

1. **Create Account**
   - Go to https://www.oracle.com/cloud/free/
   - Sign up (requires email, phone, credit card - won't charge)

2. **Get Tenancy OCID**
   ```
   Profile Icon → Tenancy: <name> → Copy OCID
   ```

3. **Get User OCID**
   ```
   Profile Icon → User Settings → Copy OCID
   ```

4. **Add API Key**
   ```
   Profile Icon → User Settings → API Keys → Add API Key
   → Paste public key content
   → Copy fingerprint
   ```

5. **Get Compartment OCID**
   ```
   Identity & Security → Compartments → Copy OCID
   (Or use Tenancy OCID)
   ```

---

## 🔐 GitHub Secrets Required

Add these 5 secrets to GitHub repository:

| Secret Name | Source | Example |
|-------------|--------|---------|
| `DOCKER_USERNAME` | Docker Hub username | `thanujaya10` |
| `DOCKER_PASSWORD` | Docker Hub access token | `dckr_pat_xxxxx` |
| `OCI_INSTANCE_IP` | `terraform output instance_public_ip` | `150.136.24.95` |
| `OCI_SSH_PRIVATE_KEY` | `cat ~/.ssh/votex_oci_key` | `-----BEGIN OPENSSH PRIVATE KEY-----\n...` |
| `MYSQL_ROOT_PASSWORD` | Strong password | `VoteX_Secure_2024!` |

---

## 📂 New File Structure

```
VoteX/
├── backup/                     # ✅ AWS files backed up
│   ├── terraform-aws/
│   ├── ansible-aws/
│   ├── deploy-aws.yml
│   └── BACKUP_INFO.txt
│
├── terraform-oci/              # ✅ NEW: OCI Terraform
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── cloud-init.yaml
│   └── terraform.tfvars.example
│
├── ansible-oci/                # ✅ NEW: OCI Ansible
│   ├── playbook.yml
│   └── inventory.example
│
├── .github/workflows/
│   └── deploy-oci.yml          # ✅ NEW: OCI deployment
│
├── client/                     # (unchanged)
├── server/                     # (unchanged)
├── docker-compose.yml          # (unchanged)
├── OCI_SETUP.md               # ✅ NEW: Complete guide
├── OCI_QUICKSTART.md          # ✅ NEW: Quick reference
└── OCI_MIGRATION_SUMMARY.md   # ✅ NEW: This file
```

---

## ✅ Deployment Process

### 1. Infrastructure Setup (One-time)
```
Terraform → Create VCN, Subnet, Security Lists, Compute Instance
```

### 2. CI/CD Pipeline (Automatic)
```
Git Push → GitHub Actions → Build Docker Images → Push to Docker Hub → Deploy with Ansible
```

### 3. Application Deployment
```
Ansible → Pull Images → Start Containers (Client, Server, MySQL)
```

---

## 🌟 Key Advantages of Oracle Cloud

1. **Always Free** (no expiration)
2. **Better specs** with ARM instances (4 OCPU, 24GB RAM)
3. **More generous** network limits (10TB/month)
4. **Global** presence (8+ regions)
5. **Professional** infrastructure
6. **No credit card** charges ever (for free tier)

---

## 📖 Documentation Files

| File | Purpose | Size |
|------|---------|------|
| `OCI_SETUP.md` | Complete step-by-step guide | 500+ lines |
| `OCI_QUICKSTART.md` | Quick reference | 200+ lines |
| `OCI_MIGRATION_SUMMARY.md` | This summary | 150+ lines |
| `backup/BACKUP_INFO.txt` | AWS restore instructions | 40 lines |

---

## 🔄 To Restore AWS Deployment

See `backup/BACKUP_INFO.txt` for full instructions.

Quick restore:
```bash
cd "/mnt/d/Studies/5th Semester/Modules/DevOps Engineering - EC5207/Day 4 Login in Docker/VoteX"

# Delete OCI files
rm -rf terraform-oci ansible-oci .github/workflows/deploy-oci.yml

# Restore AWS files
mv backup/terraform-aws terraform
mv backup/ansible-aws ansible
mv backup/deploy-aws.yml .github/workflows/deploy.yml

# Update GitHub secrets to AWS values
# Deploy as before
```

---

## 🎯 Next Steps

1. Follow **OCI_SETUP.md** for detailed setup
2. Or use **OCI_QUICKSTART.md** for quick deployment
3. Configure `terraform-oci/terraform.tfvars` with your OCIDs
4. Run `terraform apply`
5. Add GitHub secrets
6. Push to GitHub to trigger deployment
7. Access application at `http://YOUR_IP:3000`

---

## 📞 Support

- **Detailed Guide**: `OCI_SETUP.md` (Section 11: Troubleshooting)
- **Quick Reference**: `OCI_QUICKSTART.md`
- **OCI Docs**: https://docs.oracle.com/en-us/iaas/
- **Terraform OCI**: https://registry.terraform.io/providers/oracle/oci/

---

**Status**: ✅ All files created successfully!

**Ready to deploy?** Start with `OCI_SETUP.md` Section 1!
