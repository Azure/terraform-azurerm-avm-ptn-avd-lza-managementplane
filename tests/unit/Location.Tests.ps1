BeforeAll {
  $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  $main = Get-Content -Raw -LiteralPath (Join-Path $moduleRoot 'main.tf')
  $variables = Get-Content -Raw -LiteralPath (Join-Path $moduleRoot 'variables.tf')
  $telemetry = Get-Content -Raw -LiteralPath (Join-Path $moduleRoot 'main.telemetry.tf')
  $children = [ordered]@{
    virtual_desktop_application_group_location = 'avm_res_desktopvirtualization_applicationgroup'
    virtual_desktop_host_pool_location         = 'avm_res_desktopvirtualization_hostpool'
    virtual_desktop_scaling_plan_location      = 'avm_res_desktopvirtualization_scaling_plan'
    virtual_desktop_workspace_location         = 'avm_res_desktopvirtualization_workspace'
  }

  function Get-VariableBlock {
    param([string] $Name)

    $match = [regex]::Match($variables, "(?ms)^variable `"$([regex]::Escape($Name))`" \{.*?^\}")
    if (-not $match.Success) {
      throw "Missing variable $Name"
    }
    return $match.Value
  }

  function Get-ChildModuleBlock {
    param([string] $Module)

    $block = [regex]::Match($main, "(?ms)^module `"$([regex]::Escape($Module))`" \{.*?(?=^(?:module|resource|data) |\z)")
    if (-not $block.Success) {
      throw "Missing module $Module"
    }
    return $block.Value
  }

  function Get-ChildLocationExpression {
    param([string] $Module)

    $assignments = [regex]::Matches((Get-ChildModuleBlock $Module), '(?m)^  location\s*=\s*(?<expression>[^\r\n]+)')
    if ($assignments.Count -ne 1) {
      throw "Expected one location input for $Module, found $($assignments.Count)"
    }
    return $assignments[0].Groups['expression'].Value.Trim()
  }

  $fixture = @((Get-VariableBlock 'location'))
  $fixture += foreach ($child in $children.GetEnumerator()) { Get-VariableBlock $child.Key }
  $fixture += 'locals {'
  $fixture += '  resolved = {'
  $fixture += foreach ($child in $children.GetEnumerator()) {
    "    $($child.Key) = $(Get-ChildLocationExpression $child.Value)"
  }
  $fixture += '  }'
  $fixture += '}'
  Set-Content -LiteralPath (Join-Path $TestDrive 'main.tf') -Value $fixture

  function Get-ResolvedLocations {
    param([hashtable] $Inputs)

    $inputPath = Join-Path $TestDrive 'inputs.tfvars.json'
    $Inputs | ConvertTo-Json | Set-Content -LiteralPath $inputPath
    $result = 'jsonencode(local.resolved)' | & terraform "-chdir=$TestDrive" console -no-color "-var-file=$inputPath" 2>&1
    if ($LASTEXITCODE -ne 0) {
      throw "Terraform console failed: $($result | Out-String)"
    }
    return ($result | ConvertFrom-Json | ConvertFrom-Json)
  }
}

Describe 'AVD child locations' {
  It 'does not expose an unused private endpoints input' {
    $variables | Should -Not -Match '(?m)^variable "private_endpoints"\s*\{'
  }

  It 'keeps the common location required and uses it for telemetry' {
    $location = Get-VariableBlock 'location'
    $location | Should -Match '(?m)^\s*nullable\s*=\s*false\s*$'
    $location | Should -Not -Match '(?m)^\s*default\s*='
    $telemetry | Should -Match '(?m)^\s*main_location\s*=\s*var\.location\s*$'
  }

  It 'uses location with the updated Insights module in both examples' {
    foreach ($name in @('default', 'private-endpoints')) {
      $example = Get-Content -Raw -LiteralPath (Join-Path $moduleRoot 'examples' $name 'main.tf')
      $call = [regex]::Match($example, '(?ms)^module "avm_ptn_avd_lza_insights" \{(?<body>.*?)^\}')
      $call.Success | Should -BeTrue
      $call.Groups['body'].Value | Should -Match '(?m)^\s*version\s*=\s*"0\.3\.0"\s*$'
      $call.Groups['body'].Value | Should -Match '(?m)^\s*location\s*=\s*azurerm_resource_group\.this\.location\s*$'
      $call.Groups['body'].Value | Should -Not -Match 'monitor_data_collection_rule_location'
    }
  }

  It 'allows both examples to use the CI subscription without an input value' {
    foreach ($name in @('default', 'private-endpoints')) {
      $exampleRoot = Join-Path $moduleRoot 'examples' $name
      $declaration = Get-Content -Raw -LiteralPath (Join-Path $exampleRoot 'variables.tf')
      $provider = Get-Content -Raw -LiteralPath (Join-Path $exampleRoot 'main.tf')
      $declaration | Should -Match '(?s)variable "subscription_id" \{[^}]*default\s*=\s*null'
      $provider | Should -Match 'subscription_id\s*=\s*var\.subscription_id'
    }
  }

  It 'makes all four overrides optional and forwards each to its own child' {
    foreach ($child in $children.GetEnumerator()) {
      $variable = Get-VariableBlock $child.Key
      $variable | Should -Match '(?m)^\s*type\s*=\s*string\s*$'
      $variable | Should -Match '(?m)^\s*default\s*=\s*null\s*$'
      $variable | Should -Not -Match '(?m)^\s*nullable\s*=\s*false\s*$'
      (Get-ChildLocationExpression $child.Value) | Should -Be "coalesce(var.$($child.Key), var.location)"
      (Get-ChildModuleBlock $child.Value) | Should -Not -Match "(?m)^\s+$([regex]::Escape($child.Key))\s*="
    }
  }

  It 'passes the telemetry opt-out to all four resource modules' {
    (Get-VariableBlock 'enable_telemetry') | Should -Match '(?m)^\s*default\s*=\s*true\s*$'
    foreach ($child in $children.GetEnumerator()) {
      (Get-ChildModuleBlock $child.Value) | Should -Match '(?m)^\s+enable_telemetry\s*=\s*var\.enable_telemetry\s*$'
    }
  }

  It 'uses the common location when all overrides are omitted' {
    $resolved = Get-ResolvedLocations @{ location = 'uksouth' }
    foreach ($child in $children.GetEnumerator()) {
      $resolved.($child.Key) | Should -Be 'uksouth'
    }
  }

  It 'preserves four distinct explicit overrides' {
    $inputs = @{
      location                                   = 'uksouth'
      virtual_desktop_application_group_location = 'eastus'
      virtual_desktop_host_pool_location         = 'westus'
      virtual_desktop_scaling_plan_location      = 'centralus'
      virtual_desktop_workspace_location         = 'northeurope'
    }
    $resolved = Get-ResolvedLocations $inputs
    foreach ($child in $children.GetEnumerator()) {
      $resolved.($child.Key) | Should -Be $inputs[$child.Key]
    }
  }

  It 'falls back only for omitted or null overrides' {
    $resolved = Get-ResolvedLocations @{
      location                                   = 'uksouth'
      virtual_desktop_application_group_location = 'eastus'
      virtual_desktop_host_pool_location         = $null
    }
    $resolved.virtual_desktop_application_group_location | Should -Be 'eastus'
    $resolved.virtual_desktop_host_pool_location | Should -Be 'uksouth'
    $resolved.virtual_desktop_scaling_plan_location | Should -Be 'uksouth'
    $resolved.virtual_desktop_workspace_location | Should -Be 'uksouth'
  }
}
