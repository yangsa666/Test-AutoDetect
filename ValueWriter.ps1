function New-IMAPProtocolValue {
    Param(
        [Parameter(Mandatory = $True)]
        [string] $Hostname,

        [Parameter(Mandatory = $True)]
        [string] $Port,

        [Parameter(Mandatory = $False)]
        [string] $Encryption = "ssl",

        [Parameter(Mandatory = $False)]
        [string] $UserName ="{email}" 
    )
    
    Write-Host '[{"protocol":"imap","hostname":"'$Hostname '","port":' $Port ',"encryption":"' $Encryption '","username":"' $Username '"}]'

}