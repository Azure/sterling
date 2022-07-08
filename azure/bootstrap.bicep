param branchName string
param clientID string
@secure()
param clientSecret string
param location string
param aroClusterName string
param omsNamespace string
param domain string
param numworkers int
param OpenShiftPullSecret string
param networkSecurityGroupRules array
param jumpboxVirtualMachineName string
param db2VirtualMachineNamePrefix string
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
param mqsharename string
param loadBalancerName string
// param db2lbprivateIP string
param gatewayName string
param subnetVMName string
param subnetVMPrefix string
param subnetDataName string
param subnetDataPrefix string

param DBgeoRedundantBackup string
param DBbackupRetentionDays int
param dbStorageSizeGB int
param postgreSQLVersion string
param postgreSQLVMClass string
param postgreSQLEdition string

param devVMName string
param registryName string


@description('Which version of OMS do you want to configure? 1=Professional, 2=Enterprise')
@allowed([
  '1'
  '2'
])
param whichOMS string
@description('Do you want to create a DB2 VM (Y/N)?')
@allowed([
  'Y'
  'N'
])
param installdb2vm string
@description('Do you want a DB2 container in your cluster (for development purposes) (Y/N)?')
@allowed([
  'Y'
  'N'
])
param installdb2container string
@description('Do you want to create an MQ VM (Y/N)?')
@allowed([
  'Y'
  'N'
])
param installmqvm string
@description('Do you want an MQ container in your cluster (Y/N)?')
@allowed([
  'Y'
  'N'
])
param installmqcontainer string


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
    subnetVMName: subnetVMName
    subnetVMPrefix: subnetVMPrefix
    subnetDataPrefix: subnetDataPrefix
    subnetDataName: subnetDataName
    location: location
    NATGatewayName: gatewayName
  }
}

module aro 'aro.bicep' = {
  name: 'aro'
  scope:  resourceGroup()
  params : {
    aroname: aroClusterName
    location: location
    openshiftpullsecret: OpenShiftPullSecret
    domain: domain
    numWorkers: numworkers
    subnetControlNodeName: subnetControlNodeName
    subnetWorkerNodeName: subnetWorkerNodeName
    virtualNetworkName: vnetName
  }
  dependsOn:[
    network
  ]
}
module postgreSQL 'postgresFlexible.bicep' = {
  name: 'postgreSQL'
  scope: resourceGroup()
  params : {
    location: location
    geoRedundantBackup: DBgeoRedundantBackup
    backupRetentionDays: DBbackupRetentionDays
    dbStorageSizeGB: dbStorageSizeGB
    postgreSQLVersion: postgreSQLVersion
    postgreSQLVMClass: postgreSQLVMClass
    postgreSQLEdition: postgreSQLEdition
    adminUserName: adminUsername
    adminPassword: adminPassword
    subnetDataName: subnetDataName
    virtualNetworkName: vnetName
  }
}

module containerRegistery 'containerregistry.bicep' = {
  name: 'containerregistry'
  scope: resourceGroup()
  params : {
    subnetEndpointsName: subnetEndpointsName
    location: location
    registryname: registryName
    vnetName: vnetName
  }
  dependsOn:[
    network
  ]
}

/*
module loadbalancer 'loadbalancer.bicep' = {
  name: 'db2-lb'
  scope: resourceGroup()
  params :{
    loadbalancerName: loadBalancerName
    location: location
    virtualNetworkName: vnetName
    subnetName: subnetVMName
    db2lbprivateIP: db2lbprivateIP
  }
  dependsOn: [
    network
  ]
}
*/

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

module gateway 'gateway.bicep' = {
  name: gatewayName
  scope: resourceGroup()
  params: {
    gatewayName: gatewayName
    location: location
    virtualNetworkName: vnetName
    subnetName: subnetVMName
  }
  dependsOn: [
    network
  ]
}

module db2vm1 'db2.bicep' = if (installdb2vm == 'Y' || installdb2vm == 'y') {
  name: 'db2vm-1'
  scope: resourceGroup()
  params: {
    branchName: branchName
    location: location
    networkInterfaceName: '${db2VirtualMachineNamePrefix}-1-nic'
    networkSecurityGroupName: '${db2VirtualMachineNamePrefix}-1-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetVMName
    virtualNetworkName: vnetName
    virtualMachineName: '${db2VirtualMachineNamePrefix}-1'
    osDiskType: osDiskType
    virtualMachineSize: virtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '1'
    installerStorageAccountName: installerStorageAccountName
    installerContainerName: installerContainerName
    installerSASToken: installerSASToken
    loadBalancerName: loadBalancerName
  }
  dependsOn: [
    network
    //loadbalancer
  ]
}

/*
module db2vm2 'db2.bicep' = {
  name: 'db2vm-2'
  scope: resourceGroup()
  params: {
    location: location
    networkInterfaceName: '${db2VirtualMachineNamePrefix}-2-nic'
    networkSecurityGroupName: '${db2VirtualMachineNamePrefix}-2-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetVMName
    virtualNetworkName: vnetName
    virtualMachineName: '${db2VirtualMachineNamePrefix}-2'
    osDiskType: osDiskType
    virtualMachineSize: virtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '1'
    installerStorageAccountName: installerStorageAccountName
    installerContainerName: installerContainerName
    installerSASToken: installerSASToken
    loadBalancerName: loadBalancerName
  }
  dependsOn: [
    network
    loadbalancer
  ]
}
*/

module mqvm1 'mq.bicep' = if (installmqvm == 'Y' || installmqvm == 'y') {
  name: 'mqvm-1'
  scope: resourceGroup()
  params: {
    location: location
    networkInterfaceName: '${mqVirtualMachineName}-1-nic'
    networkSecurityGroupName: '${mqVirtualMachineName}-1-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetWorkerNodeName
    virtualNetworkName: vnetName
    virtualMachineName: '${mqVirtualMachineName}-1'
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

/*
module mqvm3 'mq.bicep' = {
  name: 'mqvm-2'
  scope: resourceGroup()
  params: {
    location: location
    networkInterfaceName: '${mqVirtualMachineName}-2-nic'
    networkSecurityGroupName: '${mqVirtualMachineName}-2-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetWorkerNodeName
    virtualNetworkName: vnetName
    virtualMachineName: '${mqVirtualMachineName}-2'
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
*/

module devvm 'devvm.bicep' = {
  name: 'devvm'
  scope: resourceGroup()
  params: {
    location: location
    networkInterfaceName: '${devVMName}-nic'
    networkSecurityGroupName: '${devVMName}-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetWorkerNodeName
    virtualNetworkName: vnetName
    virtualMachineName: devVMName
    osDiskType: osDiskType
    virtualMachineSize: virtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '1'
  }
  dependsOn: [
    network
  ]
}

module jumpbox 'jumpbox.bicep' = {
  name: 'jumpbox'
  scope: resourceGroup()
  params: {
    branchName: branchName
    location: location
    networkInterfaceName: '${jumpboxVirtualMachineName}-nic'
    networkSecurityGroupName: '${jumpboxVirtualMachineName}-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetWorkerNodeName
    virtualNetworkName: vnetName
    virtualMachineName: jumpboxVirtualMachineName
    osDiskType: osDiskType
    virtualMachineSize: virtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '1'
    installdb2container: installdb2container
    installmqcontainer: installmqcontainer
    aroName: aroClusterName
    omsNamespace: omsNamespace
    whichOMS: whichOMS
    clientID: clientID
    clientSecret: clientSecret
  }
  dependsOn: [
    network
  ]
}

//output adminUsername string = adminUsername
//output adminPassword string = adminPassword
