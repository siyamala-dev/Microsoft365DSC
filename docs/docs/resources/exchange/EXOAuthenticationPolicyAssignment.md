﻿# EXOAuthenticationPolicyAssignment

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **UserName** | Key | String | Name of the user assigned to the authentication policy. | |
| **AuthenticationPolicyName** | Write | String | Name of the authentication policy. | |
| **Ensure** | Write | String | Specify if the authentication Policy should exist or not. | `Present`, `Absent` |
| **Credential** | Write | PSCredential | Credentials of the Exchange Global Admin | |
| **ApplicationId** | Write | String | Id of the Azure Active Directory application to authenticate with. | |
| **TenantId** | Write | String | Id of the Azure Active Directory tenant used for authentication. | |
| **CertificateThumbprint** | Write | String | Thumbprint of the Azure Active Directory application's authentication certificate to use for authentication. | |
| **CertificatePassword** | Write | PSCredential | Username can be made up to anything but password will be used for CertificatePassword | |
| **CertificatePath** | Write | String | Path to certificate used in service principal usually a PFX file. | |
| **ManagedIdentity** | Write | Boolean | Managed ID being used for authentication. | |
| **AccessTokens** | Write | StringArray[] | Access token used for authentication. | |

## Description

This resource assigns Exchange Online Authentication Policies to users.

## Permissions

### Exchange

To authenticate with Microsoft Exchange, this resource required the following permissions:

#### Roles

- View-Only Configuration, Organization Configuration, Recipient Policies

#### Role Groups

- Organization Management

## Examples

### Example 1


```powershell
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
        EXOAuthenticationPolicyAssignment 'ConfigureAuthenticationPolicyAssignment'
        {
            UserName                 = "AdeleV@$TenantId"
            AuthenticationPolicyName = "Block Basic Auth"
            Ensure                   = "Present"
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            CertificateThumbprint = $CertificateThumbprint
        }
    }
}
```

### Example 2


```powershell
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
        EXOAuthenticationPolicy 'ConfigureAuthenticationPolicy'
        {
            Identity                            = "My Assigned Policy"
            AllowBasicAuthActiveSync            = $False
            AllowBasicAuthAutodiscover          = $False
            AllowBasicAuthImap                  = $False
            AllowBasicAuthMapi                  = $False
            AllowBasicAuthOfflineAddressBook    = $False
            AllowBasicAuthOutlookService        = $False
            AllowBasicAuthPop                   = $False
            AllowBasicAuthPowerShell            = $False
            AllowBasicAuthReportingWebServices  = $False
            AllowBasicAuthRpc                   = $False
            AllowBasicAuthSmtp                  = $False
            AllowBasicAuthWebServices           = $False
            Ensure                              = "Present"
            ApplicationId                       = $ApplicationId
            TenantId                            = $TenantId
            CertificateThumbprint               = $CertificateThumbprint
        }
        EXOAuthenticationPolicyAssignment 'ConfigureAuthenticationPolicyAssignment'
        {
            UserName                 = "AdeleV@$TenantId"
            AuthenticationPolicyName = "My Assigned Policy"
            Ensure                   = "Present"
            ApplicationId            = $ApplicationId
            TenantId                 = $TenantId
            CertificateThumbprint    = $CertificateThumbprint
        }
    }
}
```

### Example 3


```powershell
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
        EXOAuthenticationPolicyAssignment 'ConfigureAuthenticationPolicyAssignment'
        {
            UserName                 = "AdeleV@$TenantId"
            AuthenticationPolicyName = "Test Policy"
            Ensure                   = "Absent"
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            CertificateThumbprint = $CertificateThumbprint
        }
    }
}
```

