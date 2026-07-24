# ====================================================================
# Kraiiv MVP: Flutter Installation Script for Windows
# ====================================================================

Write-Host "Starting Flutter Setup..." -ForegroundColor Green

# 1. Ensure the C:\src directory exists
$targetDir = "C:\src"
if (-not (Test-Path -Path $targetDir)) {
    Write-Host "Creating $targetDir directory..."
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
}

# 2. Clone the stable Flutter branch using Git
$flutterDir = "$targetDir\flutter"
if (-not (Test-Path -Path $flutterDir)) {
    Write-Host "Cloning the Flutter SDK from GitHub (this may take a few minutes depending on your internet speed)..." -ForegroundColor Yellow
    git clone https://github.com/flutter/flutter.git -b stable $flutterDir
} else {
    Write-Host "Flutter directory already exists at $flutterDir. Skipping download." -ForegroundColor Yellow
}

# 3. Add Flutter to the User PATH if it's not already there
$flutterBin = "$flutterDir\bin"
Write-Host "Checking User PATH environment variable..."
$currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentUserPath -notlike "*$flutterBin*") {
    Write-Host "Adding $flutterBin to User PATH..." -ForegroundColor Yellow
    $newPath = $currentUserPath + ";" + $flutterBin
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added successfully! You will need to restart your terminal eventually to use it globally." -ForegroundColor Green
} else {
    Write-Host "Flutter is already in your PATH." -ForegroundColor Green
}

# 4. Run Flutter Doctor locally in this active session
Write-Host "Setting environment path for the current session..."
$env:Path += ";$flutterBin"

Write-Host "Running 'flutter doctor' to initialize the SDK and check for missing Android Studio toolchains..." -ForegroundColor Cyan
& "$flutterBin\flutter.bat" doctor

Write-Host "======================================================="
Write-Host "Flutter fetching completed! Please read the output of 'flutter doctor' above." -ForegroundColor Green
Write-Host "======================================================="
