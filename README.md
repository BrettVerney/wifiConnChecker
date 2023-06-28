# Wifi Connection Checker

PowerShell script used to check and log Wi-Fi connection information.

<b>Author:</b> Brett Verney
<b>Version:</b> v0.1 | 28-06-2023

## Introduction

This is a PowerShell script that retrieves and logs wireless connection information at regular intervals. It retrieves information including the SSID, BSSID, channel, frequency, and signal strength every second. If the network is not yet identified or if there is no current connection, this is also logged. The results are written to a log file located in the directory from which the script was run.

## Use Cases

The Wifi Connection Checker script is a versatile tool with several practical use cases. It's particularly useful in environments where you have multiple access points and want to monitor which one a client roams to and at what time. By logging the BSSID, you can pinpoint exactly when and to which access point a client connects. The script is also a valuable tool for studying your wireless environment and gaining insight into the frequency bands and channels that are being used over time. With its ability to log the frequency and channel, you can observe trends, identify overcrowded channels, or spot any unusual activity. Furthermore, the signal strength logging can help you understand the coverage areas of your wireless setup and identify any potential weak spots. Whether you're a network administrator seeking to optimize your wireless network or a curious user looking to understand your wireless environment better, this script can provide valuable insights.


## Prerequisites

- Microsoft Windows
- PowerShell
- Administrative rights to PowerShell

## Usage

1. Open PowerShell with administrative rights.
2. Navigate to the directory containing `WifiConnCheck.ps1`.
3. Run the script:

    ```powershell
    .\WifiConnCheck.ps1
    ```
	
Note: If you see an error message like "File cannot be loaded because the execution of scripts is disabled on this system", you need to enable PowerShell script execution by running wither of the following commands in an elevated PowerShell session:

<b>Bypass the default execution policy for the current user:</b><br>
`Set-ExecutionPolicy Bypass -Scope CurrentUser -Force`

<b>Bypass the execution policy for the current PowerShell session only:</b><br>
`Set-ExecutionPolicy Bypass -Scope Process -Force`

This will allow scripts to be executed on your computer.

## Disclaimer

Although this script has been thoroughly tested, I am not responsible for any disruptions, problems, data loss, or other negative effects that might arise from its use. Please use it responsibly and ensure you understand its operation before running it in a critical environment.



