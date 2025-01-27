Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AzureDevOps')]
    [string] $environment = 'AzureDevOps',
    [Parameter(Mandatory = $true)]
    [string] $version,
    [Parameter(Mandatory = $false)]
    [int] $appBuild = 0,
    [Parameter(Mandatory = $false)]
    [int] $appRevision = 0
)

Write-Host "info=$ENV:ClientId"

if ($environment -eq "AzureDevOps") {
    Write-Host "azure: $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY"
    $buildArtifactFolder = $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY
}

# Installar BcContainerHelper
# Install-Module BcContainerHelper -Force

$baseFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
Write-Host "Base folder: $baseFolder"
. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment $environment -version $version
# . (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName

$clientID = $ENV:ClientId
$clientSecret = $ENV:ClientSecret
$tenantId = $ENV:TenantId

$authContext = New-BcAuthContext `
    -clientID $clientID `
    -clientSecret $clientSecret `
    -tenantID $tenantId `
    -scopes "https://api.businesscentral.dynamics.com/.default" `
    -includeDeviceLogin

# $environment = Get-BcEnvironments -bcAuthContext $authContext -environment 'DEV-ALT'

$environmentName = $ENV:BCEnvironment
Write-Host "Env: $environmentName"

Start-Sleep -Seconds 10
Write-Host "Searching test artifact"
$currentApp = Get-BcPublishedApps -bcAuthContext $authContext -environment $environmentName | Where-Object { $_.Id -eq "c0f2cb46-b96d-4e7d-a45d-c8ec60d7f19f" }

if($currentApp){
    $currentApp | Out-Host
    SearchAppJson
} else {
    RunPipeline
}

function SearchAppJson {
    $path = Join-Path $PSScriptRoot ".."

Get-ChildItem -Path $path | Where-Object { $_.PSIsContainer -and $_.Name -notlike ".*" } | Get-ChildItem -Recurse -Filter "app.json" | ForEach-Object {
    $appJsonFile = $_.FullName
    $appJson = Get-Content $appJsonFile | ConvertFrom-Json
    # Write-Host "JSON: $appJson"
    Write-Host "Current version"
    if(!($currentApp.Version -eq $appJson.version)){
        RunPipeline
    }else{
        Write-Host "Ya posee la ultima version"
    }
}
}


function RunPipeline {
    do {
        Start-Sleep -Seconds 10
        $baseApp = Get-BcPublishedApps -bcAuthContext $authContext -environment $environmentName | Where-Object { $_.Name -eq "Base Application" }
    } while (!($baseApp))
    $baseapp | Out-Host
    
    $artifact = Get-BCArtifactUrl `
        -country 'us' `
        -version $baseApp.Version `
        -select Closest
        
    if ($artifact) {
        Write-Host "Using Artifacts: $artifact"
    }
    else {
        throw "No artifacts available"
    }
    
    # $params = @{}
    # $insiderSasToken = "$ENV:insiderSasToken"
    # $licenseFile = "$ENV:licenseFile"
    # $codeSigncertPfxFile = "$ENV:CodeSignCertPfxFile"
    # if (!$doNotSignApps -and $codeSigncertPfxFile) {
    #     if ("$ENV:CodeSignCertPfxPassword" -ne "") {
    #         $codeSignCertPfxPassword = try { "$ENV:CodeSignCertPfxPassword" | ConvertTo-SecureString } catch { ConvertTo-SecureString -String "$ENV:CodeSignCertPfxPassword" -AsPlainText -Force }
    #         $params = @{
    #             "codeSignCertPfxFile"     = $codeSignCertPfxFile
    #             "codeSignCertPfxPassword" = $codeSignCertPfxPassword
    #         }
    #     }
    #     else {
    #         $codeSignCertPfxPassword = $null
    #     }
    # }
    
    $allTestResults = "testresults*.xml"
    $testResultsFile = Join-Path $baseFolder "TestResults.xml"
    $testResultsFiles = Join-Path $baseFolder $allTestResults
    if (Test-Path $testResultsFiles) {
        Remove-Item $testResultsFiles -Force
    }
    
    Write-Host "param=$params"
    
    Run-AlPipeline `
        -pipelinename $pipelineName `
        -containerName $containerName `
        -imageName $imageName `
        -bcAuthContext $authContext `
        -environment $environmentName `
        -artifact $artifact `
        -memoryLimit $memoryLimit `
        -baseFolder $baseFolder `
        -installApps $installApps `
        -installTestApps $installTestApps `
        -previousApps $previousApps `
        -appFolders $appFolders `
        -testFolders $testFolders `
        -doNotRunTests:$doNotRunTests `
        -testResultsFile $testResultsFile `
        -testResultsFormat 'JUnit' `
        -installTestRunner:$installTestRunner `
        -installTestFramework:$installTestFramework `
        -installTestLibraries:$installTestLibraries `
        -installPerformanceToolkit:$installPerformanceToolkit `
        -enableCodeCop:$enableCodeCop `
        -enableAppSourceCop:$enableAppSourceCop `
        -enablePerTenantExtensionCop:$enablePerTenantExtensionCop `
        -enableUICop:$enableUICop `
        -azureDevOps:($environment -eq 'AzureDevOps') `
        -gitLab:($environment -eq 'GitLab') `
        -gitHubActions:($environment -eq 'GitHubActions') `
        -failOn 'error' `
        -AppSourceCopMandatoryAffixes $appSourceCopMandatoryAffixes `
        -AppSourceCopSupportedCountries $appSourceCopSupportedCountries `
        -additionalCountries $additionalCountries `
        -buildArtifactFolder $buildArtifactFolder
        # -appBuild $appBuild -appRevision $appRevision
    
    if ($environment -eq 'AzureDevOps') {
        Write-Host "##vso[task.setvariable variable=TestResults]$allTestResults"
    }
}


