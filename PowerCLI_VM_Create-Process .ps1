# Create VM w/ ISO Download & ISO Mounting via Variable
# Author: rdill-83

# Download ISO on LocalMachine:
$ISOURL = "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
$lclPath = "C:\_IT-Temp\Ubuntu_22-04_Live-Svr_AMD64.iso"
invoke-WebRequest -uri $ISOURL -OutFIle $lclPath

# VMWare Host to Variable:
$VMHost = (Get-VMHost).Name

# PortGroup ( VLAN ) to Variable:
$portGrp = (Get-VirtualPortGroup -Name "VM Network").Name

# List VMWare Host DataStores:
Get-VMHost -Name $VMHost | Get-DataStore

# VMWare Host Datastores to Variable:
$DS = (Get-VMHost -Name $VMHost | Get-DataStore).Name

# Create PSDrive:
$Store = Get-VMHost $VMHost | Get-DataStore $DS
New-PSDrive -Name DS -Location $Store -PSProvider VIMDataStore -Root '\' | Out-Null

# Upload ISO to Datastore:
$DSPath = "DS:\_ISO\Ubuntu_22-04_Live-Svr_AMD64.iso"
Copy-DataStoreItem -Item $lclPath -Destination $DSPath

# ISO to Variable:
$DSFullPath = (GCI DS:\_ISO | Where {$_.DataStoreFullPath -like "*ubuntu-22.04.2-live-server-amd64*"}).DataStoreFullPath

# Create VM:
New-VM -VMHost $VMHost -Name Ubuntu4 -DataStore $DS -StorageFormat Thin -DiskGB 60 -MemoryGB 8 -NumCPU 2 -NetworkName $portGrp -GuestID ubuntu64Guest

# VM to Variable:
$VM = (Get-VM Ubuntu4).Name 

# Add Media Drive:
Get-VM $VM | New-CDDrive

# Start VM:
Start-VM $VM -Verbose

# Mount Selected ISO:
Get-VM $VM | Get-CDDrive | Set-CDDrive -isoPath $DSFullPath -StartConnected $True -Connected $True -Confirm:$False 

# Restart VM:
Get-VM $VM | Restart-VM -Confirm:$False
