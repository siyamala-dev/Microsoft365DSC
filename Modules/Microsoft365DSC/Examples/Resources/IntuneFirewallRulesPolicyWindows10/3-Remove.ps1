<#
This example removes a Device Control Policy.
#>

Configuration Example
{
    param(
        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )
    Import-DscResource -ModuleName Microsoft365DSC

    node localhost
    {
        IntuneFirewallRulesPolicyWindows10 'myIntuneFirewallRulesPolicyWindows10'
        {
            Id          = '00000000-0000-0000-0000-000000000000'
            DisplayName = 'Intune Firewall Rules Policy Windows10'
            Ensure      = 'Absent'
            ApplicationId         = $ApplicationId;
            TenantId              = $TenantId;
            CertificateThumbprint = $CertificateThumbprint;
        }
    }
}