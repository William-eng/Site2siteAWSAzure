###############################################################################
# environments/prod/main.tf
#
# Three non-overlapping modules — no resource is created twice:
#
#   module.azure_infra        → VNet, GatewaySubnet, VPN Gateway (active-active+BGP)
#   module.aws                → VPC, VPG, Customer Gateways, S2S connections
#   module.azure_connections  → Local Network Gateways + Connections (LNGs only)
#
# DEPLOYMENT ORDER (due to Azure gateway provisioning time):
#
#   Step 1 — Create Azure VPN Gateway (wait 30-60 min):
#     terraform apply -target=module.azure_infra
#
#   Step 2 — Full apply (AWS resources + Azure LNGs/Connections):
#     terraform apply
###############################################################################

terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.73.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.46.0"
    }
  }

  # Recommended: remote state for team collaboration
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "satfstateXXXXX"
  #   container_name       = "tfstate"
  #   key                  = "azure-aws-vpn/prod.tfstate"
  # }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

provider "aws" {
  region = var.aws_region
}

# --------------------------------------------------------------------------- #
# STEP 1: Azure infra — VNet, GatewaySubnet, Active-Active BGP VPN Gateway
# Run first: terraform apply -target=module.azure_infra
# --------------------------------------------------------------------------- #
module "azure_infra" {
  source = "../../modules/azure"

  resource_group_name    = var.azure_resource_group_name
  location               = var.azure_location
  vnet_address_space     = var.azure_vnet_cidr
  workload_subnet_prefix = var.azure_workload_subnet_prefix
  gateway_subnet_prefix  = var.azure_gateway_subnet_prefix
  vpn_gateway_name       = var.azure_vpn_gateway_name
  vpn_gateway_sku        = var.azure_vpn_gateway_sku
  azure_bgp_asn          = var.azure_bgp_asn

  # Populated after module.aws resolves — Terraform handles the sequencing
  aws_tunnels = module.aws.azure_tunnel_configs

  tags = local.common_tags
}

module "aws" {
  source = "../../modules/aws"

  aws_region           = var.aws_region
  vpc_cidr             = var.aws_vpc_cidr
  private_subnet_cidrs = var.aws_private_subnet_cidrs
  availability_zones   = var.aws_availability_zones
  aws_bgp_asn          = var.aws_bgp_asn
  azure_bgp_asn        = var.azure_bgp_asn
  azure_vpngw_pip0     = module.azure_infra.vpn_gateway_pip0
  azure_vpngw_pip1     = module.azure_infra.vpn_gateway_pip1

  psk_tunnel1_instance0 = var.psk_tunnel1_instance0
  psk_tunnel2_instance0 = var.psk_tunnel2_instance0
  psk_tunnel1_instance1 = var.psk_tunnel1_instance1
  psk_tunnel2_instance1 = var.psk_tunnel2_instance1

  tags = local.common_tags
}
# # --------------------------------------------------------------------------- #
# # STEP 2A: AWS — requires azure_infra public IPs
# # --------------------------------------------------------------------------- #
# module "aws" {
#   source = "../../modules/aws"

#   aws_region           = var.aws_region
#   vpc_cidr             = var.aws_vpc_cidr
#   private_subnet_cidrs = var.aws_private_subnet_cidrs
#   availability_zones   = var.aws_availability_zones
#   aws_bgp_asn          = var.aws_bgp_asn
#   azure_bgp_asn        = var.azure_bgp_asn
#   azure_vpngw_pip0     = module.azure_infra.vpn_gateway_pip0
#   azure_vpngw_pip1     = module.azure_infra.vpn_gateway_pip1

#   psk_tunnel1_instance0 = var.psk_tunnel1_instance0
#   psk_tunnel2_instance0 = var.psk_tunnel2_instance0
#   psk_tunnel1_instance1 = var.psk_tunnel1_instance1
#   psk_tunnel2_instance1 = var.psk_tunnel2_instance1

#   tags = local.common_tags
# }

# --------------------------------------------------------------------------- #
# STEP 2B: Azure LNGs + Connections only — no infra overlap
# Uses the dedicated azure-connections module to avoid re-creating any
# existing resources (Resource Group, VNet, VPN Gateway).
# --------------------------------------------------------------------------- #
module "azure_connections" {
  source = "../../modules/azure-connections"

  # Reference existing resources created by azure_infra
  resource_group_name = module.azure_infra.resource_group_name
  location            = var.azure_location
  vpn_gateway_id      = module.azure_infra.vpn_gateway_id

  # All 4 tunnel configs built from AWS module outputs
  aws_tunnels = module.aws.azure_tunnel_configs

  tags = local.common_tags

  depends_on = [module.azure_infra, module.aws]
}

locals {
  common_tags = {
    environment = "production"
    managed_by  = "terraform"
    project     = "azure-aws-bgp-vpn"
    owner       = var.owner_tag
  }
}
