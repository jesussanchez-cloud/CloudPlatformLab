# Architecture

CloudPlatformLab is designed as a small Azure platform engineering project rather than a complex application.

The application is intentionally simple. The main focus is the Azure architecture around it: infrastructure as code, CI/CD, identity, security, governance, networking, observability and cost control.

The project is being built incrementally so that each part can be understood, tested and documented properly.

---

## Current Architecture

CloudPlatformLab currently has a deployed Dev networking foundation, with the application platform defined separately in Bicep.

```text
                         Azure DevOps
                              |
                              v
                       Build Application
                              |
                +-------------+-------------+
                |                           |
                v                           v
        App Service Path             Networking Path
                |                           |
                v                           v
        Readiness Checks             Readiness Checks
                |                           |
                v                           v
        Bicep Validation             Bicep Validation
                |                           |
                v                           v
          Bicep What-If                Bicep What-If
                |                           |
                v                           v
         Manual Approval              Manual Approval
                |                           |
                v                           v
        App Service Deploy           Networking Deploy
         (quota blocked)                    |
                                            v
                                  rg-cloudplatformlab-dev
                                            |
                                            v
                                  vnet-cloudplatformlab-dev
                                     10.10.0.0/16
                                            |
                              +-------------+-------------+
                              |                           |
                              v                           v
                           snet-app             snet-private-endpoints
                         10.10.1.0/24               10.10.2.0/24
```

The networking deployment path has been successfully executed through Azure DevOps, including readiness validation, Bicep validation, Bicep What-If, manual environment approval and Bicep deployment.

The App Service infrastructure follows an independent deployment path. Its Bicep definition is valid, but provisioning is currently blocked by the subscription's available App Service quota.

Keeping these deployment paths independent allows networking infrastructure to be validated and deployed without being blocked by an unrelated application-platform constraint.

---

## Application Layer

The current workload is an ASP.NET Core .NET 8 application containing a simple Products API.

The application is deliberately small because the main objective of the project is to demonstrate the platform around the application rather than application complexity.

Current application components:

- ASP.NET Core .NET 8
- Products API
- Azure App Service architecture
- `dev` deployment slot architecture

The App Service infrastructure is currently defined and validated through Bicep but is not provisioned because of the subscription's available App Service quota.

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

The deployed networking foundation currently consists of:

```text
vnet-cloudplatformlab-dev
10.10.0.0/16
|
+-- snet-app
|   10.10.1.0/24
|
+-- snet-private-endpoints
    10.10.2.0/24
```

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

---

## Networking Architecture

The first deployed networking foundation provides address space for application workloads and future private connectivity.

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

## Deployment Architecture

Azure DevOps is used for CI/CD.

Changes are developed in feature branches and merged into `Dev` through pull requests. The `Dev` branch is the deployment source for the Dev environment.

The pipeline separates application-platform and networking infrastructure into independent deployment paths.

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
      +---------------------------+
      |                           |
      v                           v
App Service Path            Networking Path
      |                           |
      v                           v
Readiness Checks            Readiness Checks
      |                           |
      v                           v
Bicep Validation            Bicep Validation
      |                           |
      v                           v
Bicep What-If               Bicep What-If
      |                           |
      v                           v
Manual Approval             Manual Approval
      |                           |
      v                           v
Deployment                  Deployment
```

The independent paths prevent a deployment constraint affecting one infrastructure area from unnecessarily blocking another.

This is currently demonstrated by the App Service quota constraint: App Service deployment can stop at its readiness checks while networking continues independently through validation, approval and deployment.

Both deployment paths target the Azure DevOps environment:

```text
env-cloudplatformlab-dev
```

The environment uses a manual approval check before infrastructure changes are applied.

---

### Deployment Safeguards

Infrastructure changes are not deployed directly from a developer workstation.

Each infrastructure path follows a controlled sequence:

1. Deployment readiness checks
2. Bicep validation
3. Bicep What-If
4. Azure DevOps Environment approval
5. Bicep resource-group deployment

App Service readiness currently validates:

- `Microsoft.Web` resource provider registration
- quota availability for the configured App Service SKU

Networking readiness currently validates:

- `Microsoft.Network` resource provider registration
- target resource group availability

These checks are intentionally separated from generic Bicep validation so environmental deployment constraints do not prevent the infrastructure definition itself from being validated.

The deployment stages use an Azure Resource Manager service connection configured with Workload Identity Federation, avoiding a long-lived client secret in the pipeline.

---

## Identity and Authentication

The Azure DevOps pipeline authenticates to Azure using Workload Identity Federation.

This avoids storing an Azure client secret in the pipeline or repository.

The service connection is:

```text
sc-cloudplatformlab-dev
```

The App Service is also defined with a system-assigned managed identity.

The intention is to use managed identity for access to Azure services wherever possible instead of storing credentials in application configuration.

---

## Security Design

Current security controls include:

- Workload Identity Federation
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
Readiness checks
     |
     v
Bicep validation
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

Because the environment is defined as code, resources can be removed and recreated later.

This also helps test whether the infrastructure is genuinely reproducible.

The networking foundation currently uses Azure resources that do not require the App Service capacity that is blocking the application-platform deployment. Separating the deployment paths allows useful platform work to continue without bypassing the App Service quota constraint.

---

## Target Architecture

The currently deployed networking foundation and defined App Service workload are the first parts of a broader Azure platform architecture.

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

This reduces secret-management overhead and is closer to the authentication approach I would want in a real cloud environment.

### Why Manual Approval

Infrastructure changes can affect both availability and cost.

The approval gate creates a deliberate review point between validation and deployment.

### Why Separate Infrastructure Deployment Paths

App Service and networking have different deployment dependencies and readiness requirements.

Keeping them in independent pipeline paths means a constraint affecting one platform area does not unnecessarily block validation or deployment of another.

This is demonstrated by the current App Service quota restriction: the application-platform deployment can stop at its readiness check while networking can continue independently through validation, approval and deployment.

### Why Separate Application and Private Endpoint Subnets

Application integration and Private Endpoints serve different networking purposes.

Using separate subnets provides a clearer boundary between application connectivity and private access to Azure platform services and gives each area room to evolve with its own configuration and controls.

### Why Readiness Checks Before What-If

Some Azure deployment failures are caused by subscription or environment conditions rather than invalid infrastructure code.

Readiness checks detect known environmental constraints before running deployment evaluation, while Bicep validation independently verifies that the infrastructure definition can compile successfully.

This also produces clearer pipeline failures by distinguishing an invalid infrastructure definition from an Azure subscription or deployment-readiness constraint.

### Why Cost-Aware Deployment

The project is a lab environment rather than a permanent production workload.

Paid resources are deployed only when they are needed and can be removed afterwards because the environment can be recreated from IaC.

---

## Current Status

Implemented and validated:

- .NET 8 application
- Products API
- Azure DevOps CI/CD pipeline
- independent App Service and networking pipeline paths
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

Currently provisioned:

```text
vnet-cloudplatformlab-dev
10.10.0.0/16

snet-app
10.10.1.0/24

snet-private-endpoints
10.10.2.0/24
```

Infrastructure defined but not currently provisioned:

- App Service Plan
- Products API App Service
- `dev` deployment slot

The App Service infrastructure has been validated through Bicep, but provisioning is currently blocked by the Azure subscription's available App Service quota.

The App Service SKU is parameterised so the deployment architecture is not tied permanently to S1 and can use an appropriate supported SKU in the future.

In progress:

- application deployment once suitable App Service capacity is available
- deployment validation
- health checks

Planned:

- automated tests
- Azure Monitor and Application Insights
- Log Analytics
- Key Vault
- Azure Policy
- Private Endpoints
- Private DNS
- hub-spoke networking
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