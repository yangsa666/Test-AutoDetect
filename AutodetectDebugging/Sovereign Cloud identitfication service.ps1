#Sovereign Cloud identitfication services
$configServiceUrl = "https://officeclient.microsoft.com/config16processed?rs=en-us&build=16.0.7612"
$headers = @{'Accept' = 'application/json'}
$getFederationProviderEndpoint = Invoke-WebRequest -Uri "$($configServiceUrl)&services=GetFederationProvider" -Headers $headers -Method GET
$getAutoDiscoverEndpoint = Invoke-WebRequest -Uri "$($configServiceUrl)&services=ExchangeAutoDiscoverV2Url" -Headers $headers -Method GET