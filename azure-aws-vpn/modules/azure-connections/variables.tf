variable "resource_group_name" {
  description = "Existing Azure Resource Group name (created by azure-infra module)"
  type        = string
}

variable "location" {
  description = "Azure region — must match the resource group's location"
  type        = string
}

variable "vpn_gateway_id" {
  description = "Resource ID of the existing Azure VPN Gateway"
  type        = string
}

variable "aws_tunnels" {
  description = "List of 4 AWS tunnel objects with outside IP, BGP peer, PSK, and APIPA addresses"
  type = list(object({
    name            = string
    outside_ip      = string
    bgp_peer_ip     = string
    aws_asn         = number
    psk             = string
    primary_apipa   = string
    secondary_apipa = string
  }))
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
