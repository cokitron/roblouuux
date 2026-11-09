# Publish roblouuux.rbxl to Roblox via Open Cloud Place Publishing API
param(
    [string]$UniverseId = $env:ROBLOX_UNIVERSE_ID,
    [string]$PlaceId    = $env:ROBLOX_PLACE_ID,
    [string]$ApiKey     = $env:ROBLOX_API_KEY,
    [ValidateSet("Published", "Saved")]
    [string]$VersionType = "Published"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "1. Formatting, linting, and building roblouuux.rbxl via Rojo..." -ForegroundColor Cyan
& "$env:USERPROFILE\.cargo\bin\stylua.exe" src
& "$env:USERPROFILE\.cargo\bin\selene.exe" src
& "$env:USERPROFILE\.cargo\bin\rojo.exe" build default.project.json -o roblouuux.rbxl

$studioVersions = Get-ChildItem "$env:LOCALAPPDATA\Roblox\Versions" -Directory -ErrorAction SilentlyContinue
foreach ($v in $studioVersions) {
    if (Test-Path "$($v.FullName)\RobloxStudioBeta.exe") {
        $destMusic = Join-Path $v.FullName "content\music"
        New-Item -ItemType Directory -Force -Path $destMusic | Out-Null
        Copy-Item "d:\game-dev\assets\music\*" -Destination $destMusic -Force
    }
}

if ([string]::IsNullOrWhiteSpace($UniverseId) -or [string]::IsNullOrWhiteSpace($PlaceId) -or [string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host ""
    Write-Host "Built d:\game-dev\roblouuux.rbxl successfully!" -ForegroundColor Green
    Write-Host "To publish directly from the terminal via Roblox Open Cloud, pass or set:" -ForegroundColor Yellow
    Write-Host "  `$env:ROBLOX_UNIVERSE_ID = '<your-universe-id>'"
    Write-Host "  `$env:ROBLOX_PLACE_ID    = '<your-place-id>'"
    Write-Host "  `$env:ROBLOX_API_KEY     = '<your-open-cloud-api-key>'"
    Write-Host "Or inside Roblox Studio (already opened), press Alt + P (File -> Publish to Roblox)." -ForegroundColor Cyan
    exit 0
}

$uri = "https://apis.roblox.com/universes/v1/$UniverseId/places/$PlaceId/versions?versionType=$VersionType"
Write-Host "2. Uploading roblouuux.rbxl to Roblox Open Cloud (Universe: $UniverseId, Place: $PlaceId)..." -ForegroundColor Cyan

$response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{
    "x-api-key"    = $ApiKey
    "Content-Type" = "application/octet-stream"
} -InFile "d:\game-dev\roblouuux.rbxl"

Write-Host "Published successfully! Version Number: $($response.versionNumber)" -ForegroundColor Green
