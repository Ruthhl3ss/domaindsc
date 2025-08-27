
<#PSScriptInfo
.Version 0.1
Score Utica Domain Controller Deployment
#>

#Requires -Module ActiveDirectoryDsc
#Requires -Module ComputerManagementDsc
#Requires -Module DnsServerDsc

<#
    .DESCRIPTION
        This configuration will create a new domain with a new forest and a forest
        functional level of Server 2016.
#>
Configuration domainconfig {
  param
  (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $IPRange,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DomainName
  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DscResource -ModuleName ActiveDirectoryDsc
  Import-DscResource -ModuleName ComputerManagementDsc
  Import-DscResource -ModuleName DnsServerDsc

  node 'localhost'
  {
    Script GPOCentralStore
    {
      SetScript  = {
        $PolicyDefinitions = "\\\\$DomainName\\SYSVOL\\$DomainName\\Policies"
        Copy-Item C:\Windows\PolicyDefinitions $PolicyDefinitions -Recurse -Force
      }
      GetScript  = { @{} }
      TestScript = { $false }
    }

    Script EditPreWindows2000CompatibleAccess
    {
      SetScript  = {
        Net localgroup 'Pre-Windows 2000 Compatible Access' 'nt authority\authenticated users' /delete
      }
      GetScript  = { @{} }
      TestScript = { $false }
    }

    Script PreventAccidentalDeletes
    {
      SetScript  = {
        Get-ADOrganizationalUnit -filter * | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $true
      }
      GetScript  = { @{} }
      TestScript = { $false }
    }

    Script SetLocalInternetOptions
    {
      SetScript  = {
        $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
      }
      GetScript  = { @{} }
      TestScript = { $false }
    }

    ADOptionalFeature RecycleBin
    {
      FeatureName                       = "Recycle Bin Feature"
      EnterpriseAdministratorCredential = $Credential
      ForestFQDN                        = $DomainName
    }

    DnsServerPrimaryZone 'AddPrimaryZone'
    {
      Name = "$IPRange.in-addr.arpa"
    }
  }
}
