$path = Join-Path $PSScriptRoot ".."

function ReplaceDependenciesVersion {
    param (
        $dependencies, $envDependencie
    )

    $dependencies | ForEach-Object {
        if ($_.id -eq $envDependencie.id){
            $_.version = $envDependencie.version
        }
    }
    
}

function FindEnvDependencie {
    param (
        $dependencies, $envDependencies
    )
    $envDependencies | ForEach-Object {
        ReplaceDependenciesVersion -dependencies $dependencies -envDependencie $_
    }
    
}

function GetEnvironment {
    return $environments.PSObject.Properties.name -Contains $ENV:BCEnvironment
}

$versionPath = "C:\Users\administrador\Documents"
$environments = Get-Content (Join-Path $versionPath "version.json") | ConvertFrom-Json


Get-ChildItem -Path $path | Where-Object { $_.PSIsContainer -and $_.Name -notlike ".*" } | Get-ChildItem -Recurse -Filter "app.json" | ForEach-Object {
    $appJsonFile = $_.FullName
    $appJson = Get-Content $appJsonFile | ConvertFrom-Json
    # Write-Host "JSON: $appJson"

    Write-Host "Get environment"
    if(!(GetEnvironment)){
        throw "No se encontro el ambiente $($ENV:BCEnvironment)"
    }
    Write-Host "Check Dependencies"
    $appJson.dependencies | ForEach-Object { FindEnvDependencie -dependencies $_ -envDependencies $environments."$($ENV:BCEnvironment)" }
    $appJson | ConvertTo-Json -Depth 10 | Set-Content $appJsonFile
}
