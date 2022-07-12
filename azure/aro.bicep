param aroname string
param location string
param openshiftpullsecret string
param domain string
param numWorkers int
param subnetControlNodeName string
param subnetWorkerNodeName string
param virtualNetworkName string
param clientID string
param objectID string
param clientSecret string
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var controlSubnetId = '${vnetId}/subnets/${subnetControlNodeName}'
var workerSubnetId = '${vnetId}/subnets/${subnetWorkerNodeName}'


resource vnet_rbac_scope 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: virtualNetworkName
}

var aroProviderID = '50c17c64-bc11-4fdd-a339-0ecd396bf911'
var arovnetrbac_guid_sp = guid(resourceGroup().id, deployment().name, objectID)
var arovnetrbac_guid_rp = guid(resourceGroup().id, deployment().name, aroProviderID)
var contrib_role = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'

resource arovnetrbac_sp 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: arovnetrbac_guid_sp
  scope: vnet_rbac_scope
  properties: {
    roleDefinitionId: contrib_role
    principalId: objectID
  } 
}
resource arovnetrbac_rp 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: arovnetrbac_guid_rp
  scope: vnet_rbac_scope
  properties: {
    roleDefinitionId: contrib_role
    principalId: aroProviderID
  } 
}

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
      clientId: clientID
      clientSecret: clientSecret
    }
    ingressProfiles: [
      {
        name: 'default'
        visibility: 'Private'
      }
    ]

    networkProfile: {
      podCidr: '10.100.0.0/14'
      serviceCidr: '172.30.0.0/16'
    }
    
    masterProfile: {
      subnetId: controlSubnetId
      vmSize: 'Standard_D8s_v3'
      encryptionAtHost: 'Disabled'
    }
    workerProfiles: [
      {
        count: numWorkers
        diskSizeGB: 128
        name: 'worker'
        subnetId: workerSubnetId
        vmSize: 'Standard_D4s_v3'
        encryptionAtHost: 'Disabled'
      }
    ]
    apiserverProfile: {
      visibility: 'Private'
    }
  }
}
