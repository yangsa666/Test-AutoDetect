#Fill MOPCC email address
#Please change the SMPT to be the email address you want to debugging.
#$SMTP = "Rocky1@msftofetesttenant1003.com" ##Example MOPCC account
#$SMTP = "sayang@microsoft.com" ##Example O365 account

#How to use this script
#Step1: Download to your Computer 
#Step2: Open Powershell to locate the folder where the script is
#Step3: Run .\AuodetectDebugging.ps1 -SMTP {theTestEmailAddress}
param (
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String[]]$SMTP
)

function callEXOAutoDv2 {
    process {
        try { 
            $exoAutoDv2URL = "https://outlook.office365.com/autodiscover/autodiscover.json?Email=$($SMTP)&Protocol=activesync"
            $headers = @{'Accept' = 'application/json'}
            $webResponse2 = Invoke-WebRequest -Uri $exoAutoDv2URL -Headers $headers -Method GET
            $jsonResponse2 = $webResponse2.Content | ConvertFrom-Json

            ##If the URL returns "https://outlook.office365.com/Microsoft-Server-ActiveSync", it means EXO considers it's an O365 account.
            if ($jsonResponse2.Url -eq "https://outlook.office365.com/Microsoft-Server-ActiveSync") {
                Write-Host
                Write-Host "We detected this mailbox as an O365 account." -ForegroundColor Green
                Write-Host "If your account is a Hybrid Exchange account, please ensure your Hybrid configuration are setup correctly." -ForegroundColor Yellow
                Write-Host "If your account is not an O365 or Hybrid Exchange account, please contact Outlook Mobile Support for help." -ForegroundColor Yellow
                Write-Host "---------------------------------------------------------------------------------------------------------------"
                Write-Host "Service:    " $jsonResponse1.services.service
                Write-Host "Protocol:   " $jsonResponse1.services.protocol
                Write-Host "Hostname:   " $jsonResponse1.services.hostname
                Write-Host "Azure AD:   " $jsonResponse1.services.aad
                Write-Host "On-Premises:" $jsonResponse1.services.onprem
                Write-Host "X-Request-Id:" $requestId
                Write-Host
            }
            else {
                Write-Host
                Write-Host "We can get EAS URL from EXO, but cannot get it from AutoDetect," -ForegroundColor Red
                Write-Host "please check your Hybrid setup to ensure it allows network traffic from outlookmobile.com" -ForegroundColor Red
                Write-Host "---------------------------------------------------------------------------------------------------------------"
                Write-Host $webResponse2
                Write-Host                  
            }
        }
        catch {
            Write-Host
            Write-Host "There is an issue to do AutoDisocover with your OnPrem server, please check the Onprem configuration with below error message." -ForegroundColor Red
            Write-Error $_.Exception.Message
            Write-Host            
        }
    }
}

#Make a call to AutoDetectAPI
$autoDetectURL = "https://prod-autodetect.outlookmobile.com/detect?protocols=eas,rest-cloud,imap,pop3,smtp&timeout=13.5&services=office365,outlook,google,icloud,yahoo"
$encodedEmailAddress = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($SMTP))
$authorizationHeader = @{'Authorization' = "Basic " + $encodedEmailAddress}
$webResponse1 = Invoke-WebRequest -Uri $autoDetectURL -Headers $authorizationHeader -Method GET
$jsonResponse1 = $webResponse1.Content | ConvertFrom-Json
$requestId = $webResponse1.Headers.'X-Request-Id'

#Check if the reponse is expected for MOPCC accounts
if($webResponse1.StatusCode -eq 200 ) {
    #Check if the service is Office365, if not, it needs to contact OM PG to change it
    if($jsonResponse1.services.service -eq "Office365"){
        
        #Check if it returns expected onprem EAS URL in the response
        if(!$jsonResponse1.services.onprem) {
            if($jsonResponse1.services.protocol -eq "rest") {
            #If it's true, it means autodetect cannot get the EAS endpoint via autoDv2. Needs to call EXO AutoDv2 to check.
            callEXOAutoDv2
            }
            else {
                Write-Host
                Write-Host "There is no record for this mailbox detected in Autodetect. If it's not expected, please contact Outlook Mobile support for help" -ForegroundColor Red
                Write-Host "---------------------------------------------------------------------------------------------------------------"
                Write-Host "X-Request-Id:" $requestId
                Write-Host
            }
        }
        else {
              #If it's false, it means autodetect works fine and got the EAS endpoint from AutoDv2. Output AutoDetect response.
            Write-Host
            Write-Host "Autodetect detected this is a MOPCC acount and it has the following services listed for the user." -ForegroundColor Green
            Write-Host "This should have AAD pointing to Microsoft Online and On-Premises to the correct EAS URL." -ForegroundColor Yellow
            Write-Host "---------------------------------------------------------------------------------------------------------------"
            Write-Host "Service:    " $jsonResponse1.services.service
            Write-Host "Protocol:   " $jsonResponse1.services.protocol
            Write-Host "Hostname:   " $jsonResponse1.services.hostname
            Write-Host "Azure AD:   " $jsonResponse1.services.aad
            Write-Host "On-Premises:" $jsonResponse1.services.onprem
            Write-Host "X-Request-Id:" $requestId
            Write-Host
        }
    }
    else {
        #If autoDetect doesn't return services, use protocols to recognize account type.
        if(!$jsonResponse1.services.service) {
            Write-Host
            Write-Host "Autodetect detected this account as a (an)" $jsonResponse1.protocols.protocol "account, if it's not expected, please contact Outlook Mobile Support to fix it." -ForegroundColor Green
            Write-Host "---------------------------------------------------------------------------------------------------------------"
            Write-Host "Protocol:   " $jsonResponse1.protocols
            Write-Host "X-Request-Id:" $requestId
            Write-Host
        }
        else {
              #If autoDetect return services, use services to recognize account type.
            Write-Host
            Write-Host "Autodetect detected this account as a (an)" $jsonResponse1.services.service "account, if it's not expected, please contact Outlook Mobile Support to fix it." -ForegroundColor Green
            Write-Host "---------------------------------------------------------------------------------------------------------------"
            Write-Host "Service:    " $jsonResponse1.services.service
            Write-Host "Protocol:   " $jsonResponse1.services.protocol $jsonResponse1.protocols
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

    