# CloudPlatformLab

CloudPlatformLab is a personal Azure project I am building to develop and demonstrate my cloud and platform engineering skills.

The application itself is intentionally simple. The main focus is the platform around it: infrastructure as code, CI/CD, identity, security, networking, governance, monitoring and cost management.

I am building the project incrementally rather than deploying a large number of Azure services at once. This keeps the project manageable and gives me a chance to understand and document each part properly.

---

## Architecture

The current application runs on Azure App Service.

Infrastructure is defined in Bicep and changes are validated and deployed through Azure DevOps.

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
                Azure Resource Group
                         |
                  App Service Plan
                         |
                         v
                    App Service
                         |
                         +---- dev slot
```

The main App Service represents the production application.

Development changes are deployed to the `dev` slot first so they can be validated before being promoted to production.

---

## Target Architecture

The project is being built towards a broader Azure platform architecture.

Not everything below is implemented yet. Components are being added where they demonstrate a useful cloud/platform engineering pattern rather than simply increasing the number of Azure services in the project.

### Identity & Security

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
- Private connectivity to platform services

### Application Platform

- ASP.NET Core .NET 8
- Azure App Service
- Deployment Slots

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
- Alerts
- Action Groups
- Health checks

### Infrastructure & DevOps

- Bicep
- Terraform
- Azure DevOps
- Azure Repos
- GitHub
- CI/CD
- Automated testing

### Governance & FinOps

- Management Groups
- Azure Policy
- Azure RBAC
- Resource tagging
- Azure Cost Management
- Budgets and cost alerts
- Non-production cost controls
- Cost optimisation

---

## Current Implementation

The following sections describe what has actually been implemented so far.

### Application

The current workload is an ASP.NET Core .NET 8 application containing a simple Products API.

The application is deliberately small because the focus of the project is the Azure platform and deployment architecture rather than application complexity.

Current application platform:

- ASP.NET Core .NET 8
- Products API
- Azure App Service architecture
- `dev` deployment slot

---

## Infrastructure as Code

Azure infrastructure is defined using Bicep.

The current Bicep template defines:

- S1 App Service Plan
- App Service
- `dev` deployment slot
- system-assigned managed identity
- HTTPS-only configuration
- TLS 1.2 minimum
- resource tags

The development infrastructure targets a dedicated resource group in UK South:

```text
rg-cloudplatformlab-dev
```

Bicep is kept in the repository alongside the application so infrastructure changes can follow the same Git and pull request workflow as application changes.

---

## CI/CD

Azure DevOps is currently used for CI/CD.

Changes are developed using feature branches and merged into `Dev` through pull requests.

The current pipeline follows this process:

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
Infrastructure Deployment
```

Bicep What-If runs before the deployment stage so proposed infrastructure changes can be reviewed before anything is changed in Azure.

Infrastructure deployment uses an Azure DevOps Environment with an approval check. This gives me a manual control point between validating an infrastructure change and applying it.

---

## Identity & Security

The Azure DevOps pipeline connects to Azure using Workload Identity Federation.

This means the pipeline can authenticate to Azure without storing a client secret in the repository or pipeline configuration.

The App Service is also configured with a system-assigned managed identity. This will be used as other Azure services are added so the application can authenticate without storing credentials where managed identity is supported.

Security controls currently implemented include:

- Workload Identity Federation
- system-assigned Managed Identity
- HTTPS-only App Service
- TLS 1.2 minimum
- Azure RBAC
- controlled Azure DevOps service connection
- manual deployment approval

Secrets and credentials are not stored in the repository.

Key Vault, Azure Policy, private connectivity and additional security controls are part of the target architecture and will be introduced as the project develops.

---

## Resource Organisation

Development resources are grouped under:

```text
rg-cloudplatformlab-dev
```

Resources are tagged to make their purpose and ownership easier to identify and to support cost reporting and governance.

Current tags include:

```text
Project       = CloudPlatformLab
Environment   = Dev
ManagedBy     = Bicep
CostCenter    = CloudPlatformLab
```

The same tagging approach can later be extended through Azure Policy as the governance part of the project develops.

---

## Cost Management

Cost management is part of the design of the project.

Because this is a personal lab environment, I do not want paid Azure resources running when they are not being used.

Before deploying paid infrastructure I:

1. Run Bicep What-If.
2. Review the proposed resource changes.
3. Check the expected Azure cost.
4. Manually approve the deployment.
5. Validate the deployed infrastructure.
6. Remove paid resources when they are no longer required.

Because the environment is defined as code, resources can be destroyed when they are not needed and recreated later from Bicep.

This also gives me a way to test that the infrastructure is reproducible rather than relying on resources that were configured manually.

---

## Git Workflow

Azure Repos is currently used for the main development and pull request workflow.

GitHub is maintained as the public repository for the project.

The normal workflow is:

```text
feature/*
    |
    v
Pull Request
    |
    v
Dev
    |
    v
Build and Infrastructure Validation
```

Infrastructure and pipeline changes also go through feature branches and pull requests rather than being changed directly on `Dev`.

After changes are merged, the GitHub repository is kept synchronized with the Azure Repos version.

---

## Repository Structure

```text
CloudPlatformLab
|
+-- src
|   +-- CloudPlatformLab.Web
|   +-- CloudPlatformLab.Application
|
+-- infra
|   +-- appservice
|       +-- main.bicep
|
+-- tests
|
+-- docs
|
+-- azure-pipelines.yml
|
+-- CloudPlatformLab.sln
|
+-- README.md
```

The `tests` area is currently being prepared. Automated tests will be added as the deployment workflow develops.

---

## Deployment Strategy

The current design uses one App Service with a development deployment slot.

```text
Dev branch
     |
     v
Azure DevOps Pipeline
     |
     v
dev deployment slot
     |
     v
Validation
     |
     v
Production
```

The intention is to validate changes in the `dev` slot before promoting them to the main production App Service.

Deployment slot swapping and rollback will be added once the basic application deployment pipeline is complete.

---

## Landing Zone and Governance

A later part of the project will look at the platform above the individual workload.

The aim is to build a small Azure landing zone example covering areas such as:

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
- Azure Policy
- RBAC
- governance inheritance
- budgets and cost controls
- networking
- platform security

I do not intend to create unnecessary paid resources or subscriptions simply to reproduce a large enterprise environment. Where appropriate, the project will implement a smaller working example and document how the design would scale in a production environment.

---

## Bicep and Terraform

Bicep is currently being used for the Azure workload infrastructure.

Terraform will also be introduced later in the project.

The intention is not to maintain two identical copies of every resource. I want to use both tools where they provide useful examples and demonstrate the differences between Azure-native IaC and a provider-based IaC workflow.

---

## Current Work

The current phase of the project is focused on completing the Dev deployment path.

Next steps are:

- complete the first gated Bicep deployment
- deploy the .NET application to the `dev` App Service slot
- add deployment validation and health checks
- add automated tests
- add Application Insights and Azure Monitor
- introduce Key Vault where secrets are required
- improve Azure Policy and governance controls
- add private networking where it provides a useful example
- add Terraform
- build the landing zone/governance example

The architecture will continue to change as these parts are implemented.

---

## Technologies

### Currently Used

- Microsoft Azure
- Azure App Service
- Microsoft Entra ID
- Azure DevOps
- Azure Repos
- Azure Pipelines
- Azure DevOps Environments
- Workload Identity Federation
- Managed Identity
- Bicep
- Azure CLI
- ASP.NET Core
- .NET 8
- Git
- GitHub

### Planned / In Progress

- Terraform
- Azure Key Vault
- Azure Policy
- Azure Monitor
- Application Insights
- Log Analytics
- Azure SQL
- Azure Storage
- Azure Service Bus
- Azure Event Grid
- Private Endpoints
- Private DNS
- Hub-spoke networking
- Management Groups
- Landing Zone governance