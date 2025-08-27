Configuration Deploy-DomainServices {
    Param
    (
        [Parameter(Mandatory)]
        [String] $domainFQDN,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential] $adminCredential
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ActiveDirectoryDsc'
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'NetworkingDsc'
    Import-DscResource -ModuleName 'DSCResource.Common'

    node 'localhost'
    {
        WindowsFeature 'ADDS'
        {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature 'RSAT'
        {
            Name   = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }

        WindowsFeature 'ADDSTools'
        {
            Ensure = 'Present'
            Name = 'RSAT-ADDS-Tools'
            DependsOn = '[WindowsFeature]ADDS'
        }


        ADDomain 'createforest'
        {
            DomainName                    = $domainFQDN
            Credential                    = $adminCredential
            SafemodeAdministratorPassword = $adminCredential
            ForestMode                    = 'WinThreshold'
        }
    }
}