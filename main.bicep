param rg string
param subscriptionId string
param appName string
param regions array

module functionApp 'modules/functionApp.bicep' = {
  name: 'functionApp'
  params: {
    appName: appName
    regions: regions
    rg: rg
    subscriptionId: subscriptionId
  }
}

module trafficManager 'modules/trafficManager.bicep' = {
  name: 'trafficManager'
  params: {
    appName: appName
    appServices: functionApp.outputs.appServices
  }

  dependsOn: [
    functionApp
  ]
}
