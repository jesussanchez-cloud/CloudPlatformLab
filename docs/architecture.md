# Architecture

CloudPlatformLab is designed as a small Azure platform engineering project rather than a complex application.

The application is intentionally simple. The main focus is the Azure architecture around it: infrastructure as code, CI/CD, identity, security, governance, networking, observability and cost control.

The project is being built incrementally so that each part can be understood, tested and documented properly.

---

## Current Architecture

CloudPlatformLab currently has deployed Dev networking, observability and security foundations, with the application platform defined separately in Bicep.

```text
                              Azure DevOps
                                   |
                                   v
                            Build Application
                                   |
              +--------------------+--------------------+
              |                    |                    |
              v                    v                    v
        App Service            Networking         Observability
              |                    |                    |
              +--------------------+--------------------+
                                   |
                                   v
                                Security

Each infrastructure domain follows:

Validation
    |
    v
Readiness
    |
    v
What-If
    |
    v
Manual Approval
    |
    v
Deployment
```

The networking, observability and security deployment paths have been successfully executed through Azure DevOps.

The App Service infrastructure follows an independent deployment path. Its Bicep definition is valid, but provisioning using the currently selected S1 SKU is blocked by the subscription's App Service quota.

Keeping these deployment paths independent allows networking, observability and security infrastructure to be validated and deployed without being blocked by an unrelated application-platform constraint.

The Azure DevOps pipeline has also been modularised into reusable YAML templates so that each infrastructure domain can evolve independently without turning the root pipeline into a large monolithic definition.

---

## Application Layer

The current workload is an ASP.NET Core .NET 8 application containing a simple Products API.

The application is deliberately small because the main objective of the project is to demonstrate the platform around the application rather than application complexity.

Current application components:

- ASP.NET Core .NET 8
- Products API
- Azure App Service architecture
- `dev` deployment slot architecture

The App Service infrastructure is currently defined and validated through Bicep but is not provisioned because the subscription currently has no available quota for the selected S1 SKU.

The App Service Plan SKU is parameterised so the architecture is not permanently tied to S1 and can use another appropriate supported SKU in the future.

---

## Infrastructure Layer

Infrastructure is defined using Bicep and separated by platform concern.

Current templates are located at:

```text
infra/
+-- appservice/
|   +-- main.bicep
|
+-- networking/
|   +-- main.bicep
|
+-- observability/
|   +-- main.bicep
|
+-- security/
    +-- main.bicep
```

The App Service template defines:

- configurable App Service Plan SKU
- App Service
- `dev` deployment slot
- system-assigned managed identity
- HTTPS-only configuration
- TLS 1.2 minimum
- resource tags

The networking template defines:

- Dev virtual network
- application subnet
- private endpoint subnet
- common resource tags

The observability template defines:

- Log Analytics workspace
- workspace-based Application Insights
- 30-day Log Analytics retention
- common resource tags

The security template defines:

- Azure Key Vault
- Azure RBAC authorization model
- soft delete
- 90-day soft-delete retention
- purge protection
- common resource tags

Infrastructure is deployed into:

```text
rg-cloudplatformlab-dev
```

Region:

```text
UK South
```

Separating infrastructure by platform concern allows each area to be validated, deployed and evolved independently while remaining managed through the same repository and CI/CD workflow.

Using Bicep means the environment can be recreated instead of relying on manually configured resources.

Repeated deployments converge Azure towards the declared state rather than creating duplicate resources.

---

## Networking Architecture

The deployed networking foundation provides address space for application workloads and future private connectivity.

```text
vnet-cloudplatformlab-dev
Address space: 10.10.0.0/16
|
+-- snet-app
|   10.10.1.0/24
|
+-- snet-private-endpoints
    10.10.2.0/24
```

`snet-app` provides a dedicated subnet for application-related integration as the platform develops.

`snet-private-endpoints` reserves separate address space for future Azure Private Endpoints, keeping private platform-service connectivity separated from application integration.

The current network is intentionally small. Hub-spoke topology, Private DNS, VNet peering and additional network controls will be introduced when they support an implemented platform requirement rather than being added solely for architectural complexity.

The networking infrastructure is independently deployable through the Azure DevOps pipeline and has been successfully provisioned from Bicep.

---

## Observability Architecture

The deployed observability foundation provides a central workspace for telemetry and a workspace-based Application Insights resource.

```text
appi-cloudplatformlab-dev
Application Insights
          |
          | WorkspaceResourceId
          v
log-cloudplatformlab-dev
Log Analytics Workspace
          |
          v
  30-day retention
```

Application Insights is linked to the Log Analytics workspace so application telemetry can use the workspace as the central observability data store when the application deployment path becomes operational.

The Log Analytics workspace currently uses 30-day retention. This provides sufficient retention for a development environment while limiting unnecessary long-term data retention and associated cost.

The current observability foundation has been successfully deployed through Bicep and the controlled Azure DevOps pipeline.

Application telemetry integration, Azure Monitor alerts, Action Groups, health monitoring and additional operational controls will be added as workloads requiring those capabilities become available.

---

## Security Architecture

The Dev environment now includes a Key Vault security foundation deployed through Bicep and the controlled Azure DevOps pipeline.

```text
kv-cloudplatformlab-dev
Azure Key Vault
        |
        +-- Azure RBAC authorization
        |
        +-- Soft delete
        |     90-day retention
        |
        +-- Purge protection
        |
        +-- Project tags
```

The Key Vault uses Azure RBAC rather than the legacy Key Vault access-policy model.

Soft delete provides recovery protection for deleted vault content, while purge protection prevents destructive permanent deletion during the configured protection period.

Public network access remains enabled at this stage deliberately.

Private network access will be introduced later through Private Endpoints and Private DNS as part of the private-connectivity phase rather than mixing network architecture changes into the initial Key Vault security foundation.

The App Service definition already includes a system-assigned managed identity. Once the application platform can be deployed, that managed identity can be granted an appropriate Key Vault data-plane role so the application can access secrets without storing credentials.

No application secrets are committed to the repository.

---

## Deployment Architecture

Azure DevOps is used for CI/CD.

Changes are developed in feature branches and merged into `Dev` through pull requests. The `Dev` branch is the deployment source for the Dev environment.

As the platform grew, the pipeline was refactored from one large YAML file into a root orchestration pipeline with reusable stage templates.

```text
azure-pipelines.yml
        |
        +-- pipelines/templates/appservice.yml
        |
        +-- pipelines/templates/networking.yml
        |
        +-- pipelines/templates/observability.yml
        |
        +-- pipelines/templates/security.yml
```

The root pipeline performs the shared application build and then invokes the independent infrastructure templates.

```text
Feature branch
      |
      v
Pull Request
      |
      v
Dev
      |
      v
Build Application
      |
      +---------------+---------------+---------------+
      |               |               |               |
      v               v               v               v
 App Service      Networking     Observability      Security
      |               |               |               |
      v               v               v               v
 Validation      Validation      Validation      Validation
      |               |               |               |
      v               v               v               v
 Readiness       Readiness       Readiness       Readiness
      |               |               |               |
      v               v               v               v
  What-If         What-If         What-If         What-If
      |               |               |               |
      v               v               v               v
 Approval         Approval         Approval         Approval
      |               |               |               |
      v               v               v               v
Deployment       Deployment      Deployment      Deployment
```

The independent paths prevent a deployment constraint affecting one infrastructure area from unnecessarily blocking another.

This is currently demonstrated by the App Service quota constraint: App Service deployment can stop at its readiness stage while networking, observability and security continue independently through validation, approval and deployment.

Deployment stages target the Azure DevOps environment:

```text
env-cloudplatformlab-dev
```

The environment uses a manual approval check before infrastructure changes are applied.

Feature-branch pipeline runs are used to validate infrastructure and pipeline behaviour before changes are merged. Dev environment infrastructure deployment is performed from the merged `Dev` branch.

---

### Deployment Safeguards

Infrastructure changes are not deployed directly from a developer workstation.

Each infrastructure path follows a controlled sequence:

1. Bicep validation
2. Deployment readiness checks
3. Bicep What-If
4. Azure DevOps Environment approval
5. Bicep resource-group deployment

App Service readiness currently validates:

- `Microsoft.Web` resource provider registration
- target resource group availability
- quota availability for the configured App Service SKU

Networking readiness currently validates:

- `Microsoft.Network` resource provider registration
- target resource group availability

Observability readiness currently validates:

- `Microsoft.OperationalInsights` resource provider registration
- `Microsoft.Insights` resource provider registration
- target resource group availability

Security readiness currently validates:

- `Microsoft.KeyVault` resource provider registration
- target resource group availability

Readiness checks are intentionally separated from Bicep validation.

Bicep validation verifies the infrastructure definition, while readiness checks detect known subscription or environmental conditions that could prevent a valid template from being deployed.

This distinction produces clearer pipeline failures and prevents known environmental constraints from being confused with invalid infrastructure code.

The deployment stages use an Azure Resource Manager service connection configured with Workload Identity Federation, avoiding a long-lived client secret in the pipeline.

---

## Resource Provider Strategy

Azure resource-provider registration is treated as a subscription/platform readiness concern rather than being embedded in resource-group workload templates.

The pipeline verifies required providers before deployment.

Providers currently relevant to implemented platform areas include:

```text
App Service
Microsoft.Web

Networking
Microsoft.Network

Observability
Microsoft.OperationalInsights
Microsoft.Insights

Security
Microsoft.KeyVault
```

This keeps subscription-level platform preparation separate from workload-level Infrastructure as Code.

New resource providers will be introduced and validated as additional platform capabilities are implemented rather than registering unrelated providers in advance.

---

## Identity and Authentication

The Azure DevOps pipeline authenticates to Azure using Workload Identity Federation.

This avoids storing an Azure client secret in the pipeline or repository.

The service connection is:

```text
sc-cloudplatformlab-dev
```

The App Service is defined with a system-assigned managed identity.

The intended application authentication model is:

```text
App Service
System-assigned Managed Identity
        |
        v
Azure RBAC
        |
        v
Azure Key Vault
```

This will allow the application to access required platform resources without storing long-lived credentials once the App Service deployment path is operational.

---

## Security Design

Current security controls include:

- Workload Identity Federation
- Azure Key Vault
- Azure RBAC Key Vault authorization
- Key Vault soft delete
- 90-day Key Vault soft-delete retention
- Key Vault purge protection
- Azure RBAC
- controlled Azure DevOps service connection
- manual approval before infrastructure deployment
- deployment readiness checks
- infrastructure validation before deployment
- system-assigned managed identity defined for App Service
- HTTPS-only App Service configuration
- TLS 1.2 minimum App Service configuration
- separate subnet reserved for future Private Endpoints

Planned security improvements include:

- application-to-Key-Vault access through managed identity
- Private Endpoints
- Private DNS
- Azure Policy
- Defender for Cloud
- tighter RBAC where appropriate

Secrets and credentials are not intended to be stored in source control.

---

## Resource Organisation

Development resources are grouped under:

```text
rg-cloudplatformlab-dev
```

Resources are tagged to support ownership, governance and cost tracking.

Current tags include:

```text
Project       = CloudPlatformLab
Environment   = Dev
ManagedBy     = Bicep
CostCenter    = CloudPlatformLab
```

The longer-term plan is to enforce some tagging and governance rules through Azure Policy.

---

## Cost Management

Cost is treated as part of the architecture.

This is a personal lab environment, so paid Azure resources are not intended to remain online when they are not needed.

The current process is:

```text
Bicep change
     |
     v
Bicep validation
     |
     v
Readiness checks
     |
     v
What-If
     |
     v
Review proposed resources
     |
     v
Check expected Azure cost
     |
     v
Manual approval
     |
     v
Deploy
     |
     v
Validate and gather evidence
     |
     v
Remove paid resources when appropriate
```

The Log Analytics workspace uses a 30-day retention period to provide a useful observability foundation without retaining development telemetry unnecessarily.

As telemetry sources are connected, ingestion volume and retention will be reviewed as part of the platform's cost controls.

Because the environment is defined as code, resources can be removed and recreated later.

This also helps test whether the infrastructure is genuinely reproducible.

The independent deployment architecture allows useful platform work to continue without bypassing the App Service quota constraint.

---

## Target Architecture

The deployed networking, observability and security foundations and the defined App Service workload form the initial platform baseline.

The longer-term target architecture includes the following areas.

### Identity and Security

- Microsoft Entra ID
- Managed Identities
- Azure Key Vault
- Azure RBAC
- Azure Policy
- Defender for Cloud
- Private Endpoints

### Networking

- hub-spoke virtual network architecture
- VNet peering
- Private DNS
- Private Endpoints
- private connectivity to Azure platform services
- workload subnet segmentation

### Application Platform

- Azure App Service
- deployment slots
- health checks
- controlled promotion to production

### Data

- Azure SQL
- Azure Storage
- Cosmos DB where appropriate

### Messaging

- Azure Service Bus
- Azure Event Grid

### Observability

- Azure Monitor
- Application Insights
- Log Analytics
- alerts
- Action Groups
- health monitoring

### Infrastructure and DevOps

- Bicep
- Terraform
- Azure DevOps
- Azure Repos
- GitHub
- reusable pipeline templates
- CI/CD
- automated testing

### Governance and FinOps

- Management Groups
- Azure Policy
- Azure RBAC
- resource tagging
- Azure Cost Management
- budgets and alerts
- non-production cost controls

---

## Landing Zone Direction

A later phase of the project will look at the platform above the individual workload.

The target structure is roughly:

```text
Tenant Root
     |
     +-- CloudPlatformLab
           |
           +-- Platform
           |     |
           |     +-- Connectivity
           |     +-- Management
           |
           +-- Landing Zones
                 |
                 +-- Dev
                 +-- Prod
```

This will be used to explore:

- Management Groups
- subscription organisation
- Policy inheritance
- RBAC
- governance
- networking
- cost controls
- platform security

The goal is not to reproduce a large enterprise environment at unnecessary cost.

Where appropriate, a smaller working implementation will be used together with documentation showing how the design would scale.

---

## Design Decisions

### Why App Service

App Service provides a managed application platform without requiring VM or Kubernetes management.

It is suitable for demonstrating deployment slots, managed identity, application configuration and CI/CD without adding unnecessary infrastructure complexity.

The App Service Plan SKU is parameterised so the architecture is not permanently tied to a specific SKU such as S1.

### Why a Deployment Slot

The `dev` slot allows changes to be deployed and validated separately from the main production site.

This also creates a path toward slot swapping and rollback later.

### Why Bicep

Bicep is Azure-native, works directly with Azure Resource Manager and fits naturally with the rest of the Azure-focused project.

Terraform will be introduced later to demonstrate a second IaC approach without maintaining two identical copies of every resource.

### Why Workload Identity Federation

Workload Identity Federation allows Azure DevOps to authenticate to Azure without storing a long-lived client secret.

This reduces secret-management overhead and is closer to the authentication approach intended for a production cloud environment.

### Why Azure RBAC for Key Vault

Key Vault uses the Azure RBAC permission model rather than legacy vault access policies.

This provides a consistent authorization model across Azure resources and allows access to be managed using scoped Azure role assignments.

### Why Soft Delete and Purge Protection

Key Vault can contain security-sensitive configuration that should not be permanently destroyed accidentally.

Soft delete provides a recovery window, while purge protection prevents protected content from being permanently removed before the recovery period expires.

### Why Public Key Vault Access Initially

Public network access remains enabled for the first security foundation so Key Vault deployment, RBAC and recovery controls can be implemented independently from private networking.

Private Endpoint and Private DNS integration will be introduced as a separate networking/security increment.

### Why Manual Approval

Infrastructure changes can affect availability, security and cost.

The approval gate creates a deliberate review point between validation and deployment.

### Why Separate Infrastructure Deployment Paths

App Service, networking, observability and security have different deployment dependencies and readiness requirements.

Keeping them in independent pipeline paths means a constraint affecting one platform area does not unnecessarily block validation or deployment of another.

This is demonstrated by the current App Service quota restriction: the application-platform deployment can stop at its readiness check while networking, observability and security continue independently.

### Why Modular Pipeline Templates

As additional platform domains were introduced, maintaining every stage in one root YAML pipeline would create unnecessary complexity and duplication.

Reusable stage templates keep each infrastructure domain isolated while preserving a single platform pipeline entry point.

This allows the root pipeline to remain readable while platform-specific validation and deployment logic can evolve independently.

### Why Separate Application and Private Endpoint Subnets

Application integration and Private Endpoints serve different networking purposes.

Using separate subnets provides a clearer boundary between application connectivity and private access to Azure platform services and gives each area room to evolve with its own configuration and controls.

### Why Workspace-Based Application Insights

Application Insights is linked to a Log Analytics workspace so application telemetry can use a central observability data store.

This provides a foundation for later KQL queries, alerts, operational investigation and correlation as application and platform telemetry are introduced.

### Why 30-Day Log Retention

The Dev environment does not require long-term telemetry retention.

A 30-day retention period provides enough history for development troubleshooting and observability work while limiting unnecessary retention and cost.

### Why Readiness Checks Before What-If

Some Azure deployment failures are caused by subscription or environment conditions rather than invalid infrastructure code.

Readiness checks detect known environmental constraints before deployment evaluation continues, while Bicep validation independently verifies that the infrastructure definition is valid.

This produces clearer pipeline failures by distinguishing invalid infrastructure from Azure subscription or deployment-readiness constraints.

### Why Cost-Aware Deployment

The project is a lab environment rather than a permanent production workload.

Paid resources are deployed only when they are needed and can be removed afterwards because the environment can be recreated from IaC.

---

## Current Status

Implemented and validated:

- .NET 8 application
- Products API
- Azure DevOps CI/CD pipeline
- reusable Azure DevOps YAML stage templates
- independent App Service, networking, observability and security pipeline paths
- Bicep infrastructure definitions
- Bicep validation
- Bicep What-If
- Workload Identity Federation
- Azure DevOps Environment
- manual deployment approval
- resource-provider readiness validation
- App Service SKU quota validation
- system-assigned managed identity defined in Bicep
- resource tagging defined in Bicep
- Dev virtual network deployed through Bicep
- application subnet deployed through Bicep
- private endpoint subnet deployed through Bicep
- Log Analytics workspace deployed through Bicep
- workspace-based Application Insights deployed through Bicep
- Application Insights linked to Log Analytics
- 30-day Log Analytics retention
- Azure Key Vault deployed through Bicep
- Azure RBAC Key Vault authorization
- Key Vault soft delete
- 90-day Key Vault soft-delete retention
- Key Vault purge protection

Currently provisioned:

```text
rg-cloudplatformlab-dev
|
+-- vnet-cloudplatformlab-dev
|   10.10.0.0/16
|   |
|   +-- snet-app
|   |   10.10.1.0/24
|   |
|   +-- snet-private-endpoints
|       10.10.2.0/24
|
+-- log-cloudplatformlab-dev
|   Log Analytics Workspace
|   30-day retention
|
+-- appi-cloudplatformlab-dev
|   Application Insights
|   linked to Log Analytics
|
+-- kv-cloudplatformlab-dev
    Azure Key Vault
    Azure RBAC
    Soft delete
    90-day recovery period
    Purge protection
```

Infrastructure defined but not currently provisioned:

- App Service Plan
- Products API App Service
- `dev` deployment slot

The App Service infrastructure has been validated through Bicep, but provisioning using the currently selected S1 SKU is blocked by the Azure subscription's App Service quota.

The App Service SKU is parameterised so the deployment architecture is not permanently tied to S1.

In progress:

- automated application tests
- application deployment once suitable App Service capacity is available
- application telemetry integration
- health checks

Planned:

- Azure Monitor alerts
- Action Groups
- application-to-Key-Vault managed identity access
- Azure Policy
- Private Endpoints
- Private DNS
- hub-spoke networking
- Defender for Cloud
- Terraform
- landing zone/governance example

---

## Implementation Evidence

Selected implementation evidence is stored in [`docs/evidence`](evidence/).

| Evidence | Demonstrates |
|---|---|
| [Pre-deployment quota gate](evidence/01-pre-deployment-validation-quota-gate.png) | Subscription readiness validation and fail-fast deployment control |
| [Bicep What-If](evidence/02-infrastructure-as-code-bicep-what-if.png) | Infrastructure as Code evaluated against Azure before deployment |
| [Dev deployment slot](evidence/03-deployment-slot-iac-bicep.png) | Deployment slot, managed identity, HTTPS/TLS and tagging represented through Bicep |
| [Manual Dev deployment gate](evidence/04-manual-dev-deployment-gate.png) | Controlled promotion into the Dev environment |
| [Networking deployment](evidence/05-networking-bicep-deployment-success.png) | Successful networking infrastructure deployment through the controlled Azure DevOps pipeline |
| [Deployed Virtual Network](evidence/06-networking-vnet-deployed-azure.png) | Azure Virtual Network successfully provisioned from Bicep |
| [Networking subnets](evidence/07-networking-subnets-deployed-azure.png) | Application and private endpoint subnet segmentation deployed in Azure |
| [Observability deployment pipeline](evidence/08-observability-deployment-pipeline.png) | Observability validation, readiness, What-If, approval and deployment through Azure DevOps |
| [Application Insights](evidence/09-application-insights-deployed.png) | Workspace-based Application Insights deployed and linked to Log Analytics |
| [Log Analytics workspace](evidence/10-log-analytics-workspace-deployed.png) | Central Log Analytics workspace successfully provisioned through Bicep |
| [Log Analytics retention](evidence/11-log-analytics-data-retention.png) | Explicit 30-day telemetry retention configuration for the Dev environment |
| [Key Vault deployment](evidence/12-key-vault-deployed-azure.png) | Azure Key Vault successfully provisioned in the Dev environment |
| [Key Vault security controls](evidence/13-key-vault-security-controls.png) | Soft delete, 90-day recovery protection, purge protection and project tagging |
| [Key Vault RBAC access model](evidence/14-key-vault-rbac-access-model.png) | Azure RBAC selected as the Key Vault permission model |