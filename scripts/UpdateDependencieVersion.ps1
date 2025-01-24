Param(
    [Parameter(Mandatory = $false)]
    [string] $appVersion
)

$path = "C:\Users\administrador\Documents"

Write-Host "Path: $path"

function ReplaceProperty { Param ($object)
    $object | ForEach-Object {
        if($object.id -eq $appID){
            $object.version = $appVersion
        }
    }
}

$appId = ''

$pathApp = Join-Path $PSScriptRoot ".."
Get-ChildItem -Path $pathApp | Where-Object { $_.PSIsContainer -and $_.Name -notlike ".*" } | Get-ChildItem -Recurse -Filter "app.json" | ForEach-Object {
    $appJsonFile = $_.FullName
    $appJson = Get-Content $appJsonFile | ConvertFrom-Json
    $appId = $appJson.id
    Write-Host "APPID: $appId"
}

Get-ChildItem -Path $path | Get-ChildItem -Recurse -filter "version.json" | ForEach-Object {
    $appJsonFile = $_.FullName
    $appJson = Get-Content $appJsonFile | ConvertFrom-Json
    $appJson."$($ENV:BCEnvironment)" | ForEach-Object { ReplaceProperty($_) }
    $appJson | ConvertTo-Json -Depth 10 | Set-Content $appJsonFile
}