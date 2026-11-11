$files = @(
    'windows\installer\rojob_setup.iss',
    'windows\runner\main.cpp'
)
foreach ($path in $files) {
    if (Test-Path $path) {
        $txt = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText($path, $txt, [System.Text.Encoding]::UTF8)
        Write-Output "BOM successfully written to $path"
    }
}

