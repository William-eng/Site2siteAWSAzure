variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR for the AWS VPC (must not overlap with Azure VNet)"
  type        = string
  default     = "10.2.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (one per AZ recommended)"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "availability_zones" {
  description = "AZs for subnet placement"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "aws_bgp_asn" {
  description = "BGP ASN for the AWS Virtual Private Gateway"
  type        = number
  default     = 64512
}

variable "azure_bgp_asn" {
  description = "BGP ASN used by the Azure VPN Gateway (for Customer Gateway definitions)"
  type        = number
  default     = 65000
}

variable "azure_vpngw_pip0" {
  description = "Public IP of Azure VPN Gateway Instance 0 — use after Azure resources are created"
  type        = string
}

variable "azure_vpngw_pip1" {
  description = "Public IP of Azure VPN Gateway Instance 1 — use after Azure resources are created"
  type        = string
}

# Pre-shared keys — mark as sensitive; store in Secrets Manager in production
# AWS restriction: only alphanumeric, period (.) and underscore (_) characters allowed.
# Generate with: openssl rand -hex 32
# Do NOT use: openssl rand -base64 32  (produces +/= which AWS rejects)

variable "psk_tunnel1_instance0" {
  description = "PSK for Connection 1 / Tunnel 1 (Instance 0). Alphanumeric, dot, underscore only."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9._]+$", var.psk_tunnel1_instance0))
    error_message = "AWS PSKs may only contain alphanumeric characters, periods (.), and underscores (_). Use: openssl rand -hex 32"
  }
}

variable "psk_tunnel2_instance0" {
  description = "PSK for Connection 1 / Tunnel 2 (Instance 0). Alphanumeric, dot, underscore only."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9._]+$", var.psk_tunnel2_instance0))
    error_message = "AWS PSKs may only contain alphanumeric characters, periods (.), and underscores (_). Use: openssl rand -hex 32"
  }
}

variable "psk_tunnel1_instance1" {
  description = "PSK for Connection 2 / Tunnel 1 (Instance 1). Alphanumeric, dot, underscore only."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9._]+$", var.psk_tunnel1_instance1))
    error_message = "AWS PSKs may only contain alphanumeric characters, periods (.), and underscores (_). Use: openssl rand -hex 32"
  }
}

variable "psk_tunnel2_instance1" {
  description = "PSK for Connection 2 / Tunnel 2 (Instance 1). Alphanumeric, dot, underscore only."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9._]+$", var.psk_tunnel2_instance1))
    error_message = "AWS PSKs may only contain alphanumeric characters, periods (.), and underscores (_). Use: openssl rand -hex 32"
  }
}

variable "tags" {
  description = "Tags applied to all AWS resources"
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "azure-aws-vpn"
  }
}
