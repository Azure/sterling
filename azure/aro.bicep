param aroname string
param location string
param openshiftpullsecret string
param domain string
param numWorkers int
param subnetControlNodeName string
param subnetWorkerNodeName string
param virtualNetworkName string

var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var controlSubnetId = '${vnetId}/subnets/${subnetControlNodeName}'
var workerSubnetId = '${vnetId}/subnets/${subnetWorkerNodeName}'


resource azureredhadopenshift_resource 'Microsoft.RedHatOpenShift/openShiftClusters@2022-04-01' = {
  name: aroname
  location: location
  properties: {
    clusterProfile: {
      domain: domain
      pullSecret: openshiftpullsecret
      resourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${aroname}-${domain}'
      fipsValidatedModules: 'Disabled'
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
