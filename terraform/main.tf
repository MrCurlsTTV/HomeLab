resource "proxmox_vm_qemu" "prod" {
    for_each    = local.proxmox_vm_qemu
    name        = each.value.name
    target_node = each.value.target_node
    clone       = lookup(each.value, "clone", "ubuntu-24.10-template")
    os_type     = lookup(each.value, "os_type", "cloud-init")
    tags        = lookup(each.value, "tags", "Ubuntu,Oracular")
    vmid        = each.key
    boot        = lookup(each.value, "boot", "order=scsi0;ide2;net0")

    #Hardware
    cpu {
        cores   = lookup(each.value, "cores", 2)
        type    = lookup(each.value, "cpu_type", "host")
        numa    = each.value.target_node == "nas" ? false : lookup(each.value, "numa", true)
    }
    memory      = lookup(each.value, "memory", 2048)
    scsihw      = lookup(each.value, "scsihw", "virtio-scsi-pci")

    disks {
        ide{
            ide2{
                cloudinit {
                    storage = lookup(each.value, "cloudinit_storage", "disconfig")
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size            = lookup(each.value, "disk_size", "200G")
                    cache           = lookup(each.value, "disk_cache", "writeback")
                    storage         = lookup(each.value, "disk_storage", "vm-storage")
                    discard         = lookup(each.value, "disk_discard", true)
                    emulatessd      = lookup(each.value, "disk_emulatessd", true)
                    iothread        = lookup(each.value, "disk_iothread", false)
                    readonly        = lookup(each.value, "disk_readonly", false)
                    replicate       = lookup(each.value, "disk_replicate", false)
                }
            }
        }
    }

    network {
        id      = lookup(each.value, "network_id", 0)
        model   = lookup(each.value, "network_model", "virtio")
        bridge  = lookup(each.value, "network_bridge", "vmbr0")
    }

    serial {
        id      = lookup(each.value, "serial_id", 0)
        type    = lookup(each.value, "serial_type", "socket")
    }
    
    vga {
        type   = lookup(each.value, "vga_type", "virtio")
        memory = lookup(each.value, "vga_memory", 128)
    }

    #Cloud-Init
    ciuser          = lookup(each.value, "ciuser", "ansible")
    ciupgrade       = lookup(each.value, "ciupgrade", true)
    ipconfig0       = lookup(each.value, "ipconfig0", "")
    nameserver      = lookup(each.value, "nameserver", "192.168.103.1")
    searchdomain    = lookup(each.value, "searchdomain", "mrcurls.org")
    sshkeys         = lookup(each.value, "sshkeys", file("./sshkeys.txt"))

    # Options
    agent           = lookup(each.value, "agent", 1)
    onboot          = lookup(each.value, "onboot", true)
}