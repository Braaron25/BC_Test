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

function ValidateVersion {
    param (
        $id, $version
    )

    $extensions = Get-BcEnvironmentInstalledExtensions -bcAuthContext $authContext -environment $proEnv

    $app = $extensions | Where-Object { $_.id -eq $id}

    Write-Host $app

    $appVersion = "$($app.versionMajor).$($app.versionMinor).$($app.versionBuild).$($app.versionRevision)"
    if($app -and ($appVersion -eq $version) -and $app.isInstalled){
        Write-Host "Ya se encuentra instalada la ultima versión de este artefacto"
    } else {
        Write-Host "##vso[task.setvariable variable=BuildArtifact]$true"
        RunPipeline
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
        -buildArtifactFolder $buildArtifactFolder `
        -doNotPublishApps
        # -appBuild $appBuild -appRevision $appRevision
    
    if ($environment -eq 'AzureDevOps') {
        Write-Host "##vso[task.setvariable variable=TestResults]$allTestResults"
    }
}

function SearchAppJson {
    $path = Join-Path $PSScriptRoot ".."

    Get-ChildItem -Path $path | Where-Object { $_.PSIsContainer -and $_.Name -notlike ".*" } | Get-ChildItem -Recurse -Filter "app.json" | ForEach-Object {
        $appJsonFile = $_.FullName
        $appJson = Get-Content $appJsonFile | ConvertFrom-Json
        # Write-Host "JSON: $appJson"
        Write-Host "Current version"
        ValidateVersion -id $appJson.id -version $appJson.version
    }
}


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

$environmentName = $ENV:BCEnvironment
$proEnv = $ENV:ProEnv
Write-Host "Env: $environmentName"

SearchAppJson