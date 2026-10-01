BeforeAll {
  $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  $main = Get-Content -Raw -LiteralPath (Join-Path $moduleRoot 'main.tf')
  $rootTerraform = (Get-ChildItem -LiteralPath $moduleRoot -File -Filter '*.tf' | ForEach-Object {
    Get-Content -Raw -LiteralPath $_.FullName
  }) -join "`n"
  $variables = Get-Content -Raw -LiteralPath (Join-Path $moduleRoot 'variables.tf')
  $outputs = Get-Content -Raw -LiteralPath (Join-Path $moduleRoot 'outputs.tf')
  $hostPool = [regex]::Match($main, '(?ms)^module "avm_res_desktopvirtualization_hostpool" \{(?<body>.*?)^\}')
  $removal = [regex]::Match($rootTerraform, '(?ms)^removed \{\s*from\s*=\s*azurerm_virtual_desktop_host_pool_registration_info\.registrationinfo\s*lifecycle \{\s*destroy\s*=\s*false\s*\}\s*\}')

  function Invoke-LocalTerraform {
    param([string] $Directory, [string[]] $Arguments)

    $result = & terraform "-chdir=$Directory" @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
      throw "Local terraform $($Arguments[0]) failed: $($result -join "`n")"
    }
    return ($result -join "`n")
  }
}

Describe 'AVD host-pool registration ownership' {
  It 'has no parent registration resource alongside the pinned child' {
    $hostPool.Success | Should -BeTrue
    $hostPool.Groups['body'].Value | Should -Match '(?m)^\s*source\s*=\s*"Azure/avm-res-desktopvirtualization-hostpool/azurerm"\s*$'
    $hostPool.Groups['body'].Value | Should -Match '(?m)^\s*version\s*=\s*"0\.5\.0"\s*$'
    $rootTerraform | Should -Not -Match '(?m)^resource\s+"azurerm_virtual_desktop_host_pool_registration_info"\s+'
  }

  It 'forwards the existing registration period and exports the child token' {
    $registrationPeriod = [regex]::Match($variables, '(?ms)^variable "registration_expiration_period" \{(?<body>.*?)^\}')
    $registrationPeriod.Success | Should -BeTrue
    $registrationPeriod.Groups['body'].Value | Should -Match '(?m)^\s*default\s*=\s*"48h"\s*$'
    $hostPool.Groups['body'].Value | Should -Match '(?m)^\s*registration_expiration_period\s*=\s*var\.registration_expiration_period\s*$'

    $token = [regex]::Match($outputs, '(?ms)^output "registrationinfo_token" \{(?<body>.*?)^\}')
    $token.Success | Should -BeTrue
    $token.Groups['body'].Value | Should -Match '(?m)^\s*sensitive\s*=\s*true\s*$'
    $token.Groups['body'].Value | Should -Match '(?m)^\s*value\s*=\s*module\.avm_res_desktopvirtualization_hostpool\.registrationinfo_token\s*$'
  }

  It 'forgets the duplicate state entry without proposing a deletion' {
    $removal.Success | Should -BeTrue
    @([regex]::Matches($rootTerraform, '(?m)^\s*from\s*=\s*azurerm_virtual_desktop_host_pool_registration_info\.registrationinfo\s*$')).Count | Should -Be 1

    $fixture = Join-Path $TestDrive 'registration-removal'
    New-Item -ItemType Directory -Path $fixture | Out-Null
    $fixtureFile = Join-Path $fixture 'main.tf'
    Set-Content -LiteralPath $fixtureFile -Value 'resource "terraform_data" "registrationinfo" { input = "kept" }'
    $null = Invoke-LocalTerraform -Directory $fixture -Arguments @('init', '-backend=false', '-input=false', '-no-color')
    $null = Invoke-LocalTerraform -Directory $fixture -Arguments @('apply', '-auto-approve', '-input=false', '-no-color')
    (Invoke-LocalTerraform -Directory $fixture -Arguments @('state', 'list')) | Should -Be 'terraform_data.registrationinfo'

    Set-Content -LiteralPath $fixtureFile -Value $removal.Value.Replace('azurerm_virtual_desktop_host_pool_registration_info.registrationinfo', 'terraform_data.registrationinfo')
    $planFile = Join-Path $fixture 'forget.tfplan'
    $null = Invoke-LocalTerraform -Directory $fixture -Arguments @('plan', '-refresh=false', '-input=false', '-no-color', "-out=$planFile")
    $plan = (Invoke-LocalTerraform -Directory $fixture -Arguments @('show', '-json', $planFile)) | ConvertFrom-Json -Depth 100
    $change = @($plan.resource_changes | Where-Object { $_.address -eq 'terraform_data.registrationinfo' })
    $change.Count | Should -Be 1
    $change[0].change.actions | Should -Contain 'forget'
    $change[0].change.actions | Should -Not -Contain 'delete'

    $null = Invoke-LocalTerraform -Directory $fixture -Arguments @('apply', '-input=false', '-no-color', $planFile)
    (Invoke-LocalTerraform -Directory $fixture -Arguments @('state', 'list')) | Should -BeNullOrEmpty
  }
}
