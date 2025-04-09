# List of Proxmox nodes (IP addresses or hostnames)
$ProxmoxNodes = @("192.168.103.2", "192.168.103.28", "192.168.103.29","192.168.103.30")

# Path to your custom SSH key folder
$CustomSSHKeyFolder = ".\.ssh"  # Change this to your custom folder

# Path to your private SSH key
$SSHKeyPath = "$CustomSSHKeyFolder\id_rsa"

# Check if SSH key exists, if not, generate one (optional)
if (-Not (Test-Path $SSHKeyPath)) {
    Write-Host "Private key not found at $SSHKeyPath"
    Write-Host "Please ensure that your key is placed at the specified path."
    exit
}

# Public key path (assuming the key follows the standard naming convention)
$SSHPublicKeyPath = "$SSHKeyPath.pub"

# Function to transfer SSH public key to a Proxmox node
function Transfer-SSHKey {
    param (
        [string]$Node
    )
    
    Write-Host "Transferring SSH key to $Node..."

    # Path to the authorized_keys file on the remote Proxmox node
    $remoteAuthorizedKeysPath = "/root/.ssh/authorized_keys"
    
    # Check if the SSH directory exists on the remote server
    $sshDirectoryExists = Test-Connection -ComputerName $Node -Count 1 -Quiet
    
    if ($sshDirectoryExists) {
        # Use SCP to copy the public key to the remote server
        scp -i $SSHKeyPath $SSHPublicKeyPath "root@${Node}:${remoteAuthorizedKeysPath}"
        
        if ($?) {
            Write-Host "Successfully copied the SSH key to $Node"
        } else {
            Write-Host "Failed to copy SSH key to $Node"
        }
    } else {
        Write-Host "Unable to connect to $Node via SSH."
    }
}

# Function to run pvecm updatecerts on a Proxmox node
function Run-UpdateCerts {
    param (
        [string]$Node
    )
    
    Write-Host "Running 'pvecm updatecerts' on $Node..."

    # Run pvecm updatecerts on the remote Proxmox node
    ssh -i $SSHKeyPath "root@${Node}" "pvecm updatecerts"
    
    if ($?) {
        Write-Host "'pvecm updatecerts' successfully run on $Node"
    } else {
        Write-Host "Failed to run 'pvecm updatecerts' on $Node"
    }
}

# Loop over all nodes and transfer the public key
foreach ($Node in $ProxmoxNodes) {
    Transfer-SSHKey -Node $Node
}

# Loop over all nodes and run pvecm updatecerts
foreach ($Node in $ProxmoxNodes) {
    Run-UpdateCerts -Node $Node
}

Write-Host "SSH keys have been transferred and pvecm updatecerts has been executed on all nodes."