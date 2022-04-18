param loadbalancerName string
param location string
param db2vmName string
param virtualNetworkName string
param subnetName string

var vm1nicId = resourceId(resourceGroup().name, 'Microsoft.Network/networkInterfaces', '${db2vmName}-z1-nic')
var vm2nicId = resourceId(resourceGroup().name, 'Microsoft.Network/networkInterfaces', '${db2vmName}-z3-nic')
var vnetID = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)

resource loadbalancer_resource 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: loadbalancerName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: '${loadbalancerName}-feip'
        properties: {
            privateIPAddressVersion: 'IPv4'
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
                id: '${vnetID}/subnets/${subnetName}'
            }      
        }
      }
    ]
    backendAddressPools: [
      {
        name: '${loadbalancerName}-bep'
      }
    ]
    probes: [
      {
          name: '${loadbalancerName}-hp'
          properties: {
              protocol: 'Tcp'
              port: 62500
              requestPath: null
              intervalInSeconds: 5
              numberOfProbes: 2
          }
      }
    ]
    loadBalancingRules: [
      {
          name: '${loadbalancerName}-lbr'
          properties: {
              frontendIPConfiguration: {
                id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadbalancerName, '${loadbalancerName}-feip')
              }
              frontendPort: 25010
              backendPort: 25010
              enableFloatingIP: true
              idleTimeoutInMinutes: 30
              protocol: 'Tcp'
              loadDistribution: 'Default'
              probe: {
                id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadbalancerName, '${loadbalancerName}-hp')
              }
              disableOutboundSnat: true
              enableTcpReset: false
              backendAddressPools: [
                  {
                    id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadbalancerName, '${loadbalancerName}-bep')
                  }
              ]
          }
      }
  ]
  }
}

/*
resource bepvm1_nic_resource 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${db2vmName}-z1-nic'
  properties: {
    ipConfigurations: [
      {
        id: concat(resourceId('Microsoft.Network/networkInterfaces', '${db2vmName}-z1-nic'), 'ipConfigurations/ipconfig1')
        properties: {
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadbalancerName, '${loadbalancerName}-bep')
            }
          ]
        }
      }
    ]
  }
}

resource bepvm2_nic_resource 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${db2vmName}-z3-nic'
  properties: {
    ipConfigurations: [
      {
        id: concat(resourceId('Microsoft.Network/networkInterfaces', '${db2vmName}-z3-nic'), 'ipConfigurations/ipconfig1')
        properties: {
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadbalancerName, '${loadbalancerName}-bep')
            }
          ]
        }
      }
    ]
  }
}
*/

resource temp_bepvm2_nic_resource 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${db2vmName}-nic'
  properties: {
    ipConfigurations: [
      {
        id: concat(resourceId('Microsoft.Network/networkInterfaces', '${db2vmName}-nic'), 'ipConfigurations/ipconfig1')
        properties: {
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadbalancerName, '${loadbalancerName}-bep')
            }
          ]
        }
      }
    ]
  }
}
