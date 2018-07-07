Import-Module BitsTransfer
Add-Type -AssemblyName System.IO.Compression.FileSystem

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Please run script as Administrator." -f red
    exit
}

function Unzip
{
    param([string]$zipfile, [string]$outpath)
    Write-Host "Unzipping chob.zip..." -f Cyan
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
    Write-Host "Successfully unzipped." -f Green
}


function downloadFile($url, $outPath){
    $start_time = Get-Date
    Start-BitsTransfer -Source $url -Destination $outPath
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

function Get-PSVersion {
    if (test-path variable:psversiontable){
        $psversiontable.psversion
    }else {
        [version]"1.0.0.0"
    }
}

function checkArch {
    if ($is64bit = [Environment]::Is64BitOperatingSystem)
    {
        return $is64bit
    }
}

if (Get-PSVersion) {
    $scriptRoot = $PSScriptRoot
}else {
    $scriptRoot = split-path -parent $MyInvocation.MyCommand.Definition
}

$path = $scriptRoot + "\.choban"

Write-Output $path
if (!(Test-Path $path)){
    New-Item -ItemType Directory -Force -Path $path
    Write-Host "Created directory $path " -f green
}


if (checkArch){
    $pythonUrl = "https://www.python.org/ftp/python/3.6.5/python-3.6.5-amd64.exe"
}else {
    $pythonUrl = "https://www.python.org/ftp/python/3.6.5/python-3.6.5.exe"
}
$chobanUrl = "http://mrmkaplan.com/chob.zip"

if(!(Test-Path $path"\python3.exe") -and !(Test-Path $path"\chob.zip"))
{
    Write-Host "Downloading Python 3 from $pythonUrl..." -f cyan
    downloadFile -url $pythonUrl -outPath $scriptRoot\.choban\python3.exe
	Write-Host "Downloading Choban from $chobanUrl..." -f cyan
    downloadFile -url $chobanUrl -outPath $path
}


Write-Host "Installing Python 3.." -f cyan
$p = Start-Process $path\python3.exe -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -wait -NoNewWindow -PassThru
if ($p -and $p.HasExited -and ($p.ExitCode -eq 0)){
    Write-Host "Sucessfully installed Python 3 " -f green
}else {
    Write-Host "Could not install Python 3 " -f red
}


if((Test-Path $path\choban\programData)) {
    Remove-Item $path\choban\programData -Force -Recurse
}

Unzip $path\chob.zip $path\choban\programData


Write-Host "Setting correct environments.." -f Cyan
[Environment]::SetEnvironmentVariable("chobanPath","$env:programdata\choban", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("chobanTools","$env:SystemDrive\tools", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("chobanCli","$env:programdata\choban\lib", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:chobanPath" + ";$env:chobanCli", [EnvironmentVariableTarget]::Machine)
setx PATH $env:Path + ";$env:chobanPath" + ";$env:chobanCli" -m

$cobanPath = "$path\choban\programData\"
if ((Test-Path $env:programdata\choban)) {
    Remove-Item $env:programdata\choban -Force -Recurse
}
Copy-Item $cobanPath -Recurse -Destination  "$env:programdata\choban" -Container


cmd /c "$env:programdata\choban\refreshenv.cmd"
cmd /c "$env:programdata\choban\chob --download-chob-dependencies"
#cmd /c "chob --download-chob-dependencies"

Write-Host "Removing Junk files.." -f cyan
Write-Host "You may need to restart your shell to get it run." -f Yellow
Write-Host "Sucessfully installed Choban" -f Green
Write-Host "Please run chob --doctor for the first time." -f Green
Remove-Item $path -Force -Recurse
Start-Sleep -Seconds 3
exit
