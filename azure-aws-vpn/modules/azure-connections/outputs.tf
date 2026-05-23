output "local_network_gateway_ids" {
  description = "Resource IDs of all four Local Network Gateways"
  value       = azurerm_local_network_gateway.aws_tunnels[*].id
}

output "connection_ids" {
  description = "Resource IDs of all four Azure VPN Connections"
  value       = azurerm_virtual_network_gateway_connection.aws_tunnels[*].id
}

output "connection_names" {
  description = "Names of all four Azure VPN Connections"
  value       = azurerm_virtual_network_gateway_connection.aws_tunnels[*].name
}
