BeforeAll {
  $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

Describe 'AVD example load balancing' {
  It 'keeps the initial host pool algorithm aligned with every scaling phase in both examples' {
    foreach ($example in @('default', 'private-endpoints')) {
      $exampleRoot = Join-Path $moduleRoot 'examples' $example
      $variables = Get-Content -Raw -LiteralPath (Join-Path $exampleRoot 'variables.tf')
      $main = Get-Content -Raw -LiteralPath (Join-Path $exampleRoot 'main.tf')

      $definition = [regex]::Match(
        $variables,
        '(?ms)^variable "virtual_desktop_host_pool_load_balancer_type" \{.*?^\}'
      )
      $definition.Success | Should -BeTrue
      $definition.Value | Should -Match '(?m)^\s*default\s*=\s*"DepthFirst"\s*$'

      $module = [regex]::Match($main, '(?ms)^module "avd" \{.*?^\}')
      $module.Success | Should -BeTrue
      $module.Value | Should -Match '(?m)^\s*virtual_desktop_host_pool_load_balancer_type\s*=\s*var\.virtual_desktop_host_pool_load_balancer_type\s*$'
      foreach ($phase in @('ramp_up', 'peak', 'ramp_down', 'off_peak')) {
        $assignment = "(?m)^\s*$($phase)_load_balancing_algorithm\s*=\s*var\.virtual_desktop_host_pool_load_balancer_type\s*$"
        @([regex]::Matches($module.Value, $assignment)).Count | Should -Be 1
      }
    }
  }
}
