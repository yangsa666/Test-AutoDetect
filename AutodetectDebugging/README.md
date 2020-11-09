# AutodetectDebugging

## How to use this script
**Step1**: Download this script to your Computer 

**Step2**: Open Powershell to locate the folder where the script is

**Step3**: Run `.\AuodetectDebugging.ps1 -Email {yourTestEmailAddress}`

**For example**: `.\AuodetectDebugging.ps1 -Email "test@contoso.com"`

## For Hybrid Exchange accounts

You can also run the command with additional params like this:
**`-Hybrid`**

`.\AuodetectDebugging.ps1 -Email {yourTestEmailAddress} -Hybrid` 
`-Hybrid` will call the On-Prem AutoDiscover endpoint additonally.

For example: `.\AuodetectDebugging.ps1 -Email "hybrid@contoso.com" -Hybrid`

**`-CustomAutoD`**

`.\AuodetectDebugging.ps1 -Email {yourTestEmailAddress} -Hybrid -CustomAutoD {theHostnameOfCustomAutoDiscover}` 

`-CustomAutoD {theHostnameOfCustomAutoDiscover}` allows you specificing the custom OnPrem AutoDiscover Hostname.

For example：`.\AuodetectDebugging.ps1 -Email "hybrid@contoso.com" -Hybrid -CustomAutoD "autodiscover.contoso.com"`

NOTE: For `callOnPremAutoDV2` function, it's from https://github.com/tweekerz/PowerShell/tree/master/TestHMAEAS
