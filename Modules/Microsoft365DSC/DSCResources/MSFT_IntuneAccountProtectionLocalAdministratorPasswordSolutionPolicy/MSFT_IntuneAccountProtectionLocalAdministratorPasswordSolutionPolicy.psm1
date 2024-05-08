function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $Identity,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.Int32]
        [ValidateRange(0, 2)]
        $BackupDirectory,

        [Parameter()]
        [System.Int32]
        [ValidateRange(7, 365)]
        $PasswordAgeDays_AAD,

        [Parameter()]
        [System.Int32]
        [ValidateRange(1, 365)]
        $PasswordAgeDays,

        [Parameter()]
        [System.Boolean]
        $PasswordExpirationProtectionEnabled,

        [Parameter()]
        [System.Int32]
        [ValidateRange(0, 12)]
        $AdEncryptedPasswordHistorySize,

        [Parameter()]
        [System.Boolean]
        $AdPasswordEncryptionEnabled,

        [Parameter()]
        [System.String]
        $AdPasswordEncryptionPrincipal,

        [Parameter()]
        [System.String]
        $AdministratorAccountName,

        [Parameter()]
        [System.Int32]
        [ValidateRange(1, 4)]
        $PasswordComplexity,

        [Parameter()]
        [System.Int32]
        [ValidateRange(8, 64)]
        $PasswordLength,

        [Parameter()]
        [System.Int32]
        [ValidateSet(1, 3, 5)]
        $PostAuthenticationActions,

        [Parameter()]
        [System.Int32]
        [ValidateRange(0, 24)]
        $PostAuthenticationResetDelay,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

        [Parameter()]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    Write-Verbose -Message "Checking for the Intune Account Protection LAPS Policy {$DisplayName}"

    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters `
        -ErrorAction Stop

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $nullResult = $PSBoundParameters
    $nullResult.Ensure = 'Absent'

    try
    {
        #Retrieve policy general settings
        $policy = Get-MgBetaDeviceManagementConfigurationPolicy -DeviceManagementConfigurationPolicyId $Identity -ExpandProperty settings -ErrorAction SilentlyContinue

        if ($null -eq $policy)
        {
            Write-Verbose -Message "No Account Protection LAPS Policy {id: '$Identity'} was found"
            $policyTemplateID = 'adc46e5a-f4aa-4ff6-aeff-4f27bc525796_1'
            $filter = "name eq '$DisplayName' and templateReference/TemplateId eq '$policyTemplateID'"
            $policy = Get-MgBetaDeviceManagementConfigurationPolicy -Filter $filter -ErrorAction SilentlyContinue

            if(([array]$policy).count -gt 1)
            {
                throw "A policy with a duplicated displayName {'$DisplayName'} was found - Ensure displayName is unique"
            }

            if ($null -eq $policy)
            {
                Write-Verbose -Message "No Account Protection LAPS Policy {displayName: '$DisplayName'} was found"
                return $nullResult
            }

            $policy = Get-MgBetaDeviceManagementConfigurationPolicy -DeviceManagementConfigurationPolicyId $policy.Id -ExpandProperty settings -ErrorAction SilentlyContinue
        }

        $Identity = $policy.Id

        Write-Verbose -Message "Found Account Protection LAPS Policy {$($policy.id):$($policy.Name)}"
        [array]$settings = $policy.settings

        $returnHashtable = @{}
        $returnHashtable.Add('Identity', $Identity)
        $returnHashtable.Add('DisplayName', $policy.name)
        $returnHashtable.Add('Description', $policy.description)

        foreach ($setting in $settings.SettingInstance)
        {
            $addToParameters = $true
            $settingName = $setting.settingDefinitionId.Split('_') | Select-Object -Last 1
            $replaceUri = $setting.settingDefinitionId.Replace($settingName, '')

            $settingType = $setting.AdditionalProperties.'@odata.type'
            $settingValueName = $settingType.replace('#microsoft.graph.deviceManagementConfiguration', '').replace('Instance', 'Value')
            $settingValueName = $settingValueName.Substring(0, 1).ToLower() + $settingValueName.Substring(1, $settingValueName.length - 1 )

            switch ($settingType)
            {
                '#microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'
                {
                    $settingValue = $setting.AdditionalProperties.simpleSettingValue.value
                }
                '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
                {
                    $settingValue = $setting.AdditionalProperties.choiceSettingValue.value.split('_') | Select-Object -Last 1
                }
                '#microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance'
                {
                    $values = @()
                    foreach ($value in $setting.AdditionalProperties.groupSettingCollectionValue.children)
                    {
                        $settingName = $value.settingDefinitionId.split('_') | Select-Object -Last 1
                        $settingValue = $value.choiceSettingValue.value.split('_') | Select-Object -Last 1
                        $returnHashtable.Add($settingName, $settingValue)
                        $addToParameters = $false
                    }
                }
                '#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance'
                {
                    $values = @()
                    foreach ($value in $setting.AdditionalProperties.simpleSettingCollectionValue.value)
                    {
                        $values += $value
                    }
                    $settingValue = $values
                }
                Default
                {
                    $settingValue = $setting.value
                }
            }

            foreach ($childSetting in $setting.AdditionalProperties.$settingValueName.children)
            {
                $childSettingName = $childSetting.settingDefinitionId.Replace($replaceUri, '')
                $childSettingType = $childSetting.'@odata.type'.Replace('#microsoft.graph.deviceManagementConfiguration', '').Replace('Instance', 'Value')
                $childSettingType = $childSettingType.Substring(0, 1).ToLower() + $childSettingType.Substring(1, $childSettingType.length - 1 )
                $childSettingValue = $childSetting.$childSettingType.value

                if ($childSettingType -eq 'choiceSettingValue')
                {
                    $childSettingValue = $childSettingValue.split('_') | Select-Object -Last 1
                }
                $returnHashtable.Add($childSettingName, $childSettingValue)
            }

            if ($addToParameters)
            {
                $returnHashtable.Add($settingName, $settingValue)
            }

        }
        $returnAssignments = @()
        $graphAssignments = Get-MgBetaDeviceManagementConfigurationPolicyAssignment -DeviceManagementConfigurationPolicyId $policy.Id
        if ($graphAssignments.count -gt 0)
        {
            $returnAssignments += ConvertFrom-IntunePolicyAssignment `
                                -IncludeDeviceFilter:$true `
                                -Assignments ($graphAssignments)
        }
        $returnHashtable.Add('Assignments', $returnAssignments)


        Write-Verbose -Message "Found Account Protection LAPS Policy {$($policy.name)}"

        $returnHashtable.Add('Ensure', 'Present')
        $returnHashtable.Add('Credential', $Credential)
        $returnHashtable.Add('ApplicationId', $ApplicationId)
        $returnHashtable.Add('TenantId', $TenantId)
        $returnHashtable.Add('ApplicationSecret', $ApplicationSecret)
        $returnHashtable.Add('CertificateThumbprint', $CertificateThumbprint)
        $returnHashtable.Add('ManagedIdentity', $ManagedIdentity.IsPresent)
        $returnHashtable.Add('AccessTokens', $AccessTokens)

        return $returnHashtable
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error retrieving data:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        $nullResult = Clear-M365DSCAuthenticationParameter -BoundParameters $nullResult
        return $nullResult
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $Identity,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.Int32]
        [ValidateRange(0, 2)]
        $BackupDirectory,

        [Parameter()]
        [System.Int32]
        [ValidateRange(7, 365)]
        $PasswordAgeDays_AAD,

        [Parameter()]
        [System.Int32]
        [ValidateRange(1, 365)]
        $PasswordAgeDays,

        [Parameter()]
        [System.Boolean]
        $PasswordExpirationProtectionEnabled,

        [Parameter()]
        [System.Int32]
        [ValidateRange(0, 12)]
        $AdEncryptedPasswordHistorySize,

        [Parameter()]
        [System.Boolean]
        $AdPasswordEncryptionEnabled,

        [Parameter()]
        [System.String]
        $AdPasswordEncryptionPrincipal,

        [Parameter()]
        [System.String]
        $AdministratorAccountName,

        [Parameter()]
        [System.Int32]
        [ValidateRange(1, 4)]
        $PasswordComplexity,

        [Parameter()]
        [System.Int32]
        [ValidateRange(8, 64)]
        $PasswordLength,

        [Parameter()]
        [System.Int32]
        [ValidateSet(1, 3, 5)]
        $PostAuthenticationActions,

        [Parameter()]
        [System.Int32]
        [ValidateRange(0, 24)]
        $PostAuthenticationResetDelay,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

        [Parameter()]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $currentPolicy = Get-TargetResource @PSBoundParameters
    $PSBoundParameters.Remove('Ensure') | Out-Null
    $PSBoundParameters.Remove('Credential') | Out-Null
    $PSBoundParameters.Remove('ApplicationId') | Out-Null
    $PSBoundParameters.Remove('TenantId') | Out-Null
    $PSBoundParameters.Remove('ApplicationSecret') | Out-Null
    $PSBoundParameters.Remove('CertificateThumbprint') | Out-Null
    $PSBoundParameters.Remove('ManagedIdentity') | Out-Null
    $PSBoundParameters.Remove('AccessTokens') | Out-Null

    $templateReferenceId = 'adc46e5a-f4aa-4ff6-aeff-4f27bc525796_1'
    $platforms = 'windows10'
    $technologies = 'mdm'

    if ($Ensure -eq 'Present' -and $currentPolicy.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Creating new Account Protection LAPS Policy {$DisplayName}"

        $settings = Get-IntuneSettingCatalogPolicySetting `
            -DSCParams ([System.Collections.Hashtable]$PSBoundParameters) `
            -TemplateId $templateReferenceId

        $createParameters = @{
            Name              = $DisplayName
            Description       = $Description
            TemplateReference = @{templateId = $templateReferenceId }
            Platforms         = $platforms
            Technologies      = $technologies
            Settings          = $settings
        }
        $newPolicy = New-MgBetaDeviceManagementConfigurationPolicy -bodyParameter $createParameters

        $assignmentsHash = Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $Assignments
        Update-DeviceConfigurationPolicyAssignment `
            -DeviceConfigurationPolicyId $newPolicy.Id `
            -Targets $assignmentsHash
    }
    elseif ($Ensure -eq 'Present' -and $currentPolicy.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Updating existing Account Protection LAPS Policy {$($currentPolicy.DisplayName)}"

        #format settings from PSBoundParameters for update
        $settings = Get-IntuneSettingCatalogPolicySetting `
            -DSCParams ([System.Collections.Hashtable]$PSBoundParameters) `
            -TemplateId $templateReferenceId

        Update-DeviceManagementConfigurationPolicy `
            -DeviceManagementConfigurationPolicyId $currentPolicy.Identity `
            -DisplayName $DisplayName `
            -Description $Description `
            -TemplateReference $templateReferenceId `
            -Platforms $platforms `
            -Technologies $technologies `
            -Settings $settings

        #region update policy assignments
        $assignmentsHash = Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $Assignments
        Update-DeviceConfigurationPolicyAssignment `
            -DeviceConfigurationPolicyId $currentPolicy.Identity `
            -Targets $assignmentsHash
        #endregion
    }
    elseif ($Ensure -eq 'Absent' -and $currentPolicy.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Removing Account Protection LAPS Policy {$($currentPolicy.DisplayName)}"
        Remove-MgBetaDeviceManagementConfigurationPolicy -DeviceManagementConfigurationPolicyId $currentPolicy.Identity
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String]
        $Identity,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.Int32]
        [ValidateRange(0, 2)]
        $BackupDirectory,

        [Parameter()]
        [System.Int32]
        [ValidateRange(7, 365)]
        $PasswordAgeDays_AAD,

        [Parameter()]
        [System.Int32]
        [ValidateRange(1, 365)]
        $PasswordAgeDays,

        [Parameter()]
        [System.Boolean]
        $PasswordExpirationProtectionEnabled,

        [Parameter()]
        [System.Int32]
        [ValidateRange(0, 12)]
        $AdEncryptedPasswordHistorySize,

        [Parameter()]
        [System.Boolean]
        $AdPasswordEncryptionEnabled,

        [Parameter()]
        [System.String]
        $AdPasswordEncryptionPrincipal,

        [Parameter()]
        [System.String]
        $AdministratorAccountName,

        [Parameter()]
        [System.Int32]
        [ValidateRange(1, 4)]
        $PasswordComplexity,

        [Parameter()]
        [System.Int32]
        [ValidateRange(8, 64)]
        $PasswordLength,

        [Parameter()]
        [System.Int32]
        [ValidateSet(1, 3, 5)]
        $PostAuthenticationActions,

        [Parameter()]
        [System.Int32]
        [ValidateRange(0, 24)]
        $PostAuthenticationResetDelay,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

        [Parameter()]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion
    Write-Verbose -Message "Testing configuration of Account Protection LAPS Policy {$DisplayName}"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if (-not (Test-M365DSCAuthenticationParameter -BoundParameters $CurrentValues))
    {
        Write-Verbose "An error occured in Get-TargetResource, the policy {$displayName} will not be processed"
        throw "An error occured in Get-TargetResource, the policy {$displayName} will not be processed. Refer to the event viewer logs for more information."
    }
    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    $ValuesToCheck = ([hashtable]$PSBoundParameters).clone()
    $ValuesToCheck.Remove('Identity') | Out-Null

    $testResult = $true
    if ($CurrentValues.Ensure -ne $Ensure)
    {
        Write-Verbose -Message "Test-TargetResource returned $false"
        return $false
    }

    #Compare Cim instances
    $source = Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $PSBoundParameters.Assignments
    $target = $CurrentValues.Assignments
    $testResult = Compare-M365DSCIntunePolicyAssignment -Source $source -Target $target
    $ValuesToCheck.Remove('Assignments') | Out-Null

    if ($testResult)
    {
        $TestResult = Test-M365DSCParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck $ValuesToCheck.Keys
    }

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $Filter,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $dscContent = ''
    $i = 1

    try
    {
        $policyTemplateID = 'adc46e5a-f4aa-4ff6-aeff-4f27bc525796_1'
        [array]$policies = Get-MgBetaDeviceManagementConfigurationPolicy `
            -All:$true `
            -Filter $Filter `
            -ErrorAction Stop | Where-Object -FilterScript { $_.TemplateReference.TemplateId -eq $policyTemplateID } `

        if ($policies.Length -eq 0)
        {
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }
        else
        {
            Write-Host "`r`n" -NoNewline
        }
        foreach ($policy in $policies)
        {
            Write-Host "    |---[$i/$($policies.Count)] $($policy.Name)" -NoNewline

            $params = @{
                Identity              = $policy.id
                DisplayName           = $policy.Name
                Ensure                = 'Present'
                Credential            = $Credential
                ApplicationId         = $ApplicationId
                TenantId              = $TenantId
                ApplicationSecret     = $ApplicationSecret
                CertificateThumbprint = $CertificateThumbprint
                Managedidentity       = $ManagedIdentity.IsPresent
                AccessTokens          = $AccessTokens
            }

            $Results = Get-TargetResource @params
            if (-not (Test-M365DSCAuthenticationParameter -BoundParameters $Results))
            {
                Write-Verbose "An error occured in Get-TargetResource, the policy {$($params.displayName)} will not be processed"
                throw "An error occured in Get-TargetResource, the policy {$($params.displayName)} will not be processed. Refer to the event viewer logs for more information."
            }
            if ($Results.Ensure -eq 'Present')
            {
                $Results = Update-M365DSCExportAuthenticationResults -ConnectionMode $ConnectionMode `
                    -Results $Results

                if ($Results.Assignments)
                {
                    $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString -ComplexObject ([Array]$Results.Assignments) `
                                                    -CIMInstanceName IntuneAccountProtectionLocalAdministratorPasswordSolutionPolicyAssignments
                    if ($complexTypeStringResult)
                    {
                        $Results.Assignments = $complexTypeStringResult
                    }
                    else
                    {
                        $Results.Remove('Assignments') | Out-Null
                    }
                }

                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $ResourceName `
                    -ConnectionMode $ConnectionMode `
                    -ModulePath $PSScriptRoot `
                    -Results $Results `
                    -Credential $Credential

                if ($Results.Assignments)
                {
                    $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName 'Assignments' -IsCIMArray:$true
                }

                $dscContent += $currentDSCBlock
                Save-M365DSCPartialExport -Content $currentDSCBlock `
                    -FileName $Global:PartialExportFileName

                Write-Host $Global:M365DSCEmojiGreenCheckMark
                $i++
            }
        }
        return $dscContent
    }
    catch
    {
        if ($_.Exception -like '*401*' -or $_.ErrorDetails.Message -like "*`"ErrorCode`":`"Forbidden`"*" -or `
            $_.Exception -like "*Unable to perform redirect as Location Header is not set in response*" -or `
            $_.Exception -like "*Request not applicable to target tenant*")
        {
            Write-Host "`r`n    $($Global:M365DSCEmojiYellowCircle) The current tenant is not registered for Intune."
        }
        else
        {
            Write-Host $Global:M365DSCEmojiRedX

            New-M365DSCLogEntry -Message 'Error during Export:' `
                -Exception $_ `
                -Source $($MyInvocation.MyCommand.Source) `
                -TenantId $TenantId `
                -Credential $Credential
        }

        return ''
    }
}

function Get-IntuneSettingCatalogPolicySetting
{
    [CmdletBinding()]
    [OutputType([System.Array])]
    param(
        [Parameter(Mandatory = 'true')]
        [System.Collections.Hashtable]
        $DSCParams,
        [Parameter(Mandatory = 'true')]
        [System.String]
        $TemplateId
    )

    $DSCParams.Remove('Identity') | Out-Null
    $DSCParams.Remove('DisplayName') | Out-Null
    $DSCParams.Remove('Description') | Out-Null

    #Prepare setting definitions mapping
    $settingDefinitions = Get-MgBetaDeviceManagementConfigurationPolicyTemplateSettingTemplate -DeviceManagementConfigurationPolicyTemplateId $TemplateId -ExpandProperty settingDefinitions
    $settingInstances = @()
    foreach ($settingDefinition in $settingDefinitions.SettingInstanceTemplate)
    {

        $settingInstance = @{}
        $settingName = $settingDefinition.SettingDefinitionId.split('_') | Select-Object -Last 1
        $settingType = $settingDefinition.AdditionalProperties.'@odata.type'.replace('InstanceTemplate', 'Instance')
        $settingInstance.Add('settingDefinitionId', $settingDefinition.settingDefinitionId)
        $settingInstance.Add('@odata.type', $settingType)
        if (-Not [string]::IsNullOrEmpty($settingDefinition.settingInstanceTemplateId))
        {
            $settingInstance.Add('settingInstanceTemplateReference', @{'settingInstanceTemplateId' = $settingDefinition.settingInstanceTemplateId })
        }
        $settingValueName = $settingType.replace('#microsoft.graph.deviceManagementConfiguration', '').replace('Instance', 'Value')
        $settingValueName = $settingValueName.Substring(0, 1).ToLower() + $settingValueName.Substring(1, $settingValueName.length - 1 )
        $settingValueType = $settingDefinition.AdditionalProperties."$($settingValueName)Template".'@odata.type'
        if ($null -ne $settingValueType)
        {
            $settingValueType = $settingValueType.replace('ValueTemplate', 'Value')
        }
        $settingValueTemplateId = $settingDefinition.AdditionalProperties."$($settingValueName)Template".settingValueTemplateId
        $settingValue = Get-IntuneSettingCatalogPolicySettingInstanceValue `
            -DSCParams $DSCParams `
            -SettingDefinition $settingDefinition `
            -SettingName $settingName `
            -SettingType $settingType `
            -SettingValueName $settingValueName `
            -SettingValueType $settingValueType `
            -SettingValueTemplateId $settingValueTemplateId

        if ($null -ne $settingValue) {

            if ($settingType -ne '#microsoft.graph.deviceManagementConfigurationSimpleSettingInstance')
            {
                $settingValue.$settingValueName.Add('children', @())

                foreach ($childSettingDefinition in ($settingDefinitions.SettingDefinitions | Where-Object { $_.RootDefinitionId -eq $settingInstance.settingDefinitionId }))
                {
                    if ($childSettingDefinition.Id -eq $settingDefinition.SettingDefinitionId)
                    {
                        # We have already covered that setting through the settingInstanceTemplate
                        Continue
                    }

                    $key = $DSCParams.Keys | Where-Object { $_.ToLower() -eq $settingName }
                    $dscValue = $DSCParams[$key]

                    if ($childSettingDefinition.AdditionalProperties.dependentOn.dependentOn -ne ($settingDefinition.SettingDefinitionId + '_' + $dscValue))
                    {
                        if ($childSettingDefinition.AdditionalProperties.options.dependentOn.dependentOn -notContains ($settingDefinition.SettingDefinitionId + '_' + $dscValue))
                        {
                            # This setting is not dependent on the current setting value
                            Continue
                        }
                    }
                    $childSettingUri = ($childSettingDefinition.BaseUri + $childSettingDefinition.OffsetUri).Replace('/', '_').Replace('._', '').ToLower()
                    $replaceUri = $childSettingUri.Replace($childSettingUri.Split('_')[-1], '')

                    $childSettingInstance = @{}
                    $childSettingName = $childSettingDefinition.Id.Replace($replaceUri, '')
                    $childSettingType = $childSettingDefinition.AdditionalProperties.'@odata.type'.replace('Definition', 'Instance')
                    $childSettingInstance.Add('settingDefinitionId', $childSettingDefinition.Id)
                    $childSettingInstance.Add('@odata.type', $childSettingType)
                    $childSettingValueName = $childSettingType.replace('#microsoft.graph.deviceManagementConfiguration', '').replace('Instance', 'Value')
                    $childSettingValueName = $childSettingValueName.Substring(0, 1).ToLower() + $childSettingValueName.Substring(1, $childSettingValueName.length - 1 )
                    if ($null -ne $childSettingDefinition.AdditionalProperties.valueDefinition)
                    {
                        $childSettingValueType = $childSettingDefinition.AdditionalProperties.valueDefinition.'@odata.type'.Replace('ValueDefinition', 'Value')
                    }
                    else
                    {
                        $childSettingValueType = $childSettingType.Replace('Instance', 'Value')
                    }
                    $childSettingValue = Get-IntuneSettingCatalogPolicySettingDefinitionValue `
                    -DSCParams $DSCParams `
                    -SettingDefinition $childSettingDefinition `
                    -SettingName $childSettingName `
                    -SettingValueName $childSettingValueName `
                    -SettingValueType $childSettingValueType `

                    if ($null -ne $childSettingValue)
                    {
                        $childSettingInstance += ($childSettingValue)
                        $settingValue.$settingValueName.children += $childSettingInstance
                    }
                }
            }

            $settingInstance += ($settingValue)
            $settingInstances += @{
                '@odata.type'     = '#microsoft.graph.deviceManagementConfigurationSetting'
                'settingInstance' = $settingInstance
            }
        } else {
            Continue
        }
    }

    return $settingInstances
}

function Get-IntuneSettingCatalogPolicySettingInstanceValue
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = 'true')]
        [System.Collections.Hashtable]
        $DSCParams,

        [Parameter()]
        $SettingDefinition,

        [Parameter()]
        [System.String]
        $SettingType,

        [Parameter()]
        [System.String]
        $SettingName,

        [Parameter()]
        [System.String]
        $SettingValueName,

        [Parameter()]
        [System.String]
        $SettingValueType,

        [Parameter()]
        [System.String]
        $SettingValueTemplateId
    )

    $settingValueReturn = @{}
    switch ($settingType)
    {
        '#microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance'
        {
            $groupSettingCollectionValue = @{}
            $groupSettingCollectionValueChildren = @()

            $groupSettingCollectionDefinitionChildren = $SettingDefinition.AdditionalProperties.groupSettingCollectionValueTemplate.children
            foreach ($childDefinition in $groupSettingCollectionDefinitionChildren)
            {
                $childSettingName = $childDefinition.settingDefinitionId.split('_') | Select-Object -Last 1
                $childSettingType = $childDefinition.'@odata.type'.replace('InstanceTemplate', 'Instance')
                $childSettingValueName = $childSettingType.replace('#microsoft.graph.deviceManagementConfiguration', '').replace('Instance', 'Value')
                $childSettingValueType = "#microsoft.graph.deviceManagementConfiguration$($childSettingValueName)"
                $childSettingValueName = $childSettingValueName.Substring(0, 1).ToLower() + $childSettingValueName.Substring(1, $childSettingValueName.length - 1 )
                $childSettingValueTemplateId = $childDefinition.$childSettingValueName.settingValueTemplateId
                $childSettingValue = Get-IntuneSettingCatalogPolicySettingInstanceValue `
                    -DSCParams $DSCParams `
                    -SettingDefinition $childDefinition `
                    -SettingName $childSettingName `
                    -SettingType $childDefinition.'@odata.type' `
                    -SettingValueName $childSettingValueName `
                    -SettingValueType $childSettingValueType `
                    -SettingValueTemplateId $childSettingValueTemplateId

                if ($null -ne $childSettingValue)
                {
                    $childSettingValue.add('settingDefinitionId', $childDefinition.settingDefinitionId)
                    $childSettingValue.add('@odata.type', $childSettingType )
                    $groupSettingCollectionValueChildren += $childSettingValue
                }
            }
            $groupSettingCollectionValue.add('children', $groupSettingCollectionValueChildren)
            $settingValueReturn.Add('groupSettingCollectionValue', @($groupSettingCollectionValue))
        }
        '#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance'
        {
            $values = @()
            foreach ( $key in $DSCParams.Keys)
            {
                if ($settingName -eq ($key.ToLower()))
                {
                    $values = $DSCParams[$key]
                    break
                }
            }
            $settingValueCollection = @()
            foreach ($v in $values)
            {
                $settingValueCollection += @{
                    value         = $v
                    '@odata.type' = $settingValueType
                }
            }
            $settingValueReturn.Add($settingValueName, $settingValueCollection)
        }
        Default
        {
            $value = $null
            foreach ( $key in $DSCParams.Keys)
            {
                if ($settingName -eq ($key.ToLower()))
                {
                    if ($settingValueType -eq '#microsoft.graph.deviceManagementConfigurationBooleanSettingValue')
                    {
                        $value = [bool]::Parse($DSCParams[$key])
                    }
                    elseif ($settingValueType -eq '#microsoft.graph.deviceManagementConfigurationIntegerSettingValue')
                    {
                        $value = [int]::Parse($DSCParams[$key])
                    }
                    elseif ($settingValueType -eq '#microsoft.graph.deviceManagementConfigurationStringSettingValue')
                    {
                        $value = $DSCParams[$key]
                    }
                    else {
                        $value = "$($SettingDefinition.settingDefinitionId)_$($DSCParams[$key])"
                    }
                    break
                }
            }
            $settingValue = @{}

            if (-not [string]::IsNullOrEmpty($settingValueType))
            {
                $settingValue.Add('@odata.type', $settingValueType)
            }
            if (-not [string]::IsNullOrEmpty($settingValueTemplateId))
            {
                $settingValue.Add('settingValueTemplateReference', @{'settingValueTemplateId' = $settingValueTemplateId })
            }

            if ($null -eq $value)
            {
                # Use the default value if exists
                $value = $SettingDefinition.$SettingValueName.defaultValue
                if ($null -eq $value)
                {
                    return $null
                }
            }
            $settingValue.Add('value', $value)
            $settingValueReturn.Add($settingValueName, $settingValue)
        }
    }
    return $settingValueReturn
}

function Get-IntuneSettingCatalogPolicySettingDefinitionValue
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = 'true')]
        [System.Collections.Hashtable]
        $DSCParams,

        [Parameter()]
        $SettingDefinition,

        [Parameter()]
        [System.String]
        $SettingName,

        [Parameter()]
        [System.String]
        $SettingValueName,

        [Parameter()]
        [System.String]
        $SettingValueType
    )

    $settingValueReturn = @{}
    $key = $DSCParams.Keys | Where-Object { $_.ToLower() -eq $SettingName }
    if ($null -ne $key)
    {
        $value = $DSCParams[$key]
    }
    else
    {
        # Use default value if exists
        if ($null -ne $SettingDefinition.AdditionalProperties.defaultValue)
        {
            $value = $SettingDefinition.AdditionalProperties.defaultValue.value
        }
        elseif ($null -ne $SettingDefinition.AdditionalProperties.defaultOptionId)
        {
            $value = $SettingDefinition.AdditionalProperties.defaultOptionId
        }
    }

    $settingValue = @{}
    if (-Not [string]::IsNullOrEmpty($settingValueType))
    {
        $settingValue.add('@odata.type', $settingValueType)
    }
    if ($null -eq $value)
    {
        return $null
    }
    $settingValue.add('value', $value)
    $settingValueReturn.Add($settingValueName, $settingValue)

    return $settingValueReturn
}

function Update-DeviceManagementConfigurationPolicy
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = 'true')]
        [System.String]
        $DeviceManagementConfigurationPolicyId,

        [Parameter(Mandatory = 'true')]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $TemplateReferenceId,

        [Parameter()]
        [System.String]
        $Platforms,

        [Parameter()]
        [System.String]
        $Technologies,

        [Parameter()]
        [System.Array]
        $Settings
    )

    $templateReference = @{
        'templateId' = $TemplateReferenceId
    }

    $Uri = "https://graph.microsoft.com/beta/deviceManagement/ConfigurationPolicies/$DeviceManagementConfigurationPolicyId"
    $policy = [ordered]@{
        'name'              = $DisplayName
        'description'       = $Description
        'platforms'         = $Platforms
        'technologies'      = $Technologies
        'templateReference' = $templateReference
        'settings'          = $Settings
    }
    Invoke-MgGraphRequest -Method PUT `
        -Uri $Uri `
        -ContentType 'application/json' `
        -Body ($policy | ConvertTo-Json -Depth 20) 4> out-null
}

function Get-DeviceManagementConfigurationPolicyAssignment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = 'true')]
        [System.String]
        $DeviceManagementConfigurationPolicyId
    )

    try
    {
        $configurationPolicyAssignments = @()

        $Uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$DeviceManagementConfigurationPolicyId/assignments"
        $results = Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop 4> out-null
        foreach ($result in $results.value.target)
        {
            $configurationPolicyAssignments += @{
                dataType                                   = $result.'@odata.type'
                groupId                                    = $result.groupId
                collectionId                               = $result.collectionId
                deviceAndAppManagementAssignmentFilterType = $result.deviceAndAppManagementAssignmentFilterType
                deviceAndAppManagementAssignmentFilterId   = $result.deviceAndAppManagementAssignmentFilterId
            }
        }

        while ($results.'@odata.nextLink')
        {
            $Uri = $results.'@odata.nextLink'
            $results = Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop 4> out-null
            foreach ($result in $results.value.target)
            {
                $configurationPolicyAssignments += @{
                    dataType                                   = $result.'@odata.type'
                    groupId                                    = $result.groupId
                    collectionId                               = $result.collectionId
                    deviceAndAppManagementAssignmentFilterType = $result.deviceAndAppManagementAssignmentFilterType
                    deviceAndAppManagementAssignmentFilterId   = $result.deviceAndAppManagementAssignmentFilterId
                }
            }
        }
        return $configurationPolicyAssignments
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error retrieving data:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        return $null
    }
}

Export-ModuleMember -Function *-TargetResource
