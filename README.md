# Azure ↔ AWS Site-to-Site BGP VPN — Terraform

Production-grade, dual-tunnel, active-active BGP VPN between **Azure VPN Gateway** and **AWS Virtual Private Gateway**.

## Architecture

```
                 ┌──────────────────────────────────────┐
                 │               AZURE                   │
                 │  VNet: 10.1.0.0/16                   │
                 │  ┌───────────────────────────────┐   │
                 │  │ VPN GW (VpnGw2AZ)             │   │
                 │  │ Active-Active | BGP ASN 65000  │   │
                 │  │  Instance 0: <pip0>            │   │
                 │  │  Instance 1: <pip1>            │   │
                 │  └───────────┬───────────────────┘   │
                 └──────────────│───────────────────────-┘
                                │ 4 × IPsec/IKEv2 + BGP
                 ┌──────────────│────────────────────────┐
                 │    AWS       │                         │
                 │  VPC: 10.2.0.0/16                     │
                 │  ┌───────────────────────────────┐   │
                 │  │ Virtual Private Gateway       │   │
                 │  │ BGP ASN 64512                 │   │
                 │  │ CG1 → Instance 0 (2 tunnels)  │   │
                 │  │ CG2 → Instance 1 (2 tunnels)  │   │
                 │  └───────────────────────────────┘   │
                 └────────────────────────────────────────┘
```

## Tunnel / APIPA Mapping

| Tunnel                           | Azure APIPA  | AWS BGP Peer | AWS Inside CIDR  |
|----------------------------------|--------------|--------------|------------------|
| AWS Tunnel 1 → Azure Instance 0  | 169.254.21.2 | 169.254.21.1 | 169.254.21.0/30  |
| AWS Tunnel 2 → Azure Instance 0  | 169.254.22.2 | 169.254.22.1 | 169.254.22.0/30  |
| AWS Tunnel 1 → Azure Instance 1  | 169.254.21.6 | 169.254.21.5 | 169.254.21.4/30  |
| AWS Tunnel 2 → Azure Instance 1  | 169.254.22.6 | 169.254.22.5 | 169.254.22.4/30  |

## Prerequisites

| Tool      | Requirement                       |
|-----------|-----------------------------------|
| Terraform | >= 1.7                            |
| Azure CLI | `az login` completed              |
| AWS CLI   | `aws configure` completed         |

## Quick Start

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit with your PSKs, subscription ID, region preferences
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

> ⚠️ Azure VPN Gateway provisioning takes 30-60 minutes.

## Module Layout

```
.
├── modules/
│   ├── azure/    # VNet, GatewaySubnet, Active-Active VPN GW, LNGs, Connections
│   └── aws/      # VPC, VPG, Customer Gateways, S2S Connections
└── environments/
    └── prod/     # Root module — wires both clouds, passes outputs across
```

## Security Best Practices (Production)

- Store PSKs in **Azure Key Vault** and **AWS Secrets Manager** — never in tfvars committed to git
- Add `terraform.tfvars` to `.gitignore`
- Restrict NSGs/SGs to only required IKE (UDP 500/4500) and ESP traffic
- Enable **Azure DDoS Standard** for VNet protection
- Monitor BGP session health via **Azure Monitor** metrics + **AWS CloudWatch**
- Use **VpnGw2AZ or higher** for zone-redundancy in production
