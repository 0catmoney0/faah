# Installeur FAAH pour Windows (Windows PowerShell 5.1 / PowerShell 7+).
# Usage : iwr -useb https://raw.githubusercontent.com/0catmoney0/faah/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'

$FaahDir   = Join-Path $HOME '.faah'
$LibDir    = Join-Path $FaahDir 'lib'
$MediaDir  = Join-Path $FaahDir 'media'
$Raw       = 'https://raw.githubusercontent.com/0catmoney0/faah/main'

Write-Host "[*] Installation de FAAH dans $FaahDir"

New-Item -ItemType Directory -Force -Path $LibDir   | Out-Null
New-Item -ItemType Directory -Force -Path $MediaDir | Out-Null

# Telecharge les fichiers lib depuis le repo
function Fetch($url, $dst) {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $dst
}

Fetch "$Raw/lib/faah_hook.ps1"         (Join-Path $LibDir 'faah_hook.ps1')
Fetch "$Raw/lib/faah_launcher_win.ps1" (Join-Path $LibDir 'faah_launcher_win.ps1')

# Si aucune video dans media/, telecharge la video par defaut
$existing = Get-ChildItem -Path $MediaDir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -match '^\.(mp4|mkv|webm|mov|avi)$' }
if (-not $existing) {
    Write-Host "[+] Aucune video presente -> telechargement de la video par defaut"
    try { Fetch "$Raw/media/default.mp4" (Join-Path $MediaDir 'default.mp4') } catch {}
}

# Ajoute le hook au profil PowerShell de l'utilisateur
$ProfilePath = $PROFILE.CurrentUserAllHosts
$ProfileDir  = Split-Path -Parent $ProfilePath
if (-not (Test-Path $ProfileDir)) { New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null }
if (-not (Test-Path $ProfilePath)) { New-Item -ItemType File -Force -Path $ProfilePath | Out-Null }

$marker = '# === FAAH hook ==='
$hookLine = ". `"$LibDir\faah_hook.ps1`""

$current = Get-Content -LiteralPath $ProfilePath -Raw -ErrorAction SilentlyContinue
if ($current -and $current.Contains($marker)) {
    Write-Host "[=] Hook deja present dans $ProfilePath"
} else {
    Add-Content -LiteralPath $ProfilePath -Value ""
    Add-Content -LiteralPath $ProfilePath -Value $marker
    Add-Content -LiteralPath $ProfilePath -Value $hookLine
    Write-Host "[+] Hook ajoute a $ProfilePath"
}

# Verifie/repare l'ExecutionPolicy : sans RemoteSigned (ou plus permissif) le profil ne se charge pas
$effective = Get-ExecutionPolicy
$cu = Get-ExecutionPolicy -Scope CurrentUser
$blocking = @('Restricted', 'AllSigned', 'Undefined')
if ($effective -in $blocking) {
    Write-Host ""
    Write-Host "[!] ExecutionPolicy actuelle ($effective) bloque le chargement du profil PowerShell."
    Write-Host "    Sans correctif, FAAH ne marchera pas au prochain demarrage de PowerShell."
    Write-Host ""
    $ans = Read-Host "Activer 'RemoteSigned' au scope CurrentUser maintenant ? [O/n]"
    if ([string]::IsNullOrWhiteSpace($ans) -or $ans -match '^(o|y|oui|yes)$') {
        try {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
            Write-Host "[+] ExecutionPolicy CurrentUser passee a RemoteSigned."
        } catch {
            Write-Host "[!] Echec : $($_.Exception.Message)"
            Write-Host "    Lance manuellement : Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
        }
    } else {
        Write-Host "[!] OK, mais tu devras lancer toi-meme :"
        Write-Host "    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
    }
}

Write-Host ""
Write-Host "[OK] Installation terminee."
Write-Host "    1. Pose ta video dans : $MediaDir\video.mp4 (extension libre)"
Write-Host "    2. Ouvre un nouveau PowerShell pour charger le hook."
Write-Host "    3. Tape une commande inconnue (ex: blabla) pour declencher."
