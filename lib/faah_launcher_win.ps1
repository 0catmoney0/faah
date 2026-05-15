param(
    [Parameter(Mandatory=$true)][string]$VideoPath
)

# Mutex global : une seule fenetre a la fois
$mutexName = 'Global\FaahVideoLock_v1'
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) { exit 0 }

try {
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
    try { $mutex.ReleaseMutex() } catch {}
    try { $mutex.Dispose() } catch {}
}
