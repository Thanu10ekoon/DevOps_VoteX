# OCI Authentication Variables
variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the OCI user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the OCI API key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key file"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "compartment_ocid" {
  description = "OCID of the compartment (can use tenancy OCID for root compartment)"
  type        = string
}

variable "region" {
  description = "OCI region (e.g., us-ashburn-1, uk-london-1, ap-mumbai-1)"
  type        = string
  default     = "us-ashburn-1"
}

# Instance Configuration
variable "instance_shape" {
  description = "Shape of the compute instance - Always Free options: VM.Standard.E2.1.Micro (AMD) or VM.Standard.A1.Flex (ARM)"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
  
  validation {
    condition     = contains(["VM.Standard.E2.1.Micro", "VM.Standard.A1.Flex"], var.instance_shape)
    error_message = "Instance shape must be VM.Standard.E2.1.Micro or VM.Standard.A1.Flex for Always Free tier."
  }
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/votex_oci_key.pub"
}

variable "project_name" {
  description = "Project name for tagging resources"
  type        = string
  default     = "VoteX"
}
