function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $Id,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String[]]
        $ResourceScopes,

        [Parameter()]
        [System.String[]]
        $ResourceScopesDisplayNames,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersDisplayNames,

        [Parameter()]
        [System.String]
        $RoleDefinition,

        [Parameter()]
        [System.String]
        $RoleDefinitionDisplayName,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure = $true,

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
        $ManagedIdentity
    )

    try
    {
        $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
            -InboundParameters $PSBoundParameters `
            -ProfileName 'beta'

        Select-MgProfile 'beta'
    }
    catch
    {
        Write-Verbose -Message ($_)
    }

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
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
        $getValue = $null
        if($Id -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')
        {
            $getValue = Get-MgDeviceManagementRoleAssignment -DeviceAndAppManagementRoleAssignmentId $id -ErrorAction SilentlyContinue
            if($null -ne $getValue){
                Write-Verbose -Message "Found something with id {$id}"
            }
        }
        else
        {
            Write-Verbose -Message "Nothing with id {$id} was found"
            $Filter = "displayName eq '$DisplayName'"
            $getValue = Get-MgDeviceManagementRoleAssignment -Filter $Filter -ErrorAction SilentlyContinue
            if($null -ne $getValue){
                Write-Verbose -Message "Found something with displayname {$DisplayName}"
            }
            else{
                Write-Verbose -Message "Nothing with displayname {$DisplayName} was found"
                return $nullResult
            }
        }

        $ScopeTagsId = @()
        $ScopeTagsId = (Get-MgDeviceManagementRoleAssignmentRoleScopeTag -DeviceAndAppManagementRoleAssignmentId $getValue.Id).Id

        #Get Roledefinition first, loop through all roledefinitions and find the assignment match the id
        $tempRoleDefinitions = Get-MgDeviceManagementRoleDefinition
        foreach($tempRoleDefinition in $tempRoleDefinitions)
        {
            $item = Get-MgDeviceManagementRoleDefinitionRoleAssignment -RoleDefinitionId $tempRoleDefinition.Id | Where-Object {$_.Id -eq $getValue.Id}
            if($null -ne $item)
            {
                $RoleDefinition = $tempRoleDefinition.Id
                $RoleDefinitionDisplayName = $tempRoleDefinition.DisplayName
                break
            }
        }

        #$RoleDefinitionid = Get-MgDeviceManagementRoleAssignment -DeviceAndAppManagementRoleAssignmentId $getvalue.Id -ExpandProperty *

        $ResourceScopesDisplayNames = @()
        foreach($ResourceScope in $getValue.ResourceScopes)
        {
            $ResourceScopesDisplayNames += (Get-MgGroup -GroupId $ResourceScope).DisplayName
        }

        $MembersDisplayNames = @()
        foreach($tempMember in $getValue.Members)
        {
            $MembersDisplayNames += (Get-MgGroup -GroupId $tempMember).DisplayName
        }

        Write-Verbose -Message "Found something with id {$id}"

        $results = @{
            Id = $getValue.Id
            Description                 = $getValue.Description
            DisplayName                 = $getValue.DisplayName
            ResourceScopes              = $getValue.ResourceScopes
            ResourceScopesDisplayNames  = $ResourceScopesDisplayNames
            Members                     = $getValue.Members
            MembersDisplayNames         = $MembersDisplayNames
            RoleDefinition              = $RoleDefinition
            RoleDefinitionDisplayName   = $RoleDefinitionDisplayName
            Ensure                      = 'Present'
            Credential                  = $Credential
            ApplicationId               = $ApplicationId
            TenantId                    = $TenantId
            ApplicationSecret           = $ApplicationSecret
            CertificateThumbprint       = $CertificateThumbprint
            Managedidentity             = $ManagedIdentity.IsPresent
            RoleScopeTagIds             = $ScopeTags
        }


        return [System.Collections.Hashtable] $results
    }
    catch
    {
        try
        {
            Write-Verbose -Message $_
            $tenantIdValue = ''
            if (-not [System.String]::IsNullOrEmpty($TenantId))
            {
                $tenantIdValue = $TenantId
            }
            elseif ($null -ne $Credential)
            {
                $tenantIdValue = $Credential.UserName.Split('@')[1]
            }
            Add-M365DSCEvent -Message $_ -EntryType 'Error' `
                -EventID 1 -Source $($MyInvocation.MyCommand.Source) `
                -TenantId $tenantIdValue
        }
        catch
        {
            Write-Verbose -Message $_
        }
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
        $Id,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String[]]
        $ResourceScopes,

        [Parameter()]
        [System.String[]]
        $ResourceScopesDisplayNames,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersDisplayNames,

        [Parameter()]
        [System.String]
        $RoleDefinition,

        [Parameter()]
        [System.String]
        $RoleDefinitionDisplayName,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure = $true,

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
        $ManagedIdentity
    )

    try
    {
        $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
            -InboundParameters $PSBoundParameters `
            -ProfileName 'beta'

        Select-MgProfile 'beta' -ErrorAction Stop
    }
    catch
    {
        Write-Verbose -Message $_
    }

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $currentInstance = Get-TargetResource @PSBoundParameters

    $PSBoundParameters.Remove('Ensure') | Out-Null
    $PSBoundParameters.Remove('Credential') | Out-Null
    $PSBoundParameters.Remove('ApplicationId') | Out-Null
    $PSBoundParameters.Remove('ApplicationSecret') | Out-Null
    $PSBoundParameters.Remove('TenantId') | Out-Null
    $PSBoundParameters.Remove('CertificateThumbprint') | Out-Null
    $PSBoundParameters.Remove('ManagedIdentity') | Out-Null

    if($null -ne $RoleScopeTagIds){
        $ScopeTags = @()
        foreach($roleScopeTagId in $RoleScopeTagIds){
            $Tag = Get-MgDeviceManagementRoleScopeTag -RoleScopeTagId $roleScopeTagId -ErrorAction SilentlyContinue
            if($null -ne $Tag){
                $ScopeTags += $Tag.Id
            }
        }
    }

    if(!($RoleDefinition -match "^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$")){
        [string]$roleDefinition = $null
        $Filter = "displayName eq '$RoleDefinitionDisplayName'"
        $RoleDefinitionId = Get-MgDeviceManagementRoleDefinition -Filter $Filter -ErrorAction SilentlyContinue
        if($null -ne $RoleDefinitionId){
            $roleDefinition = $RoleDefinitionId.Id
        }
        else{
            Write-Verbose -Message "Nothing with displayname {$RoleDefinitionDisplayName} was found"
        }
    }

    foreach($MembersDisplayName in $membersDisplayNames){
        $Filter = "displayName eq '$MembersDisplayName'"
        $MemberId = Get-MgGroup -Filter $Filter -ErrorAction SilentlyContinue
        if($null -ne $MemberId){
            if($Members -notcontains $MemberId.Id){
                $Members += $MemberId.Id
            }
        }
        else{
            Write-Verbose -Message "Nothing with displayname {$MembersDisplayName} was found"
        }
    }

    foreach($ResourceScopesDisplayName in $ResourceScopesDisplayNames){
        $Filter = "displayName eq '$ResourceScopesDisplayName'"
        $ResourceScopeId = Get-MgGroup -Filter $Filter -ErrorAction SilentlyContinue
        if($null -ne $ResourceScopeId){
            if($ResourceScopes -notcontains $ResourceScopeId.Id){
                $ResourceScopes += $ResourceScopeId.Id
            }
        }
        else{
            Write-Verbose -Message "Nothing with displayname {$ResourceScopesDisplayName} was found"
        }
    }

    if ($Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Creating {$DisplayName}"

        $CreateParameters = @{
            description = $Description
            displayName = $DisplayName
            resourceScopes = $ResourceScopes
            scopeType = 'resourceScope'
            members = $Members
            '@odata.type' = '#microsoft.graph.deviceAndAppManagementRoleAssignment'
            'roleDefinition@odata.bind' = "https://graph.microsoft.com/beta/deviceManagement/roleDefinitions('$roleDefinition')"
            roleScopeTagIds = $ScopeTags
        }

        $policy=New-MgDeviceManagementRoleAssignment -BodyParameter $CreateParameters

    }
    elseif ($Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Updating {$DisplayName}"

        $UpdateParameters = @{
            description = $Description
            displayName = $DisplayName
            resourceScopes = $ResourceScopes
            scopeType = 'resourceScope'
            members = $Members
            '@odata.type' = '#microsoft.graph.deviceAndAppManagementRoleAssignment'
            'roleDefinition@odata.bind' = "https://graph.microsoft.com/beta/deviceManagement/roleDefinitions('$roleDefinition')"
            roleScopeTagIds = $ScopeTags
        }

        Update-MgDeviceManagementRoleAssignment -BodyParameter $UpdateParameters `
            -DeviceAndAppManagementRoleAssignmentId $currentInstance.Id

    }
    elseif ($Ensure -eq 'Absent' -and $currentInstance.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Removing {$DisplayName}"
        Remove-MgDeviceManagementRoleAssignment -DeviceAndAppManagementRoleAssignmentId $currentInstance.Id
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
        $Id,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String[]]
        $ResourceScopes,

        [Parameter()]
        [System.String[]]
        $ResourceScopesDisplayNames,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersDisplayNames,

        [Parameter()]
        [System.String]
        $RoleDefinition,

        [Parameter()]
        [System.String]
        $RoleDefinitionDisplayName,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure = $true,

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
        $ManagedIdentity
    )

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    Write-Verbose -Message "Testing configuration of {$id}"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    $ValuesToCheck = ([Hashtable]$PSBoundParameters).clone()

    if(!($RoleDefinition -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')){
        [string]$roleDefinition = $null
        $Filter = "displayName eq '$RoleDefinitionDisplayName'"
        $RoleDefinitionId = Get-MgDeviceManagementRoleDefinition -Filter $Filter -ErrorAction SilentlyContinue
        if($null -ne $RoleDefinitionId){
            $roleDefinition = $RoleDefinitionId.Id
            $PSBoundParameters.Set_Item('RoleDefinition',$roleDefinition)
        }
        else{
            Write-Verbose -Message "Nothing with displayname {$RoleDefinitionDisplayName} was found"
        }
    }

    foreach($MembersDisplayName in $membersDisplayNames){
        $Filter = "displayName eq '$MembersDisplayName'"
        $newMemeber = Get-MgGroup -Filter $Filter -ErrorAction SilentlyContinue
        if($null -ne $newMemeber){
            if($Members -notcontains $newMemeber.Id){
                $Members += $newMemeber.Id
            }
        }
        else{
            Write-Verbose -Message "Nothing with displayname {$RoleDefinitionDisplayName} was found"
        }
    }
    $PSBoundParameters.Set_Item('Members',$Members)

    foreach($ResourceScopesDisplayName in $resourceScopesDisplayNames){
        $Filter = "displayName eq '$ResourceScopesDisplayName'"
        $newResourceScope = Get-MgGroup -Filter $Filter -ErrorAction SilentlyContinue
        if($null -ne $newResourceScope){
            if($ResourceScopes -notcontains $newResourceScope.Id){
                $ResourceScopes += $newResourceScope.Id
            }
        }
        else{
            Write-Verbose -Message "Nothing with displayname {$RoleDefinitionDisplayName} was found"
        }
    }
    $PSBoundParameters.Set_Item('ResourceScopes',$ResourceScopes)

    if($CurrentValues.Ensure -eq "Absent")
    {
        Write-Verbose -Message "Test-TargetResource returned $false"
        return $false
    }
    $testResult=$true

    #Compare Cim instances
    foreach($key in $PSBoundParameters.Keys)
    {
        $source=$PSBoundParameters.$key
        $target=$CurrentValues.$key
        if($source.getType().Name -like "*CimInstance*")
        {
            $source=Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $source

            $testResult=Compare-M365DSCComplexObject `
                -Source ($source) `
                -Target ($target)

            if(-Not $testResult)
            {
                $testResult=$false
                break;
            }

            $ValuesToCheck.Remove($key)|Out-Null

        }
    }

    $ValuesToCheck.Remove('Credential') | Out-Null
    $ValuesToCheck.Remove('ApplicationId') | Out-Null
    $ValuesToCheck.Remove('TenantId') | Out-Null
    $ValuesToCheck.Remove('ApplicationSecret') | Out-Null
    $ValuesToCheck.Remove('RoleScopeTagIds') | Out-Null
    $ValuesToCheck.Remove('Id') | Out-Null
    $ValuesToCheck.Remove('ResourceScopesDisplayNames') | Out-Null
    $ValuesToCheck.Remove('membersDisplayNames') | Out-Null

    foreach ($key in $ValuesToCheck.Keys)
    {
        if (($null -ne $CurrentValues[$key]) `
                -and ($CurrentValues[$key].getType().Name -eq 'DateTime'))
        {
            $CurrentValues[$key] = $CurrentValues[$key].toString()
        }
    }

    if ($testResult)
    {
        $testResult = Test-M365DSCParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck $ValuesToCheck.Keys
    }

    Write-Verbose -Message "Test-TargetResource returned $testResult"

    return $testResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
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
        $ManagedIdentity
    )

    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters `
        -ProfileName 'beta'
    Select-MgProfile 'beta' -ErrorAction Stop

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    try
    {
        [array]$getValue = Get-MgDeviceManagementRoleAssignment `
            -ErrorAction Stop | Where-Object `
            -FilterScript { `
                $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.deviceAndAppManagementRoleAssignment'  `
            }

        if (-not $getValue)
        {
            [array]$getValue = Get-MgDeviceManagementRoleAssignment `
                -ErrorAction Stop
        }

        $i = 1
        $dscContent = ''
        if ($getValue.Length -eq 0)
        {
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }
        else
        {
            Write-Host "`r`n" -NoNewline
        }
        foreach ($config in $getValue)
        {
            $displayedKey=$config.id
            if(-not [String]::IsNullOrEmpty($config.displayName))
            {
                $displayedKey=$config.displayName
            }
            Write-Host "    |---[$i/$($getValue.Count)] $displayedKey" -NoNewline
            $params = @{
                id                    = $config.id
                Ensure                = 'Present'
                Credential            = $Credential
                ApplicationId         = $ApplicationId
                TenantId              = $TenantId
                ApplicationSecret     = $ApplicationSecret
                CertificateThumbprint = $CertificateThumbprint
                Managedidentity       = $ManagedIdentity.IsPresent
            }

            $Results = Get-TargetResource @Params
            $Results = Update-M365DSCExportAuthenticationResults -ConnectionMode $ConnectionMode `
                -Results $Results

            $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $ResourceName `
                -ConnectionMode $ConnectionMode `
                -ModulePath $PSScriptRoot `
                -Results $Results `
                -Credential $Credential

            $dscContent += $currentDSCBlock
            Save-M365DSCPartialExport -Content $currentDSCBlock `
                -FileName $Global:PartialExportFileName
            $i++
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }
        return $dscContent
    }
    catch
    {
        Write-Host $Global:M365DSCEmojiGreenCheckMark
        try
        {
            Write-Verbose -Message $_
            $tenantIdValue = ''
            if (-not [System.String]::IsNullOrEmpty($TenantId))
            {
                $tenantIdValue = $TenantId
            }
            elseif ($null -ne $Credential)
            {
                $tenantIdValue = $Credential.UserName.Split('@')[1]
            }
            Add-M365DSCEvent -Message $_ -EntryType 'Error' `
                -EventID 1 -Source $($MyInvocation.MyCommand.Source) `
                -TenantId $tenantIdValue
        }
        catch
        {
            Write-Verbose -Message $_
        }
        return ''
    }
}

function Get-M365DSCAdditionalProperties
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = 'true')]
        [System.Collections.Hashtable]
        $Properties
    )

    $additionalProperties = @(

    )
    $results = @{'@odata.type' = '#microsoft.graph.deviceAndAppManagementRoleAssignment' }
    $cloneProperties = $Properties.clone()
    foreach ($property in $cloneProperties.Keys)
    {
        if ($property -in ($additionalProperties) )
        {
            $propertyName = $property[0].ToString().ToLower() + $property.Substring(1, $property.Length - 1)
            if ($properties.$property -and $properties.$property.getType().FullName -like '*CIMInstance*')
            {
                if ($properties.$property.getType().FullName -like '*[[\]]')
                {
                    $array = @()
                    foreach ($item in $properties.$property)
                    {
                        $array += Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $item

                    }
                    $propertyValue = $array
                }
                else
                {
                    $propertyValue = Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $properties.$property
                }

            }
            else
            {
                $propertyValue = $properties.$property
            }


            $results.Add($propertyName, $propertyValue)

        }
    }
    if ($results.Count -eq 1)
    {
        return $null
    }
    return $results
}


function Rename-M365DSCCimInstanceODataParameter
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = 'true')]
        [System.Collections.Hashtable]
        $Properties
    )
    $CIMparameters = $Properties.getEnumerator() | Where-Object -FilterScript { $_.value.GetType().Fullname -like '*CimInstance*' }
    foreach ($CIMParam in $CIMparameters)
    {
        if ($CIMParam.value.GetType().Fullname -like '*[[\]]')
        {
            $CIMvalues = @()
            foreach ($item in $CIMParam.value)
            {
                $CIMHash = Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $item
                $keys = ($CIMHash.clone()).keys
                if ($keys -contains 'odataType')
                {
                    $CIMHash.add('@odata.type', $CIMHash.odataType)
                    $CIMHash.remove('odataType')
                }
                $CIMvalues += $CIMHash
            }
            $Properties.($CIMParam.key) = $CIMvalues
        }
        else
        {
            $CIMHash = Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $CIMParam.value
            $keys = ($CIMHash.clone()).keys
            if ($keys -contains 'odataType')
            {
                $CIMHash.add('@odata.type', $CIMHash.odataType)
                $CIMHash.remove('odataType')
                $Properties.($CIMParam.key) = $CIMHash
            }
        }
    }
    return $Properties
}
function Get-M365DSCDRGComplexTypeToHashtable
{
    [CmdletBinding()]
    [OutputType([hashtable],[hashtable[]])]
    param(
        [Parameter()]
        $ComplexObject
    )

    if($null -eq $ComplexObject)
    {
        return $null
    }


    if($ComplexObject.getType().Fullname -like "*hashtable")
    {
        return $ComplexObject
    }
    if($ComplexObject.getType().Fullname -like "*hashtable[[\]]")
    {
        return ,[hashtable[]]$ComplexObject
    }


    if($ComplexObject.gettype().fullname -like "*[[\]]")
    {
        $results=@()

        foreach($item in $ComplexObject)
        {
            if($item)
            {
                $hash = Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $item
                $results+=$hash
            }
        }

        # PowerShell returns all non-captured stream output, not just the argument of the return statement.
        #An empty array is mangled into $null in the process.
        #However, an array can be preserved on return by prepending it with the array construction operator (,)
        return ,[hashtable[]]$results
    }

    $results = @{}
    $keys = $ComplexObject | Get-Member | Where-Object -FilterScript {$_.MemberType -eq 'Property' -and $_.Name -ne 'AdditionalProperties'}

    foreach ($key in $keys)
    {

        if($null -ne $ComplexObject.$($key.Name))
        {
            $keyName = $key.Name[0].ToString().ToLower() + $key.Name.Substring(1, $key.Name.Length - 1)

            if($ComplexObject.$($key.Name).gettype().fullname -like "*CimInstance*")
            {
                $hash = Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $ComplexObject.$($key.Name)

                $results.Add($keyName, $hash)
            }
            else
            {
                $results.Add($keyName, $ComplexObject.$($key.Name))
            }
        }
    }

    return [hashtable]$results
}

function Get-M365DSCDRGComplexTypeToString
{
    [CmdletBinding()]
    #[OutputType([System.String])]
    param(
        [Parameter()]
        $ComplexObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $CIMInstanceName,

        [Parameter()]
        [Array]
        $ComplexTypeMapping,

        [Parameter()]
        [System.String]
        $Whitespace="",

        [Parameter()]
        [switch]
        $isArray=$false
    )

    if ($null -eq $ComplexObject)
    {
        return $null
    }

    #If ComplexObject  is an Array
    if ($ComplexObject.GetType().FullName -like "*[[\]]")
    {
        $currentProperty=@()
        foreach ($item in $ComplexObject)
        {
            $split=@{
                'ComplexObject'=$item
                'CIMInstanceName'=$CIMInstanceName
                'Whitespace'="                $whitespace"
            }
            if ($ComplexTypeMapping)
            {
                $split.add('ComplexTypeMapping',$ComplexTypeMapping)
            }

            $currentProperty += Get-M365DSCDRGComplexTypeToString -isArray:$true @split

        }

        # PowerShell returns all non-captured stream output, not just the argument of the return statement.
        #An empty array is mangled into $null in the process.
        #However, an array can be preserved on return by prepending it with the array construction operator (,)
        return ,$currentProperty
    }

    $currentProperty=""
    if($isArray)
    {
        $currentProperty += "`r`n"
    }
    $currentProperty += "$whitespace`MSFT_$CIMInstanceName{`r`n"
    $keyNotNull = 0
    foreach ($key in $ComplexObject.Keys)
    {
        if ($null -ne $ComplexObject.$key)
        {
            $keyNotNull++
            if ($ComplexObject.$key.GetType().FullName -like "Microsoft.Graph.PowerShell.Models.*" -or $key -in $ComplexTypeMapping.Name)
            {
                $hashPropertyType=$ComplexObject[$key].GetType().Name.tolower()

                #overwrite type if object defined in mapping complextypemapping
                if($key -in $ComplexTypeMapping.Name)
                {
                    $hashPropertyType=($ComplexTypeMapping|Where-Object -FilterScript {$_.Name -eq $key}).CimInstanceName
                    $hashProperty=$ComplexObject[$key]
                }
                else
                {
                    $hashProperty=Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $ComplexObject[$key]
                }

                if($key -notin $ComplexTypeMapping.Name)
                {
                    $Whitespace+="            "
                }

                if(-not $isArray -or ($isArray -and $key -in $ComplexTypeMapping.Name ))
                {
                    $currentProperty += $whitespace + $key + " = "
                    if($ComplexObject[$key].GetType().FullName -like "*[[\]]")
                    {
                        $currentProperty += "@("
                    }
                }

                if($key -in $ComplexTypeMapping.Name)
                {
                    $Whitespace=""

                }
                $currentProperty += Get-M365DSCDRGComplexTypeToString `
                                -ComplexObject $hashProperty `
                                -CIMInstanceName $hashPropertyType `
                                -Whitespace $Whitespace `
                                -ComplexTypeMapping $ComplexTypeMapping

                if($ComplexObject.$key.GetType().FullName -like "*[[\]]")
                {
                    $currentProperty += ")"
                }
            }
            else
            {
                if(-not $isArray)
                {
                    $Whitespace= "            "
                }
                $currentProperty += Get-M365DSCDRGSimpleObjectTypeToString -Key $key -Value $ComplexObject[$key] -Space ($Whitespace+"    ")
            }
        }
        else
        {
            $mappedKey=$ComplexTypeMapping|where-object -filterscript {$_.name -eq $key}

            if($mappedKey -and $mappedKey.isRequired)
            {
                if($mappedKey.isArray)
                {
                    $currentProperty += "$Whitespace    $key = @()`r`n"
                }
                else
                {
                    $currentProperty += "$Whitespace    $key = `$null`r`n"
                }
            }
        }
    }
    $currentProperty += "$Whitespace}"

    return $currentProperty
}

Function Get-M365DSCDRGSimpleObjectTypeToString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = 'true')]
        [System.String]
        $Key,

        [Parameter(Mandatory = 'true')]
        $Value,

        [Parameter()]
        [System.String]
        $Space="                "

    )

    $returnValue=""
    switch -Wildcard ($Value.GetType().Fullname )
    {
        "*.Boolean"
        {
            $returnValue= $Space + $Key + " = `$" + $Value.ToString() + "`r`n"
        }
        "*.String"
        {
            if($key -eq '@odata.type')
            {
                $key='odataType'
            }
            $returnValue= $Space + $Key + " = '" + $Value + "'`r`n"
        }
        "*.DateTime"
        {
            $returnValue= $Space + $Key + " = '" + $Value + "'`r`n"
        }
        "*[[\]]"
        {
            $returnValue= $Space + $key + " = @("
            $whitespace=""
            $newline=""
            if($Value.count -gt 1)
            {
                $returnValue += "`r`n"
                $whitespace=$Space+"    "
                $newline="`r`n"
            }
            foreach ($item in $Value)
            {
                switch -Wildcard ($item.GetType().Fullname )
                {
                    "*.String"
                    {
                        $returnValue += "$whitespace'$item'$newline"
                    }
                    "*.DateTime"
                    {
                        $returnValue += "$whitespace'$item'$newline"
                    }
                    Default
                    {
                        $returnValue += "$whitespace$item$newline"
                    }
                }
            }
            if($Value.count -gt 1)
            {
                $returnValue += "$Space)`r`n"
            }
            else
            {
                $returnValue += ")`r`n"

            }
        }
        Default
        {
            $returnValue= $Space + $Key + " = " + $Value + "`r`n"
        }
    }
    return $returnValue
}

function Compare-M365DSCComplexObject
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter()]
        $Source,
        [Parameter()]
        $Target
    )

    #Comparing full objects
    if($null -eq  $Source  -and $null -eq $Target)
    {
        return $true
    }

    $sourceValue=""
    $targetValue=""
    if (($null -eq $Source) -xor ($null -eq $Target))
    {
        if($null -eq $Source)
        {
            $sourceValue="Source is null"
        }

        if($null -eq $Target)
        {
            $targetValue="Target is null"
        }
        Write-Verbose -Message "Configuration drift - Complex object: {$sourceValue$targetValue}"
        return $false
    }

    if($Source.getType().FullName -like "*CimInstance[[\]]" -or $Source.getType().FullName -like "*Hashtable[[\]]")
    {
        if($source.count -ne $target.count)
        {
            Write-Verbose -Message "Configuration drift - The complex array have different number of items: Source {$($source.count)} Target {$($target.count)}"
            return $false
        }
        if($source.count -eq 0)
        {
            return $true
        }

        $i=0
        foreach($item in $Source)
        {

            $compareResult= Compare-M365DSCComplexObject `
                    -Source (Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $Source[$i]) `
                    -Target $Target[$i]

            if(-not $compareResult)
            {
                Write-Verbose -Message "Configuration drift - The complex array items are not identical"
                return $false
            }
            $i++
        }
        return $true
    }

    $keys= $Source.Keys|Where-Object -FilterScript {$_ -ne "PSComputerName"}
    foreach ($key in $keys)
    {
        #write-verbose -message "Comparing key: {$key}"
        #Matching possible key names between Source and Target
        $skey=$key
        $tkey=$key
        if($key -eq 'odataType')
        {
            $skey='@odata.type'
        }
        else
        {
            $tmpkey=$Target.keys|Where-Object -FilterScript {$_ -eq "$key"}
            if($tkey)
            {
                $tkey=$tmpkey|Select-Object -First 1
            }
        }

        $sourceValue=$Source.$key
        $targetValue=$Target.$tkey
        #One of the item is null and not the other
        if (($null -eq $Source.$skey) -xor ($null -eq $Target.$tkey))
        {

            if($null -eq $Source.$skey)
            {
                $sourceValue="null"
            }

            if($null -eq $Target.$tkey)
            {
                $targetValue="null"
            }

            Write-Verbose -Message "Configuration drift - key: $key Source {$sourceValue} Target {$targetValue}"
            return $false
        }

        #Both keys aren't null or empty
        if(($null -ne $Source.$skey) -and ($null -ne $Target.$tkey))
        {
            if($Source.$skey.getType().FullName -like "*CimInstance*" -or $Source.$skey.getType().FullName -like "*hashtable*"  )
            {
                #Recursive call for complex object
                $compareResult= Compare-M365DSCComplexObject `
                    -Source (Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $Source.$skey) `
                    -Target $Target.$tkey

                if(-not $compareResult)
                {

                    Write-Verbose -Message "Configuration drift - complex object key: $key Source {$sourceValue} Target {$targetValue}"
                    return $false
                }
            }
            else
            {
                #Simple object comparison
                $referenceObject=$Target.$tkey
                $differenceObject=$Source.$skey

                $compareResult = Compare-Object `
                    -ReferenceObject ($referenceObject) `
                    -DifferenceObject ($differenceObject)

                if ($null -ne $compareResult)
                {
                    Write-Verbose -Message "Configuration drift - simple object key: $key Source {$sourceValue} Target {$targetValue}"
                    return $false
                }

            }

        }
    }

    return $true
}
function Convert-M365DSCDRGComplexTypeToHashtable
{
    [CmdletBinding()]
    [OutputType([hashtable],[hashtable[]])]
    param(
        [Parameter(Mandatory = 'true')]
        $ComplexObject
    )


    if($ComplexObject.getType().Fullname -like "*[[\]]")
    {
        $results=@()
        foreach($item in $ComplexObject)
        {
            $hash=Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $item
            $results+=$hash
        }

        #Write-Verbose -Message ("Convert-M365DSCDRGComplexTypeToHashtable >>> results: "+(convertTo-JSON $results -Depth 20))
        # PowerShell returns all non-captured stream output, not just the argument of the return statement.
        #An empty array is mangled into $null in the process.
        #However, an array can be preserved on return by prepending it with the array construction operator (,)
        return ,[hashtable[]]$results
    }
    $hashComplexObject = Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $ComplexObject

    if($null -ne $hashComplexObject)
    {

        $results=$hashComplexObject.clone()
        $keys=$hashComplexObject.Keys|Where-Object -FilterScript {$_ -ne 'PSComputerName'}
        foreach ($key in $keys)
        {
            if($hashComplexObject[$key] -and $hashComplexObject[$key].getType().Fullname -like "*CimInstance*")
            {
                $results[$key]=Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $hashComplexObject[$key]
            }
            else
            {
                $propertyName = $key[0].ToString().ToLower() + $key.Substring(1, $key.Length - 1)
                $propertyValue=$results[$key]
                $results.remove($key)|out-null
                $results.add($propertyName,$propertyValue)
            }
        }
    }
    return [hashtable]$results
}
Export-ModuleMember -Function *-TargetResource
