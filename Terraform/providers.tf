provider "proxmox" {
    pm_api_url          = var.pm_api_url
    pm_user             = var.pm_user
    pm_password         = var.pm_password
    pm_tls_insecure     = var.pm_tls_insecure
    pm_otp              = var.pm_otp
    pm_api_token_id     = var.pm_api_token_id
    pm_api_token_secret = var.pm_api_token_secret
    pm_parallel         = var.pm_parallel
}

terraform { 
    cloud { 
    
        organization = "MrCurls" 

    workspaces { 
        name = "Automation" 
        } 
    } 
}