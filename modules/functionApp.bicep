param regions array
param appName string
param subscriptionId string
param rg string

var functions = [for region in regions: {
  name: '${appName}-${region.shortname}-function'
}]

resource hostingPlans 'Microsoft.Web/serverfarms@2020-10-01' = [for region in regions: {
  name: '${appName}-${region.shortname}-sp'
  location: region.name
  sku: {
    name: 'Y1' 
    tier: 'Dynamic'
  }
}]

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = [for (region, i) in regions: {
  name: '${functions[i].name}-insights'
  location: region.name
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
     'hidden-link:/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${functions[i].name}': 'Resource'
  }
}]

resource storageAccounts 'Microsoft.Storage/storageAccounts@2019-06-01' = [for region in regions: {
  name: '${appName}func${region.shortname}storage'
  location: region.name
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
  }
}]

resource functionApps 'Microsoft.Web/sites@2020-06-01' = [for (region, i) in regions: {
  name: '${functions[i].name}'
  location: region.name
  kind: 'functionapp'
  properties: {
    httpsOnly: true
    serverFarmId: hostingPlans[i].id
    siteConfig: {
      appSettings: [
        {
          'name': 'APPINSIGHTS_INSTRUMENTATIONKEY'
          'value': appInsights[i].properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccounts[i].name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccounts[i].id, storageAccounts[i].apiVersion).keys[0].value}'
        }
        {
          'name': 'FUNCTIONS_EXTENSION_VERSION'
          'value': '~3'
        }
        {
          'name': 'FUNCTIONS_WORKER_RUNTIME'
          'value': 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccounts[i].name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccounts[i].id, storageAccounts[i].apiVersion).keys[0].value}'
        }
      ]
    }
  }
}]

output appServices array = [for function in functions : {
  id: '/subscriptions/${subscriptionId}/resourceGroups/${rg}/providers/Microsoft.Web/sites/${function.name}'
  name: function.name
}]
