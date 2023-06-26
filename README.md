# Azure Monitored Objects
Information how to setup Monitored Objects in Azure for on-premises Win 10/11 (AADJ/HAADH) Clients using the Azure Monitor Agent (AMA)

Via Cloud Shell or PS CLI (logged into your tenant/subscription) run the following command to ensure Monitored Objects are supported in your Cloud Environment.

```console
(Get-AzResourceProvider -ProviderNamespace Microsoft.Insights).ResourceTypes | ? { $_.ResourceTypeName -eq 'monitoredObjects' } | % { Write-Host $_.ResourceTypeName }
```
![image](https://github.com/dcodev1702/azure_monitoredObjects/assets/32214072/477ba43c-0cfa-49e5-b0dd-454099d292b0)

