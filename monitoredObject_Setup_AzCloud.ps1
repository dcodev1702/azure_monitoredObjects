$ResourceGroup = "sec_telem_law_1"                    #Your Resource Group
$DCRName       = "MO-Win1X-Clients-Evtx-DCR"                   #Your Data Collection Rule for Windows (must already exist)
$SetCloudEnv   = @("AzureCloud","AzureUSGovernment")  #Cloud Environment List
$index         = $null

Write-Host "`nGreetings! Please select your cloud environment: " -ForegroundColor Yellow

# Set your cloud environment: (AzureCloud, AzureUSGovernment)
$idx = 0
foreach ($cloud in $SetCloudEnv) {
  Write-Output("{0} -> {1}" -f $idx, $cloud)
  $idx++
}

try {
  $index = Read-Host -Prompt 'Select your cloud environment by entering the index number '
  if ($index.Trim() -eq "") {
      throw "Invalid index entered. Exiting program..."
  }
  $index = [int]$index.Trim()
}
catch [System.FormatException] {
  Write-Host "`nInvalid index entered `"$index`". Exiting script." -ForegroundColor Red
  exit 1
}
catch {
  Write-Host "An unexpected error occurred: $_" -ForegroundColor Red
  exit 1
}

# Login to the selected Azure Cloud Tenant & Environment
if ($index -ge 0 -and $index -lt $SetCloudEnv.Count) {

  Connect-AzAccount -Environment $SetCloudEnv[$index]
  
  #Sets the Azure Cloud Subscription
  $TenantID = (Get-AzTenant).TenantId
  $SubscriptionID = (Get-AzSubscription).SubscriptionId

  #Sets the Azure Cloud Subscription
  Select-AzSubscription -TenantId $TenantID -SubscriptionId $SubscriptionID

  #Sets the Azure Cloud API URL
  $resourceUrl = (Get-AzContext).Environment.ResourceManagerUrl
}else{
  Write-Host "Invalid Cloud Environment selected, exiting script." -ForegroundColor Red
  Exit
}

#Grant Access to User at root scope "/"
$user = Get-AzADUser -UserPrincipalName (Get-AzContext).Account

New-AzRoleAssignment -Scope '/' -RoleDefinitionName 'Owner' -ObjectId $user.Id

#Create Auth Token
$auth = Get-AzAccessToken

$AuthenticationHeader = @{
  "Content-Type" = "application/json"
  "Authorization" = "Bearer " + $auth.Token
}

#0. Validate Data Collection Rule Existence
$requestURL = "$($resourceUrl)subscriptions/$SubscriptionID/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionRules/$DCRName`?api-version=2022-06-01"
$Respond = Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method GET -Verbose
if ($Respond -eq $null) {
  Write-Host "Data Collection Rule $DCRName does not exist. Create DCR before proceeding, exiting script." -ForegroundColor Red
  Exit
}

#1. Assign ‘Monitored Object Contributor’ Role to the operator
$newguid = (New-Guid).Guid
$UserObjectID = $user.Id

$body = @"
  {
      "properties": {
          "roleDefinitionId":"/providers/Microsoft.Authorization/roleDefinitions/56be40e24db14ccf93c37e44c597135b",
          "principalId": `"$UserObjectID`"
      }
  }
"@

$requestURL = "$($resourceUrl)providers/microsoft.insights/providers/microsoft.authorization/roleassignments/$newguid`?api-version=2021-04-01-preview"

Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method PUT -Body $body

##########################
#2. Create Monitored Object

# "location" property value under the "body" section should be the Azure region where the MO object would be stored. It should be the "same region" where you created the Data Collection Rule. This is the location of the region from where agent communications would happen.
$requestURL = "$($resourceUrl)providers/Microsoft.Insights/monitoredObjects/$TenantID`?api-version=2021-09-01-preview"

# TODO: INSERT A CHECK (API CALL) TO VALIDATE $DCRName EXISTS BEFORE PROCEEDING!
$Location   = (Get-AzDataCollectionRule -Name $DCRName -ResourceGroupName $ResourceGroup -WarningAction SilentlyContinue).Location

$body = @"
  {
      "properties":{
          "location":`"$Location`"
      }
  }
"@

$Respond = Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method PUT -Body $body -Verbose
$RespondID = $($Respond.id).Substring(1)

##########################
#3. Associate DCR to Monitored Object
#See reference documentation https://learn.microsoft.com/en-us/rest/api/monitor/data-collection-rule-associations/create?tabs=HTTP
$associationName = "MOAssoc01" #You can define your custom associationname, must change the association name to a unique name, if you want to associate multiple DCR to monitored object

$requestURL = "$($resourceUrl)$RespondId/providers/microsoft.insights/datacollectionruleassociations/$associationName`?api-version=2022-06-01"
$body = @"
  {
      "properties": {
          "dataCollectionRuleId": "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionRules/$DCRName"
      }
  }
"@

Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method PUT -Body $body
