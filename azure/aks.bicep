param clusterName string
param location string
param k8sversion string = '1.24.6'
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
  identity: {
        type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: k8sversion
    dnsPrefix: '${clusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 1
        vmSize: 'Standard_B4ms'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        vnetSubnetID: '${vnetId}/subnets/${subnetName}'
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
        vmSize: 'Standard_D4s_v3'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        vnetSubnetID: '${vnetId}/subnets/${subnetName}'
        maxPods: 30
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
        orchestratorVersion: k8sversion
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
    nodeResourceGroup: 'MC_${clusterName}'
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
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
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
  }
}


