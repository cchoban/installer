$chobanPath = $env:ProgramData + '\choban'
function RemoveFromPath($env_value) {
    $path = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $path = ($path.Split(';') | Where-Object { $_ -ne $env_value }) -join ';'
    [System.Environment]::SetEnvironmentVariable('PATH', $path, 'Machine')
}

if (Test-Path($chobanPath)) {
    Write-Host 'Deleting '$chobanPath -f Cyan
    Remove-Item $chobanPath -Force -Recurse
}

Write-Host 'Deleting from PATH environment'. -f Cyan
$oldUserPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
$oldMachinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')

try {
    RemoveFromPath -env_value $env:chobanCli
    RemoveFromPath -env_value $env:chobanPath
}
catch {
    Write-Host 'Problem occured, reverting old PATH environments..' -f Red
    [Environment]::SetEnvironmentVariable('PATH', $oldUserPath, 'User')
    [Environment]::SetEnvironmentVariable('PATH', $oldMachinePath, 'Machine')
}


Write-Host 'Deleting Envoirement Variables' -f Cyan
[Environment]::SetEnvironmentVariable("chobanApps", $null, "Machine")
[Environment]::SetEnvironmentVariable("chobanCli", $null, "Machine")
[Environment]::SetEnvironmentVariable("chobanPath", $null, "Machine")




Write-Host 'Successfully uninstalled Choban from your computer :(' -f Green
