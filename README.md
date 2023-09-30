# Azure Monitored Objects
Information how to setup Monitored Objects in Azure for on-premises Win 10/11 (AADJ/HAADH) Clients using the Azure Monitor Agent (AMA)

Via Cloud Shell or PS CLI (logged into your tenant/subscription) run the following command to ensure Monitored Objects are supported in your Cloud Environment.

```console
(Get-AzResourceProvider -ProviderNamespace Microsoft.Insights).ResourceTypes | ? { $_.ResourceTypeName -eq 'monitoredObjects' } | % { Write-Host $_.ResourceTypeName }
```
![image](https://github.com/dcodev1702/azure_monitoredObjects/assets/32214072/477ba43c-0cfa-49e5-b0dd-454099d292b0)

[Microsoft Documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-windows-client): Windows 10/11 Hosts running the Azure Monitor Agent (standalone)

Create a Data Collection Rule [Windows Events] -- This is where the monitored object will be applied to. <br />
![Data Collection Rule [Windows]](https://github.com/dcodev1702/azure_monitoredObjects/assets/32214072/2bf78e3d-2c0e-4309-9655-c8dd5eb52517)

This is a critical piece of documenation if you're setting up Monitored Objects on Cloud Environments other than Azure Commerical (default). <br />

```console
msiexec /i AzureMonitorAgentClientSetup.msi /qn CLOUDENV="Azure US Gov" DATASTOREDIR="C:\example\folder"
```
![AMA Standalone - CLOUDENV](https://github.com/dcodev1702/azure_monitoredObjects/assets/32214072/b166b3a8-23dd-4f64-93d7-bd11b84d5f2b)
