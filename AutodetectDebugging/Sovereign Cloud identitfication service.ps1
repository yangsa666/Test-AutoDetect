param (
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String[]]$SMTP,
    [Switch]$Hybrid,
    [String]$CustomAutoD
)

$SMTPAddress = $SMTP.Split("@") 
$headers = @{'Accept' = 'application/json'}

#Call configService to get autoDiscover service Url
function getAutoDiscoverUrl {
    $configServiceUrl = "https://officeclient.microsoft.com/config16processed?rs=en-us&build=16.0.7612"
    $getAutoDiscoverResponse = Invoke-WebRequest -Uri "$($configServiceUrl)&services=ExchangeAutoDiscoverV2Url" -Headers $headers -Method GET
    $getAutoDiscoverResult = $getAutoDiscoverResponse.Content | ConvertFrom-Json
    $autoDiscoverUrl = $getAutoDiscoverResult.'o:OfficeConfig'.'o:services'.'o:service'.'o:url'    
}

#Call AutoDiscover service
function callAutoDiscover {
    process{
        try{
            $requestUrl = "$($autoDiscoverUrl)/v1.0/$($SMTP)?protocol=rest"
            Write-Host $requestUrl
            $callAutoDiscover = Invoke-WebRequest -Uri $requestUrl -Headers $headers -Method GET
            $autoDiscoverResult = $callAutoDiscover.Content | ConvertFrom-Json
            $aadDisocverUrl = $autoDiscoverResult.Url
            Write-Host $autoDiscoverResult
            Write-Host $aadDisocverUrl
        }
        catch{
            Write-Host $_.Exception
        }
    }
}

#Discover AAD Authority
function discoveryAadAuthority {
    process{
        try{
            $emptyBearerHeader =  @{ 'Authorization' = 'Bearer'}
            $aadDiscoverResponse = Invoke-WebRequest -Uri $aadDisocverUrl -Headers $emptyBearerHeader -Method Options
        }
        catch{
            $exception = $_.Exception
            $authenticateData = $exception.Response.Headers.GetValues(5).split(",")
            $value = $authenticateData[3].subString(' authorization_uri="'.Length)
            $aadUrl = $value.substring(0, $value.indexOf('"'))
            Write-Host
            Write-Host "Sent an empty Bearer token auth challenge to AAD discover endpoint,"
            Write-Host "got the AAD authorize Url: $($aadUrl)"            
        }
    }
}
#Call AutoDetect service
function callAutoDetect {
    process{
        try{
            $autoDetectURL = "https://prod-autodetect.outlookmobile.com/detect?protocols=eas,rest-cloud,imap,pop3,smtp&timeout=13.5&services=office365,outlook,google,icloud,yahoo"
            $encodedEmailAddress = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($SMTP))
            $authorizationHeader = @{'Authorization' = "Basic " + $encodedEmailAddress}
            $autoDetectResponse = Invoke-WebRequest -Uri $autoDetectURL -Headers $authorizationHeader -Method GET
            $autoDetectResult = $autoDetectResponse.Content | ConvertFrom-Json
            $requestId = $autoDetectResponse.Headers.'X-Request-Id'
            #Write-Host $autoDetectResult
            if($autoDetectResponse.StatusCode -eq 200 ) {
                #Check if the service is Office365, if not, it needs to contact OM PG to change it
                if($autoDetectResult.services.service -eq "office365"){
                    #Check if it returns expected onprem EAS URL in the response
                    if(!!$autoDetectResult.services.onprem) {
                        #If it's true, it means autodetect works fine and got the EAS endpoint from AutoDv2. Output AutoDetect response.
                        Write-Host
                        Write-Host "Autodetect detected this is a MOPCC acount and it has the following services listed for the user." -ForegroundColor Green
                        Write-Host "This should have AAD pointing to Microsoft Online and On-Premises to the correct EAS URL." -ForegroundColor Yellow
                        Write-Host "---------------------------------------------------------------------------------------------------------------"
                        Write-Host "Service:    " $autoDetectResult.services.service
                        Write-Host "Protocol:   " $autoDetectResult.services.protocol
                        Write-Host "Hostname:   " $autoDetectResult.services.hostname
                        Write-Host "Azure AD:   " $autoDetectResult.services.aad
                        Write-Host "On-Premises:" $autoDetectResult.services.onprem
                        Write-Host "X-Request-Id:" $requestId
                        Write-Host
                    }
                    elseif ($autoDetectResult.services.protocol -eq "rest") {
                        #If it's true, it means it's detected as O365 account.

                    }
                    else {
                        #If the procotol is not rest, it should be a known account.
                        Write-Host
                        Write-Host "There is no record for this mailbox detected in Autodetect. If it's not expected, please contact Outlook Mobile support for help."
                        Write-Host
                    }
                }
                else {
                    #If autoDetect doesn't return services, use protocols to recognize account type.
                    if(!$autoDetectResult.services.service) {
                            Write-Host
                            Write-Host "Autodetect detected this account as a (an)" $autoDetectResult.protocols.protocol "account, if it's not expected, please contact Outlook Mobile Support to fix it." -ForegroundColor Green
                            Write-Host "---------------------------------------------------------------------------------------------------------------"
                            Write-Host "Protocol:   " $autoDetectResult.protocols
                            Write-Host "X-Request-Id:" $requestId
                            Write-Host
                    }
                    else {
                        #If autoDetect return services, use services to recognize account type.
                        Write-Host
                        Write-Host "Autodetect detected this account as a (an)" $autoDetectResult.services.service "account, if it's not expected, please contact Outlook Mobile Support to fix it." -ForegroundColor Green
                        Write-Host "---------------------------------------------------------------------------------------------------------------"
                        Write-Host "Service:    " $autoDetectResult.services.service
                        Write-Host "Protocol:   " $autoDetectResult.services.protocol $autoDetectResult.protocols
                        Write-Host "X-Request-Id:" $requestId
                        Write-Host
                    }
                }
            }
            else {
                Write-Host
                Write-Host "Oops...It looks like something went wrong with calling AutoDetect." -ForegroundColor Red
                Write-Host "---------------------------------------------------------------------------------------------------------------"
                Write-Host "Status Code:"        $webResponse1.StatusCode
                Write-Host "Status Description:" $webResponse1.StatusDescription
                Write-Host "X-Request-Id:"       $webResponse1.Headers.'X-Request-Id'
                Write-Host
            }

        }
        catch{
            Write-Host $_.Exception
        }
    }
}

#Call OnPrem AutoDiscoverV2
function callOnPremAutoDV2 {
    process {
        try {
            if ($CustomAutoD) {
                $onPremAutoDV2Url = "https://$($CustomAutoD)/autodiscover/autodiscover.json?Email=$($SMTP)&Protocol=activesync&RedirectCount=3"
            }
            else {
                $onPremAutoDV2Url = "https://autodiscover.$($SMTPAddress[1])/autodiscover/autodiscover.json?Email=$($SMTP)&Protocol=activesync&RedirectCount=3"
            }
            $headers = @{
                'Accept'         = 'application/json'
                'Content-Length' = '0'
            }
            $onPremAutoDV2Response = Invoke-WebRequest -Uri $onPremAutoDV2Url -Headers $headers -Method GET
            $onPremAutoDV2Result = $onPremAutoDV2Response.Content | ConvertFrom-Json
            Write-Host
            Write-Host "We sent an AutoDiscover Request to On-Premises for the Exchange ActiveSync Virtual Directory and below is the response" -ForegroundColor Green
            Write-Host "The response should contain the Protocol ActiveSync with a valid URL" -ForegroundColor Yellow
            Write-Host "---------------------------------------------------------------------------------------------------------------"
            Write-Host $onPremAutoDV2Result.Url
            Write-Host
        }
        catch [System.Net.Sockets.SocketException] {
            Write-Host
            Write-Host "We sent an AutoDiscover Request to On-Premises for the Exchange ActiveSync Virtual Directory and below is the response" -ForegroundColor Green
            Write-Host "The response should contain the Protocol ActiveSync with a valid URL" -ForegroundColor Yellow
            Write-Host "---------------------------------------------------------------------------------------------------------------"
            Write-Host "ERROR: We were unable to complete the AutoDiscover request." -ForegroundColor Red -Verbose
            Write-Host "Please ensure that autodiscover.$($SMTPAddress[1]) is the correct AutoDiscover endpoint and is not being blocked by a firewall" -ForegroundColor Yellow -Verbose
            Write-Host
        }
        catch [System.Net.WebException] {
            Write-Host
            Write-Host "We sent an AutoDiscover Request to On-Premises for the Exchange ActiveSync Virtual Directory and below is the response" -ForegroundColor Green
            Write-Host "The response should contain the Protocol ActiveSync with a valid URL" -ForegroundColor Yellow
            Write-Host "---------------------------------------------------------------------------------------------------------------"
            Write-Host "ERROR: We were unable to complete the AutoDiscover request." -ForegroundColor Red -Verbose
            Write-Host "Please ensure that autodiscover.$($SMTPAddress[1]) is the correct AutoDiscover endpoint and is able to be resolved in DNS" -ForegroundColor Yellow -Verbose
            Write-Host
        }        
        catch {
            Write-Host
            Write-Error $_.Exception.Message
            Write-Host            
        }
    }
}

#Get federation provider
function getFederationProvider {
    process{
        try {
            $getFederationProviderServiceUrl =  "https://odc.officeapps.live.com/odc/v2.1/federationprovider?domain=$($SMTPAddress[1])"
            $getFederationProviderResponse = Invoke-WebRequest -Uri $getFederationProviderServiceUrl -Headers $headers -Method GET
            $getFederationProviderResult = $getFederationProviderResponse.Content | ConvertFrom-Json
            #$environment =  $getFederationProviderResult.environment
            $configProvider = $getFederationProviderResult.configProviderName

            #Check if it returns configProviderName. If not, it should not be a sovereign cloud account.
            #Conitnue with AutoDetect.
            if(!$configProvider) {
                Write-Host
                Write-Host "It's not a sovereign cloud account, continue with AutoDetect."
                Write-Host
                callAutoDetect
            }
            else {
                switch ($environ) {
                    "gcc.microsoftonline.com" { Write-Host "It's detected as a GCC Moderate account." }
                    "microsoftonline.us" { Write-Host "It's detected as a GCC High account." }
                    "microsoftonline.mil" { Write-Host "It's detected as a DoD account." }
                    "partner.microsoftonline.cn" { Write-Host "It's detected as a Gallatin account." }
                    "microsoftonline.de" { Write-Host "It's detected as a Black Forest account." }
                }
                callAutoDiscover
            }
        }
        catch {
            $_.Exception
        }
    }
}

if($Hybrid){
    callAutoDetect
    callOnPremAutoDV2
}
else {
    getFederationProvider
}