<#
.SYNOPSIS
    Simple Wi-Fi logger (SSID, BSSID, channel, MHz, RSSI dBm) using netsh.

.DESCRIPTION
    - Calls `netsh wlan show interfaces` once per interval (no fancy parsing beyond what we need).
    - Writes timestamped lines with SSID, BSSID, channel, frequency (MHz), and RSSI (dBm).
    - Stops after IterationLimit, or runs until Ctrl+C when IterationLimit = 0.

.USAGE
    .\wifiConnChecker.ps1 [-IterationLimit 0] [-IntervalSeconds 1]

.NOTES
    File Name   : wifiConnChecker.ps1
    Author      : Brett Verney (@WiFiWizardOfOz)
    Version     : 3.0
#>

param(
    [int]$IterationLimit = 0,  # 0 = run until stopped
    [int]$IntervalSeconds = 1
)

function Log($message) {
    Add-Content $script:LogFilePath $message
    Write-Output $message
}

function Get-FrequencyMHz($channel) {
    $parsed = 0
    if (-not [int]::TryParse($channel, [ref]$parsed)) { return "Unknown" }
    if ($parsed -ge 1 -and $parsed -le 14) { return 2407 + ($parsed - 1) * 5 }   # 2.4 GHz
    if ($parsed -ge 32 -and $parsed -le 177) { return 5000 + $parsed * 5 }       # 5 GHz
    if ($parsed -ge 1 -and $parsed -le 233) { return 5950 + ($parsed - 1) * 5 }  # 6 GHz (basic)
    return "Unknown"
}

function Get-WirelessInfo {
    $netshOutput = netsh wlan show interfaces 2>&1
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    $ssidRegex = '^\s*SSID\s+:\s+(?!.*BSSID)(.+)$'
    $bssidRegex = '^\s*BSSID\s+:\s+(\b([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b)'
    $channelRegex = '^\s*Channel\s+:\s+(\d+)'
    $signalRegex = '^\s*Signal\s+:\s+(\d+)%'

    $ssidMatch = $netshOutput | Select-String -Pattern $ssidRegex | Select-Object -First 1
    $bssidMatch = $netshOutput | Select-String -Pattern $bssidRegex | Select-Object -First 1
    $channelMatch = $netshOutput | Select-String -Pattern $channelRegex | Select-Object -First 1
    $signalMatch = $netshOutput | Select-String -Pattern $signalRegex | Select-Object -First 1

    if (-not $ssidMatch -or -not $bssidMatch -or -not $channelMatch -or -not $signalMatch) {
        return $null
    }

    $ssid = $ssidMatch.Matches[0].Groups[1].Value.Trim()
    $bssid = $bssidMatch.Matches[0].Groups[1].Value.Trim()
    $channel = $channelMatch.Matches[0].Groups[1].Value.Trim()
    $signal = $signalMatch.Matches[0].Groups[1].Value.Trim()

    $freq = Get-FrequencyMHz $channel
    $rssiDbm = (($signal / 2) - 100)

    [pscustomobject]@{
        Ssid      = $ssid
        Bssid     = $bssid
        Channel   = $channel
        Frequency = $freq
        RssiDbm   = $rssiDbm
        SignalPct = [int]$signal
        Band      = if ($freq -is [int] -or $freq -is [double]) {
            if ($freq -ge 5955) { "6 GHz" }
            elseif ($freq -ge 5000) { "5 GHz" }
            elseif ($freq -ge 2400) { "2.4 GHz" }
            else { "Unknown band" }
        } else { "Unknown band" }
    }
}

$logFileName = "WifiConnCheck_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
$script:LogFilePath = Join-Path $PWD.Path $logFileName

Log "`n==================== Wi-Fi Logger started @ $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss tt') ====================`n"

$iteration = 0
while ($IterationLimit -le 0 -or $iteration -lt $IterationLimit) {
    $iteration++
    $timestamp = Get-Date -Format "ddd MMM dd yyyy hh:mm:ss tt"

    $info = Get-WirelessInfo
    if (-not $info) {
        Log "[$timestamp] No Wi-Fi connection detected."
    } else {
        $rssiRounded = "{0:F1}" -f $info.RssiDbm
        Log "[$timestamp] Connected via $($info.Bssid) to Network '$($info.Ssid)' | $($info.Band) (ch $($info.Channel) - $($info.Frequency) MHz) | RSSI $rssiRounded dBm"
    }

    Start-Sleep -Seconds $IntervalSeconds
}

Log "`n==================== Wi-Fi Logger stopped @ $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss tt') ====================`n"
