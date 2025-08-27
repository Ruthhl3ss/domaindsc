<#PSScriptInfo
.Version 0.1
Score Utica Domain Controller Deployment
#>

#Requires -Module ActiveDirectoryDsc
#Requires -Module ComputerManagementDsc

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
  Import-DscResource -ModuleName ComputerManagementDsc

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

    TimeZone SetTimeZone
    {
      IsSingleInstance = 'Yes'
      TimeZone         = 'W. Europe Standard Time'
    }

    ADDomain CreateADForest
    {
      DomainName                    = $DomainName
      Credential                    = $Credential
      SafemodeAdministratorPassword = $Credential
      ForestMode                    = 'WinThreshold'
      DependsOn = '[WindowsFeature]InstallDNS', '[WindowsFeature]InstallADDS', '[WindowsFeature]InstallADDSTools', '[WindowsFeature]InstallDNSTools', '[WindowsFeature]InstallRSAT'

    }
    PendingReboot RebootAfterDomainJoin
    {
      Name = 'DomainJoin'
      DependsOn = '[ADDomain]CreateADForest'
    }
  }
}