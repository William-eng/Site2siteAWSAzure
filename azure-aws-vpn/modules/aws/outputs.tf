output "vpc_id" {
  description = "ID of the AWS VPC"
  value       = aws_vpc.main.id
}

output "vpn_gateway_id" {
  description = "ID of the AWS Virtual Private Gateway"
  value       = aws_vpn_gateway.main.id
}

output "aws_bgp_asn" {
  description = "BGP ASN of the AWS Virtual Private Gateway"
  value       = var.aws_bgp_asn
}

# Connection 1 (Instance 0) tunnel details
output "conn1_tunnel1_outside_ip" {
  description = "Outside IP of Connection 1 / Tunnel 1 (AWS side)"
  value       = aws_vpn_connection.to_azure_instance0.tunnel1_address
}

output "conn1_tunnel2_outside_ip" {
  description = "Outside IP of Connection 1 / Tunnel 2 (AWS side)"
  value       = aws_vpn_connection.to_azure_instance0.tunnel2_address
}

output "conn1_tunnel1_bgp_peer_ip" {
  description = "BGP peer IP (AWS side) for Connection 1 / Tunnel 1"
  value       = aws_vpn_connection.to_azure_instance0.tunnel1_bgp_asn != null ? "169.254.21.1" : "169.254.21.1"
}

output "conn1_tunnel2_bgp_peer_ip" {
  description = "BGP peer IP (AWS side) for Connection 1 / Tunnel 2"
  value       = "169.254.22.1"
}

# Connection 2 (Instance 1) tunnel details
output "conn2_tunnel1_outside_ip" {
  description = "Outside IP of Connection 2 / Tunnel 1 (AWS side)"
  value       = aws_vpn_connection.to_azure_instance1.tunnel1_address
}

output "conn2_tunnel2_outside_ip" {
  description = "Outside IP of Connection 2 / Tunnel 2 (AWS side)"
  value       = aws_vpn_connection.to_azure_instance1.tunnel2_address
}

output "conn2_tunnel1_bgp_peer_ip" {
  description = "BGP peer IP (AWS side) for Connection 2 / Tunnel 1"
  value       = "169.254.21.5"
}

output "conn2_tunnel2_bgp_peer_ip" {
  description = "BGP peer IP (AWS side) for Connection 2 / Tunnel 2"
  value       = "169.254.22.5"
}

# Aggregated tunnel list — consumed by the Azure module to create LNGs/Connections
output "azure_tunnel_configs" {
  description = "All 4 tunnel configs ready for the Azure module's aws_tunnels variable"
  sensitive   = true
  value = [
    {
      name            = "aws-conn1-tun1"
      outside_ip      = aws_vpn_connection.to_azure_instance0.tunnel1_address
      bgp_peer_ip     = "169.254.21.1"
      aws_asn         = var.aws_bgp_asn
      psk             = var.psk_tunnel1_instance0
      primary_apipa   = "169.254.21.2"  # Instance 0 APIPA for this tunnel
      secondary_apipa = "169.254.21.6"  # Instance 1 APIPA — unused, required by API
      use_primary     = true
    },
    {
      name            = "aws-conn1-tun2"
      outside_ip      = aws_vpn_connection.to_azure_instance0.tunnel2_address
      bgp_peer_ip     = "169.254.22.1"
      aws_asn         = var.aws_bgp_asn
      psk             = var.psk_tunnel2_instance0
      primary_apipa   = "169.254.22.2"  # Instance 0 APIPA for this tunnel
      secondary_apipa = "169.254.21.6"  # Instance 1 APIPA — unused, required by API
      use_primary     = true
    },
    {
      name            = "aws-conn2-tun1"
      outside_ip      = aws_vpn_connection.to_azure_instance1.tunnel1_address
      bgp_peer_ip     = "169.254.21.5"
      aws_asn         = var.aws_bgp_asn
      psk             = var.psk_tunnel1_instance1
      primary_apipa   = "169.254.21.2"  # Instance 0 APIPA — unused, required by API
      secondary_apipa = "169.254.21.6"  # Instance 1 APIPA for this tunnel
      use_primary     = false
    },
    {
      name            = "aws-conn2-tun2"
      outside_ip      = aws_vpn_connection.to_azure_instance1.tunnel2_address
      bgp_peer_ip     = "169.254.22.5"
      aws_asn         = var.aws_bgp_asn
      psk             = var.psk_tunnel2_instance1
      primary_apipa   = "169.254.21.2"  # Instance 0 APIPA — unused, required by API
      secondary_apipa = "169.254.22.6"  # Instance 1 APIPA for this tunnel
      use_primary     = false
    }
  ]
}
