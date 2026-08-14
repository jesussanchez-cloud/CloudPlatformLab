# CloudPlatformLab

CloudPlatformLab is a production-oriented Azure platform engineering project demonstrating infrastructure as code, CI/CD, identity, security, networking, governance, observability and cost-aware cloud operations.

The application workload is intentionally simple. The engineering focus is the platform around it: reproducible infrastructure, secretless authentication, controlled deployments, environment validation and operational safeguards.

The platform is being developed incrementally, with implemented capabilities separated from the target architecture so that architectural decisions, deployment controls and operational behaviour can be validated and documented as the platform evolves.

---

## Architecture

The application platform is designed around Azure App Service, with infrastructure defined in Bicep and validated through Azure DevOps.

```text
                    Azure DevOps
                         |
                         v
                 Build and Validate
                         |
                         v
              Pre-deployment Checks
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

Development changes are designed to be deployed to the `dev` slot first so they can be validated before being promoted to production.

> **Deployment status:** The App Service infrastructure is defined in Bicep and has been successfully validated through Bicep What-If. Final S1 provisioning is currently blocked by a subscription-level App Service quota constraint. See [Deployment Validation and Evidence](#deployment-validation-and-evidence).

---

## Target Architecture

The project is being built towards a broader Azure platform architecture.

Not everything below is implemented yet. Components are added where they demonstrate a useful cloud/platform engineering pattern rather than simply increasing the number of Azure services in the project.

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

- Azure Service Bus for asynchronous messaging
- Azure Event Grid for event distribution

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

The following sections describe capabilities that have actually been implemented or validated so far.

### Application

The current workload is an ASP.NET Core .NET 8 application containing a simple Products API.

The application is deliberately small because the engineering focus is the Azure platform and deployment architecture rather than application complexity.

Currently implemented:

- ASP.NET Core .NET 8 application
- Products API
- App Service infrastructure defined in Bicep
- `dev` deployment slot defined in Bicep
- system-assigned managed identity defined in Bicep
- App Service infrastructure validated through Bicep What-If

---

## Infrastructure as Code

Azure infrastructure is defined using Bicep.

The current App Service Bicep template defines:

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

Bicep is kept in the repository alongside the application so infrastructure changes follow the same Git and pull request workflow as application changes.

Infrastructure is validated before deployment rather than relying on manually configured Azure resources.

---

## CI/CD

Azure DevOps is used for CI/CD.

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
Restore & Build
      |
      v
IaC Validation
      |
      v
Pre-deployment Checks
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

Infrastructure deployment uses an Azure DevOps Environment with an approval check, providing a control point between validating an infrastructure change and applying it.

Pre-deployment checks are used to detect Azure subscription prerequisites before reaching the deployment stage.

---

## Deployment Validation and Evidence

The infrastructure deployment workflow is implemented through Azure DevOps and Bicep.

The pipeline currently performs:

- .NET 8 restore and build
- Azure subscription pre-deployment checks
- `Microsoft.Web` resource provider validation
- App Service S1 quota validation
- Bicep What-If before deployment
- Azure DevOps Environment approval before Dev infrastructure deployment
- Azure authentication through Workload Identity Federation

The Bicep What-If has successfully validated the intended creation of:

- Standard S1 App Service Plan
- Products API App Service
- `dev` deployment slot

The template also defines HTTPS-only access, TLS 1.2, resource tagging and system-assigned managed identity.

### Current deployment constraint

Final S1 provisioning is currently blocked by an Azure subscription-level App Service quota of `0`.

Rather than bypassing the deployment controls or manually creating resources, the pipeline detects this condition during pre-deployment validation and stops before infrastructure deployment.

This is an Azure subscription quota constraint rather than a Bicep validation failure. No S1 App Service resources were provisioned by the failed deployment.

The failed deployment path was used to improve the pipeline so that subscription prerequisites are now detected earlier in the deployment lifecycle.

### Evidence

Pipeline and IaC evidence is available in [`docs/evidence`](docs/evidence/):

- [Pre-deployment quota gate](docs/evidence/01-pre-deployment-validation-quota-gate.png)
- [Bicep Infrastructure as Code What-If](docs/evidence/02-infrastructure-as-code-bicep-what-if.png)
- [Dev deployment slot defined through Bicep](docs/evidence/03-deployment-slot-iac-bicep.png)
- [Manual Dev deployment gate](docs/evidence/04-manual-dev-deployment-gate.png)

Additional architectural decisions and implementation details are documented in [`docs/architecture.md`](docs/architecture.md).

---

## Identity & Security

The Azure DevOps pipeline connects to Azure using Workload Identity Federation.

This allows the pipeline to authenticate to Azure without storing a long-lived client secret in the repository or pipeline configuration.

The App Service definition also includes a system-assigned managed identity. As dependent Azure services are introduced, managed identity will be preferred where supported instead of application credentials.

Security controls currently implemented or represented in the deployment architecture include:

- Workload Identity Federation
- system-assigned Managed Identity
- HTTPS-only App Service configuration
- TLS 1.2 minimum
- Azure RBAC
- controlled Azure DevOps service connection
- manual deployment approval

Secrets and credentials are not stored in the repository.

Key Vault, Azure Policy, private connectivity and additional security controls form part of the target architecture and will be introduced where they support a concrete platform requirement.

---

## Resource Organisation

Development resources target:

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

The same tagging approach can later be enforced through Azure Policy as the governance layer develops.

---

## Cost Management

Cost management is treated as part of the platform design rather than as a separate administrative task.

Because this is a personal lab environment, paid Azure resources do not need to remain online when they are not being actively used.

Before deploying paid infrastructure:

1. Run Bicep What-If.
2. Review the proposed resource changes.
3. Check the expected Azure cost.
4. Validate subscription prerequisites.
5. Manually approve the deployment.
6. Validate the deployed infrastructure.
7. Remove paid resources when they are no longer required.

Because the environment is defined as code, resources can be destroyed when they are not needed and recreated later from Bicep.

This also tests infrastructure reproducibility rather than relying on resources that were configured manually and left running indefinitely.

---

## Git Workflow

Azure Repos is used for the main development and pull request workflow.

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

Infrastructure, pipeline and documentation changes go through feature branches and pull requests rather than being changed directly on `Dev`.

After changes are merged, the public GitHub repository is synchronized with the Azure Repos version.

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
|   |   +-- main.bicep
|   |
|   +-- networking
|       +-- main.bicep
|
+-- tests
|
+-- docs
|   +-- architecture.md
|   +-- evidence
|
+-- azure-pipelines.yml
|
+-- CloudPlatformLab.sln
|
+-- README.md
```

The `tests` area is currently being prepared. Genuine automated tests will be added as the deployment workflow develops.

---

## Deployment Strategy

The application deployment architecture uses one App Service with a development deployment slot.

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

The intended promotion path validates changes in the `dev` slot before promoting them to the main production App Service.

Deployment slot swapping and rollback can then provide controlled promotion and recovery once the application deployment path is operational.

---

## Landing Zone and Governance

A later phase will extend the project from workload-level infrastructure into a small enterprise-style governance model.

The target model explores a structure such as:

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

This architecture will be used to explore:

- Management Groups
- subscription organisation
- Azure Policy
- RBAC
- governance inheritance
- budgets and cost controls
- networking
- platform security

The objective is not to create unnecessary paid resources or subscriptions simply to reproduce the size of an enterprise environment.

Where appropriate, the project will implement a smaller working example and document how the same design would scale in a production environment.

---

## Bicep and Terraform

Bicep is currently used for Azure workload infrastructure.

Terraform will be introduced later for selected infrastructure.

The intention is not to maintain two identical implementations of every resource. The project will use both tools where they demonstrate useful infrastructure patterns and the differences between Azure-native IaC and a provider-based IaC workflow.

---

## Current Work

The current phase is extending the platform beyond the initial App Service deployment architecture.

Current priorities are:

- integrate the networking Bicep module into CI validation
- build the Dev virtual network and subnet foundation
- separate generic IaC validation from workload-specific deployment readiness checks
- add automated application tests
- introduce observability with Application Insights and Azure Monitor
- add Key Vault and managed-identity based access where required
- introduce private connectivity as dependent platform services are added
- extend governance with Azure Policy
- introduce Terraform for selected infrastructure

The architecture and documentation will continue to evolve alongside implemented capabilities.

---

## Technologies

### Currently Used

- Microsoft Azure
- Microsoft Entra ID
- Azure DevOps
- Azure Repos
- Azure Pipelines
- Azure DevOps Environments
- Workload Identity Federation
- Managed Identity
- Bicep
- Bicep What-If
- Azure CLI
- ASP.NET Core
- .NET 8
- Git
- GitHub

### Defined / In Progress

- Azure App Service
- App Service Deployment Slots
- Azure Virtual Network
- Subnet architecture

### Planned

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
