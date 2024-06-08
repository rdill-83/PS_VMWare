# ESXI Process - VMHost IP Address Update / Change 

# This Live Example walkthrough specifically addresses assignment via DHCP Reservation 
# Static Method Also Available but not covered in this document

# ReAssign DHCP Reservation:
# Assumes in PSSession / Remoted into DHCP Server:
Remove-DHCPServerV4Reservation -IPAddress 192.168.0.100 -Verbose
Add-DHCPServerV4Reservation -ScopeID 192.168.0.0 -IPAddress 192.168.0.200 -ClientID 5cba2c450768 -Description "VM-Host.DOMAIN.com" -Name "VM-Host.DOMAIN.com"

# Below 2 Assumes Connected vCenter Server w/ PowerCLI:
# Enable SSH on VMHost:
Get-VMHost VM-Host.DOMAIN.com | Get-VMHostService | Where {$_.key -like '*TSM*'} | Start-VMHostService -Verbose
# Remove VMHost from vSphere:
Remove-VMHost -VMHost VM-Host.DOMAIN.com

# Restart MGMT Network via ESXCLI:
# Assumes SSH Session w/ Target Host:
esxcli network ip interface set -e false -i vmk0; esxcli network ip interface set -e true -i vmk0

# Delete & Recreate Host DNS Record:
Remove-dnsServerResourceRecord -ZoneName DOMAIN.com -name VMHost -rrType A
Add-DNSServerResourceRecordA -AllowUpdateAny -CreatePTR -ZoneName DOMAIN.com -Name VM-Host -IPV4Address 192.168.0.200 -Verbose

# Clear VCSA (vCenter Server Appliance) DNS Cache
# Assumes SSH"d into VCSA
# Source: https://brisk-it.net/clear-dns-cache-vcsa-photonos/
# Restart VCSA DNS Service:
systemctl restart dnsmasq.service
# View VCSA DNS Service State:
systemctl status dnsmasq.service



# Add VMHost to vSphere:
$esxUser = "<insert-actual>"
$esxPW = "<insert-actual>"
$Location = (Get-DataCenter DATACENTER).Name
# $Location = (Get-DataCenter <DataCenter>).Name

Add-VMHost -Name $newName -Location $Location  -User $esxUser -Password $esxPW -Force -Confirm:$false 

# Move VMHost to Appropriate Folder:
$VMHost = Get-VMHost VM-Host.DOMAIN.com
$Folder = Get-Folder VMHost-Racks
Move-VMHost -VMHost $VMHost -Destination $Folder -Verbose

# Alternate VMHost Move Method:
Get-VMHost -VMHost VM-Host.DOMAIN.com  -Destination (Get-Folder VMHost-Racks).Name

# Disable SSH on VMHost:
Get-VMHost VM-Host.DOMAIN.com | Get-VMHostService | Where {$_.key -like '*TSM*'} | Stop-VMHostService -Verbose 
