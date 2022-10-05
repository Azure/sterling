@description('Name of the VNet you are deploying')
param vnetName string

@description('Total address prefix')
param vnetAddressPrefix string

@description('Control plane node prefix')
param subnetControlNodePrefix string

@description('Control plane subnet name')
param subnetControlNodeName string

@description('Worker node prefix')
param subnetWorkerNodePrefix string

@description('Worker node subnet name')
param subnetWorkerNodeName string

@description('Azure Private Endpoints subnet prefix')
param subnetEndpointsPrefix string

@description('Azure Private Endpoints subnet name')
param subnetEndpointsName string

@description('Location for all resources.')
param location string

param gatewayName string
param subnetVMName string
param subnetVMPrefix string
param subnetDataPrefix string
param subnetDataName string
param subnetANFPrefix string
param subnetANFName string

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetControlNodeName
        properties: {
          addressPrefix: subnetControlNodePrefix
        }
      }
      {
        name: subnetWorkerNodeName
        properties: {
          addressPrefix: subnetWorkerNodePrefix
        }
      }
      //{
      //  name: subnetVMName
      //  properties: {
      //    addressPrefix: subnetVMPrefix
      //    //natGateway: {
      //    //  id: resourceId('Microsoft.Network/natGateways@2021-05-01',NATGatewayName)
      //    //}
      //  }
      //}
      {
        name: subnetDataName
        properties: {
          addressPrefix: subnetDataPrefix
          delegations: [
            {
              name: 'Microsoft.DBforPostgreSQL.flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
      {
        name: subnetANFName
        properties: {
          addressPrefix: subnetANFPrefix
          delegations: [
            {
              name: 'NetAppDelegation'
              properties: {
                serviceName: 'Microsoft.Netapp/volumes'
              }
            }
          ]
        }
      }            
      {
        name: subnetEndpointsName
        properties: {
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          addressPrefix: subnetEndpointsPrefix
        }
      }
    ]
  }
}

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

resource gateway_subnet_update 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: subnetVMName
  properties: {
    addressPrefix: subnetVMPrefix
    natGateway: {
      id: resourceId('Microsoft.Network/natGateways/', gatewayName)
    }
  }
  parent: vnet
  dependsOn: [
    gateway_resource
  ]
}
