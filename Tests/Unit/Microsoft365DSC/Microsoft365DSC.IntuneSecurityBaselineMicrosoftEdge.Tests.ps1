[CmdletBinding()]
param(
)
$M365DSCTestFolder = Join-Path -Path $PSScriptRoot `
                        -ChildPath '..\..\Unit' `
                        -Resolve
$CmdletModule = (Join-Path -Path $M365DSCTestFolder `
            -ChildPath '\Stubs\Microsoft365.psm1' `
            -Resolve)
$GenericStubPath = (Join-Path -Path $M365DSCTestFolder `
    -ChildPath '\Stubs\Generic.psm1' `
    -Resolve)
Import-Module -Name (Join-Path -Path $M365DSCTestFolder `
        -ChildPath '\UnitTestHelper.psm1' `
        -Resolve)

$Global:DscHelper = New-M365DscUnitTestHelper -StubModule $CmdletModule `
    -DscResource "IntuneSecurityBaselineMicrosoftEdge" -GenericStubModule $GenericStubPath
Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope
        BeforeAll {

            $secpasswd = ConvertTo-SecureString (New-Guid | Out-String) -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ('tenantadmin@mydomain.com', $secpasswd)

            Mock -CommandName Confirm-M365DSCDependencies -MockWith {
            }

            Mock -CommandName Get-PSSession -MockWith {
            }

            Mock -CommandName Remove-PSSession -MockWith {
            }

            Mock -CommandName Update-MgBetaDeviceManagementConfigurationPolicy -MockWith {
            }

            Mock -CommandName New-MgBetaDeviceManagementConfigurationPolicy -MockWith {
                return @{
                    Id = '12345-12345-12345-12345-12345'
                }
            }

            Mock -CommandName Get-MgBetaDeviceManagementConfigurationPolicy -MockWith {
                return @{
                    Id              = '12345-12345-12345-12345-12345'
                    Description     = 'My Test'
                    Name            = 'My Test'
                    RoleScopeTagIds = @("FakeStringValue")
                    TemplateReference = @{
                        TemplateId = 'c66347b7-8325-4954-a235-3bf2233dfbfd_2'
                    }
                }
            }

            Mock -CommandName Remove-MgBetaDeviceManagementConfigurationPolicy -MockWith {
            }

            Mock -CommandName Update-IntuneDeviceConfigurationPolicy -MockWith {
            }

            Mock -CommandName Get-IntuneSettingCatalogPolicySetting -MockWith {
            }

            Mock -CommandName Get-MgBetaDeviceManagementConfigurationPolicySetting -MockWith {
                return @(
                    @{
                        Id = '0'
                        SettingDefinitions = @(
                            @{
                                Id = 'device_vendor_msft_policy_config_microsoft_edgev92~policy~microsoft_edge~privatenetworkrequestsettings_insecureprivatenetworkrequestsallowed'
                                Name = 'InsecurePrivateNetworkRequestsAllowed'
                                OffsetUri = '/Config/microsoft_edgev92~Policy~microsoft_edge~PrivateNetworkRequestSettings/InsecurePrivateNetworkRequestsAllowed'
                                AdditionalProperties = @{
                                    '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingDefinition'
                                }
                            }
                        )
                        SettingInstance = @{
                            SettingDefinitionId = 'device_vendor_msft_policy_config_microsoft_edgev92~policy~microsoft_edge~privatenetworkrequestsettings_insecureprivatenetworkrequestsallowed'
                            SettingInstanceTemplateReference = @{
                                SettingInstanceTemplateId = 'c6dec9f2-a235-4878-8462-e88569b47e0b'
                            }
                            AdditionalProperties = @{
                                '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
                                choiceSettingValue = @{
                                    children = @()
                                    value = 'device_vendor_msft_policy_config_microsoft_edgev92~policy~microsoft_edge~privatenetworkrequestsettings_insecureprivatenetworkrequestsallowed_0'
                                }
                            }
                        }
                    },
                    @{
                        Id = '1'
                        SettingDefinitions = @(
                            @{
                                Id = 'device_vendor_msft_policy_config_microsoft_edgev92~policy~microsoft_edge_internetexplorerintegrationreloadiniemodeallowed'
                                Name = 'InternetExplorerIntegrationReloadInIEModeAllowed'
                                OffsetUri = '/Config/microsoft_edgev92~Policy~microsoft_edge/InternetExplorerIntegrationReloadInIEModeAllowed'
                                AdditionalProperties = @{
                                    '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingDefinition'
                                }
                            }
                        )
                        SettingInstance = @{
                            SettingDefinitionId = 'device_vendor_msft_policy_config_microsoft_edgev92~policy~microsoft_edge_internetexplorerintegrationreloadiniemodeallowed'
                            SettingInstanceTemplateReference = @{
                                SettingInstanceTemplateId = 'fd416796-3442-405c-9f9e-e1ca3c0b9e3f'
                            }
                            AdditionalProperties = @{
                                '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
                                choiceSettingValue = @{
                                    children = @()
                                    value = 'device_vendor_msft_policy_config_microsoft_edgev92~policy~microsoft_edge_internetexplorerintegrationreloadiniemodeallowed_0'
                                }
                            }
                        }
                    },
                    @{
                        Id = '2'
                        SettingDefinitions = @(
                            @{
                                Id = 'device_vendor_msft_policy_config_microsoft_edgev117~policy~microsoft_edge_internetexplorerintegrationzoneidentifiermhtfileallowed'
                                Name = 'InternetExplorerIntegrationZoneIdentifierMhtFileAllowed'
                                OffsetUri = '/Config/microsoft_edgev117~Policy~microsoft_edge/InternetExplorerIntegrationZoneIdentifierMhtFileAllowed'
                                AdditionalProperties = @{
                                    '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingDefinition'
                                }
                            }
                        )
                        SettingInstance = @{
                            SettingDefinitionId = 'device_vendor_msft_policy_config_microsoft_edgev117~policy~microsoft_edge_internetexplorerintegrationzoneidentifiermhtfileallowed'
                            SettingInstanceTemplateReference = @{
                                SettingInstanceTemplateId = 'ba15aa09-ea95-49bd-92bf-de9cec9c1146'
                            }
                            AdditionalProperties = @{
                                '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
                                choiceSettingValue = @{
                                    children = @()
                                    value = 'device_vendor_msft_policy_config_microsoft_edgev117~policy~microsoft_edge_internetexplorerintegrationzoneidentifiermhtfileallowed_0'
                                }
                            }
                        }
                    },
                    @{
                        Id = '3'
                        SettingDefinitions = @(
                            @{
                                Id = 'device_vendor_msft_policy_config_microsoft_edgev96~policy~microsoft_edge_internetexplorermodetoolbarbuttonenabled'
                                Name = 'InternetExplorerModeToolbarButtonEnabled'
                                OffsetUri = '/Config/microsoft_edgev96~Policy~microsoft_edge/InternetExplorerModeToolbarButtonEnabled'
                                AdditionalProperties = @{
                                    '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingDefinition'
                                }
                            }
                        )
                        SettingInstance = @{
                            SettingDefinitionId = 'device_vendor_msft_policy_config_microsoft_edgev96~policy~microsoft_edge_internetexplorermodetoolbarbuttonenabled'
                            SettingInstanceTemplateReference = @{
                                SettingInstanceTemplateId = 'fd416796-3442-405c-9f9e-e1ca3c0b9e3f'
                            }
                            AdditionalProperties = @{
                                '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
                                choiceSettingValue = @{
                                    children = @()
                                    value = 'device_vendor_msft_policy_config_microsoft_edgev96~policy~microsoft_edge_internetexplorermodetoolbarbuttonenabled_0'
                                }
                            }
                        }
                    }
                )
            }

            Mock -CommandName Update-DeviceConfigurationPolicyAssignment -MockWith {
            }

            Mock -CommandName New-M365DSCConnection -MockWith {
                return "Credentials"
            }

            # Mock Write-Host to hide output during the tests
            Mock -CommandName Write-Host -MockWith {
            }
            $Script:exportedInstances =$null
            $Script:ExportMode = $false

            Mock -CommandName Get-MgBetaDeviceManagementConfigurationPolicyAssignment -MockWith {
                return @(@{
                    Id       = '12345-12345-12345-12345-12345'
                    Source   = 'direct'
                    SourceId = '12345-12345-12345-12345-12345'
                    Target   = @{
                        DeviceAndAppManagementAssignmentFilterId   = '12345-12345-12345-12345-12345'
                        DeviceAndAppManagementAssignmentFilterType = 'none'
                        AdditionalProperties                       = @(
                            @{
                                '@odata.type' = '#microsoft.graph.exclusionGroupAssignmentTarget'
                                groupId       = '26d60dd1-fab6-47bf-8656-358194c1a49d'
                            }
                        )
                    }
                })
            }

        }
        # Test contexts
        Context -Name "The IntuneSecurityBaselineMicrosoftEdge should exist but it DOES NOT" -Fixture {
            BeforeAll {
                $testParams = @{
                    Assignments = [CimInstance[]]@(
                        (New-CimInstance -ClassName MSFT_DeviceManagementConfigurationPolicyAssignments -Property @{
                            DataType     = '#microsoft.graph.exclusionGroupAssignmentTarget'
                            groupId = '26d60dd1-fab6-47bf-8656-358194c1a49d'
                            deviceAndAppManagementAssignmentFilterType = 'none'
                        } -ClientOnly)
                    )
                    Description = "My Test"
                    Id = "12345-12345-12345-12345-12345"
                    InsecurePrivateNetworkRequestsAllowed                   = "0"
                    InternetExplorerIntegrationReloadInIEModeAllowed        = "0"
                    InternetExplorerIntegrationZoneIdentifierMhtFileAllowed = "0"
                    InternetExplorerModeToolbarButtonEnabled                = "0"
                    DisplayName = "My Test"
                    RoleScopeTagIds = @("FakeStringValue")
                    Ensure = "Present"
                    Credential = $Credential;
                }

                Mock -CommandName Get-MgBetaDeviceManagementConfigurationPolicy -MockWith {
                    return $null
                }
            }
            It 'Should return Values from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should -Be 'Absent'
            }
            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should -Be $false
            }
            It 'Should Create the group from the Set method' {
                Set-TargetResource @testParams
                Should -Invoke -CommandName New-MgBetaDeviceManagementConfigurationPolicy -Exactly 1
            }
        }

        Context -Name "The IntuneSecurityBaselineMicrosoftEdge exists but it SHOULD NOT" -Fixture {
            BeforeAll {
                $testParams = @{
                    Assignments = [CimInstance[]]@(
                        (New-CimInstance -ClassName MSFT_DeviceManagementConfigurationPolicyAssignments -Property @{
                            DataType     = '#microsoft.graph.exclusionGroupAssignmentTarget'
                            groupId = '26d60dd1-fab6-47bf-8656-358194c1a49d'
                            deviceAndAppManagementAssignmentFilterType = 'none'
                        } -ClientOnly)
                    )
                    Description = "My Test"
                    Id = "12345-12345-12345-12345-12345"
                    InsecurePrivateNetworkRequestsAllowed                   = "0"
                    InternetExplorerIntegrationReloadInIEModeAllowed        = "0"
                    InternetExplorerIntegrationZoneIdentifierMhtFileAllowed = "0"
                    InternetExplorerModeToolbarButtonEnabled                = "0"
                    DisplayName = "My Test"
                    RoleScopeTagIds = @("FakeStringValue")
                    Ensure = "Absent"
                    Credential = $Credential;
                }
            }

            It 'Should return Values from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
            }

            It 'Should return true from the Test method' {
                Test-TargetResource @testParams | Should -Be $false
            }

            It 'Should Remove the group from the Set method' {
                Set-TargetResource @testParams
                Should -Invoke -CommandName Remove-MgBetaDeviceManagementConfigurationPolicy -Exactly 1
            }
        }
        Context -Name "The IntuneSecurityBaselineMicrosoftEdge Exists and Values are already in the desired state" -Fixture {
            BeforeAll {
                $testParams = @{
                    Assignments = [CimInstance[]]@(
                        (New-CimInstance -ClassName MSFT_DeviceManagementConfigurationPolicyAssignments -Property @{
                            DataType     = '#microsoft.graph.exclusionGroupAssignmentTarget'
                            groupId = '26d60dd1-fab6-47bf-8656-358194c1a49d'
                            deviceAndAppManagementAssignmentFilterType = 'none'
                        } -ClientOnly)
                    )
                    Description = "My Test"
                    Id = "12345-12345-12345-12345-12345"
                    InsecurePrivateNetworkRequestsAllowed                   = "0"
                    InternetExplorerIntegrationReloadInIEModeAllowed        = "0"
                    InternetExplorerIntegrationZoneIdentifierMhtFileAllowed = "0"
                    InternetExplorerModeToolbarButtonEnabled                = "0"
                    DisplayName = "My Test"
                    RoleScopeTagIds = @("FakeStringValue")
                    Ensure = "Present"
                    Credential = $Credential;
                }
            }

            It 'Should return true from the Test method' {
                Test-TargetResource @testParams | Should -Be $true
            }
        }

        Context -Name "The IntuneSecurityBaselineMicrosoftEdge exists and values are NOT in the desired state" -Fixture {
            BeforeAll {
                $testParams = @{
                    Assignments = [CimInstance[]]@(
                        (New-CimInstance -ClassName MSFT_DeviceManagementConfigurationPolicyAssignments -Property @{
                            DataType     = '#microsoft.graph.exclusionGroupAssignmentTarget'
                            groupId = '26d60dd1-fab6-47bf-8656-358194c1a49d'
                            deviceAndAppManagementAssignmentFilterType = 'none'
                        } -ClientOnly)
                    )
                    Description = "My Test"
                    Id = "12345-12345-12345-12345-12345"
                    InsecurePrivateNetworkRequestsAllowed                   = "0"
                    InternetExplorerIntegrationReloadInIEModeAllowed        = "0"
                    InternetExplorerIntegrationZoneIdentifierMhtFileAllowed = "0"
                    InternetExplorerModeToolbarButtonEnabled                = "1" # Drift
                    DisplayName = "My Test"
                    RoleScopeTagIds = @("FakeStringValue")
                    Ensure = "Present"
                    Credential = $Credential;
                }
            }

            It 'Should return Values from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should -Be $false
            }

            It 'Should call the Set method' {
                Set-TargetResource @testParams
                Should -Invoke -CommandName Update-IntuneDeviceConfigurationPolicy -Exactly 1
            }
        }

        Context -Name 'ReverseDSC Tests' -Fixture {
            BeforeAll {
                $Global:CurrentModeIsExport = $true
                $Global:PartialExportFileName = "$(New-Guid).partial.ps1"
                $testParams = @{
                    Credential = $Credential
                }
            }
            It 'Should Reverse Engineer resource from the Export method' {
                $result = Export-TargetResource @testParams
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope
