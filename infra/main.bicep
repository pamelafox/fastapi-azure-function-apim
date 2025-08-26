targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name which is used to generate a short unique hash for each resource')
param name string

// Constrained due to Flex plan limitations
// https://learn.microsoft.com/azure/azure-functions/flex-consumption-how-to#view-currently-supported-regions
@minLength(1)
@description('Primary location for all resources')
@allowed(['australiaeast', 'eastasia', 'eastus', 'eastus2', 'northeurope', 'southcentralus', 'southeastasia', 'swedencentral', 'uksouth', 'westus2', 'eastus2euap'])
@metadata({
  azd: {
    type: 'location'
  }
})
param location string

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param publisherName string

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = { 'azd-env-name': name }

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
  tags: tags
}

// Azure Storage Account name must be between 3 and 24 characters, lowercase, and unique.
// See: https://learn.microsoft.com/azure/storage/common/storage-account-overview#storage-account-name
var storageAccountTokenLength = 5           // Number of characters from resourceToken to use (can be adjusted if needed)
var storageSuffixLength = length('storage') // Length of 'storage'
var storageAccountPrefixLength = 24 - storageAccountTokenLength - storageSuffixLength // Calculated for maintainability
var prefix = '${toLower(take(name, 30))}-${resourceToken}'
var prefixWithoutHyphens = replace(prefix, '-', '')
var functionAppName = '${prefix}-funcapp'
var storageAccountName = '${take(prefixWithoutHyphens, storageAccountPrefixLength)}${take(resourceToken, storageAccountTokenLength)}storage'
var blobContainerName = '${prefixWithoutHyphens}-container'
var apimName = '${prefix}-apim'

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${prefix}-logworkspace'
    applicationInsightsName: '${prefix}-appinsights'
    applicationInsightsDashboardName: 'appinsights-dashboard'
  }
}

// Backing storage for Azure functions backend API
module storageAccount 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: resourceGroup
  params: {
    name: storageAccountName
    location: location
    tags: tags
    containers: [
    {name: blobContainerName}
    ]
  }
}


// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: resourceGroup
  params: {
    name: '${prefix}-plan'
    location: location
    tags: tags
    kind: 'functionapp'
    sku: {
      name: 'FC1'
      tier: 'FlexConsumption'
    }
  }
}

module functionApp 'core/host/functions.bicep' = {
  name: 'function-app'
  scope: resourceGroup
  params: {
    name: functionAppName
    location: location
    tags: union(tags, { 'azd-service-name': 'api' })
    alwaysOn: false
    appSettings: {
      FUNCTIONS_EXTENSION_VERSION: '~4'
      AzureWebJobsStorage__accountName: storageAccount.outputs.name
      AzureWebJobsStorage__blobServiceUri: storageAccount.outputs.primaryEndpoints.blob
      RUNNING_IN_PRODUCTION: 'true'
    }
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.10'
    storageAccountName: storageAccount.outputs.name
    blobContainerName: blobContainerName
  }
}

module diagnostics 'app-diagnostics.bicep' = {
  name: 'function-diagnostics'
  scope: resourceGroup
  params: {
    appName: functionApp.outputs.name
    kind: 'functionapp'
    diagnosticWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// Creates Azure API Management (APIM) service to mediate the requests between the frontend and the backend API
module apim './core/gateway/apim.bicep' = {
  name: 'apim-deployment'
  scope: resourceGroup
  params: {
    name: apimName
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

// Configures the API in the Azure API Management (APIM) service
module apimAPI 'apimanagement.bicep' = {
  name: 'apimanagement-resources'
  scope: resourceGroup
  params: {
    apimServiceName: apim.outputs.apimServiceName
    functionAppName: functionApp.outputs.name
  }
  dependsOn: [
    functionApp
  ]
}


output SERVICE_API_ENDPOINTS array = ['${apimAPI.outputs.apimServiceUrl}/public/docs']
