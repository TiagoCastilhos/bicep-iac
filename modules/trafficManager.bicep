param appName string
param appServices array

var profileName = '${appName}-tmp'

resource trafficManagerProfile 'Microsoft.Network/trafficManagerProfiles@2018-04-01' = {
  name: profileName
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Performance'
    dnsConfig: {
      relativeName: profileName
      ttl: 60
    }
    monitorConfig: {
      profileMonitorStatus: 'Online'
      protocol: 'HTTPS'
      port: 443
      path: '/'
      intervalInSeconds: 30
      toleratedNumberOfFailures: 1
      timeoutInSeconds: 5
      expectedStatusCodeRanges: [
        {
          min: 200
          max: 299
        }
      ]
    }
    endpoints: [for appService in appServices: {
      name: appService.name
      type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
      properties: {
        endpointStatus: 'Enabled'
        endpointMonitorStatus: 'Online'
        targetResourceId: appService.id
      }
    }]
    trafficViewEnrollmentStatus: 'Enabled'
  }
}
