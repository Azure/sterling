param loadbalancerName string
param location string
param virtualNetworkName string
param subnetName string
param db2lbprivateIP string

var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)

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
          privateIPAddress: db2lbprivateIP
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
              id: '${vnetId}/subnets/${subnetName}'
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
                id: resourceId('Microsoft.Network/loadBalancers/probes', loadbalancerName, '${loadbalancerName}-hp')
              }
              disableOutboundSnat: true
              enableTcpReset: false
              backendAddressPools: [
                  {
                    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadbalancerName, '${loadbalancerName}-bep')
                  }
              ]
          }
      }
  ]
  }
}
