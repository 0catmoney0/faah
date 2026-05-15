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

function global:Invoke-Faah {
    $elapsedMs = ([DateTime]::UtcNow - $script:FaahLastTriggerUtc).TotalMilliseconds
    if ($elapsedMs -lt $script:FaahCooldownMs) { return }
    if (script:Test-FaahInstanceRunning) { return }

    $video = Get-ChildItem -Path $script:FaahMediaDir -Filter 'video.*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $video) { return }
    if (-not (Test-Path $script:FaahLauncherScript)) { return }

    $script:FaahLastTriggerUtc = [DateTime]::UtcNow
    try {
        Start-Process -WindowStyle Hidden -FilePath 'powershell.exe' -ArgumentList @(
            '-STA', '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:FaahLauncherScript,
            '-VideoPath', $video.FullName
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
