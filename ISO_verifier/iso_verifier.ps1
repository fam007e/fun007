param (
    [string]$isoFilePath
)

function Import-Public-Key {
    param (
        [string]$email
    )
    gpg --auto-key-locate clear,wkd -v --locate-external-key $email
}

function Verify-With-Sig {
    param (
        [string]$isoFilePath,
        [string]$sigFilePath
    )
    if (!(Get-Command gpg -ErrorAction SilentlyContinue)) {
        Write-Error "GPG is not installed. Please install it from https://gnupg.org/download/index.html"
        return
    }
    gpg --verify $sigFilePath $isoFilePath
    if ($LASTEXITCODE -eq 0) {
        Write-Output "Verification with .sig file succeeded."
    } else {
        Write-Error "Verification with .sig file failed. If the error is 'No public key', please import the public key."
        $sigContent = Get-Content $sigFilePath -Raw
        $emailMatch = $sigContent -match '.*@.*'
        if ($emailMatch) {
            $email = $matches[0]
            Import-Public-Key -email $email
            gpg --verify $sigFilePath $isoFilePath
            if ($LASTEXITCODE -eq 0) {
                Write-Output "Verification with .sig file succeeded after importing the public key."
            } else {
                Write-Error "Verification with .sig file failed even after importing the public key."
            }
        } else {
            Write-Error "Could not extract email from .sig file for public key import."
        }
    }
}

function Verify-With-B2Sums {
    param (
        [string]$isoFilePath,
        [string]$b2sumsFilePath
    )
    if (!(Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Error "Node.js is not installed. Please install it from https://nodejs.org/"
        return
    }
    if (!(Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Error "NPM is not installed. Please ensure NPM is installed with Node.js."
        return
    }
    $blake2Installed = npm list -g | Select-String -Pattern "blake2.wasm"
    if (-not $blake2Installed) {
        Write-Output "Installing blake2.wasm npm package..."
        npm install -g blake2.wasm
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install blake2.wasm. Please ensure npm is installed and try again."
            return
        }
    }

    $expectedHash = (Get-Content $b2sumsFilePath).Trim() -replace "  .*", ""
    $hash = & node -e "
    const fs = require('fs');
    const blake2 = require('blake2.wasm');
    blake2.ready(() => {
        const inputFile = '$isoFilePath';
        const readStream = fs.createReadStream(inputFile);
        const hash = new blake2.Blake2b(64);
        readStream.on('data', chunk => hash.update(chunk));
        readStream.on('end', () => {
            const result = hash.final();
            console.log(Buffer.from(result).toString('hex'));
        });
    });
    " | Out-String
    $hash = $hash.Trim()

    if ($hash -eq $expectedHash) {
        Write-Output "BLAKE2 verification succeeded."
    } else {
        Write-Error "BLAKE2 verification failed."
    }
}

function Verify-With-Sha256Sums {
    param (
        [string]$isoFilePath,
        [string]$sha256sumsFilePath
    )
    $hash = Get-FileHash -Algorithm SHA256 $isoFilePath
    $hashString = $hash.Hash.ToLower()
    $expectedHash = Get-Content $sha256sumsFilePath | Select-String -Pattern $hashString

    if ($expectedHash) {
        Write-Output "SHA-256 verification succeeded."
    } else {
        Write-Error "SHA-256 verification failed."
    }
}

function Main {
    param (
        [string]$isoFilePath
    )

    if (!(Test-Path $isoFilePath)) {
        Write-Error "ISO file not found: $isoFilePath"
        return
    }

    $verificationMethod = Read-Host "Select verification method (1: .sig, 2: b2sums.txt, 3: sha256sums.txt, e.g., 1,2 or 1,3):"

    $methods = $verificationMethod -split ","
    foreach ($method in $methods) {
        switch ($method.Trim()) {
            "1" {
                $sigFilePath = Read-Host "Enter the path to the .sig file"
                if (Test-Path $sigFilePath) {
                    Verify-With-Sig -isoFilePath $isoFilePath -sigFilePath $sigFilePath
                } else {
                    Write-Error "Signature file not found: $sigFilePath"
                }
            }
            "2" {
                $b2sumsFilePath = Read-Host "Enter the path to the b2sums.txt file"
                if (Test-Path $b2sumsFilePath) {
                    Verify-With-B2Sums -isoFilePath $isoFilePath -b2sumsFilePath $b2sumsFilePath
                } else {
                    Write-Error "b2sums file not found: $b2sumsFilePath"
                }
            }
            "3" {
                $sha256sumsFilePath = Read-Host "Enter the path to the sha256sums.txt file"
                if (Test-Path $sha256sumsFilePath) {
                    Verify-With-Sha256Sums -isoFilePath $isoFilePath -sha256sumsFilePath $sha256sumsFilePath
                } else {
                    Write-Error "sha256sums file not found: $sha256sumsFilePath"
                }
            }
            default {
                Write-Error "Invalid verification method selected: $method"
            }
        }
    }
}

Main -isoFilePath $isoFilePath
