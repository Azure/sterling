param location string
param networkSecurityGroupRules array
param jumpboxVirtualMachineName string
param db2VirtualMachineName string
param mqVirtualMachineName string
param osDiskType string
param virtualMachineSize string
param adminUsername string
@secure()
param adminPassword string
param vnetName string
param vnetAddressPrefix string
param subnetControlNodePrefix string
param subnetControlNodeName string
param subnetWorkerNodePrefix string
param subnetWorkerNodeName string
param subnetEndpointsPrefix string
param subnetEndpointsName string
param storageNamePrefix string
param subnetBastionPrefix string
param subnetBastionName string
param bastionHostName string
param installerStorageAccountName string
param installerContainerName string
@secure()
param installerSASToken string
@secure()
param mqsharename string


module network 'networking.bicep' = {
  name: 'VNet'
  scope: resourceGroup()
  params: {
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnetControlNodePrefix: subnetControlNodePrefix
    subnetControlNodeName: subnetControlNodeName
    subnetWorkerNodePrefix: subnetWorkerNodePrefix
    subnetWorkerNodeName: subnetWorkerNodeName
    subnetEndpointsPrefix: subnetEndpointsPrefix
    subnetEndpointsName: subnetEndpointsName
    location: location
  }
}

module premiumStorage 'storage.bicep' = {
  name: 'privateStorage'
  scope: resourceGroup()
  params: {
    storageNamePrefix: storageNamePrefix
    subnetEndpointsName: subnetEndpointsName
    vnetName: vnetName
    location: location
    mqsharename: mqsharename
  }
  dependsOn:[
    network
  ]
  
}

module bastionHost 'bastion.bicep' = {
  name: 'bastionHost'
  scope: resourceGroup()
  params: {
    subnetBastionName: subnetBastionName
    subnetBastionPrefix: subnetBastionPrefix
    bastionHostName: bastionHostName
    vnetName: vnetName
   location: location
  }
  dependsOn:[
    network
  ]
}


module db2vm_1 'db2.bicep' = {
  name: 'db2vm-1'
  scope: resourceGroup()
  params: {
    location: location
    networkInterfaceName: '${db2VirtualMachineName}-z1-nic'
    networkSecurityGroupName: '${db2VirtualMachineName}-z1-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetWorkerNodeName
    virtualNetworkName: vnetName
    virtualMachineName: db2VirtualMachineName
    osDiskType: osDiskType
    virtualMachineSize: virtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '1'
    installerStorageAccountName: installerStorageAccountName
    installerContainerName: installerContainerName
    installerSASToken: installerSASToken
  }
  dependsOn: [
    network
  ]
}

module db2vm_2 'db2.bicep' = {
  name: 'db2vm-2'
  scope: resourceGroup()
  params: {
    location: location
    networkInterfaceName: '${db2VirtualMachineName}-z3-nic'
    networkSecurityGroupName: '${db2VirtualMachineName}-z3-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetWorkerNodeName
    virtualNetworkName: vnetName
    virtualMachineName: db2VirtualMachineName
    osDiskType: osDiskType
    virtualMachineSize: virtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '3'
    installerStorageAccountName: installerStorageAccountName
    installerContainerName: installerContainerName
    installerSASToken: installerSASToken
  }
  dependsOn: [
    network
  ]
}

module mqvm1 'mq.bicep' = {
  name: 'mqvm-1'
  scope: resourceGroup()
  params: {
    location: location
    networkInterfaceName: '${mqVirtualMachineName}-z1-nic'
    networkSecurityGroupName: '${mqVirtualMachineName}-z1-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetWorkerNodeName
    virtualNetworkName: vnetName
    virtualMachineName: '${mqVirtualMachineName}-z1'
    osDiskType: osDiskType
    virtualMachineSize: virtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '1'
    installerStorageAccountName: installerStorageAccountName
    installerContainerName: installerContainerName
    installerSASToken: installerSASToken
    storageNamePrefix: storageNamePrefix
    mqsharename: mqsharename    
  }
  dependsOn: [
    network
  ]
}

module mqvm3 'mq.bicep' = {
  name: 'mqvm-2'
  scope: resourceGroup()
  params: {
    location: location
    networkInterfaceName: '${mqVirtualMachineName}-z3-nic'
    networkSecurityGroupName: '${mqVirtualMachineName}-z3-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetWorkerNodeName
    virtualNetworkName: vnetName
    virtualMachineName: '${mqVirtualMachineName}-z3'
    osDiskType: osDiskType
    virtualMachineSize: virtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '3'
    installerStorageAccountName: installerStorageAccountName
    installerContainerName: installerContainerName
    installerSASToken: installerSASToken
    storageNamePrefix: storageNamePrefix
    mqsharename: mqsharename
  }
  dependsOn: [
    network
    mqvm1
  ]
}

//output adminUsername string = adminUsername
//output adminPassword string = adminPassword
