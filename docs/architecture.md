# Architecture

CloudPlatformLab is designed as a small Azure platform engineering project rather than a complex application.

The application is intentionally simple. The main focus is the Azure architecture around it: infrastructure as code, CI/CD, identity, security, governance, networking, observability and cost control.

The project is being built incrementally so that each part can be understood and tested properly.

---

## Current Architecture

The current workload uses Azure App Service with a development deployment slot.

```text
                    Azure DevOps
                         |
                         v
                 Build and Validate
                         |
                         v
                   Bicep What-If
                         |
                         v
                  Manual Approval
                         |
                         v
                  Bicep Deployment
                         |
                         v
                rg-cloudplatformlab-dev
                         |
                         v
                  App Service Plan
                         |
                         v
                    App Service
                         |
                         +---- dev slot
```

The main App Service represents the production application.

The `dev` slot is used for development and validation before changes are promoted to production.

---

## Application Layer

The current workload is an ASP.NET Core .NET 8 application containing a simple Products API.

The application is deliberately small because the main objective of the project is to demonstrate the platform around the application rather than application complexity.

Current application components:

- ASP.NET Core .NET 8
- Products API
- Azure App Service
- `dev` deployment slot

---

## Infrastructure Layer

Infrastructure is defined using Bicep.

The current template is located at:

```text
infra/appservice/main.bicep
```

It currently defines:

- S1 App Service Plan
- App Service
- `dev` deployment slot
- system-assigned managed identity
- HTTPS-only configuration
- TLS 1.2 minimum
- resource tags

The infrastructure is deployed into:

```text
rg-cloudplatformlab-dev
```

Region:

```text
UK South
```

Using Bicep means the environment can be recreated instead of relying on manually configured resources.

---

## Deployment Architecture

Azure DevOps is used for CI/CD.

Changes are developed in feature branches and merged into `Dev` through pull requests.

The current deployment flow is:

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
Restore
      |
      v
Build
      |
      v
Bicep What-If
      |
      v
Azure DevOps Environment
      |
      v
Manual Approval
      |
      v
Bicep Deployment
```

Bicep What-If runs before infrastructure deployment so that proposed Azure changes can be reviewed before they are applied.

The deployment stage targets the Azure DevOps environment:

```text
env-cloudplatformlab-dev
```

This environment has a manual approval check.

---

## Identity and Authentication

The Azure DevOps pipeline authenticates to Azure using Workload Identity Federation.

This avoids storing an Azure client secret in the pipeline or repository.

The service connection is:

```text
sc-cloudplatformlab-dev
```

The App Service also uses a system-assigned managed identity.

The intention is to use managed identity for access to Azure services wherever possible instead of storing credentials in application configuration.

---

## Security Design

Current security controls include:

- Workload Identity Federation
- system-assigned managed identity
- HTTPS-only App Service
- TLS 1.2 minimum
- Azure RBAC
- controlled Azure DevOps service connection
- manual approval before infrastructure deployment

Planned security improvements include:

- Azure Key Vault
- Azure Policy
- Private Endpoints
- Private DNS
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
Remove paid resources
```

Because the environment is defined as code, resources can be removed and recreated later.

This also helps test whether the infrastructure is genuinely reproducible.

---

## Target Architecture

The current App Service workload is only the first part of the project.

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

- Hub-spoke virtual network
- VNet Peering
- Private DNS
- private connectivity to Azure platform services

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

The goal is not to reproduce a huge enterprise environment at unnecessary cost.

Where appropriate, a smaller working implementation will be used together with documentation showing how the design would scale.

---

## Design Decisions

### Why App Service

App Service provides a managed application platform without requiring VM or Kubernetes management.

It is suitable for demonstrating deployment slots, managed identity, application configuration and CI/CD without adding unnecessary infrastructure complexity.

### Why a Deployment Slot

The `dev` slot allows changes to be deployed and validated separately from the main production site.

This also creates a path toward slot swapping and rollback later.

### Why Bicep

Bicep is Azure-native, works directly with Azure Resource Manager and fits naturally with the rest of the Azure-focused project.

Terraform will be introduced later to demonstrate a second IaC approach without maintaining two identical copies of every resource.

### Why Workload Identity Federation

Workload Identity Federation allows Azure DevOps to authenticate to Azure without storing a long-lived client secret.

This reduces secret-management overhead and is closer to the authentication approach I would want in a real cloud environment.

### Why Manual Approval

Infrastructure changes can affect both availability and cost.

The approval gate creates a deliberate review point between validation and deployment.

### Why Cost-Aware Deployment

The project is a lab environment rather than a permanent production workload.

Paid resources are deployed only when they are needed and can be removed afterwards because the environment can be recreated from IaC.

---

## Current Status

Implemented:

- .NET 8 application
- Products API
- Azure DevOps CI pipeline
- Bicep infrastructure
- Bicep What-If
- Workload Identity Federation
- Azure DevOps Environment
- manual deployment approval
- App Service architecture
- `dev` deployment slot
- managed identity
- resource tagging

In progress:

- first gated infrastructure deployment
- application deployment to the `dev` slot
- deployment validation
- health checks

Planned:

- automated tests
- monitoring and logging
- Key Vault
- Azure Policy
- private networking
- Terraform
- landing zone/governance example