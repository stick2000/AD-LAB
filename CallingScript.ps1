﻿break

# Shout out to @brwilkinson for assistance with some of this.


# Install the Azure Resource Manager modules from PowerShell Gallery
# Takes a while to install 28 modules
Install-Module AzureRM -Force -Verbose
Install-AzureRM

# Install the Azure Service Management module from PowerShell Gallery
Install-Module Azure -Force -Verbose

# Import AzureRM modules for the given version manifest in the AzureRM module
Import-AzureRM -Verbose

# Import Azure Service Management module
Import-Module Azure -Verbose

# Authenticate to your Azure account
Login-AzureRmAccount

# Adjust the 'yournamehere' part of these three strings to
# something unique for you. Leave the last two characters in each.
# $URI       = 'https://raw.githubusercontent.com/GoateePFE/AzureRM/master/active-directory-new-domain-with-data/azuredeploy.json'
$URI       = 'https://raw.githubusercontent.com/stick2000/ad-lab/master/azuredeploy.json'
$Location  = 'West Europe'
$rgname    = 'stick2000rg'
$saname    = 'stick2000sa'     # Lowercase required
$addnsName = 'stick2000ad'     # Lowercase required

# Check that the public dns $addnsName is available
if (Test-AzureRmDnsAvailability -DomainNameLabel $addnsName -Location $Location)
{ 'Available' } else { 'Taken. addnsName must be globally unique.' }

# Create the new resource group. Runs quickly.
New-AzureRmResourceGroup -Name $rgname -Location $Location

# Parameters for the template and configuration
$MyParams = @{
    newStorageAccountName = $saname
    location              = 'West Europe'
    domainName            = 'stick.com'
    addnsName             = $addnsName
   }

# Splat the parameters on New-AzureRmResourceGroupDeployment  
$SplatParams = @{
    TemplateUri             = $URI
    ResourceGroupName       = $rgname 
    TemplateParameterObject = $MyParams
    Name                    = 'Stick'
   }

# Create Azure Keyvault and enable for template deployment

New-AzureRmKeyVault -VaultName 'Stick2000rgVault' -ResourceGroupName $rgname -Location $Location -EnabledForDeployment

#Add Secret
$secretvalue = ConvertTo-SecureString '' -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName 'Stick2000rgVault' -Name 'adminPassword' -SecretValue $secretvalue


# This takes ~30 minutes
# One prompt for the domain admin password
New-AzureRmResourceGroupDeployment -ResourceGroupName 'Stick2000rg' -templateuri 'https://raw.githubusercontent.com/stick2000/ad-lab/master/azuredeploy.json' -TemplateParameterUri 'https://raw.githubusercontent.com/stick2000/ad-lab/master/azuredeploy.parameters.json'

# Find the VM IP and FQDN
$PublicAddress = (Get-AzureRmPublicIpAddress -ResourceGroupName $rgname)[0]
$IP   = $PublicAddress.IpAddress
$FQDN = $PublicAddress.DnsSettings.Fqdn

# RDP either way
Start-Process -FilePath mstsc.exe -ArgumentList "/v:$FQDN"
Start-Process -FilePath mstsc.exe -ArgumentList "/v:$IP"

# Login as:  alpineskihouse\adadministrator
# Use the password you supplied at the beginning of the build.

# Explore the Active Directory domain:
#  Recycle bin enabled
#  Admin tools installed
#  Five new OU structures
#  Users and populated groups within the OU structures
#  Users root container has test users and populated test groups

# Delete the entire resource group when finished
Remove-AzureRmResourceGroup -Name $rgname -Force -Verbose
