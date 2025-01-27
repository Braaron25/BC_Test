Write-Host "Publishing to tenant"
Publish-PerTenantExtensionApps -useNewLine `
 -ClientID $ENV:ClientId `
 -ClientSecret $ENV:ClientSecret `
 -tenantId $ENV:TenantId `
 -environment $ENV:ProEnv `
 -appFiles @(Get-Item ".output/*.app" | % { $_.FullName })