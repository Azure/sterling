param gatewayName string
param location string
param virtualNetworkName string
param subnetName string

resource gateway_public_ip_resource 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: '${gatewayName}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }  
}

resource gateway_resource 'Microsoft.Network/natGateways@2019-09-01' = {
  name: gatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: resourceId('Microsoft.Network/publicIpAddresses/', '${gatewayName}-pip')
      }
    ]
  }
  dependsOn: [
    gateway_public_ip_resource
  ]
}

/*
resource VNET 'Microsoft.Network/virtualNetworks@2021-02-01' existing  = {
  name: virtualNetworkName
}

resource Subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: subnetName
  parent: VNET
}

var existingServiceEndpoints = Subnet.properties.serviceEndpoints
var existingAddressPrefix = Subnet.properties.addressPrefix
var existingNSG = Subnet.properties.networkSecurityGroup

resource gateway_subnet_update 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: subnetName
  properties: {
    networkSecurityGroup: existingNSG
    serviceEndpoints: existingServiceEndpoints
    addressPrefix: existingAddressPrefix
    natGateway: {
      id: resourceId('Microsoft.Network/natGateways/', gatewayName)
    }
  }
  parent: VNET
  dependsOn: [
    gateway_resource
  ]
}
*/
