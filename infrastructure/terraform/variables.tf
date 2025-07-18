variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "homelab-rg"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "eastus"
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
  default     = "homelab-kv"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "homelabacr"
}

# ArgoCD Variables
variable "argocd_admin_password" {
  description = "Admin password for ArgoCD"
  type        = string
  sensitive   = true
}

variable "argocd_server_url" {
  description = "URL of the ArgoCD server"
  type        = string
}

# Terraform Backend Variables
variable "tf_state_storage_account" {
  description = "Name of the storage account for Terraform state"
  type        = string
  default     = "homelabterraformstate"
}

variable "tf_state_container" {
  description = "Name of the container for Terraform state"
  type        = string
  default     = "tfstate"
}

variable "tf_state_key" {
  description = "Name of the state file for Terraform"
  type        = string
  default     = "homelab.tfstate"
}

# Azure Service Principal Variables
variable "azure_client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
} 