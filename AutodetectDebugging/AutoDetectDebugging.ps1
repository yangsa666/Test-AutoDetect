param (
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String[]]$SMTP,
    [Switch]$Hybrid,
    [String]$CustomAutoD
)

$SMTPAddress = $SMTP.Split("@")
$headers = @{'Accept' = 'application/json'}

#Get federation provider
function getFederationProvider {
    process{
        try {
            Write-Host
            Write-Host "Calling get fedration pvider serivce to see if it's a sovereign cloud account." -ForegroundColor Yellow
            $getFederationProviderServiceUrl =  "https://odc.officeapps.live.com/odc/v2.1/federationprovider?domain=$($SMTPAddress[1])"
            $getFederationProviderResponse = Invoke-WebRequest -Uri $getFederationProviderServiceUrl -Headers $headers -Method GET
            $getFederationProviderResult = $getFederationProviderResponse.Content | ConvertFrom-Json
            #$environment =  $getFederationProviderResult.environment
            $configProvider = $getFederationProviderResult.configProviderName

            #Check if it returns configProviderName. If not, it should not be a sovereign cloud account.
            #Conitnue with AutoDetect.
            if(!$configProvider) {
                Write-Host
                Write-Host "It's not a sovereign cloud account, continue with AutoDetect." -ForegroundColor Green
                Write-Host
                callAutoDetect
            }
            else {
                switch ($configProvider) {
                    "gcc.microsoftonline.com" { Write-Host "It's detected as a GCC Moderate account." -ForegroundColor Green }
                    "microsoftonline.us" { Write-Host "It's detected as a GCC High account." -ForegroundColor Green }
                    "microsoftonline.mil" { Write-Host "It's detected as a DoD account." -ForegroundColor Green }
                    "partner.microsoftonline.cn" { Write-Host "It's detected as a Gallatin account." -ForegroundColor Green }
                    "microsoftonline.de" { Write-Host "It's detected as a Black Forest account." -ForegroundColor Green }
                }
                getAutoDiscoverUrl
            }
        }
        catch {
            $_.Exception
        }
    }
}


#Call configService to get autoDiscover service Url
function getAutoDiscoverUrl {
    process{
        try{
            Write-Host
            Write-Host "Calling OfficeClient service to discover AutoDiscover URL." -ForegroundColor Yellow
            $configServiceUrl = "https://officeclient.microsoft.com/config16processed?rs=en-us&build=16.0.7612"
            $getAutoDiscoverResponse = Invoke-WebRequest -Uri "$($configServiceUrl)&services=ExchangeAutoDiscoverV2Url,ExchangeWebService&fp=$($configProvider)" -Headers $headers -Method GET
            $getAutoDiscoverResult = $getAutoDiscoverResponse.Content | ConvertFrom-Json
            $autoDiscoverUrl = $getAutoDiscoverResult.'o:OfficeConfig'.'o:services'.'o:service'.'o:url'[1]
            callAutoDiscover
        }
        catch{
            Write-Host $_.Exception
        }
    }
}

#Call AutoDiscover service
function callAutoDiscover {
    process{
        try{
            Write-Host
            Write-Host "Calling AutoDiscover service." -ForegroundColor Yellow
            $requestUrl = "$($autoDiscoverUrl)/v1.0/$($SMTP)?protocol=rest"
            $callAutoDiscover = Invoke-WebRequest -Uri $requestUrl -Headers $headers -Method GET
            $autoDiscoverResult = $callAutoDiscover.Content | ConvertFrom-Json
            $aadDisocverUrl = $autoDiscoverResult.Url 
            discoveryAadAuthority
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
            Write-Host
            Write-Host "Discovering AAD authority." -ForegroundColor Yellow
            $emptyBearerHeader =  @{ 'Authorization' = 'Bearer'}
            $aadDiscoverResponse = Invoke-WebRequest -Uri $aadDisocverUrl -Headers $emptyBearerHeader -Method Options
        }
        catch{
            $exception = $_.Exception
            $authenticateData = $exception.Response.Headers.GetValues("WWW-Authenticate").split(",")
            $value = $authenticateData[3].subString(' authorization_uri="'.Length)
            $aadUrl = $value.substring(0, $value.indexOf('"'))
            Write-Host "Sent an empty Bearer token auth challenge to AAD discover endpoint," -ForegroundColor Yellow
            Write-Host "Found the AAD Authority URL" -ForegroundColor Yellow
            Write-Host "---------------------------------------------------------------------------------------------------------------"
            Write-Host "AAD Authority URL:" $($aadUrl)           
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
                        Write-Host "Autodetect detected this is a Hybrid Exchange acount and it has the following services listed for the user." -ForegroundColor Green
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
                        Write-Host
                        Write-Host "Autodetect detected this is an Office 365 acount and it has the following services listed for the user." -ForegroundColor Green
                        Write-Host "---------------------------------------------------------------------------------------------------------------"
                        Write-Host "Service:     " $autoDetectResult.services.service
                        Write-Host "Protocol:    " $autoDetectResult.services.protocol
                        Write-Host "Hostname:    " $autoDetectResult.services.hostname
                        Write-Host "Azure AD:    " $autoDetectResult.services.aad
                        Write-Host "On-Premises: " $autoDetectResult.services.onprem
                        Write-Host "X-Request-Id:" $requestId
                        Write-Host
                    }
                    else {
                        #If the procotol is not rest, it should be a known account.
                        Write-Host
                        Write-Host "There is no rest protocol detected for this mailbox in Autodetect, but the service provider is Office365"
                        Write-Host "If it's not expected, please contact Outlook Mobile support for help."
                        Write-Host "---------------------------------------------------------------------------------------------------------------"
                        Write-Host "Service:     " $autoDetectResult.services.service
                        Write-Host "Protocol:    " $autoDetectResult.services.protocol
                        Write-Host "Hostname:    " $autoDetectResult.services.hostname
                        Write-Host "Azure AD:    " $autoDetectResult.services.aad
                        Write-Host "On-Premises: " $autoDetectResult.services.onprem
                        Write-Host "X-Request-Id:" $requestId
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
                        Write-Host "Service:     " $autoDetectResult.services.service
                        Write-Host "Protocol:    " $autoDetectResult.services.protocol $autoDetectResult.protocols
                        Write-Host "X-Request-Id:" $requestId
                        Write-Host
                    }
                }
            }
            elseif($autoDetectResponse.StatusCode -eq 202) {
                Write-Host
                Write-Host "No service or protocol found in Autodetect yet, which means there is no record for the domain in autodetect." -ForegroundColor Red
                Write-Host "---------------------------------------------------------------------------------------------------------------"
                Write-Host "Status Code:       " $autoDetectResponse.StatusCode
                Write-Host "Status Description:" $autoDetectResponse.StatusDescription
                Write-Host "X-Request-Id:      " $requestId
                Write-Host
            }
            elseif ($autoDetectResponse.StatusCode -eq 503) {
                Write-Host
                Write-Host "It looks like the service is not avaiable currently, please try again later." -ForegroundColor Red
                Write-Host "If the issue persits, please contact Outlook Mobile support for help." -ForegroundColor Red
                Write-Host "---------------------------------------------------------------------------------------------------------------"
                Write-Host "Status Code:"        $autoDetectResponse.StatusCode
                Write-Host "Status Description:" $autoDetectResponse.StatusDescription
                Write-Host "X-Request-Id:"       $requestId
                Write-Host
            }
            else {
                Write-Host
                Write-Host "Oops...It looks like something went wrong with calling AutoDetect." -ForegroundColor Red
                Write-Host "---------------------------------------------------------------------------------------------------------------"
                Write-Host "Status Code:"        $autoDetectResponse.StatusCode
                Write-Host "Status Description:" $autoDetectResponse.StatusDescription
                Write-Host "X-Request-Id:"       $requestId
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
            Write-Host "If AutoDetect doesn't return On-Prem value for your Hybrid account, please check your firewall and Hybrid configuration," -ForegroundColor Yellow
            Write-Host "to ensure you have allowed traffic from 'outlookmobile.com'." -ForegroundColor Yellow
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

if($Hybrid) {
    callAutoDetect
    callOnPremAutoDV2
}
else {
    getFederationProvider
}