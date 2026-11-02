# Play rejects screenshots and feature graphics with an alpha channel. Rewrites the
# rendered PNGs as 24-bit, and makes the 512 px listing icon from the app icon.
# Run from the project root after test/store_assets/generate_store_assets.dart.
Add-Type -AssemblyName System.Drawing

$dir = Join-Path (Get-Location) 'docs\store_assets'

Get-ChildItem $dir -Filter *.png | Where-Object { $_.Name -ne 'icon_512.png' } | ForEach-Object {
    $source = [System.Drawing.Image]::FromFile($_.FullName)
    $flat = New-Object System.Drawing.Bitmap($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($flat)
    $g.DrawImage($source, 0, 0, $source.Width, $source.Height)
    $g.Dispose()
    $source.Dispose()
    $flat.Save($_.FullName, [System.Drawing.Imaging.ImageFormat]::Png)
    $flat.Dispose()
}

$icon = [System.Drawing.Image]::FromFile((Join-Path (Get-Location) 'assets\branding\app_icon.png'))
$small = New-Object System.Drawing.Bitmap(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($small)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($icon, 0, 0, 512, 512)
$g.Dispose()
$icon.Dispose()
$small.Save((Join-Path $dir 'icon_512.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$small.Dispose()

Get-ChildItem $dir -Filter *.png | ForEach-Object {
    $i = [System.Drawing.Image]::FromFile($_.FullName)
    '{0}: {1}x{2} {3} {4} KB' -f $_.Name, $i.Width, $i.Height, $i.PixelFormat, [int]($_.Length / 1024)
    $i.Dispose()
}
