# AutodetectDebugging

## How to use this script
**Step1**: Download this script to your Computer 

**Step2**: Open Powershell to locate the folder where the script is

**Step3**: Run `.\AuodetectDebugging.ps1 -SMTP {yourTestEmailAddress}`

## For Hybrid Exchange accounts

You can also run the command with additional params like this:

`.\AuodetectDebugging.ps1 -SMTP {yourTestEmailAddress} -Hybrid` 
`-Hybrid` will call the On-Prem AutoDiscover endpoint additonally.

`.\AuodetectDebugging.ps1 -SMTP {yourTestEmailAddress} -Hybrid -CustomAutoD {theHostnameOfCustomAutoDiscover}` 

`-CustomAutoD {theHostnameOfCustomAutoDiscover}` allows you specificing the custom OnPrem AutoDiscover Hostname.

NOTE: For `callOnPremAutoDV2` function, it's from https://github.com/tweekerz/PowerShell/tree/master/TestHMAEAS
