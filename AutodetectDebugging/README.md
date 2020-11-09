# AutodetectDebugging

## How to use this script
**Step1**: Download this script to your Computer 

**Step2**: Open Powershell to locate the folder where the script is

**Step3**: Run `.\AuodetectDebugging.ps1 -SMTP {yourTestEmailAddress}`

**For example**: `.\AuodetectDebugging.ps1 -SMTP "test@contoso.com"`

## For Hybrid Exchange accounts

You can also run the command with additional params like this:

`.\AuodetectDebugging.ps1 -SMTP {yourTestEmailAddress} -Hybrid` 
`-Hybrid` will call the On-Prem AutoDiscover endpoint additonally.

**For example:** `.\AuodetectDebugging.ps1 -SMTP "hybrid@contoso.com" -Hybrid`

`.\AuodetectDebugging.ps1 -SMTP {yourTestEmailAddress} -Hybrid -CustomAutoD {theHostnameOfCustomAutoDiscover}` 

`-CustomAutoD {theHostnameOfCustomAutoDiscover}` allows you specificing the custom OnPrem AutoDiscover Hostname.

**For example：** `.\AuodetectDebugging.ps1 -SMTP "hybrid@contoso.com" -Hybrid -CustomAutoD "autodiscover.contoso.com"`

NOTE: For `callOnPremAutoDV2` function, it's from https://github.com/tweekerz/PowerShell/tree/master/TestHMAEAS
