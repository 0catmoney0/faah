# Desinstalleur FAAH pour Windows.
$ErrorActionPreference = 'Stop'

$FaahDir = Join-Path $HOME '.faah'
$marker  = '# === FAAH hook ==='

Write-Host "[*] Desinstallation de FAAH"

# Retire le hook du profil
$ProfilePath = $PROFILE.CurrentUserAllHosts
if (Test-Path $ProfilePath) {
    $lines = Get-Content -LiteralPath $ProfilePath
    $out = New-Object System.Collections.Generic.List[string]
    $skip = 0
    foreach ($line in $lines) {
        if ($skip -gt 0) { $skip--; continue }
        if ($line -eq $marker) { $skip = 1; continue }
        $out.Add($line)
    }
    Set-Content -LiteralPath $ProfilePath -Value $out
    Write-Host "[-] Hook retire de $ProfilePath"
}

# Supprime le dossier (avec demande pour media/)
if (Test-Path $FaahDir) {
    $ans = Read-Host "Supprimer aussi $FaahDir (avec ta video) ? [y/N]"
    if ($ans -match '^(y|yes)$') {
        Remove-Item -Recurse -Force $FaahDir
        Write-Host "[-] $FaahDir supprime"
    } else {
        Remove-Item -Recurse -Force (Join-Path $FaahDir 'lib') -ErrorAction SilentlyContinue
        Write-Host "[-] $FaahDir\lib supprime (media\ conserve)"
    }
}

Write-Host "[OK] Desinstalle. Ouvre un nouveau PowerShell pour confirmer."
