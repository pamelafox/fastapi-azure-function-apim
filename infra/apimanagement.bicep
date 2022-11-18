param location string
param tags object
param prefix string
param functionAppName string
param functionAppUrl string
param functionAppId string
@secure()
param functionAppKey string
param appInsightsName string
param appInsightsId string
param appInsightsKey string

resource apimService 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
  name: '${prefix}-function-app-apim'
  location: location
  tags: tags
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: 'admin@example.com'
    publisherName: 'API Provider'
  }
}

resource apimBackend 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  parent: apimService
  name: functionAppName
  properties: {
    description: functionAppName
    url: 'https://${functionAppUrl}'
    protocol: 'http'
    resourceId: '${environment().resourceManager}${functionAppId}'
    credentials: {
      header: {
        'x-functions-key': [
          '{{function-app-key}}'
        ]
      }
    }
  }
}

resource apimNamedValuesKey 'Microsoft.ApiManagement/service/namedValues@2021-12-01-preview' = {
  parent: apimService
  name: 'function-app-key'
  properties: {
    displayName: 'function-app-key'
    value: functionAppKey
    tags: [
      'key'
      'function'
      'auto'
    ]
    secret: true
  }
}

resource apimAPI 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  parent: apimService
  name: 'simple-flask-api'
  properties: {
    displayName: 'Simple Flask API'
    apiRevision: '1'
    subscriptionRequired: true
    protocols: [
      'https'
    ]
    path: ''
  }
}

resource apimAPIGet 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  parent: apimAPI
  name: 'generate-name'
  properties: {
    displayName: 'Generate Name'
    method: 'GET'
    urlTemplate: '/generate_name'
  }
}

resource apimModelPredictPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  parent: apimAPIGet
  name: 'policy'
  properties: {
    format: 'xml'
    value: '<policies>\r\n<inbound>\r\n<base />\r\n\r\n<set-backend-service id="apim-generated-policy" backend-id="${functionAppName}" />\r\n<cache-lookup vary-by-developer="false" vary-by-developer-groups="false" allow-private-response-caching="false" must-revalidate="false" downstream-caching-type="none" />\r\n<rate-limit calls="20" renewal-period="90" remaining-calls-variable-name="remainingCallsPerSubscription" />\r\n<cors allow-credentials="false">\r\n<allowed-origins>\r\n<origin>*</origin>\r\n</allowed-origins>\r\n<allowed-methods>\r\n<method>GET</method>\r\n<method>POST</method>\r\n</allowed-methods>\r\n</cors>\r\n</inbound>\r\n<backend>\r\n<base />\r\n</backend>\r\n<outbound>\r\n<base />\r\n<cache-store duration="3600" />\r\n</outbound>\r\n<on-error>\r\n<base />\r\n</on-error>\r\n</policies>'
  }
}

/* Logging*/

resource namedValueAppInsightsKey 'Microsoft.ApiManagement/service/namedValues@2021-01-01-preview' = {
  parent: apimService
  name: 'logger-credentials'
  properties: {
    displayName: 'logger-credentials'
    value: appInsightsKey
    secret: true
  }
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2021-12-01-preview' = {
  parent: apimService
  name: appInsightsName
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: '{{logger-credentials}}'
    }
    isBuffered: true
    resourceId: appInsightsId
  }
  dependsOn: [
    namedValueAppInsightsKey
  ]
}

resource apimAPIDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2021-12-01-preview' = {
  parent: apimAPI
  name: 'applicationinsights'
  properties: {
    alwaysLog: 'allErrors'
    loggerId: apimLogger.id
  }
}

output apimServiceID string = apimService.id
