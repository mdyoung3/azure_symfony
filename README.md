# Secure Azure Web Hosting Environment

An Infrastructure as Code (IaC) project using Terraform to provision a security-hardened Linux web hosting environment in Microsoft Azure. This project demonstrates secure cloud infrastructure practices aligned with NIST 800-171 control families, with an emphasis on access control, network segmentation, and compliance-ready resource governance.

## Architecture Overview

This configuration deploys the following resources within a single Azure resource group:

- **Virtual Network** with a `10.0.0.0/16` address space, providing network isolation for all compute resources
- **Subnet** (`10.0.2.0/24`) for internal workloads, segmented from the broader VNet
- **Network Security Group (NSG)** restricting inbound SSH (port 22) to a single whitelisted IP address, associated at the subnet level
- **Linux Virtual Machine** (Ubuntu 22.04 LTS) using SSH key-based authentication — password authentication is disabled
- **Public IP** for remote administration, scoped behind NSG rules
- **Network Interface** bridging the VM to the internal subnet with the public IP attached

### Network Diagram

```
┌─────────────────────────────────────────────────────┐
│  Azure Resource Group                               │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Virtual Network (10.0.0.0/16)                │  │
│  │                                               │  │
│  │  ┌─────────────────────────────────────────┐  │  │
│  │  │  Subnet: internal (10.0.2.0/24)         │  │  │
│  │  │  ┌──────────┐    ┌───────────────────┐  │  │  │
│  │  │  │   NSG    │───▶│  Network Interface │  │  │  │
│  │  │  │ SSH only │    │  ┌─────────────┐  │  │  │  │
│  │  │  │ (1 IP)   │    │  │  Linux VM   │  │  │  │  │
│  │  │  └──────────┘    │  │  Ubuntu LTS │  │  │  │  │
│  │  │                  │  └─────────────┘  │  │  │  │
│  │  │                  └───────────────────┘  │  │  │
│  │  └──────────────────────────┬──────────────┘  │  │
│  │                             │                 │  │
│  └─────────────────────────────┼─────────────────┘  │
│                                │                    │
│                       ┌────────┴────────┐           │
│                       │   Public IP     │           │
│                       │   (Static)      │           │
│                       └─────────────────┘           │
└─────────────────────────────────────────────────────┘
```

## Security Considerations

This project applies several security practices relevant to regulated and compliance-driven environments:

### Access Control (NIST 800-171: AC-17 — Remote Access)

- SSH is the sole remote access method; password-based authentication is disabled
- The NSG restricts inbound SSH to a single authorized IP address, reducing the attack surface to a known endpoint
- All other inbound traffic is denied by default via Azure NSG implicit deny rules

### Network Segmentation (NIST 800-171: SC-7 — Boundary Protection)

- Workloads are isolated within a dedicated VNet and subnet
- The NSG is associated at the subnet level, enforcing consistent security policy across all resources within the subnet rather than per-NIC, which reduces configuration drift

### Authentication (NIST 800-171: IA-2 — Identification and Authentication)

- SSH key-based authentication is enforced; no shared or static passwords
- Admin access is limited to a single named account

### Resource Governance

All resources are tagged with compliance metadata to support automated policy enforcement and audit readiness:

| Tag                    | Purpose                                                                 |
|------------------------|-------------------------------------------------------------------------|
| `environment`          | Identifies the deployment stage (dev, staging, prod)                    |
| `project`              | Groups resources by project for cost tracking and ownership             |
| `data_classification`  | Enables Azure Policy rules based on data sensitivity (e.g., CUI, public)|
| `compliance_framework` | Maps resources to applicable regulatory frameworks (e.g., NIST-800-171) |
| `managed_by`           | Indicates the provisioning method for change control audits             |
| `owner`                | Identifies the responsible party for incident response                  |

In a production environment, Azure Policy definitions could enforce that resources without required tags (such as `data_classification`) are denied at deployment time.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0 (or [OpenTofu](https://opentofu.org/))
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) authenticated (`az login`)
- An Azure subscription with an active resource provider for `Microsoft.Compute`
- An SSH key pair (the config expects `~/.ssh/azure.pub`)

## Usage

1. **Clone the repository:**

   ```bash
   git clone git@github.com:mdyoung3/azure_symfony.git
   cd azuresymfony
   ```

2. **Create your variable overrides:**

   ```bash
   touch terraform.tfvars
   ```

   Edit `terraform.tfvars` with your values:

   ```hcl
   project_name = "azure_website_environment"
   ip_address   = "YOUR_PUBLIC_IP/32"
   ```

3. **Initialize and plan:**

   ```bash
   terraform init
   terraform plan
   ```

4. **Apply:**

   ```bash
   terraform apply
   ```

5. **Connect to the VM:**

   ```bash
   ssh adminuser@$(terraform output -raw public_ip)
   ```

6. **Tear down when finished:**

   ```bash
   terraform destroy
   ```

## Future Enhancements

- **Azure Key Vault** for centralized secrets management, replacing local SSH key references
- **Log Analytics Workspace** with VM diagnostic settings for centralized logging and monitoring, supporting incident response and audit evidence collection
- **Managed Identity** (Entra ID) assigned to the VM to eliminate static credentials for Azure service access
- **Remote state backend** using Azure Storage with state locking to support team-based workflows
- **CI/CD pipeline** (GitHub Actions) running `terraform fmt`, `terraform validate`, and `terraform plan` on pull requests
- **Modularized structure** separating networking, compute, and security into reusable modules

## Technologies

- **Terraform** — Infrastructure as Code
- **Microsoft Azure** — Cloud platform (Resource Groups, VNets, NSGs, Linux VMs)
- **Ubuntu 22.04 LTS** — Server operating system
- **Cloud-init** — VM bootstrapping and provisioning