variable "resource_group_name" {
  description = "Name of the resource group containing the AKS platform resources."
  type        = string
  default     = "rg-cloudplatformlab-dev"
}

variable "location" {
  description = "Azure region used for the AKS platform."
  type        = string
  default     = "uksouth"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
  default     = "cloudplatformlab"
}

variable "tags" {
  description = "Common tags applied to supported Azure resources."
  type        = map(string)

  default = {
    Project     = "CloudPlatformLab"
    Environment = "Dev"
    ManagedBy   = "Terraform"
    CostCenter  = "CloudPlatformLab"
  }
}