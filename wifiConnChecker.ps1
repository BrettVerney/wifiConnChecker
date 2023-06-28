<#
.SYNOPSIS
    This script retrieves and logs wireless connection information at regular intervals.

.DESCRIPTION
    The script retrieves wireless connection information including SSID, BSSID, channel, frequency, and signal strength every second.
    If the network is not yet identified or if there is no current connection, this is also logged. The results are written to a .log file located in the directory that the script was run from.


.USAGE
    .\WifiConnCheck.ps1


.NOTES
    File Name  : WifiConnCheck.ps1
    Author     : Brett Verney (@WiFiWizardOfOz)
    Date       : June 28, 2023
    Version    : 1.0
    Prerequisite: Windows 10 (Admin rights required)

.LINK
    Blog: wifiwizardofoz.com
    GitHub: github.com/BrettVerney
#>



function Log($message) {
    Add-Content $logFilePath $message
    Write-Output $message
}

function GetWirelessInfo {
    try {
        $netshOutput = netsh wlan show interfaces refresh
    }
    catch {
        Log "Error when trying to refresh wireless interface information: $_"
        return @("", "", "", "", "")
    }

    # Retrieve the BSSID information using the Netsh command
    $bssidRegexPattern = 'BSSID\s+:\s+(\b([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})\b)'
    $bssidMatches = $netshOutput | Select-String -Pattern $bssidRegexPattern
    $bssid = $bssidMatches.Matches.Groups[1].Value

    # Retrieve the SSID information using the Netsh command
    $ssidRegexPattern = 'SSID\s+:\s+(?!.*BSSID)(.*)'
    $ssidMatches = $netshOutput | Select-String -Pattern $ssidRegexPattern
    $ssid = ($ssidMatches.Matches[0].Value -replace 'SSID\s+:\s+', '').Trim()

    # Retrieve the channel information using the Netsh command
    $channelRegexPattern = 'Channel\s+:\s+(\d+)'
    $channelMatches = $netshOutput | Select-String -Pattern $channelRegexPattern
    $channel = $channelMatches.Matches.Value -replace 'Channel\s+:\s+', ''

    # Calculate the frequency based on the channel
    $frequency = "Unknown"
    if ($channel -match "^([0-9]+)$") {
        $frequency = switch ($channel) {
            {$_ -in 1..14}   {2407 + ($_-1)*5}
            {$_ -in 36, 40, 44, 48, 149, 153, 157, 161} {5170 + ($_-36)*5}
            {$_ -in 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144} {5250 + ($_-52)*5}
            default {"Unknown"}
        }
    } 

    # Retrieve the signal information using the Netsh command
    $signalRegexPattern = 'Signal\s+:\s+([0-9]+)%'
    $signalMatches = $netshOutput | Select-String -Pattern $signalRegexPattern
    $signal = $signalMatches.Matches.Groups[1].Value
    $rssi = "{0:F1}" -f (($signal / 2) - 100)

    # Return the result as an array of five elements
    return @($ssid, $bssid, $channel, $frequency, $rssi)
}

# Set a limit on the number of iterations
$iterationLimit = 1000

# Set the log file path
$logFileName = "WifiConnCheck_$(Get-Date -Format 'yyyy-MM-dd').log"
$logFilePath = Join-Path $PWD.Path $logFileName

Log "`n==================================================== Script Executed @ $(Get-Date -Format 'hh:mm:ss tt') ====================================================`n"

for ($i = 1; $i -le $iterationLimit; $i++) {
    $connectionProfile = Get-NetConnectionProfile
    $connectionProfileName = $connectionProfile.Name
    $timestamp = Get-Date -Format "ddd MMM dd yyyy hh:mm:ss tt"

    if ($connectionProfileName -eq "Identifying...") {
        Log "Identifying Network at $timestamp"
    }
    elseif ($null -ne $connectionProfileName) {
        $ssid, $bssid, $channel, $frequency, $rssi = GetWirelessInfo
        if ($ssid -eq "" -and $bssid -eq "" -and $channel -eq "" -and $frequency -eq "" -and $rssi -eq "") {
        # An error occurred when trying to get wireless info.
        Log "Skipping this iteration due to an error."
        Start-Sleep -Seconds 1
        continue
}
        Log "Connected to network '$ssid' ($bssid) | Channel is $channel ($frequency MHz) | Signal strength is $rssi dBm | $timestamp"
    }
    else {
        Log "Wi-Fi adapter is not connected to a Network at $timestamp"
    }

    # Wait for 1 second before looping again
    Start-Sleep -Seconds 1
}