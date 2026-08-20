# CloudPlatformLab

CloudPlatformLab is a production-oriented Azure platform engineering project demonstrating Infrastructure as Code, CI/CD, identity, security, networking, observability, governance and cost-aware cloud operations.

The application workload is intentionally simple. The engineering focus is the Azure platform around it: reproducible infrastructure, identity-first authentication, controlled deployments, operational monitoring and governance.

> For the full architecture, design decisions, identity flows, pipeline implementation and governance model, see [`docs/architecture.md`](docs/architecture.md).

---

## Platform Overview

                         Azure DevOps
                              |
                              v
                     Build Application
                              |
       +----------+-----------+-----------+----------+
       |          |           |           |          |
       v          v           v           v          v
 App Service  Networking  Observability Security Governance
       |          |           |           |          |
       +----------+-----------+-----------+----------+
                              |
                 Validation -> Readiness
                              |
                           What-If
                              |
                       Manual Approval
                              |
                         Deployment

Infrastructure domains are independently validated and deployed through reusable Azure DevOps YAML templates.

This allows one platform constraint to fail safely without unnecessarily blocking unrelated infrastructure.

---

## What Is Implemented

### Infrastructure & CI/CD

- Azure infrastructure defined with Bicep
- Azure DevOps CI/CD
- reusable YAML stage templates
- Bicep validation and What-If
- deployment readiness checks
- Azure DevOps Environment approval gates
- Workload Identity Federation
- independent App Service, networking, observability, security and governance deployment paths

### Networking

- `vnet-cloudplatformlab-dev`
- application subnet
- dedicated private-endpoint subnet
- infrastructure deployed and managed through Bicep

### Identity & Security

- Microsoft Entra ID
- Azure Key Vault
- Azure RBAC authorization
- `DefaultAzureCredential`
- application-to-Key-Vault integration
- Key Vault soft delete and purge protection
- system-assigned Managed Identity defined for the future App Service
- Azure DevOps identity-based Key Vault access
- secrets and environment-specific values kept out of source control

### Observability

- workspace-based Application Insights
- Log Analytics with 30-day retention
- real ASP.NET Core request telemetry
- Azure Monitor failed-request metric alert
- Azure Monitor Action Group
- email notification configuration retrieved securely from Key Vault

The monitoring path has been tested end-to-end:

    Failed Application Request
              |
              v
    Application Insights
              |
              v
    Azure Monitor Alert
              |
              v
    Action Group
              |
              v
    Email Notification

### Governance

Azure Policy is integrated into the platform through Bicep and its own controlled pipeline path.

The first custom policy audits resources missing the required `Environment` tag.

Real compliance evaluation produced:

    Resources evaluated: 7
    Compliant:           6
    Non-compliant:       1
    Compliance:          86%

The non-compliant resource was an Azure-created Application Insights supporting resource. It was investigated rather than manually changed simply to produce a 100% score.

---

## Application Integration

The ASP.NET Core .NET 8 workload currently runs locally while consuming real Azure platform services:

    ASP.NET Core
        |
        +--> DefaultAzureCredential
        |        |
        |        v
        |     Entra ID -> RBAC -> Key Vault
        |
        +--> Application Insights SDK
                 |
                 v
            Application Insights
                 |
                 +--> Log Analytics
                 |
                 +--> Azure Monitor Alerting

This allows identity, security, telemetry and monitoring integration to be validated even though the App Service deployment is currently blocked by subscription capacity.

---

## App Service Deployment Constraint

The App Service Plan, App Service and `dev` deployment slot are defined and validated through Bicep.

Provisioning using the currently selected S1 SKU is blocked by an Azure subscription-level App Service quota of `0`.

The pipeline detects this during readiness validation rather than allowing an avoidable deployment failure.

The App Service SKU is parameterised, so the architecture is not permanently tied to S1.

---

## Implementation Evidence

Implementation evidence is stored in [`docs/evidence`](docs/evidence/).

Evidence currently covers:

- Bicep What-If and deployment safeguards
- manual Azure DevOps deployment approval
- deployed networking
- Application Insights and Log Analytics
- Key Vault security and RBAC
- application-to-Key-Vault integration
- live Application Insights telemetry
- Azure Monitor alerting and email notification
- Azure Policy compliance and resource-level governance evaluation

Current evidence: **01–21**.

---

## Current Technology Stack

**Azure:** Entra ID, Key Vault, RBAC, Virtual Network, Application Insights, Log Analytics, Azure Monitor, Action Groups, Azure Policy

**Infrastructure:** Bicep, Azure CLI

**DevOps:** Azure DevOps, Azure Repos, Azure Pipelines, reusable YAML templates, Workload Identity Federation, GitHub

**Application:** ASP.NET Core, .NET 8, `DefaultAzureCredential`, .NET User Secrets

---

## Next Platform Increments

Planned additions include:

- automated application testing
- Cosmos DB application persistence
- Azure Container Registry and Azure Container Apps
- Azure API Management
- Private Endpoints and Private DNS
- Terraform
- additional Azure Policy controls
- Management Groups and landing-zone governance
- Defender for Cloud

---

## Detailed Architecture

The README intentionally provides only a high-level portfolio overview.

For the complete engineering design — including deployment scopes, Bicep modules, RBAC decisions, identity flows, governance strategy, monitoring implementation, network design, cost controls and architectural reasoning — see:

**[`docs/architecture.md`](docs/architecture.md)**