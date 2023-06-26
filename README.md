# Azure Monitored Objects
Information how to setup Monitored Objects in Azure for on-premises Win 10/11 (AADJ/HAADH) Clients using the Azure Monitor Agent (AMA)

Via Cloud Shell or PS CLI (logged into your tenant/subscription) run the following command to ensure Monitored Objects are supported in your Cloud Environment.

```console
(Get-AzResourceProvider -ProviderNamespace Microsoft.Insights).ResourceTypes | ? { $_.ResourceTypeName -eq 'monitoredObjects' } | % { Write-Host $_.ResourceTypeName }
```
![image](https://github.com/dcodev1702/azure_monitoredObjects/assets/32214072/477ba43c-0cfa-49e5-b0dd-454099d292b0)

[Microsoft Documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-windows-client)

This is a critical piece the documenation is missing if you're setting up Monitored Objects on Cloud Environments other than Commerical (Azure Cloud).
![AMA Standalone - CLOUDENV](https://github.com/dcodev1702/azure_monitoredObjects/assets/32214072/779718d0-d3b7-452c-9e6d-6ed95f0d7013)
