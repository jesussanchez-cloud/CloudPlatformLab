variable "location" {
  description = "Azure region used for the Terraform state infrastructure."
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "Resource group containing the Terraform state storage."
  type        = string
  default     = "rg-cloudplatformlab-tfstate"
}

variable "storage_account_name" {
  description = "Globally unique storage account used for Terraform remote state."
  type        = string
  default     = "stcplabtfstate"
}

variable "container_name" {
  description = "Blob container used to store Terraform state files."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Common tags applied to Terraform managed resources."
  type        = map(string)

  default = {
    Project     = "CloudPlatformLab"
    Environment = "Dev"
    ManagedBy   = "Terraform"
    CostCenter  = "CloudPlatformLab"
  }
}
