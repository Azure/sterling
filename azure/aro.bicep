param name string
param location string
param openshiftpullsecret string
param domain string
param numWorkers int
param subnetControlNodeName string
param subnetWorkerNodeName string
param virtualNetworkName string


//var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)

var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var controlSubnetId = '${vnetId}/subnets/${subnetControlNodeName}'
var workerSubnetId = '${vnetId}/subnets/${subnetWorkerNodeName}'
//var controlSubnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', subnetControlNodeName)
//var workerSubnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', subnetWorkerNodeName)

resource azureredhadopenshift_resource 'Microsoft.RedHatOpenShift/openShiftClusters@2022-04-01' = {
  name: name
  location: location
  properties: {
    clusterProfile: {
      domain: domain
      pullSecret: openshiftpullsecret
      resourceGroupId: "[concat('/subscriptions/', subscription().subscriptionId,'/resourceGroups/aro-', parameters('domain'))]",
    }
    servicePrincipalProfile: {
      clientId: 'string'
      clientSecret: 'string'
    }
    ingressProfiles: [
      {
        name: 'default'
        visibility: 'Public'
      }
    ]

    networkProfile: {
      podCidr: '10.100.0.0/14'
      serviceCidr: '172.30.0.0/16'
    }
    
    masterProfile: {
      subnetId: controlSubnetId
      vmSize: 'Standard_D8s_v3'
    }

    workerProfiles: [
      {
        count: numWorkers
        diskSizeGB: 128
        name: 'worker'
        subnetId: workerSubnetId
        vmSize: 'Standard_D4s_v3'
      }
    ]
  }
}
