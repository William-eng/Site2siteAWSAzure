output "vnet_id" {
  description = "Resource ID of the Azure VNet"
  value       = azurerm_virtual_network.main.id
}

output "vpn_gateway_id" {
  description = "Resource ID of the Azure VPN Gateway"
  value       = azurerm_virtual_network_gateway.main.id
}

output "vpn_gateway_pip0" {
  description = "Public IP address of VPN Gateway Instance 0 (use for AWS Customer Gateway 1)"
  value       = azurerm_public_ip.vpngw_pip0.ip_address
}

output "vpn_gateway_pip1" {
  description = "Public IP address of VPN Gateway Instance 1 (use for AWS Customer Gateway 2)"
  value       = azurerm_public_ip.vpngw_pip1.ip_address
}

output "vpn_gateway_bgp_asn" {
  description = "BGP ASN of the Azure VPN Gateway"
  value       = var.azure_bgp_asn
}

output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.main.name
}


