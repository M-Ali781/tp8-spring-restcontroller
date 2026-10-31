param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$ExitSuffix = 'Process finished with exit code 0',
    [int]$Width = 1088,
    [int]$FontSize = 15
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$lines = @(Get-Content -LiteralPath $In -Encoding UTF8)
if ($lines.Count -eq 0) { $lines = @('') }

if ($ExitSuffix -ne '') {
    $lines += ''
    $lines += $ExitSuffix
}

$font = New-Object System.Drawing.Font('Consolas', $FontSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$lineHeight = [int][Math]::Ceiling($font.GetHeight() * 1.32)
$padX = 22
$padY = 18
$height = $padY * 2 + $lineHeight * $lines.Count

$bmp = New-Object System.Drawing.Bitmap $Width, $height
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

$gfx.Clear([System.Drawing.ColorTranslator]::FromHtml('#2B2B2B'))

$cLog = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#C5766E'))
$cSql = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#C9C9C9'))
$cOut = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#EDEDED'))

$y = $padY
foreach ($line in $lines) {
    $brush = $cOut
    $text = $line

    if ($line -match '^(INFO:|WARN:|ERROR:)' -or $line -match 'org\.hibernate|HCANN|Hibernate Commons|Hibernate:') {
        $brush = $cLog
    }
    elseif ($line -match '^(Hibernate:|    )|select |insert |from products') {
        $brush = $cSql
    }

    $gfx.DrawString($text, $font, $brush, $padX, $y)
    $y += $lineHeight
}

$outPath = [System.IO.Path]::GetFullPath($Out)
$dir = Split-Path $outPath
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)

$gfx.Dispose()
$bmp.Dispose()
$font.Dispose()

Write-Output ("image : " + $outPath + " (" + $Width + "x" + $height + ")")
