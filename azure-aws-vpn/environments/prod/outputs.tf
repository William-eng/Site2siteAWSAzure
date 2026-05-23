output "azure_vpn_gateway_pip0" {
  description = "Azure VPN Gateway Instance 0 public IP (used for AWS Customer Gateway 1)"
  value       = module.azure_infra.vpn_gateway_pip0
}

output "azure_vpn_gateway_pip1" {
  description = "Azure VPN Gateway Instance 1 public IP (used for AWS Customer Gateway 2)"
  value       = module.azure_infra.vpn_gateway_pip1
}

output "azure_vpn_gateway_id" {
  description = "Resource ID of the Azure VPN Gateway"
  value       = module.azure_infra.vpn_gateway_id
}

output "azure_resource_group_name" {
  description = "Azure Resource Group name"
  value       = module.azure_infra.resource_group_name
}

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = module.aws.vpc_id
}

output "aws_vpn_gateway_id" {
  description = "AWS Virtual Private Gateway ID"
  value       = module.aws.vpn_gateway_id
}

output "conn1_tunnel1_aws_outside_ip" {
  description = "AWS outside IP — Connection 1 / Tunnel 1 (toward Azure Instance 0)"
  value       = module.aws.conn1_tunnel1_outside_ip
}

output "conn1_tunnel2_aws_outside_ip" {
  description = "AWS outside IP — Connection 1 / Tunnel 2 (toward Azure Instance 0)"
  value       = module.aws.conn1_tunnel2_outside_ip
}

output "conn2_tunnel1_aws_outside_ip" {
  description = "AWS outside IP — Connection 2 / Tunnel 1 (toward Azure Instance 1)"
  value       = module.aws.conn2_tunnel1_outside_ip
}

output "conn2_tunnel2_aws_outside_ip" {
  description = "AWS outside IP — Connection 2 / Tunnel 2 (toward Azure Instance 1)"
  value       = module.aws.conn2_tunnel2_outside_ip
}

output "azure_connection_ids" {
  description = "Resource IDs of all 4 Azure VPN Connections"
  value       = module.azure_connections.connection_ids
}

output "azure_connection_names" {
  description = "Names of all 4 Azure VPN Connections"
  value       = module.azure_connections.connection_names
  sensitive   = true
}
