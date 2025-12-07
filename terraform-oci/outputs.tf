output "instance_id" {
  description = "OCID of the VoteX compute instance"
  value       = oci_core_instance.votex_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the VoteX server"
  value       = data.oci_core_vnic.votex_vnic.public_ip_address
}

output "instance_private_ip" {
  description = "Private IP address of the VoteX server"
  value       = data.oci_core_vnic.votex_vnic.private_ip_address
}

output "vcn_id" {
  description = "OCID of the Virtual Cloud Network"
  value       = oci_core_vcn.votex_vcn.id
}

output "subnet_id" {
  description = "OCID of the subnet"
  value       = oci_core_subnet.votex_subnet.id
}

output "ssh_connection" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/votex_oci_key ubuntu@${data.oci_core_vnic.votex_vnic.public_ip_address}"
}

output "frontend_url" {
  description = "VoteX Frontend URL"
  value       = "http://${data.oci_core_vnic.votex_vnic.public_ip_address}:3000"
}

output "backend_url" {
  description = "VoteX Backend API URL"
  value       = "http://${data.oci_core_vnic.votex_vnic.public_ip_address}:4000"
}

output "health_check_url" {
  description = "Backend health check endpoint"
  value       = "http://${data.oci_core_vnic.votex_vnic.public_ip_address}:4000/api/health"
}

output "instance_shape" {
  description = "Shape of the compute instance"
  value       = oci_core_instance.votex_server.shape
}

output "availability_domain" {
  description = "Availability domain where instance is running"
  value       = oci_core_instance.votex_server.availability_domain
}
