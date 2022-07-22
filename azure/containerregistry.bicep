
param registryname string
param location string
param vnetName string
param subnetEndpointsName string

var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', vnetName)
var subnetReference = '${vnetId}/subnets/${subnetEndpointsName}'

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
