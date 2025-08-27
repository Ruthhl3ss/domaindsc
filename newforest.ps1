<#PSScriptInfo
.VERSION 1.0.1
.GUID 86c0280c-6b48-4689-815d-5bc0692845a4
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ActiveDirectoryDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/ActiveDirectoryDsc
.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png
.RELEASENOTES
Updated author, copyright notice, and URLs.
#>

#Requires -Module ActiveDirectoryDsc

<#
    .DESCRIPTION
        This configuration will create a new domain with a new forest and a forest
        functional level of Server 2016.
#>
Configuration NewForest {
  param
  (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DomainName
  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DscResource -ModuleName ActiveDirectoryDsc

  node 'localhost'
  {
    WindowsFeature InstallADDS
    {
      Name   = 'AD-Domain-Services'
      Ensure = 'Present'
    }

    WindowsFeature InstallDNS
    {
      Ensure = 'Present'
      Name = 'DNS'
    }

    WindowsFeature InstallRSAT
    {
      Name   = 'RSAT-AD-PowerShell'
      Ensure = 'Present'
    }

    WindowsFeature InstallDNSTools
    {
      Ensure = 'Present'
      Name = 'RSAT-DNS-Server'
      DependsOn = '[WindowsFeature]InstallDNS'
    }

    WindowsFeature InstallADDSTools
    {
      Ensure = 'Present'
      Name = 'RSAT-ADDS-Tools'
      DependsOn = '[WindowsFeature]InstallADDS'
    }

    ADDomain CreateADForest
    {
      DomainName                    = $DomainName
      Credential                    = $Credential
      SafemodeAdministratorPassword = $Credential
      ForestMode                    = 'WinThreshold'
      DependsOn = '[WindowsFeature]InstallDNS', '[WindowsFeature]InstallADDS', '[WindowsFeature]InstallADDSTools', '[WindowsFeature]InstallDNSTools', '[WindowsFeature]InstallRSAT'
    }

    PendingReboot RebootAfterCreatingADForest
    {
      Name = 'RebootAfterCreatingADForest'
      DependsOn = "[ADDomain]CreateADForest"
    }
  }
}