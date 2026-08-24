# CloudPlatformLab

CloudPlatformLab is an Azure platform engineering portfolio project demonstrating Infrastructure as Code, CI/CD, identity, security, networking, observability, governance and cost-aware cloud operations.

The application is intentionally simple. The engineering focus is the platform around it: **reproducible infrastructure, identity-first authentication, controlled deployments, operational monitoring and enterprise-style governance**.

> For the detailed architecture, implementation decisions and identity/governance flows, see [`docs/architecture.md`](docs/architecture.md).

---

## Architecture at a Glance

```text
                         Azure DevOps
                              |
                              v
                       Build + Validate
                              |
       +----------+-----------+-----------+----------+
       |          |           |           |          |
       v          v           v           v          v
 App Service  Networking  Observability Security Governance
       |          |           |           |          |
       +----------+-----------+-----------+----------+
                              |
                  Readiness -> What-If
                              |
                       Manual Approval
                              |
                         Deployment
```

Infrastructure domains use independent, reusable Azure DevOps YAML templates so a constraint affecting one platform area does not unnecessarily block another.

---

## What Is Implemented

### Infrastructure & CI/CD

- Azure infrastructure defined with **Bicep**
- modular Azure DevOps pipeline with reusable YAML stage templates
- Bicep validation and What-If
- deployment readiness checks
- manual Azure DevOps Environment approval gates
- **Workload Identity Federation** instead of long-lived deployment credentials
- independent application, networking, observability, security and governance deployment paths

### Networking & Security

- Dev Virtual Network with separate application and Private Endpoint subnets
- Azure Key Vault using the Azure RBAC permission model
- Key Vault soft delete and purge protection
- `DefaultAzureCredential` application authentication
- application-to-Key-Vault integration through Microsoft Entra ID and RBAC
- system-assigned Managed Identity defined for App Service
- environment-specific values and secrets kept out of source control

### Observability

- workspace-based Application Insights
- Log Analytics with 30-day retention
- real ASP.NET Core request telemetry
- Azure Monitor failed-request metric alert
- Azure Monitor Action Group
- notification configuration retrieved securely from Key Vault

The monitoring path has been tested end-to-end:

```text
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
```

### Landing Zone & Governance

CloudPlatformLab now implements a Management Group hierarchy rather than limiting governance to individual resource groups.

```text
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
```

A custom Azure Policy audits resources missing the required `Environment` tag.

The policy is assigned at the **Landing Zones Management Group** and inherited by `Dev`, the CloudPlatformLab subscription and its workload resources.

The previous direct resource-group assignment was removed after inheritance was validated.

Latest real compliance evaluation:

```text
Resources evaluated: 8
Compliant:           6
Non-compliant:       2
Compliance:          75%
```

The non-compliant findings include Azure-created/supporting resources. They were investigated rather than modified simply to produce a 100% compliance score, demonstrating the distinction between policy enforcement and governance decision-making.

---

## Application Integration

The ASP.NET Core .NET 8 workload currently runs locally while consuming real Azure services:

```text
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
```

This allows identity, security, telemetry and monitoring integration to be validated against real Azure infrastructure independently of the application-hosting constraint.

---

## App Service Deployment Constraint

The App Service Plan, App Service and `dev` deployment slot are defined and validated through Bicep.

Provisioning with the selected S1 SKU is currently blocked by an Azure subscription-level App Service quota of `0`.

Rather than bypassing the constraint, the pipeline detects it during **readiness validation** and stops that deployment path while unrelated platform domains can continue.

The SKU is parameterised so the architecture is not permanently tied to S1.

---

## Engineering Decisions

Several implementation choices are deliberate:

- **Bicep over portal configuration** — infrastructure remains reproducible and reviewable.
- **Workload Identity Federation** — avoids long-lived Azure DevOps client secrets.
- **Managed Identity architecture** — avoids application-managed Azure credentials.
- **Azure RBAC for Key Vault** — provides a consistent Azure authorization model.
- **Audit before enforcement** — policy behaviour is evaluated before introducing blocking controls.
- **Management Group policy inheritance** — governance is defined at the appropriate platform scope instead of duplicated per resource group.
- **Least privilege** — privileged subscription placement is separated from normal repeatable governance deployment.
- **Independent pipeline paths** — one platform constraint does not unnecessarily block unrelated infrastructure.
- **Manual approval after What-If** — infrastructure changes are reviewed before deployment.
- **Cost-aware deployment** — paid lab resources can be removed and recreated from IaC when required.

Detailed reasoning is documented in [`docs/architecture.md`](docs/architecture.md).

---

## Implementation Evidence

Evidence of the working implementation is stored in [`docs/evidence`](docs/evidence/).

The **25 captured evidence items** cover:

- Bicep What-If and deployment safeguards
- manual deployment approval
- deployed networking
- Key Vault security and RBAC
- application-to-Key-Vault integration
- Application Insights and Log Analytics
- live application telemetry
- end-to-end Azure Monitor alerting
- Azure Policy compliance
- deployed Management Group hierarchy
- policy inheritance from Landing Zones
- Management Group-level compliance and resource findings

This evidence distinguishes implemented and validated capabilities from target-state architecture.

---

## Technology Stack

**Azure:** Entra ID, Key Vault, RBAC, Virtual Network, Application Insights, Log Analytics, Azure Monitor, Action Groups, Azure Policy, Management Groups

**Infrastructure:** Bicep, Azure CLI

**DevOps:** Azure DevOps, Azure Repos, Azure Pipelines, reusable YAML templates, Workload Identity Federation, GitHub

**Application:** ASP.NET Core, .NET 8, `DefaultAzureCredential`

---

## Final Portfolio Increments

The remaining work is deliberately limited to high-value platform-engineering gaps:

1. **Private Endpoints + Private DNS**
2. **Hub-and-spoke networking + VNet peering**
3. **Network segmentation / NSGs where appropriate**
4. **Terraform** for a meaningful infrastructure slice
5. **Architecture Decision Records (ADRs)**
6. **Final architecture diagrams and documentation cleanup**
7. **Lightweight resilience / DR design**
8. **Lightweight threat model**

After these increments, CloudPlatformLab will be considered **portfolio-complete** rather than expanded with additional Azure services for their own sake.

---

## Detailed Architecture

For the complete implementation — including deployment scopes, Bicep structure, RBAC decisions, identity flows, Management Group governance, policy inheritance, monitoring, networking, cost controls and architectural reasoning — see:

**[`docs/architecture.md`](docs/architecture.md)**