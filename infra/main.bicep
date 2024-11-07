targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name which is used to generate a short unique hash for each resource')
param name string

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

var prefix = '${name}-${resourceToken}'
var functionAppName = '${take(prefix, 19)}-funcapp'

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
var validStoragePrefix = toLower(take(replace(prefix, '-', ''), 17))
module storageAccount 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: resourceGroup
  params: {
    name: '${validStoragePrefix}storage'
    location: location
    tags: tags
    containers: [
    {name: functionAppName}
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
    name: '${take(prefix, 18)}-function-app-apim'
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
