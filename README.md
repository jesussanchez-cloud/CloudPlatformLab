# CloudPlatformLab

CloudPlatformLab is an Azure platform engineering portfolio project demonstrating Infrastructure as Code, CI/CD, identity, security, networking, observability, governance, containerisation and cost-aware cloud operations.

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

The application build also validates the container deployment artifact:

    ASP.NET Core .NET 8
            |
            +--> .NET Build
            |
            +--> Docker Build
                     |
                     v
              Container Image

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
- .NET application build validation
- **Docker image build validation through Azure DevOps CI**

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

The ASP.NET Core .NET 8 workload consumes real Azure services during local development:

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

The same application has now also been packaged and executed successfully as a Docker container.

The production Dockerfile uses a **multi-stage build**, separating the .NET 8 SDK build environment from the ASP.NET Core runtime image. The container exposes the application on port `8080`.

Containerisation has been validated at two levels:

    Repository
        |
        +--> Local Docker Build
        |        |
        |        v
        |   Running Products API
        |   localhost:8080
        |
        +--> Azure DevOps
                 |
                 v
            Docker Image Build

The CI pipeline currently validates that the image can be built reproducibly on a Microsoft-hosted Linux agent. Image publication and Kubernetes deployment are deliberately deferred to the ACR/AKS increment.

Azure authentication from the future Kubernetes workload will use **Azure Workload Identity** rather than embedding credentials in the container image.

---

## App Service Deployment Constraint

The App Service Plan, App Service and `dev` deployment slot are defined and validated through Bicep.

Provisioning with the selected S1 SKU is currently blocked by the subscription's App Service quota.

The pipeline detects this during **readiness validation** and stops only the App Service deployment path. The SKU is parameterised so the architecture is not permanently tied to S1.

---

## Engineering Decisions

- **Bicep over portal configuration** — infrastructure remains reproducible and reviewable.
- **Multi-stage Docker build** — separates application compilation from the final runtime image.
- **CI container validation** — proves the Docker image can be built outside the developer workstation.
- **Workload Identity Federation** — avoids long-lived Azure DevOps client secrets.
- **Managed Identity / Workload Identity architecture** — avoids application-managed Azure credentials.
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

The **32 captured evidence items** cover:

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
- **containerised Products API running on port 8080**
- **Docker container runtime and port publishing**
- **Docker image build through Azure DevOps CI**

This evidence distinguishes implemented capabilities from target-state architecture.

---

## Technology Stack

**Azure:** Microsoft Entra ID, Key Vault, RBAC, Virtual Network, Private Link, Private DNS, Application Insights, Log Analytics, Azure Monitor, Action Groups, Azure Policy, Management Groups

**Infrastructure:** Bicep, Azure CLI

**Containers:** Docker, multi-stage .NET container builds

**DevOps:** Azure DevOps, Azure Repos, Azure Pipelines, reusable YAML templates, Workload Identity Federation, GitHub

**Application:** ASP.NET Core, .NET 8, `DefaultAzureCredential`

---

## Remaining Portfolio Increments

The remaining work is deliberately limited to high-value platform-engineering capabilities:

1. **Terraform implementation for the AKS platform**
2. **Azure Container Registry + bounded AKS implementation**
3. **Kubernetes workload configuration** — Deployment, Service, health probes, resource controls, autoscaling and ingress
4. **Azure Workload Identity + Key Vault integration from AKS**
5. **VNet-side private connectivity validation from the Kubernetes workload**
6. **Hub-and-spoke networking** where it adds architectural value
7. **Architecture Decision Records**
8. **Resilience / disaster-recovery and FinOps documentation**
9. **Final architecture diagram and repository cleanup**

Terraform will be introduced as part of the AKS platform rather than as a disconnected rewrite of infrastructure already implemented successfully in Bicep.

The intended next progression is:

    Docker
      |
      v
    Terraform
      |
      v
    Azure Container Registry
      |
      v
    Azure Kubernetes Service
      |
      v
    Kubernetes Workload
      |
      v
    Azure Workload Identity
      |
      v
    Key Vault + Private Connectivity
      |
      v
    Azure Monitor / Container Insights

After these bounded increments, CloudPlatformLab will be considered **portfolio-complete** rather than expanded with additional Azure services for their own sake.

---

## Detailed Architecture

For the complete implementation, deployment architecture, identity flows, container design, governance model and design reasoning, see:

**[`docs/architecture.md`](docs/architecture.md)**