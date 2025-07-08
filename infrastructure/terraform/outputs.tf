output "resource_group_name" {
  value = azurerm_resource_group.homelab.name
}

output "key_vault_name" {
  value = azurerm_key_vault.homelab.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.homelab.vault_uri
}

output "acr_login_server" {
  value = azurerm_container_registry.homelab.login_server
}

output "acr_name" {
  value = azurerm_container_registry.homelab.name
}

# Key Vault Secret Names (not values)
output "key_vault_secrets" {
  value = {
    acr = {
      username_secret_name = azurerm_key_vault_secret.acr_username.name
      password_secret_name = azurerm_key_vault_secret.acr_password.name
    }
    argocd = {
      password_secret_name = azurerm_key_vault_secret.argocd_admin_password.name
      server_url_secret_name = azurerm_key_vault_secret.argocd_server_url.name
    }
    terraform = {
      storage_account_secret_name = azurerm_key_vault_secret.terraform_storage_account.name
      container_name_secret_name  = azurerm_key_vault_secret.terraform_container_name.name
      state_key_secret_name      = azurerm_key_vault_secret.terraform_state_key.name
    }
    azure_sp = {
      client_id_secret_name     = azurerm_key_vault_secret.azure_client_id.name
      client_secret_secret_name = azurerm_key_vault_secret.azure_client_secret.name
      tenant_id_secret_name     = azurerm_key_vault_secret.azure_tenant_id.name
      subscription_id_secret_name = azurerm_key_vault_secret.azure_subscription_id.name
    }
  }
  description = "Names of secrets stored in Key Vault (not the secret values themselves)"
} 