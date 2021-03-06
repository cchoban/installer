﻿Add-Type -AssemblyName System.IO.Compression.FileSystem
Import-Module BitsTransfer

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Please run script as Administrator." -f red
    pause
}

function Add-To-Path {
    Write-Host "Setting correct environments.." -f Cyan
    [Environment]::SetEnvironmentVariable("chobanPath","$env:programdata\choban", [EnvironmentVariableTarget]::Machine)
    [Environment]::SetEnvironmentVariable("chobanApps","$env:SystemDrive\chobanapps", [EnvironmentVariableTarget]::Machine)
    [Environment]::SetEnvironmentVariable("chobanCli","$env:programdata\choban\lib", [EnvironmentVariableTarget]::Machine)
    $envs = $env:PATH+";"+$env:chobanPath+";"+$env:chobanCli
    $addPath = [Environment]::SetEnvironmentVariable("PATH", $envs, [EnvironmentVariableTarget]::Machine)
    if (!$addPath){
        setx PATH $envs -m
        Write-Debug -Message "Using setx"
    }
}

function Run-Choban {
    $runDoctor = Start-Process $env:chobanPath\chob.exe -ArgumentList "doctor" -wait -Passthru -verb runAs
    if ($runDoctor.HasExited -and ($runDoctor.ExitCode -eq 0)) {
        Write-Host "You can now use the Choban Package Manager. I hope you enjoy it!" -f Green
    }else {
        Write-Host "Cannot run Choban from the 'PATH' environment." -f Red
        Write-Host "Trying to add Choban to 'PATH' enviroment." -f Cyan
        Add-to-Path
        $runDoctor = Start-Process powershell.exe -ArgumentList "$env:programdata\choban\chob.exe doctor; pause" -wait -Passthru -verb runAs
        if ($runDoctor.HasExited -and ($runDoctor.ExitCode -eq 0)) {
            Write-Host "Choban is working fine but you need add Choban package manager to your 'PATH' enviroment" -f Cyan
        }else {
            Write-Host "Installation was not success" -f Red
            Write-Host $runDoctor.ExitCode
        }
    }
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
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest $url -Out $outPath

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

if (!(Test-Path $path)){
    New-Item -ItemType Directory -Force -Path $path
    Write-Host "Created directory $path " -f green
}


if (checkArch){
    $pythonUrl = "https://www.python.org/ftp/python/3.6.5/python-3.6.5-amd64.exe"
}else {
    $pythonUrl = "https://www.python.org/ftp/python/3.6.5/python-3.6.5.exe"
}
$chobanUrl = "https://github.com/cchoban/chob/releases/download/0.6.3/chob.zip"

if(!(Test-Path $path"\python3.exe") -and !(Test-Path $path"\chob.zip"))
{
    Write-Host "Downloading Python 3 from $pythonUrl..." -f cyan
    downloadFile -url $pythonUrl -outPath $scriptRoot\.choban\python3.exe
	Write-Host "Downloading Choban from $chobanUrl..." -f cyan
    downloadFile -url $chobanUrl -outPath $scriptRoot\.choban\chob.zip
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

Add-To-Path

$cobanPath = "$path\choban\programData\"
if ((Test-Path $env:programdata\choban)) {
    Remove-Item $env:programdata\choban -Force -Recurse
}

Move-Item -Path $cobanPath -Destination "$env:programdata\choban"

Write-Host "Removing Junk files.." -f cyan
Write-Host "You may need to restart your shell to get it run." -f Yellow
Write-Host "Sucessfully installed Choban" -f Green
Remove-Item $path -Force -Recurse
Run-Choban

pause
