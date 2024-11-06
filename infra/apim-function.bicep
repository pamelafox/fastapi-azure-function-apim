param functionAppName string
param apiManagementConfigId string

resource functionApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: functionAppName
}

resource functionAppProperties 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'web'
  kind: 'string'
  parent: functionApp
  properties: {
      apiManagementConfig: {
        id: apiManagementConfigId
      }
  }
}
