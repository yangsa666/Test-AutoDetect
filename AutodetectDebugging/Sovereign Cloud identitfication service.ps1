param (
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String[]]$SMTP
)
$SMTPAddress = $SMTP.Split("@") 

#Sovereign Cloud identitfication services
$configServiceUrl = "https://officeclient.microsoft.com/config16processed?rs=en-us&build=16.0.7612"
$headers = @{'Accept' = 'application/json'}

#Call configService to get emailHrd service Url
$getFederationProviderEndpoint = Invoke-WebRequest -Uri "$($configServiceUrl)&services=GetFederationProvider" -Headers $headers -Method GET
$obj1 = $getFederationProviderEndpoint.Content | ConvertFrom-Json
$emailHrdUrl = $obj1.'o:OfficeConfig'.'o:services'.'o:service'.'o:url'

#Call configService to get autoDiscover service Url
$getAutoDiscoverEndpoint = Invoke-WebRequest -Uri "$($configServiceUrl)&services=ExchangeAutoDiscoverV2Url" -Headers $headers -Method GET
$obj2 = $getAutoDiscoverEndpoint.Content | ConvertFrom-Json
$autoDiscoverUrl = $obj2.'o:OfficeConfig'.'o:services'.'o:service'.'o:url'

#Call AutoDiscover service
function callAutoDiscover {
    $requestUrl = "$($autoDiscoverUrl)/v1.0/$($SMTP)?protocol=rest"
    Write-Host $requestUrl
    $callAutoDiscover = Invoke-WebRequest -Uri $requestUrl -Headers $headers -Method GET
    $autoDiscoverResult = $callAutoDiscover.Content | ConvertFrom-Json
    $aadDisocverUrl = $autoDiscoverResult.Url
    Write-Host $autoDiscoverResult
    Write-Host $aadDisocverUrl
}

#Discover AAD Authority
function discoveryAadAuthority {
    process{
        try{
            $emptyBearerHeader =  @{ 'Authorization' = 'Bearer'}
            $aadDiscoverResult = Invoke-WebRequest -Uri $aadDisocverUrl -Headers $emptyBearerHeader -Method Options
            $aadUrl = $aadDiscoverResult.Headers
            Write-Host $aadUrl
        }
        catch{
            $Exception = $_.Exception
            
        }
    }
}
#Call AutoDetect service
function callAutoDetect {
    $autoDetectURL = "https://prod-autodetect.outlookmobile.com/detect?protocols=eas,rest-cloud,imap,pop3,smtp&timeout=13.5&services=office365,outlook,google,icloud,yahoo"
    $encodedEmailAddress = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($SMTP))
    $authorizationHeader = @{'Authorization' = "Basic " + $encodedEmailAddress}
    $webResponse1 = Invoke-WebRequest -Uri $autoDetectURL -Headers $authorizationHeader -Method GET
    $autoDetectResult = $webResponse1.Content | ConvertFrom-Json
    $requestId = $webResponse1.Headers.'X-Request-Id'
    Write-Host $autoDetectResult
}

#Call OnPrem AutoDiscoverV2


#Call emailHrd service
$webResponse = Invoke-WebRequest -Uri "$($emailHrdUrl)?domain=$($SMTPAddress[1])" -Headers $headers -Method GET
$emailHrdResult = $webResponse.Content
if(!$emailHrdResult -eq "Global") {
    callAutoDiscover
    Write-Host
    Write-Host "This account is a sovereign cloud user, calling EXO AutoDisocver service"
}
else {
    callAutoDetect
    Write-Host
    Write-Host "This account is not a sovereign cloud user, calling EXO AutoDisocver service"
}

