@description('Which branch name do you want to pull artifact, like installer scripts, from the Azure Sterling Repository')
param branchName string
@description('Your Azure Application Registration ClientID')
param clientID string
@description('Your Azure Enterprise Application Registration ObjectID (see README for more information')
param objectID string
@description('Your Azure Application Registration Secret')
@secure()
param clientSecret string
@description('Which Azure region to deploy to')
param location string
@description('The name of your Azure Redhat OpenShift Cluster')
param aroClusterName string
@description('Your ARO Cluster Visibility (Public/Private)')
param aroVisibility string
@description('Your desired OMS Namespace in your ARO cluster')
param omsNamespace string
@description('Your ARO Domain Name (see README for more information')
param domain string
@description('Number of initial workers to deploy to your cluster')
param numworkers int
@description('Your Red Hat Pull Secret, if applicable')
param OpenShiftPullSecret string
@description('An array of NSG rules (JSON Objects) to deploy, such as inbound SSH, RDP, etc...')
param networkSecurityGroupRules array
@description('The (host)name of your "jumpbox" for securely connecting to resources')
param jumpboxVirtualMachineName string
@description('The (host)name prefix of your DB2 virtual machines, if deploying any. Multiple VMs can be deployed with -1, -2, etc for securely connecting to resources')
param db2VirtualMachineNamePrefix string
@description('The (host)name prefix of your MQ virtual machines, if deploying any. Multiple VMs can be deployed with -1, -2, etc for securely connecting to resources')
param mqVirtualMachineName string
@description('What type of storage to use for your VM OD disks (Premium LRS)')
param osDiskType string
@description('For non-specific virtual machines (such as your jumpbox), which VM SKU to use')
param virtualMachineSize string
@description('DB2 VM SKU/Size')
param db2VirtualMachineSize string
@description('MQ VM SKU/Size')
param mqVirtualMachineSize string
@description('The name of the initial (admin) user that will be created on your VMs')
param adminUsername string
@description('Your admin user password. NOTE: This password will also be the default used for other services, like DB2, PostgreSQL, etc')
@secure()
param adminPassword string
@description('The name of the virtual network to create')
param vnetName string
@description('VNET Address Space')
param vnetAddressPrefix string
@description('Control node subnet address space')
param subnetControlNodePrefix string
@description('Control node subnet name')
param subnetControlNodeName string
@description('Worker node worker address space')
param subnetWorkerNodePrefix string
@description('Worker node subnet name')
param subnetWorkerNodeName string
@description('Endpoints subnet address space')
param subnetEndpointsPrefix string
@description('Endpoints node subnet name')
param subnetEndpointsName string
@description('Bastion subnet address space')
param subnetBastionPrefix string
@description('Bastion subnet name')
param subnetBastionName string
@description('Bastion host name')
param bastionHostName string
@description('VMs subnet name')
param subnetVMName string
@description('VMs subnet address space')
param subnetVMPrefix string
@description('Data subnet name')
param subnetDataName string
@description('Data subnet address space')
param subnetDataPrefix string
//@description('If installing MQ as part of this deployment, provide the filename of the MQ tar.gz file')
//param mqInstallerArchiveName string
//@description('If installing DB2 as part of this deployment, provide the filename of the DB2 tar.gz file')
//param db2InstallerArchiveName string
//@description('If installing DB2 and/or MQ as part of this deployment, provide the the storage account name where the installers can be downloaded from')
//param installerStorageAccountName string
//@description('If installing DB2 and/or MQ as part of this deployment, provide the the storage account container name where the installers can be downloaded from')
//param installerContainerName string
//@description('If installing DB2 and/or MQ as part of this deployment, provide the the a SAS token with read and list permissions to the container with the binaries')
//@secure()
//param installerSASToken string
@description('The name of the Azure Premium File Share to create for your MQ instance')
param mqsharename string
@description('The name of the outbound NAT gateway for your virtual machines')
param gatewayName string
@description('If deploying Azure PostgreSQL Flexible Server, setting for using geo-redundnant backups or not')
param DBgeoRedundantBackup string
@description('If deploying Azure PostgreSQL Flexible Server, number of days to keep backups')
param DBbackupRetentionDays int
@description('If deploying Azure PostgreSQL Flexible Server, initial size of your database')
param dbStorageSizeGB int
@description('If deploying Azure PostgreSQL Flexible Server, the name of your PostgreSQL service')
param postgreSQLName string
@description('If deploying Azure PostgreSQL Flexible Server, the version of PostgreSQL to deploy')
param postgreSQLVersion string
@description('If deploying Azure PostgreSQL Flexible Server, the VM Size to use')
param postgreSQLVMClass string
@description('If deploying Azure PostgreSQL Flexible Server, the VM compute tier to use')
param postgreSQLEdition string
@description('Developer VM Name')
param devVMName string
@description('Azure Container Registry Name')
param registryName string
@description('Which OMS Version (image) to deploy')
param whichOMS string
//@description('If installing DB2, the name of the empty database to be created')
//param db2DatabaseName string
//@description('If installing DB2, name of the schema to be created in your new, empty database')
//param db2SchemaName string
@description('Your IBM Entitlement Key')
param ibmEntitlementKey string
@description('Storage Account Name Prefix')
param storageNamePrefix string

param loadBalancerName string
param db2lbprivateIP string
param logAnalyticsWorkspaceName string

param anfName string
param db2DataSizeGB int
param db2LogSizeGB int
param subnetANFPrefix string

@description('Do you want to deploy a Log Analytics Workspace as part of this deployment? (Y/N)?')
@allowed([
  'Y'
  'N'
])
param deployLogAnalytics string


@description('Do you want to create VMs for DB2? (Y/N)?')
@allowed([
  'Y'
  'N'
])
param installdb2vm string

@description('Do you want to create VMs for MQ (Y/N)?')
@allowed([
  'Y'
  'N'
])
param installmqvm string


@description('Do you want to create an instance of Azure PostgresSQL Flexible Server? (Y/N)?')
@allowed([
  'Y'
  'N'
])
param installPostgres string

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
    gatewayName: gatewayName
    subnetANFName: '${anfName}-vnet'
    subnetANFPrefix: subnetANFPrefix
  }
}

module aro 'aro.bicep' = {
  name: 'aro'
  scope:  resourceGroup()
  params : {
    aroname: aroClusterName
    visibility: aroVisibility
    location: location
    openshiftpullsecret: OpenShiftPullSecret
    domain: domain
    numWorkers: numworkers
    subnetControlNodeName: subnetControlNodeName
    subnetWorkerNodeName: subnetWorkerNodeName
    virtualNetworkName: vnetName
    clientID: clientID
    objectID: objectID
    clientSecret: clientSecret
  }
  dependsOn:[
    network
  ]
}
module postgreSQL 'postgresFlexible.bicep' = if (installPostgres == 'Y' || installPostgres == 'y') {
  name: 'postgreSQL'
  scope: resourceGroup()
  params : {
    location: location
    geoRedundantBackup: DBgeoRedundantBackup
    backupRetentionDays: DBbackupRetentionDays
    dbStorageSizeGB: dbStorageSizeGB
    postgreSQLName: postgreSQLName
    postgreSQLVersion: postgreSQLVersion
    postgreSQLVMClass: postgreSQLVMClass
    postgreSQLEdition: postgreSQLEdition
    adminUserName: adminUsername
    adminPassword: adminPassword
    subnetDataName: subnetDataName
    virtualNetworkName: vnetName
    deployLogAnalytics: deployLogAnalytics
    logAnalyticsWorkSpaceName: logAnalyticsWorkspaceName
  }
  dependsOn:[
    network
  ]
}

module containerRegistery 'containerregistry.bicep' = {
  name: 'containerregistry'
  scope: resourceGroup()
  params : {
    subnetEndpointsName: subnetEndpointsName
    location: location
    registryname: registryName
    vnetName: vnetName
    deployLogAnalytics: deployLogAnalytics    
    logAnalyticsWorkSpaceName: logAnalyticsWorkspaceName
  }
  dependsOn:[
    network
  ]
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
    deployLogAnalytics: deployLogAnalytics    
    logAnalyticsWorkSpaceName: logAnalyticsWorkspaceName
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

module anf 'netappfiles.bicep' = if (installdb2vm == 'Y' || installdb2vm == 'y') {
  name: 'netappfiles'
  scope: resourceGroup()
  params: {
    anfName: anfName
    location: location
    db2vmprefix: db2VirtualMachineNamePrefix
    dataVolGB: db2DataSizeGB
    logVolGB: db2LogSizeGB
    virtualNetworkName: vnetName
    anfSubnetName: '${anfName}-vnet'
  }
  dependsOn: [
    network
  ]
}

module loadbalancer 'loadbalancer.bicep' = if (installdb2vm == 'Y' || installdb2vm == 'y') {
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
    virtualMachineSize: db2VirtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '1'
    anfAccountName: anfName
    anfPoolName: '${db2VirtualMachineNamePrefix}-1'    
    //installerStorageAccountName: installerStorageAccountName
    //installerContainerName: installerContainerName
    //installerSASToken: installerSASToken
    //db2InstallerArchiveName: db2InstallerArchiveName
    loadBalancerName: loadBalancerName
    //db2DatabaseName: db2DatabaseName
    //db2SchemaName: db2SchemaName
  }
  dependsOn: [
    network
    loadbalancer
    anf
  ]
}



module db2vm2 'db2.bicep'= if (installdb2vm == 'Y' || installdb2vm == 'y') {
  name: 'db2vm-2'
  scope: resourceGroup()
  params: {
    branchName: branchName
    location: location
    networkInterfaceName: '${db2VirtualMachineNamePrefix}-2-nic'
    networkSecurityGroupName: '${db2VirtualMachineNamePrefix}-2-nsg'
    networkSecurityGroupRules:networkSecurityGroupRules
    subnetName: subnetVMName
    virtualNetworkName: vnetName
    virtualMachineName: '${db2VirtualMachineNamePrefix}-2'
    osDiskType: osDiskType
    virtualMachineSize: db2VirtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '3'
    anfAccountName: anfName
    anfPoolName: '${db2VirtualMachineNamePrefix}-2'
    //installerStorageAccountName: installerStorageAccountName
    //installerContainerName: installerContainerName
    //installerSASToken: installerSASToken
    //db2InstallerArchiveName: db2InstallerArchiveName
    loadBalancerName: loadBalancerName
    //db2DatabaseName: db2DatabaseName
    //db2SchemaName: db2SchemaName
  }
  dependsOn: [
    network
    loadbalancer
    anf
  ]
}



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
    virtualMachineSize: mqVirtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '1'
    //installerStorageAccountName: installerStorageAccountName
    //installerContainerName: installerContainerName
    //installerSASToken: installerSASToken
    storageNamePrefix: storageNamePrefix
    mqsharename: mqsharename    
    //mqInstallerArchiveName: mqInstallerArchiveName
    branchName: branchName
  }
  dependsOn: [
    network
  ]
}


module mqvm3 'mq.bicep' = if (installmqvm == 'Y' || installmqvm == 'y') {
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
    virtualMachineSize: mqVirtualMachineSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: '3'
    //installerStorageAccountName: installerStorageAccountName
    //installerContainerName: installerContainerName
    //installerSASToken: installerSASToken
    storageNamePrefix: storageNamePrefix
    mqsharename: mqsharename    
    //mqInstallerArchiveName: mqInstallerArchiveName
    branchName: branchName
  }
  dependsOn: [
    network
    mqvm1
  ]
}

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
    aroName: aroClusterName
    omsNamespace: omsNamespace
    whichOMS: whichOMS
    clientID: clientID
    clientSecret: clientSecret
    ibmEntitlementKey: ibmEntitlementKey
    acrName: registryName
  }
  dependsOn: [
    network
    aro
    containerRegistery
  ]
}

//output adminUsername string = adminUsername
//output adminPassword string = adminPassword
