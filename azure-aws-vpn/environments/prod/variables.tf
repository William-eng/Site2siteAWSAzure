# Azure
variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "azure_resource_group_name" {
  description = "Name of the Azure Resource Group to create"
  type        = string
  default     = "rg-azure-aws-vpn-prod"
}

variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "azure_vnet_cidr" {
  description = "CIDR block for the Azure VNet (must not overlap AWS VPC)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "azure_workload_subnet_prefix" {
  description = "CIDR for the Azure workload subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "azure_gateway_subnet_prefix" {
  description = "CIDR for GatewaySubnet in Azure"
  type        = string
  default     = "10.1.1.0/24"
}

variable "azure_vpn_gateway_name" {
  description = "Name of the Azure VPN Gateway"
  type        = string
  default     = "vpngw-prod-azure-aws"
}

variable "azure_vpn_gateway_sku" {
  description = "SKU for the Azure VPN Gateway (AZ variants recommended)"
  type        = string
  default     = "VpnGw2AZ"
}

variable "azure_bgp_asn" {
  description = "BGP ASN for the Azure VPN Gateway (must differ from AWS)"
  type        = number
  default     = 65000
}

# AWS
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for the AWS VPC (must not overlap Azure VNet)"
  type        = string
  default     = "10.2.0.0/16"
}

variable "aws_private_subnet_cidrs" {
  description = "CIDRs for AWS private subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "aws_availability_zones" {
  description = "AZs to place subnets in"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "aws_bgp_asn" {
  description = "BGP ASN for the AWS Virtual Private Gateway"
  type        = number
  default     = 64512
}

# PSKs — sensitive, never commit to source control.
# AWS restriction: only alphanumeric, period (.) and underscore (_) allowed.
# Generate safely with: openssl rand -hex 32
# Do NOT use base64 — the +/= characters will be rejected by AWS.

variable "psk_tunnel1_instance0" {
  description = "PSK: AWS Connection 1 Tunnel 1 (Azure Instance 0). Alphanumeric/dot/underscore only."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9._]+$", var.psk_tunnel1_instance0))
    error_message = "AWS PSKs may only contain alphanumeric characters, periods (.), and underscores (_). Generate with: openssl rand -hex 32"
  }
}

variable "psk_tunnel2_instance0" {
  description = "PSK: AWS Connection 1 Tunnel 2 (Azure Instance 0). Alphanumeric/dot/underscore only."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9._]+$", var.psk_tunnel2_instance0))
    error_message = "AWS PSKs may only contain alphanumeric characters, periods (.), and underscores (_). Generate with: openssl rand -hex 32"
  }
}

variable "psk_tunnel1_instance1" {
  description = "PSK: AWS Connection 2 Tunnel 1 (Azure Instance 1). Alphanumeric/dot/underscore only."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9._]+$", var.psk_tunnel1_instance1))
    error_message = "AWS PSKs may only contain alphanumeric characters, periods (.), and underscores (_). Generate with: openssl rand -hex 32"
  }
}

variable "psk_tunnel2_instance1" {
  description = "PSK: AWS Connection 2 Tunnel 2 (Azure Instance 1). Alphanumeric/dot/underscore only."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9._]+$", var.psk_tunnel2_instance1))
    error_message = "AWS PSKs may only contain alphanumeric characters, periods (.), and underscores (_). Generate with: openssl rand -hex 32"
  }
}

variable "owner_tag" {
  description = "Owner tag applied to all resources"
  type        = string
  default     = "platform-team"
}
