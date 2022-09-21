param clusterName string
param location string
param k8sversion string
param virtualNetworkName string
param subnetName string
param serviceCidr string
param dnsServiceIP string

var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)


resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-07-02-preview' = {
  name: clusterName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Paid'
  }
  extendedLocation: {
    name: 'string'
    type: 'EdgeZone'
  }
  identity: {
        type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: k8sversion
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 1
        vmSize: 'Standard_B4ms'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        vnetSubnetID: '${vnetId}/subnets/aks'
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
        orchestratorVersion: k8sversion
        enableNodePublicIP: false
        enableCustomCATrust: false
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        enableFIPS: false
      }
      {
        name: 'mqpool'
        count: 3
        vmSize: 'Standard_B2ms'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        vnetSubnetID: '${vnetId}/subnets/aks'
        maxPods: 30
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
        orchestratorVersion: '1.23.8'
        enableNodePublicIP: false
        enableCustomCATrust: false
        mode: 'User'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        enableFIPS: false
      }
    ]
    servicePrincipalProfile: {
      clientId: 'msi'
      secret: 'string'
    }    
    nodeResourceGroup: concat('MC_OMSDEMO_', clusterName, '_eastus')
    enableRBAC: true
    networkProfile: {
      networkPluginMode: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'Standard'
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: '172.17.0.1/16'
      outboundType: 'loadBalancer'
      serviceCidrs: [
        serviceCidr
      ]
      ipFamilies: [
        'IPv4'
      ]
    }
    disableLocalAccounts: false
    storageProfile: {
      diskCSIDriver: {
          enabled: true
          version: 'v1'
      }
      fileCSIDriver: {
          enabled: true
      }
      snapshotController: {
          enabled: true
      }
    }
    oidcIssuerProfile: {
        enabled: false
    }
  }
}



resource systemPool 'Microsoft.ContainerService/managedClusters/agentPools@2022-06-02-preview' = {
  name: 'agentPool'
  parent: aksCluster
  properties: {
    count: 1
    enableAutoScaling: false
    enableCustomCATrust: false
    enableEncryptionAtHost: false
    kubeletDiskType: 'OS'
    maxPods: 110
    mode: 'System'
    orchestratorVersion: k8sversion
    osDiskSizeGB: 128
    osDiskType: 'Managed'
    osSKU: 'Ubuntu'
    osType: 'Linux'
    type: 'VirtualMachineScaleSets'
    upgradeSettings: {
      maxSurge: 'string'
    }
    vmSize: 'Standard_B4ms'
    vnetSubnetID: '${vnetId}/subnets/aks'
  }
}

resource mqPool 'Microsoft.ContainerService/managedClusters/agentPools@2022-06-02-preview' = {
  name: 'mqPool'
  parent: aksCluster
  properties: {
    count: 3
    enableAutoScaling: false
    enableCustomCATrust: false
    enableEncryptionAtHost: false
    kubeletDiskType: 'OS'
    maxPods: 30
    mode: 'System'
    orchestratorVersion: k8sversion
    osDiskSizeGB: 128
    osDiskType: 'Managed'
    osSKU: 'Ubuntu'
    osType: 'Linux'
    type: 'VirtualMachineScaleSets'
    upgradeSettings: {
      maxSurge: 'string'
    }
    vmSize: 'Standard_B4ms'
    vnetSubnetID: '${vnetId}/subnets/aks'
  }
}
