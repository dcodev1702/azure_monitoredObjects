$TenantID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  #Your Tenant ID
$SubscriptionID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  #Your Subscription ID
$ResourceGroup  = "YOUR_RG"                               #Your resroucegroup
$DCRName        = "MO-Win10-Evtx-00"                      #Your Data collection rule name
$Location       = "eastus"                                #Use your own loacation
$resourceUrl    = (Get-AzContext).Environment.ResourceManagerUrl

Connect-AzAccount -Tenant $TenantID

#Select the subscription
Select-AzSubscription -SubscriptionId $SubscriptionID

#Grant Access to User at root scope "/"
$user = Get-AzADUser -UserPrincipalName (Get-AzContext).Account

New-AzRoleAssignment -Scope '/' -RoleDefinitionName 'Owner' -ObjectId $user.Id

#Create Auth Token
$auth = Get-AzAccessToken

$AuthenticationHeader = @{
  "Content-Type" = "application/json"
  "Authorization" = "Bearer " + $auth.Token
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

$requestURL = "$resourceUrl/providers/microsoft.insights/providers/microsoft.authorization/roleassignments/$newguid`?api-version=2021-04-01-preview"

Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method PUT -Body $body

##########################
#2. Create Monitored Object

# "location" property value under the "body" section should be the Azure region where the MO object would be stored. It should be the "same region" where you created the Data Collection Rule. This is the location of the region from where agent communications would happen.
$requestURL = "$resourceUrl/providers/Microsoft.Insights/monitoredObjects/$TenantID`?api-version=2021-09-01-preview"
$body = @"
{
    "properties":{
        "location":`"$Location`"
    }
}
"@

$Respond = Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method PUT -Body $body -Verbose
$RespondID = $Respond.id

##########################
#3. Associate DCR to Monitored Object
#See reference documentation https://learn.microsoft.com/en-us/rest/api/monitor/data-collection-rule-associations/create?tabs=HTTP
$associationName = "MOAssoc01" #You can define your custom associationName, must change the association name to a unique name, if you want to associate multiple DCR to monitored object

$requestURL = "$resourceUrl$RespondId/providers/microsoft.insights/datacollectionruleassociations/$associationName`?api-version=2021-09-01-preview"
$body = @"
    {
        "properties": {
            "dataCollectionRuleId": "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionRules/$DCRName"
        }
    }
"@

Invoke-RestMethod -Uri $requestURL -Headers $AuthenticationHeader -Method PUT -Body $body
