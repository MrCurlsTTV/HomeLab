locals {
    proxmox_vm_qemu = {
        "200" = {
            name        = "k8s-master-0"
            target_node = "alvin"
            clone       = "ubuntu-24.04-template"
            tags        = "k8s;master;ubuntu-24.04"
            memory      = 4096
            cores       = 2
            disk_size   = "50G"
            ipconfig0   = "ip=172.16.10.200/16,gw=172.16.0.1"
        }
        "201" = {
            name        = "k8s-master-1"
            target_node = "simon"
            clone       = "ubuntu-24.04-template"
            tags        = "k8s;master;ubuntu-24.04"
            memory      = 4096
            cores       = 2
            disk_size   = "50G"
            ipconfig0   = "ip=172.16.10.201/16,gw=172.16.0.1"
        }
        "202" = {
            name        = "k8s-master-2"
            target_node = "theodore"
            clone       = "ubuntu-24.04-template"
            tags        = "k8s;master;ubuntu-24.04"
            memory      = 4096
            cores       = 2
            disk_size   = "50G"
            ipconfig0   = "ip=172.16.10.202/16,gw=172.16.0.1"
        }
        "210" = {
            name        = "k8s-worker-1"
            target_node = "alvin"
            clone       = "ubuntu-24.04-template"
            tags        = "k8s;worker;ubuntu-24.04"
            memory      = 8192
            cores       = 4
            ipconfig0   = "ip=172.16.10.210/16,gw=172.16.0.1"
        }
        "211" = {
            name        = "k8s-worker-2"
            target_node = "alvin"
            clone       = "ubuntu-24.04-template"
            tags        = "k8s;worker;ubuntu-24.04"
            memory      = 8192
            cores       = 4
            ipconfig0   = "ip=172.16.10.211/16,gw=172.16.0.1"
        }
        "212" = {
            name        = "k8s-worker-3"
            target_node = "simon"
            clone       = "ubuntu-24.04-template"
            tags        = "k8s;worker;ubuntu-24.04"
            memory      = 8192
            cores       = 4
            ipconfig0   = "ip=172.16.10.212/16,gw=172.16.0.1"
        }
        "213" = {
            name        = "k8s-worker-4"
            target_node = "simon"
            clone       = "ubuntu-24.04-template"
            tags        = "k8s;worker;ubuntu-24.04"
            memory      = 8192
            cores       = 4
            ipconfig0   = "ip=172.16.10.213/16,gw=172.16.0.1"
        }
        "214" = {
            name        = "k8s-worker-5"
            target_node = "theodore"
            clone       = "ubuntu-24.04-template"
            tags        = "k8s;worker;ubuntu-24.04"
            memory      = 8192
            cores       = 4
            ipconfig0   = "ip=172.16.10.214/16,gw=172.16.0.1"
        }
        "215" = {
            name        = "k8s-worker-6"
            target_node = "theodore"
            clone       = "ubuntu-24.04-template"
            tags        = "k8s;worker;ubuntu-24.04"
            memory      = 8192
            cores       = 4
            ipconfig0   = "ip=172.16.10.215/16,gw=172.16.0.1"
        }
        "1000" ={
            name        = "HAProxy01"
            target_node = "alvin"
            clone       = "ubuntu-24.04-template"
            tags        = "haproxy;primary;ubuntu-24.04"
            memory      = 2048
            cores       = 1
            disk_size   = "20G"
            ipconfig0   = "ip=172.16.255.0/16,gw=172.16.0.1"
        }
        "1001" ={
            name        = "HAProxy02"
            target_node = "simon"
            clone       = "ubuntu-24.04-template"
            tags        = "haproxy;backup;ubuntu-24.04"
            memory      = 2048
            cores       = 1
            disk_size   = "20G"
            ipconfig0   = "ip=172.16.255.1/16,gw=172.16.0.1"
        }
        #"8010" = {
        #    name        = "Ubuntu-24-10"
        #    target_node = "nas"
        #    clone       = "ubuntu-24.10-template"
        #    tags        = "Ubuntu,Oracular"
        #    ipconfig0   = "ip=172.16.10.110/16,gw=172.16.0.1"
        #}
        #"8011" = {
        #    name        = "Ubuntu-24.04"
        #    target_node = "nas"
        #    clone       = "ubuntu-24.04-template"
        #    tags        = "Ubuntu,Noble"
        #    ipconfig0   = "ip=172.16.10.111/16,gw=172.16.0.1"
        #}
        #"8012" = {
        #    name        = "Ubuntu-22.04"
        #    target_node = "nas"
        #    clone       = "ubuntu-22.04-template"
        #    tags        = "Ubuntu,Jammy"
        #    ipconfig0   = "ip=172.16.10.112/16,gw=172.16.0.1"
        #}
        #"8003" = {
        #    name        = "Debian-12"
        #    target_node = "nas"
        #    clone       = "debian-12-template"
        #    tags        = "Debian,Bookworm"
        #    ipconfig0   = "ip=172.16.10.103/16,gw=172.16.0.1"
        #}
        #"8004" = {
        #    name        = "Debian-11"
        #    target_node = "nas"
        #    clone       = "debian-11-template"
        #    tags        = "Debian,Bullseye"
        #    ipconfig0   = "ip=172.16.10.104/16,gw=172.16.0.1"
        #}
    }
}