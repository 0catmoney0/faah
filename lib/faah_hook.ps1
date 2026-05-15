# FAAH hook for PowerShell
# Dot-source ce fichier depuis ton profil PowerShell.
# Declenche la video sur erreur PowerShell (command not found, parametre invalide, parse error, etc.)

$script:FaahDir            = if ($env:FAAH_DIR) { $env:FAAH_DIR } else { Join-Path $HOME '.faah' }
$script:FaahLauncherScript = Join-Path $script:FaahDir 'lib\faah_launcher_win.ps1'
$script:FaahMediaDir       = Join-Path $script:FaahDir 'media'
$script:FaahMutexName      = 'Global\FaahVideoLock_v1'
$script:FaahCooldownMs     = 10000
$script:FaahLastTriggerUtc = [DateTime]::MinValue
$script:FaahLastErrorRef   = $null

function script:Test-FaahInstanceRunning {
    $createdNew = $false
    try {
        $m = New-Object System.Threading.Mutex($false, $script:FaahMutexName, [ref]$createdNew)
        if (-not $m.WaitOne(0)) { $m.Dispose(); return $true }
        $m.ReleaseMutex(); $m.Dispose(); return $false
    } catch { return $false }
}

function script:Get-FaahVideos {
    Get-ChildItem -Path $script:FaahMediaDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '^\.(mp4|mkv|webm|mov|avi)$' } |
        Sort-Object Name
}

function script:Format-FaahSize {
    param([long]$bytes)
    if     ($bytes -lt 1024)            { return "$bytes B" }
    elseif ($bytes -lt 1048576)         { return ("{0} Ko" -f [math]::Round($bytes / 1024)) }
    elseif ($bytes -lt 1073741824)     { return ("{0} Mo" -f [math]::Round($bytes / 1048576)) }
    else                                { return ("{0:N1} Go" -f ($bytes / 1073741824)) }
}

function script:Get-FaahDuration {
    param([string]$path)
    try {
        $shell  = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace((Split-Path $path -Parent))
        $file   = $folder.ParseName((Split-Path $path -Leaf))
        # Cherche dynamiquement la colonne 'Length' / 'Durée' / 'Longueur'
        for ($i = 0; $i -lt 320; $i++) {
            $colName = $folder.GetDetailsOf($null, $i)
            if ($colName -eq 'Length' -or $colName -eq 'Durée' -or $colName -eq 'Longueur') {
                $val = $folder.GetDetailsOf($file, $i)
                if ($val -match '\d') { return $val.Trim() }
                break
            }
        }
    } catch {}
    return ''
}

# Commande `faah` : interactif, affiche le dossier, liste les videos, permet de choisir la video active
function global:faah {
    $dir        = $script:FaahMediaDir
    $activeFile = Join-Path $script:FaahDir 'active'

    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

    $videos = @(script:Get-FaahVideos)

    Write-Host ""
    Write-Host "Dossier video : $dir"

    if ($videos.Count -eq 0) {
        Write-Host "Aucune video pour le moment."
        Write-Host "Pose un fichier .mp4 / .mkv / .webm dans le dossier ci-dessus, puis retape `"faah`"."
        Write-Host ""
        return
    }

    $current = ""
    if (Test-Path $activeFile) { $current = (Get-Content -Raw $activeFile).Trim() }
    if ($current -and -not (Test-Path (Join-Path $dir $current))) { $current = "" }
    if (-not $current) { $current = $videos[0].Name }

    Write-Host ""
    Write-Host "Videos disponibles :"
    for ($i = 0; $i -lt $videos.Count; $i++) {
        $v        = $videos[$i]
        $size     = script:Format-FaahSize $v.Length
        $duration = script:Get-FaahDuration $v.FullName
        if ($duration -and $size) { $info = " ($duration, $size)" }
        elseif ($duration)        { $info = " ($duration)" }
        elseif ($size)            { $info = " ($size)" }
        else                      { $info = "" }
        if ($v.Name -eq $current) {
            Write-Host ("  {0}) {1}{2}  (active)" -f ($i + 1), $v.Name, $info)
        } else {
            Write-Host ("  {0}) {1}{2}" -f ($i + 1), $v.Name, $info)
        }
    }

    if ($videos.Count -eq 1) {
        Set-Content -LiteralPath $activeFile -Value $current -NoNewline
        Write-Host ""
        Write-Host "[OK] Une seule video : elle est active."
        Write-Host ""
        return
    }

    Write-Host ""
    $choice = Read-Host ("Choisis une video (1-{0}, Entree pour garder `"{1}`")" -f $videos.Count, $current)
    if ([string]::IsNullOrWhiteSpace($choice)) {
        Set-Content -LiteralPath $activeFile -Value $current -NoNewline
        Write-Host "(inchange)"
        Write-Host ""
        return
    }
    $n = 0
    if (-not [int]::TryParse($choice, [ref]$n) -or $n -lt 1 -or $n -gt $videos.Count) {
        Write-Host "Choix invalide."
        Write-Host ""
        return
    }
    $selected = $videos[$n - 1].Name
    Set-Content -LiteralPath $activeFile -Value $selected -NoNewline
    Write-Host "[OK] Video active : $selected"
    Write-Host ""
}

function global:Invoke-Faah {
    $elapsedMs = ([DateTime]::UtcNow - $script:FaahLastTriggerUtc).TotalMilliseconds
    if ($elapsedMs -lt $script:FaahCooldownMs) { return }
    if (script:Test-FaahInstanceRunning) { return }

    # Selectionne la video : 1) fichier 'active' s'il est valide, 2) 1ere video trouvee
    $videoPath  = ''
    $activeFile = Join-Path $script:FaahDir 'active'
    if (Test-Path $activeFile) {
        $activeName = (Get-Content -Raw $activeFile -ErrorAction SilentlyContinue)
        if ($activeName) { $activeName = $activeName.Trim() }
        if ($activeName) {
            $candidate = Join-Path $script:FaahMediaDir $activeName
            if (Test-Path $candidate) { $videoPath = $candidate }
        }
    }
    if (-not $videoPath) {
        $first = script:Get-FaahVideos | Select-Object -First 1
        if ($first) { $videoPath = $first.FullName }
    }
    if (-not $videoPath) { return }
    if (-not (Test-Path $script:FaahLauncherScript)) { return }

    $script:FaahLastTriggerUtc = [DateTime]::UtcNow
    try {
        Start-Process -WindowStyle Hidden -FilePath 'powershell.exe' -ArgumentList @(
            '-STA', '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:FaahLauncherScript,
            '-VideoPath', $videoPath
        ) | Out-Null
    } catch {}
}

# Un seul hook : le prompt. Couvre tous les cas d'erreur shell.
function global:prompt {
    if ($Error.Count -gt 0) {
        $err = $Error[0]
        if (-not [object]::ReferenceEquals($err, $script:FaahLastErrorRef)) {
            $script:FaahLastErrorRef = $err
            $fqid = [string]$err.FullyQualifiedErrorId
            if ($fqid -match 'CommandNotFoundException|ParameterBinding|ParameterArgument|ParserError|InvalidArgument|MissingArgument|AmbiguousParameter') {
                Invoke-Faah
            }
        }
    }
    "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
}
