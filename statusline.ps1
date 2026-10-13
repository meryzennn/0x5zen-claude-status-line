$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
function E([int]$cp) { [char]::ConvertFromUtf32($cp) }
$payload = [Console]::In.ReadToEnd()

try {
    $data = $payload | ConvertFrom-Json
    $model = $data.model.display_name
    if (-not $model) { $model = 'model' }

    $context = $data.context_window.used_percentage
    $ctxText = if ($null -eq $context) { '--' } else { '{0}%' -f [math]::Floor([double]$context) }

    # rate_limits only exists for Pro/Max after the first API response
    $five = $data.rate_limits.five_hour
    $rlText = if ($null -eq $five.used_percentage) { '--' } else {
        $left = [math]::Max(0, [long]$five.resets_at - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
        $h = [math]::Floor($left / 3600); $m = [math]::Floor(($left % 3600) / 60)
        $resetIn = if ($h -gt 0) { '{0}h {1}m' -f $h, $m } else { '{0}m' -f $m }
        '{0}% (reset {1})' -f [math]::Floor([double]$five.used_percentage), $resetIn
    }

    $cwd = $data.workspace.current_dir
    if (-not $cwd) { $cwd = $data.cwd }
    $folder = if ($cwd) { Split-Path -Path $cwd -Leaf } else { '--' }

    $branch = ''
    if ($cwd) {
        $branchOutput = & git -C $cwd branch --show-current 2>$null | Select-Object -First 1
        if ($branchOutput) { $branch = $branchOutput.Trim() }
    }
    if (-not $branch) { $branch = '--' }

    # Keep the existing Orca status-line integration working alongside this display.
    $orcaScript = Join-Path $env:USERPROFILE '.orca\agent-hooks\claude-statusline.cmd'
    if (Test-Path -LiteralPath $orcaScript) {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = $env:ComSpec
        $psi.Arguments = '/d /c ""' + $orcaScript + '""'
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo = $psi
        if ($process.Start()) {
            $process.StandardInput.Write($payload)
            $process.StandardInput.Close()
            if (-not $process.WaitForExit(1800)) { $process.Kill() }
            $process.Dispose()
        }
    }

    $esc = [char]27
    # effort is absent when the model doesn't support it
    $effortText = ''
    $level = $data.effort.level
    if ($level) {
        $colors = @{ low = '32'; medium = '94'; high = '91'; xhigh = '35' }
        if ($level -eq 'max') {
            # static rainbow, one truecolor per letter
            $rainbow = @('255;85;85', '255;200;60', '90;170;255')
            $txt = ''
            for ($i = 0; $i -lt $level.Length; $i++) { $txt += '{0}[38;2;{1}m{2}' -f $esc, $rainbow[$i % $rainbow.Length], $level[$i] }
            $effortText = ' {0} {1}{2}[0m' -f [char]0xB7, $txt, $esc
        } else {
            $c = $colors[$level]; if (-not $c) { $c = '0' }
            $effortText = ' {0} {1}[{2}m{3}{1}[0m' -f [char]0xB7, $esc, $c, $level
        }
    }
    Write-Output ('{2}[38;2;217;119;87m{10}{2}[0m {1}{0} | {2}[32mctx: {3}{2}[0m | {4} {5} | {2}[34m{6} {7}{2}[0m | {2}[33m{8} 5h: {9}{2}[0m' -f $effortText, $model, $esc, $ctxText, (E 0x1F4C1), $folder, (E 0xE0A0), $branch, (E 0x23F3), $rlText, (E 0x273B))
} catch {
    Write-Output 'status unavailable'
}
