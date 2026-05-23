###############################################################################
# Azure Module — Active-Active BGP VPN Gateway + Local Network Gateways
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
# Resource Group
# --------------------------------------------------------------------------- #
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# --------------------------------------------------------------------------- #
# Virtual Network & Subnets
# --------------------------------------------------------------------------- #
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.workload_subnet_prefix]
}

# GatewaySubnet must be named exactly "GatewaySubnet" — Azure requirement
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.gateway_subnet_prefix]
}

# --------------------------------------------------------------------------- #
# Public IPs — two required for active-active mode
# --------------------------------------------------------------------------- #
resource "azurerm_public_ip" "vpngw_pip0" {
  name                = "${var.vpn_gateway_name}-pip0"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_public_ip" "vpngw_pip1" {
  name                = "${var.vpn_gateway_name}-pip1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

# --------------------------------------------------------------------------- #
# VPN Gateway — Active-Active + BGP
# --------------------------------------------------------------------------- #
resource "azurerm_virtual_network_gateway" "main" {
  name                = var.vpn_gateway_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  type          = "Vpn"
  vpn_type      = "RouteBased"
  sku           = var.vpn_gateway_sku
  generation    = "Generation2"
  active_active = true # Required for multi-tunnel AWS connectivity
  bgp_enabled   = true

  # Instance 0 — primary public IP
  ip_configuration {
    name                          = "vpngw-ipconfig0"
    public_ip_address_id          = azurerm_public_ip.vpngw_pip0.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  # Instance 1 — secondary public IP (active-active)
  ip_configuration {
    name                          = "vpngw-ipconfig1"
    public_ip_address_id          = azurerm_public_ip.vpngw_pip1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  bgp_settings {
    asn = var.azure_bgp_asn

    # Instance 0: two APIPA addresses (one per AWS tunnel terminating on this instance)
    peering_addresses {
      ip_configuration_name = "vpngw-ipconfig0"
      apipa_addresses       = var.apipa_instance0
    }

    # Instance 1: two APIPA addresses (one per AWS tunnel terminating on this instance)
    peering_addresses {
      ip_configuration_name = "vpngw-ipconfig1"
      apipa_addresses       = var.apipa_instance1
    }
  }

  tags = var.tags
}

# --------------------------------------------------------------------------- #
# Local Network Gateways — one per AWS tunnel (4 total)
# --------------------------------------------------------------------------- #
# resource "azurerm_local_network_gateway" "aws_tunnels" {
#   count = length(var.aws_tunnels)

#   name                = "lng-${var.aws_tunnels[count.index].name}"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_resource_group.main.location

#   gateway_address = var.aws_tunnels[count.index].outside_ip

#   # No static address spaces — BGP handles route exchange
#   address_space = []

#   bgp_settings {
#     asn                 = var.aws_tunnels[count.index].aws_asn
#     bgp_peering_address = var.aws_tunnels[count.index].bgp_peer_ip
#   }

#   tags = var.tags
# }

# # --------------------------------------------------------------------------- #
# # Connections — one per AWS tunnel (4 total)
# # --------------------------------------------------------------------------- #
# resource "azurerm_virtual_network_gateway_connection" "aws_tunnels" {
#   count = length(var.aws_tunnels)

#   name                = "conn-${var.aws_tunnels[count.index].name}"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_resource_group.main.location

#   type                       = "IPsec"
#   virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
#   local_network_gateway_id   = azurerm_local_network_gateway.aws_tunnels[count.index].id

#   shared_key  = var.aws_tunnels[count.index].psk
#   bgp_enabled = true

#   custom_bgp_addresses {
#     # Only one of primary/secondary is actively used per connection;
#     # the other must still be provided (set to a valid but unused value).
#     primary   = var.aws_tunnels[count.index].primary_apipa
#     secondary = var.aws_tunnels[count.index].secondary_apipa
#   }

#   # IKEv2 policy aligned with AWS defaults
#   ipsec_policy {
#     ike_encryption   = "AES256"
#     ike_integrity    = "SHA256"
#     dh_group         = "DHGroup14"
#     ipsec_encryption = "AES256"
#     ipsec_integrity  = "SHA256"
#     pfs_group        = "PFS2048"
#     sa_lifetime      = 3600
#     sa_datasize      = 102400000
#   }

#   connection_mode     = "Default"
#   dpd_timeout_seconds = 45

#   tags = var.tags
# }
