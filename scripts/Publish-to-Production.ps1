Write-Host "Publishing to tenant"
Publish-PerTenantExtensionApps -useNewLine `
 -ClientID $ENV:ClientId `
 -ClientSecret $ENV:ClientSecret `
 -tenantId $ENV:TenantId `
 -environment $ENV:ProEnv `
 -appFiles @(Get-Item "Artifacts/output/Apps/*.app" | % { $_.FullName })