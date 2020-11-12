# AutoDetectDebugging

## How to use this script
**Step1**: Download this script to your Computer 

**Step2**: Open Powershell to locate the folder where the script is

- For Windows, you can open Powershell directly. 

- For Mac, you need to install Powershell first, please refer to this doc for installation: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos?view=powershell-7

**Step3**: Run `.\AutoDetectDebugging.ps1 -Email {yourTestEmailAddress}`

**For example**: `.\AutoDetectDebugging.ps1 -Email "test@contoso.com"`

## For Hybrid Exchange accounts

You can also run the command with additional params like this:

`.\AutoDetectDebugging.ps1 -Email {yourTestEmailAddress} -Hybrid` 

### `-Hybrid`

`.\AutoDetectDebugging.ps1 -Email {yourTestEmailAddress} -Hybrid` 

`-Hybrid` will call the On-Prem AutoDiscover endpoint additonally.

**For example:** `.\AutoDetectDebugging.ps1 -Email "hybrid@contoso.com" -Hybrid`

`.\AutoDetectDebugging.ps1 -Email {yourTestEmailAddress} -Hybrid -CustomAutoD {theHostnameOfCustomAutoDiscover}` 

### `-CustomAutoD`

`.\AutodetectDebugging.ps1 -Email {yourTestEmailAddress} -Hybrid -CustomAutoD {theHostnameOfCustomAutoDiscover}` 

`-CustomAutoD {theHostnameOfCustomAutoDiscover}` allows you specificing the custom OnPrem AutoDiscover Hostname.

**For example：** `.\AutoDetectDebugging.ps1 -Email "hybrid@contoso.com" -Hybrid -CustomAutoD "autodiscover.contoso.com"`

NOTE: For `callOnPremAutoDV2` function, it's from https://github.com/tweekerz/PowerShell/tree/master/TestHMAEAS