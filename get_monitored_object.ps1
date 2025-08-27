function Get-ARMTokenString {
    <#
      .SYNOPSIS
        Returns a plain string ARM token for the current Az context.
      .DESCRIPTION
        Wraps Get-AzAccessToken and handles cases where the Token comes back
        as a SecureString. Works across Public and Gov clouds.
    #>
    [CmdletBinding()]
    param()

    # Get current ARM resource URL (works in Public or Gov)
    $resourceUrl = (Get-AzContext).Environment.ResourceManagerUrl

    # Grab token
    $tok = (Get-AzAccessToken -ResourceUrl $resourceUrl).Token

    # If returned as SecureString, convert to plain string
    if ($tok -is [System.Security.SecureString]) {
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($tok)
        try {
            return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        }
        finally {
            if ($bstr -ne [IntPtr]::Zero) {
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            }
        }
    }
    return [string]$tok
}

# Context (assumes you've already Connect-AzAccount'd)
$TenantID       = (Get-AzContext).Tenant.Id
$SubscriptionID = (Get-AzContext).Subscription.Id
$resourceUrl    = (Get-AzContext).Environment.ResourceManagerUrl

# Get the access token and normalize to plain text
$token = Get-ARMTokenString

# Build URL and call
$url = "$($resourceUrl.TrimEnd('/'))/providers/Microsoft.Insights/monitoredObjects/$AADTenantId/providers/microsoft.insights/datacollectionruleassociations?api-version=2021-09-01-preview"

$headers = @{
  Authorization = "Bearer $token"
  Accept        = "application/json"
}

$response = Invoke-WebRequest -Method GET -Uri $url -Headers $headers
if ($response.StatusCode -ne 200) {
  throw "Error: $($response.StatusCode) - $($response.StatusDescription) - $($response.Content)"
}
($response.Content | ConvertFrom-Json)
