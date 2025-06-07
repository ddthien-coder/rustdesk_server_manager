# Define variables
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$idServer = "192.168.1.100"                           # Replace with your ID Server IP or domain
$publicKey = "Your_Public_Key_Here"                   # Replace with your RustDesk public key
$configPath = "$env:APPDATA\RustDesk\config\config.json"

# Search for the RustDesk installer in the script directory
$installerPatterns = @("rustdesk-1.3.9-x86_64.msi")
$installerPath = $null
foreach ($pattern in $installerPatterns) {
    $installerPath = Get-ChildItem -Path $scriptDir -Filter $pattern -File | Select-Object -First 1 -ExpandProperty FullName
    if ($installerPath) { break }
}

# Check if the installer file was found
if (-not $installerPath) {
    Write-Host "Error: No RustDesk installer (e.g., RustDesk*.exe or rustdesk-1.3.9-x86_64.msi) found in $scriptDir. Please place the installer in the same folder as this script."
    exit 1
}
Write-Host "Found installer: $installerPath"

# Install RustDesk silently
Write-Host "Installing RustDesk..."
if ($installerPath -like "*.exe") {
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -NoNewWindow
} elseif ($installerPath -like "*.msi") {
    Start-Process -FilePath "msiexec" -ArgumentList "/i `"$installerPath`" /quiet" -Wait -NoNewWindow
}
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to install RustDesk."
    exit 1
}
Write-Host "RustDesk installed successfully."

# Wait for configuration file to be created
Write-Host "Waiting for configuration file to be generated..."
Start-Sleep -Seconds 5

# Check if config file exists, create it if it doesn't
if (-not (Test-Path $configPath)) {
    New-Item -Path $configPath -ItemType File -Force | Out-Null
    $config = @{}
} else {
    # Read existing config file
    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($null -eq $config) {
        $config = @{}
    }
}

# Update or add ID Server and public key
$config | Add-Member -Name "id-server" -Value $idServer -Force
$config | Add-Member -Name "key" -Value $publicKey -Force

# Save the updated config
$config | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8
Write-Host "Configuration updated with ID Server: $idServer and Public Key: $publicKey"

# Restart RustDesk to apply changes
$rustdeskProcess = Get-Process -Name "RustDesk" -ErrorAction SilentlyContinue
if ($rustdeskProcess) {
    Write-Host "Restarting RustDesk..."
    Stop-Process -Name "RustDesk" -Force
    Start-Sleep -Seconds 2
    Start-Process -FilePath "C:\Program Files\RustDesk\RustDesk.exe" -ErrorAction SilentlyContinue
    Write-Host "RustDesk restarted successfully."
} else {
    Write-Host "RustDesk not running. Please start it manually if needed."
}

Write-Host "Installation and configuration completed."