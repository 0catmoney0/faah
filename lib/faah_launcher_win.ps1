param(
    [Parameter(Mandatory=$true)][string]$VideoPath
)

# Mutex global : une seule fenetre a la fois
$mutexName = 'Global\FaahVideoLock_v1'
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) { exit 0 }

function script:Pause-OtherMedia {
    # Met en pause toutes les sessions media en cours (Spotify, YouTube, etc.) via WinRT.
    # Windows 10+ requis. Silencieux en cas d'echec.
    try {
        $null = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType=WindowsRuntime]
        $null = [Windows.Foundation.IAsyncOperation`1, Windows.Foundation, ContentType=WindowsRuntime]

        $asTaskGen = ([System.WindowsRuntimeSystemExtensions].GetMethods() |
            Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

        $await = {
            param($op, $resultType)
            $task = $asTaskGen.MakeGenericMethod($resultType).Invoke($null, @($op))
            $task.Wait(2000) | Out-Null
            return $task.Result
        }

        $mgr = & $await ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager])
        if ($null -ne $mgr) {
            foreach ($s in $mgr.GetSessions()) {
                try {
                    if ($s.GetPlaybackInfo().PlaybackStatus -eq 'Playing') {
                        $null = & $await ($s.TryPauseAsync()) ([bool])
                    }
                } catch {}
            }
        }
    } catch {
        # Fallback : touche media play/pause (toggle, moins precis)
        try {
            Add-Type -Name FaahKbd -Namespace WinAPI -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern void keybd_event(byte vk, byte scan, uint flags, uint extra);
"@ -ErrorAction SilentlyContinue
            [WinAPI.FaahKbd]::keybd_event(0xB3, 0, 0, 0)
            [WinAPI.FaahKbd]::keybd_event(0xB3, 0, 2, 0)
        } catch {}
    }
}

try {
    # Pause les autres medias EN PARALLELE (job background) pour ne pas retarder l'affichage
    $pauseJob = $null
    try {
        $pauseJob = Start-Job -ScriptBlock {
            try {
                $null = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType=WindowsRuntime]
                $asTaskGen = ([System.WindowsRuntimeSystemExtensions].GetMethods() |
                    Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
                $await = {
                    param($op, $resultType)
                    $task = $asTaskGen.MakeGenericMethod($resultType).Invoke($null, @($op))
                    $task.Wait(2000) | Out-Null
                    return $task.Result
                }
                $mgr = & $await ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager])
                if ($null -ne $mgr) {
                    foreach ($s in $mgr.GetSessions()) {
                        try { if ($s.GetPlaybackInfo().PlaybackStatus -eq 'Playing') { $null = & $await ($s.TryPauseAsync()) ([bool]) } } catch {}
                    }
                }
            } catch {}
        }
    } catch {
        # Fallback synchrone si Start-Job indispo
        script:Pause-OtherMedia
    }

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Windows.Forms

    $script:Windows = New-Object System.Collections.ArrayList
    $script:App     = New-Object System.Windows.Application
    $script:App.ShutdownMode = 'OnExplicitShutdown'
    $script:Closed  = $false

    function script:CloseAll {
        if ($script:Closed) { return }
        $script:Closed = $true
        foreach ($w in $script:Windows) {
            try { $w.Close() } catch {}
        }
        try { $script:App.Shutdown() } catch {}
    }

    $screens = [System.Windows.Forms.Screen]::AllScreens
    $primaryDone = $false

    foreach ($screen in $screens) {
        $w = New-Object System.Windows.Window
        $w.WindowStyle    = 'None'
        $w.ResizeMode     = 'NoResize'
        $w.Topmost        = $true
        $w.ShowInTaskbar  = $false
        $w.Background     = [System.Windows.Media.Brushes]::Black
        $w.Cursor         = [System.Windows.Input.Cursors]::None
        $w.Left   = $screen.Bounds.Left + 10
        $w.Top    = $screen.Bounds.Top  + 10
        $w.Width  = 200
        $w.Height = 200

        $m = New-Object System.Windows.Controls.MediaElement
        $m.Source         = New-Object System.Uri($VideoPath)
        $m.LoadedBehavior = 'Play'
        $m.Stretch        = 'Uniform'

        if (-not $primaryDone -and $screen.Primary) {
            $m.Volume  = 1.0
            $m.IsMuted = $false
            $m.Add_MediaEnded({ script:CloseAll })
            $m.Add_MediaFailed({ script:CloseAll })
            $primaryDone = $true
        } else {
            $m.Volume  = 0
            $m.IsMuted = $true
        }

        $w.Content = $m
        $w.Add_KeyDown({
            param($s, $e)
            if ($e.Key -eq [System.Windows.Input.Key]::Escape) { script:CloseAll }
        })
        $w.Add_Loaded({ $this.WindowState = 'Maximized' })

        [void]$script:Windows.Add($w)
        $w.Show()
    }

    if (-not $primaryDone -and $script:Windows.Count -gt 0) {
        $firstMedia = $script:Windows[0].Content
        $firstMedia.Volume  = 1.0
        $firstMedia.IsMuted = $false
        $firstMedia.Add_MediaEnded({ script:CloseAll })
        $firstMedia.Add_MediaFailed({ script:CloseAll })
    }

    $safety = New-Object System.Windows.Threading.DispatcherTimer
    $safety.Interval = [TimeSpan]::FromSeconds(15)
    $safety.Add_Tick({ $safety.Stop(); script:CloseAll })
    $safety.Start()

    $script:App.Run() | Out-Null
}
finally {
    try { if ($pauseJob) { Remove-Job -Job $pauseJob -Force -ErrorAction SilentlyContinue } } catch {}
    try { $mutex.ReleaseMutex() } catch {}
    try { $mutex.Dispose() } catch {}
}
