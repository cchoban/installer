$chobanPath = $env:ProgramData + '\choban'

if (Test-Path($chobanPath)) {
    Write-Host 'Deleting '$chobanPath -f Cyan
    Remove-Item $chobanPath -Force -Recurse
}

Write-Host 'Deleting Envoirement Variables' -f Cyan
[Environment]::SetEnvironmentVariable("chobanTools", $null, "Machine")
[Environment]::SetEnvironmentVariable("chobanCli", $null, "Machine")
[Environment]::SetEnvironmentVariable("chobanPath", $null, "Machine")


Write-Host 'Successfully uninstalled Choban from your computer :(' -f Green