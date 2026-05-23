###############################################################################
# azure-connections module
#
# Creates ONLY the Local Network Gateways and Site-to-Site Connections
# for each AWS tunnel. The VNet, GatewaySubnet, and VPN Gateway must
# already exist (created by the azure-infra module).
#
# This module is intentionally infra-free so it can be applied after
# AWS outside IPs are known, without touching existing Azure resources.
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.73.0"
    }
  }
}

# --------------------------------------------------------------------------- #
# Local Network Gateways — one per AWS tunnel (4 total)
# --------------------------------------------------------------------------- #
resource "azurerm_local_network_gateway" "aws_tunnels" {
  count = length(var.aws_tunnels)

  name                = "lng-${var.aws_tunnels[count.index].name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  gateway_address = var.aws_tunnels[count.index].outside_ip
  address_space   = [] # BGP handles all route exchange — no static prefixes needed

  bgp_settings {
    asn                 = var.aws_tunnels[count.index].aws_asn
    bgp_peering_address = var.aws_tunnels[count.index].bgp_peer_ip
  }

  tags = var.tags
}

# --------------------------------------------------------------------------- #
# Connections — one per AWS tunnel (4 total)
# --------------------------------------------------------------------------- #
resource "azurerm_virtual_network_gateway_connection" "aws_tunnels" {
  count = length(var.aws_tunnels)

  name                = "conn-${var.aws_tunnels[count.index].name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  type                       = "IPsec"
  virtual_network_gateway_id = var.vpn_gateway_id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_tunnels[count.index].id

  shared_key  = var.aws_tunnels[count.index].psk
  bgp_enabled = true

  custom_bgp_addresses {
    primary   = var.aws_tunnels[count.index].primary_apipa
    secondary = var.aws_tunnels[count.index].secondary_apipa
  }

  # IKEv2 policy — must match what was set on the AWS side
  ipsec_policy {
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    dh_group         = "DHGroup14"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2048"
    sa_lifetime      = 3600
    sa_datasize      = 102400000
  }

  connection_mode     = "Default"
  dpd_timeout_seconds = 45

  tags = var.tags
}
