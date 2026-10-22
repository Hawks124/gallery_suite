<#
.SYNOPSIS
    Optimises the demo GIFs shipped with the Gallery Suite example.

.DESCRIPTION
    The raw screen recordings are far too heavy for a package archive.
    This script re-encodes them with ffmpeg using a restricted palette and
    a frame-rate cap, which typically divides the weight by 2 to 6.

    Two renditions are produced:
      * example/assets/    -> the sharp version (240 px, 96 colours, 12 fps).
                              Served from GitHub by the README only.
      * doc/screenshots/   -> the light version (180 px, 64 colours, 10 fps).
                              Published in the archive and shown on pub.dev.
                              Every file MUST stay below the 4 MB pub.dev limit.

.EXAMPLE
    pwsh -File tool/optimize-gifs.ps1 -Source "D:\recordings\gif"

.NOTES
    Requires ffmpeg on the PATH: https://ffmpeg.org/download.html
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Source,

    [string] $Ffmpeg = 'ffmpeg'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$assetsDir = Join-Path $repoRoot 'example/assets'
$screenshotsDir = Join-Path $repoRoot 'doc/screenshots'

# The three showcases published on the pub.dev package page.
$publishedScreenshots = @('image_picker', 'swipe_to_select', 'audio_picker')

New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null
New-Item -ItemType Directory -Path $screenshotsDir -Force | Out-Null

function Invoke-Optimize {
    param(
        [Parameter(Mandatory = $true)][string] $Input,
        [Parameter(Mandatory = $true)][string] $Output,
        [Parameter(Mandatory = $true)][int] $Fps,
        [Parameter(Mandatory = $true)][int] $Colors,
        [Parameter(Mandatory = $true)][int] $Width
    )

    $filter = "[0:v]fps=$Fps,scale='min(iw,$Width)':-2:flags=lanczos,split[s0][s1];" +
    "[s0]palettegen=max_colors=$Colors`:stats_mode=diff[p];" +
    "[s1][p]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle"

    & $Ffmpeg -y -v error -i $Input -filter_complex $filter -loop 0 $Output
}

Get-ChildItem -Path $Source -Filter '*.gif' | ForEach-Object {
    $name = $_.BaseName

    $sharp = Join-Path $assetsDir "$name.gif"
    Invoke-Optimize -Input $_.FullName -Output $sharp -Fps 12 -Colors 96 -Width 240
    '{0,-28} {1,6} Ko -> {2,6} Ko' -f $name, [math]::Round($_.Length / 1KB), [math]::Round((Get-Item $sharp).Length / 1KB)

    if ($publishedScreenshots -contains $name) {
        $light = Join-Path $screenshotsDir "$name.gif"
        Invoke-Optimize -Input $_.FullName -Output $light -Fps 10 -Colors 64 -Width 180
        '  -> published screenshot {0,6} Ko' -f [math]::Round((Get-Item $light).Length / 1KB)
    }
}

Write-Host ''
Write-Host 'Done. Remember pub.dev rejects any screenshot above 4 MB.'
Get-ChildItem -Path $screenshotsDir -Filter '*.gif' |
    Where-Object { $_.Length -gt 4MB } |
    ForEach-Object { Write-Warning "$($_.Name) is above the 4 MB pub.dev limit." }
