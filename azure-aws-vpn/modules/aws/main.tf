###############################################################################
# AWS Module — VPC, Virtual Private Gateway, Customer Gateways, S2S Connections
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.46.0"
    }
  }
}

# --------------------------------------------------------------------------- #
# VPC & Subnets
# --------------------------------------------------------------------------- #
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "vpc-azure-aws" })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, { Name = "snet-private-${count.index + 1}" })
}

# --------------------------------------------------------------------------- #
# Virtual Private Gateway
# --------------------------------------------------------------------------- #
resource "aws_vpn_gateway" "main" {
  vpc_id          = aws_vpc.main.id
  amazon_side_asn = var.aws_bgp_asn

  tags = merge(var.tags, { Name = "vpg-azure-aws" })
}

# Enable BGP route propagation to all private route tables
resource "aws_vpn_gateway_route_propagation" "main" {
  count          = length(aws_subnet.private)
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "rtb-private-${count.index + 1}" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --------------------------------------------------------------------------- #
# Customer Gateways — one per Azure VPN Gateway instance
# --------------------------------------------------------------------------- #

# Customer Gateway 1 → Azure Instance 0
resource "aws_customer_gateway" "instance0" {
  bgp_asn    = var.azure_bgp_asn
  ip_address = var.azure_vpngw_pip0
  type       = "ipsec.1"

  tags = merge(var.tags, { Name = "cgw-to-azure-instance0" })
}

# Customer Gateway 2 → Azure Instance 1
resource "aws_customer_gateway" "instance1" {
  bgp_asn    = var.azure_bgp_asn
  ip_address = var.azure_vpngw_pip1
  type       = "ipsec.1"

  tags = merge(var.tags, { Name = "cgw-to-azure-instance1" })
}

# --------------------------------------------------------------------------- #
# S2S VPN Connection 1 — toward Azure Instance 0
# Two tunnels, each landing on Instance 0's two APIPA addresses
# --------------------------------------------------------------------------- #
resource "aws_vpn_connection" "to_azure_instance0" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.instance0.id
  type                = "ipsec.1"
  static_routes_only  = false # false = use BGP (dynamic routing)

  # Tunnel 1 — maps to Azure APIPA 169.254.21.2
  tunnel1_inside_cidr   = "169.254.21.0/30"
  tunnel1_preshared_key = var.psk_tunnel1_instance0

  # Tunnel 2 — maps to Azure APIPA 169.254.22.2
  tunnel2_inside_cidr   = "169.254.22.0/30"
  tunnel2_preshared_key = var.psk_tunnel2_instance0

  # IKEv2 — matches Azure IPsec policy
  tunnel1_ike_versions = ["ikev2"]
  tunnel2_ike_versions = ["ikev2"]

  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  #tunnel1_phase2_pfs_group_numbers     = [14]

  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  #tunnel2_phase2_pfs_group_numbers     = [14]

  tunnel1_startup_action = "start"
  tunnel2_startup_action = "start"

  tags = merge(var.tags, { Name = "vpn-to-azure-instance0" })
}

# --------------------------------------------------------------------------- #
# S2S VPN Connection 2 — toward Azure Instance 1
# Two tunnels, each landing on Instance 1's two APIPA addresses
# --------------------------------------------------------------------------- #
resource "aws_vpn_connection" "to_azure_instance1" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.instance1.id
  type                = "ipsec.1"
  static_routes_only  = false

  # Tunnel 1 — maps to Azure APIPA 169.254.21.6
  tunnel1_inside_cidr   = "169.254.21.4/30"
  tunnel1_preshared_key = var.psk_tunnel1_instance1

  # Tunnel 2 — maps to Azure APIPA 169.254.22.6
  tunnel2_inside_cidr   = "169.254.22.4/30"
  tunnel2_preshared_key = var.psk_tunnel2_instance1

  tunnel1_ike_versions = ["ikev2"]
  tunnel2_ike_versions = ["ikev2"]

  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  #tunnel1_phase2_pfs_group_numbers     = [14]

  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  #tunnel2_phase2_pfs_group_numbers     = [14]

  tunnel1_startup_action = "start"
  tunnel2_startup_action = "start"

  tags = merge(var.tags, { Name = "vpn-to-azure-instance1" })
}
