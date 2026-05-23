variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region (e.g. eastus, westeurope)"
  type        = string
  default     = "eastus"
}

variable "vnet_name" {
  description = "Name of the Azure Virtual Network"
  type        = string
  default     = "vnet-azure-aws"
}

variable "vnet_address_space" {
  description = "Address space for the Azure VNet (must not overlap with AWS VPC)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "workload_subnet_prefix" {
  description = "CIDR for the workload subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "gateway_subnet_prefix" {
  description = "CIDR for GatewaySubnet (must be named exactly 'GatewaySubnet')"
  type        = string
  default     = "10.1.1.0/24"
}

variable "vpn_gateway_name" {
  description = "Name of the Azure VPN Gateway"
  type        = string
  default     = "vpngw-azure-aws"
}

variable "vpn_gateway_sku" {
  description = "SKU for the VPN Gateway. Use VpnGw2AZ+ for production zone-redundancy"
  type        = string
  default     = "VpnGw2AZ"

  validation {
    condition     = contains(["VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"], var.vpn_gateway_sku)
    error_message = "SKU must be an AZ-variant for zone redundancy."
  }
}

variable "azure_bgp_asn" {
  description = "BGP ASN for the Azure VPN Gateway (must differ from AWS ASN)"
  type        = number
  default     = 65000
}

# APIPA addresses for Instance 0 (primary)
variable "apipa_instance0" {
  description = "Two APIPA BGP addresses for Instance 0 (Tunnel1 and Tunnel2)"
  type        = list(string)
  default     = ["169.254.21.2", "169.254.22.2"]
}

# APIPA addresses for Instance 1 (secondary)
variable "apipa_instance1" {
  description = "Two APIPA BGP addresses for Instance 1 (Tunnel1 and Tunnel2)"
  type        = list(string)
  default     = ["169.254.21.6", "169.254.22.6"]
}

# AWS tunnel info passed in from the root module after AWS resources are created
variable "aws_tunnels" {
  description = "List of 4 AWS tunnel objects with outside_ip and bgp_peer_ip"
  type = list(object({
    name              = string
    outside_ip        = string
    bgp_peer_ip       = string
    aws_asn           = number
    psk               = string
    primary_apipa     = string  # Azure APIPA for this tunnel
    secondary_apipa   = string  # The other Instance's APIPA (left as default)
    use_primary       = bool    # true = Instance 0 connection, false = Instance 1
  }))
}

variable "tags" {
  description = "Tags applied to all Azure resources"
  type        = map(string)
  default = {
    environment = "production"
    managed_by  = "terraform"
    project     = "azure-aws-vpn"
  }
}
