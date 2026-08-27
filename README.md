# CloudPlatformLab

CloudPlatformLab is an Azure platform engineering portfolio project demonstrating Infrastructure as Code, CI/CD, identity, security, networking, observability, governance and cost-aware cloud operations.

The application is intentionally simple. The engineering focus is the platform around it: **reproducible infrastructure, identity-first authentication, controlled deployments, private connectivity, operational monitoring and enterprise-style governance**.

> For detailed architecture and design decisions, see [`docs/architecture.md`](docs/architecture.md).

---

## Architecture at a Glance

    Azure DevOps
         |
    Build + Validate
         |
         +-----------+-----------+-----------+-----------+
         |           |           |           |           |
         v           v           v           v           v
    App Service  Networking  Observability Security  Governance
         |           |           |           |           |
         +-----------+-----------+-----------+-----------+
                                 |
                     Readiness -> What-If
                                 |
                          Manual Approval
                                 |
                            Deployment

Infrastructure domains use independent reusable Azure DevOps YAML templates, allowing each area to be validated and deployed without unrelated constraints blocking the entire platform.

---

## What Is Implemented

### Infrastructure & CI/CD

- Azure infrastructure defined with **Bicep**
- modular Azure DevOps pipeline with reusable YAML templates
- Bicep validation and What-If
- deployment readiness checks
- manual Azure DevOps Environment approval
- **Workload Identity Federation** instead of long-lived deployment credentials
- independent App Service, networking, observability, security and governance deployment paths

### Networking & Security

- Dev VNet `10.10.0.0/16`
- separate application and Private Endpoint subnets
- Azure Key Vault using Azure RBAC
- Key Vault soft delete and purge protection
- **Key Vault Private Endpoint**
- Private Endpoint address `10.10.2.4`
- Private DNS zone `privatelink.vaultcore.azure.net`
- Private DNS VNet link and DNS Zone Group
- Key Vault private A record mapped to `10.10.2.4`
- `DefaultAzureCredential` application authentication
- application-to-Key-Vault integration through Microsoft Entra ID and RBAC
- system-assigned Managed Identity defined for App Service
- secrets and environment-specific values kept out of source control

Private connectivity is now represented in the deployed platform:

    vnet-cloudplatformlab-dev
    10.10.0.0/16
    |
    +-- snet-app
    |   10.10.1.0/24
    |
    +-- snet-private-endpoints
        10.10.2.0/24
             |
             +-- Key Vault Private Endpoint
                 10.10.2.4
                      |
                      +-- privatelink.vaultcore.azure.net
                      |
                      +-- kv-cloudplatformlab-dev

The Private Endpoint and DNS infrastructure are deployed and evidenced. Runtime private-path validation from a VNet-connected workload remains outstanding because suitable low-cost Azure compute is currently unavailable under the subscription's capacity constraints.

### Observability

- workspace-based Application Insights
- Log Analytics with 30-day retention
- real ASP.NET Core request telemetry
- Azure Monitor failed-request metric alert
- Azure Monitor Action Group
- notification configuration retrieved securely from Key Vault

The monitoring path has been tested end-to-end:

    Failed Application Request
              |
    Application Insights
              |
    Azure Monitor Alert
              |
    Action Group
              |
    Email Notification

### Landing Zone & Governance

CloudPlatformLab implements a Management Group landing-zone hierarchy:

    CloudPlatformLab
    |
    +-- Platform
    |   |
    |   +-- Connectivity
    |   +-- Management
    |
    +-- Landing Zones
        |
        +-- Dev
        |   |
        |   +-- CloudPlatformLab subscription
        |
        +-- Prod

A custom Azure Policy audits resources missing the required `Environment` tag.

The policy is assigned at the **Landing Zones Management Group** and inherited by `Dev`, the CloudPlatformLab subscription and its workload resources.

Latest validated compliance:

    Resources evaluated: 8
    Compliant:            6
    Non-compliant:        2
    Compliance:           75%

The non-compliant findings include Azure-created supporting resources. They were investigated rather than changed solely to produce a 100% compliance score.

Privileged subscription placement is kept separate from normal repeatable CI/CD deployment to avoid unnecessarily broad pipeline permissions.

---

## Application Integration

The ASP.NET Core .NET 8 workload currently runs locally while consuming real Azure services:

    ASP.NET Core
        |
        +--> DefaultAzureCredential
        |        |
        |        v
        |    Entra ID -> RBAC -> Key Vault
        |
        +--> Application Insights SDK
                 |
                 v
            Application Insights
                 |
                 +--> Log Analytics
                 |
                 +--> Azure Monitor Alerting

This allows identity, security, telemetry and monitoring integration to be validated against real Azure infrastructure independently of the application-hosting constraint.

---

## App Service Deployment Constraint

The App Service Plan, App Service and `dev` deployment slot are defined and validated through Bicep.

Provisioning with the selected S1 SKU is currently blocked by the subscription's App Service quota.

The pipeline detects this during **readiness validation** and stops only the App Service deployment path. The SKU is parameterised so the architecture is not permanently tied to S1.

---

## Engineering Decisions

- **Bicep over portal configuration** — infrastructure remains reproducible and reviewable.
- **Workload Identity Federation** — avoids long-lived Azure DevOps client secrets.
- **Managed Identity architecture** — avoids application-managed Azure credentials.
- **Azure RBAC for Key Vault** — provides a consistent authorization model.
- **Private Endpoint + Private DNS** — establishes private service connectivity for VNet-hosted workloads.
- **Separate application and Private Endpoint subnets** — separates workload integration from private platform-service connectivity.
- **Audit before enforcement** — policy behaviour is evaluated before introducing blocking controls.
- **Management Group policy inheritance** — governance is established once at the appropriate platform scope.
- **Least privilege** — privileged subscription placement is separated from normal governance deployment.
- **Independent pipeline paths** — one platform constraint does not block unrelated infrastructure.
- **Manual approval after What-If** — infrastructure changes are reviewed before deployment.
- **Cost-aware deployment** — unnecessary paid resources are avoided and infrastructure can be recreated from IaC.

Detailed reasoning is documented in [`docs/architecture.md`](docs/architecture.md).

---

## Implementation Evidence

Evidence of the working implementation is stored in [`docs/evidence`](docs/evidence/).

The **29 captured evidence items** cover:

- Bicep What-If and deployment safeguards
- manual deployment approval
- VNet and subnet deployment
- Key Vault security and RBAC
- application-to-Key-Vault integration
- Application Insights and Log Analytics
- real application telemetry
- end-to-end Azure Monitor alerting
- Management Group landing-zone hierarchy
- Azure Policy inheritance and compliance
- Key Vault Private Endpoint and private IP
- Private DNS zone and VNet integration
- Key Vault private DNS A record
- public DNS baseline for comparison with future VNet-side resolution

This evidence distinguishes implemented capabilities from target-state architecture.

---

## Technology Stack

**Azure:** Microsoft Entra ID, Key Vault, RBAC, Virtual Network, Private Link, Private DNS, Application Insights, Log Analytics, Azure Monitor, Action Groups, Azure Policy, Management Groups

**Infrastructure:** Bicep, Azure CLI

**DevOps:** Azure DevOps, Azure Repos, Azure Pipelines, reusable YAML templates, Workload Identity Federation, GitHub

**Application:** ASP.NET Core, .NET 8, `DefaultAzureCredential`

---

## Remaining Portfolio Increments

The remaining work is deliberately limited to high-value platform-engineering capabilities:

1. **Terraform networking implementation**
2. **Containerised Products API + bounded AKS implementation**
3. **Hub-and-spoke networking** where it adds architectural value
4. **Architecture Decision Records**
5. **Resilience / disaster-recovery design**
6. **FinOps documentation**
7. **Final architecture diagram and repository cleanup**

After these increments, CloudPlatformLab will be considered **portfolio-complete** rather than expanded with additional Azure services for their own sake.

---

## Detailed Architecture

For the complete implementation, deployment architecture, identity flows, governance model and design reasoning, see:

**[`docs/architecture.md`](docs/architecture.md)**