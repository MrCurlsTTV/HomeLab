terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration will be provided via backend config file or CLI
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "homelab" {
  name     = var.resource_group_name
  location = var.location
}

# Key Vault
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "homelab" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.homelab.location
  resource_group_name         = azurerm_resource_group.homelab.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                   = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete",
    ]
  }
}

# Container Registry
resource "azurerm_container_registry" "homelab" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.homelab.name
  location            = azurerm_resource_group.homelab.location
  sku                = "Standard"
  admin_enabled      = true
}

# Store ACR credentials in Key Vault
resource "azurerm_key_vault_secret" "acr_username" {
  name         = "acr-username"
  value        = azurerm_container_registry.homelab.admin_username
  key_vault_id = azurerm_key_vault.homelab.id
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  value        = azurerm_container_registry.homelab.admin_password
  key_vault_id = azurerm_key_vault.homelab.id
}

# ArgoCD Secrets
resource "azurerm_key_vault_secret" "argocd_admin_password" {
  name         = "argocd-admin-password"
  value        = var.argocd_admin_password
  key_vault_id = azurerm_key_vault.homelab.id
}

resource "azurerm_key_vault_secret" "argocd_server_url" {
  name         = "argocd-server-url"
  value        = var.argocd_server_url
  key_vault_id = azurerm_key_vault.homelab.id
}

# Terraform Backend Secrets
resource "azurerm_key_vault_secret" "terraform_storage_account" {
  name         = "terraform-storage-account"
  value        = var.tf_state_storage_account
  key_vault_id = azurerm_key_vault.homelab.id
}

resource "azurerm_key_vault_secret" "terraform_container_name" {
  name         = "terraform-container-name"
  value        = var.tf_state_container
  key_vault_id = azurerm_key_vault.homelab.id
}

resource "azurerm_key_vault_secret" "terraform_state_key" {
  name         = "terraform-state-key"
  value        = var.tf_state_key
  key_vault_id = azurerm_key_vault.homelab.id
}

# Azure Service Principal Secrets (for CI/CD)
resource "azurerm_key_vault_secret" "azure_client_id" {
  name         = "azure-client-id"
  value        = var.azure_client_id
  key_vault_id = azurerm_key_vault.homelab.id
}

resource "azurerm_key_vault_secret" "azure_client_secret" {
  name         = "azure-client-secret"
  value        = var.azure_client_secret
  key_vault_id = azurerm_key_vault.homelab.id
}

resource "azurerm_key_vault_secret" "azure_tenant_id" {
  name         = "azure-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.homelab.id
}

resource "azurerm_key_vault_secret" "azure_subscription_id" {
  name         = "azure-subscription-id"
  value        = data.azurerm_client_config.current.subscription_id
  key_vault_id = azurerm_key_vault.homelab.id
} 