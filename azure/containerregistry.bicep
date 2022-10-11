
param registryname string
param location string
param vnetName string
param subnetEndpointsName string
param deployLogAnalytics string
param logAnalyticsWorkSpaceName string

var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', vnetName)
var subnetReference = '${vnetId}/subnets/${subnetEndpointsName}'
//var logAnalyticsId = resourceId(resourceGroup().name, 'insights-integration/providers/Microsoft.OperationalInsights/workspaces', logAnalyticsWorkSpaceName)

resource registry_resource 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: registryname
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    zoneRedundancy: 'Disabled'
    adminUserEnabled: true
  }
}

resource registry_private_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink${environment().suffixes.acrLoginServer}' //azurecr.io'
  location: 'global' 
  properties: {}
}


resource registry_private_zone_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${registry_private_zone.name}/${vnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource registry_private_endpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: 'oms-pe-acr'
  location: location
  properties: {
    subnet: {
      id: subnetReference
    }
    privateLinkServiceConnections: [
      {
        properties: {
          privateLinkServiceId: registry_resource.id
          groupIds: [
            'registry'
          ]
        }
        name: 'oms-pe-acr'
      }
    ]
  }
}

resource registry_private_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${registry_private_endpoint.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'registry'
        properties: {
          privateDnsZoneId:registry_private_zone.id
        }
      }
    ]
  }
}

resource pgLogAnalyticsSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployLogAnalytics  == 'Y' || deployLogAnalytics  == 'y') {
  name: registry_resource.name
  scope: registry_resource
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    logs: [
      {
        category: 'allLogs'
        enabled: true
      }
      {
        category: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: resourceId(resourceGroup().name, 'insights-integration/providers/Microsoft.OperationalInsights/workspaces', logAnalyticsWorkSpaceName)
  }
}
