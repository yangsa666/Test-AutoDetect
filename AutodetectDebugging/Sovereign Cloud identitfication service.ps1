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



