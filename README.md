# Test-AutoDetect

## How to use this script
**Step1**: Clone this project to your computer: https://github.com/WayneYangsa/Test-AutoDetect.git

**Step2**: Open Powershell to locate the folder where the script is.

- For Windows, you can open Powershell directly. 

- For Mac, you need to install Powershell first, please refer to this doc for installation: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos?view=powershell-7

**Step3**: Run `.\Test-AutoDetect.ps1 -Email {yourTestEmailAddress}`

**For example**: `.\Test-AutoDetect.ps1 -Email "test@contoso.com"`

## For Hybrid Exchange accounts

You can also run the command with additional params like this:

`.\Test-AutoDetect.ps1 -Email {yourTestEmailAddress} -Hybrid` 

### `-Hybrid`

`-Hybrid` will call the On-Prem AutoDiscover endpoint additonally.

**For example:** `.\Test-AutoDetect.ps1 -Email "hybrid@contoso.com" -Hybrid`

`.\Test-AutoDetect.ps1 -Email {yourTestEmailAddress} -Hybrid -CustomAutoD {theHostnameOfCustomAutoDiscover}` 

### `-CustomAutoD`

`.\Test-AutoDetect.ps1 -Email {yourTestEmailAddress} -Hybrid -CustomAutoD {theHostnameOfCustomAutoDiscover}` 

`-CustomAutoD {theHostnameOfCustomAutoDiscover}` allows you specificing the custom OnPrem AutoDiscover Hostname.

**For example：** `.\Test-AutoDetect.ps1 -Email "hybrid@contoso.com" -Hybrid -CustomAutoD "autodiscover.contoso.com"`

### `-TestAutoDV2`

`-TestAutoDV2` allows you to call the On-Prem AutoDiscoverV2 endpoint alone.

**For example:**  `.\Test-AutoDetect.ps1 -Email "hybrid@contoso.com" -TestAutoDV2`

NOTE: For `callOnPremAutoDV2` function, it's from https://github.com/tweekerz/PowerShell/tree/master/TestHMAEAS