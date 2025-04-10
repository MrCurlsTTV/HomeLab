variable "pm_api_url" {
    description = "Proxmox API URL"
    type        = string
    default     = "https://192.168.103.2:8006/api2/json"
}

variable "pm_user" {
    description = "Proxmox API user"
    type        = string
    default     = null
}

variable "pm_password" {
    description = "Proxmox API password"
    type        = string
    sensitive   = true
    default     = null
}

variable "pm_api_token_id" {
    description = "Proxmox API token ID"
    type        = string
}

variable "pm_api_token_secret" {
    description = "Proxmox API token secret"
    type        = string
    sensitive   = true
}

variable "pm_tls_insecure" {
    description = "Skip TLS verification"
    type        = bool
    default     = true
}

variable "pm_parallel" {
    description = "Allowed Simultaneous Proxmox Requests"
    type        = number
    default     = 2
}

variable "pm_otp" {
    description = "Proxmox OTP code"
    type        = string
    default     = null
}

variable "pm_log_enabled" {
    description = "Enable Proxmox API logging"
    type        = bool
    default     = true
}

variable "pm_log_file" {
    description = "Proxmox API log file path"
    type        = string
    default     = "terraform-proxmox.log"
}

variable "pm_timeout" {
    description = "Proxmox API timeout in seconds"
    type        = number
    default     = 300
}

variable "pm_debug" {
    description = "Enable Proxmox API debug mode"
    type        = bool
    default     = true
}

variable "nfs" {
    description = "NFS server address"
    type        = string
    default     = "truenas.mrcurls.org"
}