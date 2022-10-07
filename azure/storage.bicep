@description('Prefix name of your storage accounts')
param storageNamePrefix string

@description('Location for all resources.')
param location string

// Details for private endpoints

@description('Azure Private Endpoints subnet name')
param subnetEndpointsName string

@description('Name of the VNet you are deploying')
param vnetName string

param mqsharename string

param logAnalyticsWorkSpaceName string
param deployLogAnalytics string

// Some variables to grab the details we need
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', vnetName)
var subnetReference = '${vnetId}/subnets/${subnetEndpointsName}'
//var logAnalyticsId = resourceId(resourceGroup().name, 'insights-integration/providers/Microsoft.OperationalInsights/workspaces', logAnalyticsWorkSpaceName)

// More performant and lower latency storage for databases, Kafka and 
// other resources.
resource storage_premium 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: '${storageNamePrefix}prm'
  location: location
  kind: 'FileStorage'
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    allowSharedKeyAccess: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: false
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
  }
}

// Standard storage account for fileshares that are less performance hungry 
// and smaller. Costs for standard storage accounts are lower and there is 
// no minimum share size of 100GiB.
/*
resource storage_standard 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: take('${storageNamePrefix}std${uniqueString(resourceGroup().id)}', 24)
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }
  properties: {
    allowSharedKeyAccess: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
  }
}
*/

// Endpoints

resource files_private_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.${environment().suffixes.storage}' //core.windows.net'
  location: 'global' 
  properties: {}
}

resource files_private_zone_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${files_private_zone.name}/${vnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Premium endpoint 

resource premium_private_endpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: 'oms-pe-premiumstorage'
  location: location
  properties: {
    subnet: {
      id: subnetReference
    }
    privateLinkServiceConnections: [
      {
        properties: {
          privateLinkServiceId: storage_premium.id
          groupIds: [
            'file'
          ]
        }
        name: 'oms-pe-premiumstorage'
      }
    ]
  }
}

resource files_private_zone_group_premium 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${premium_private_endpoint.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'premium'
        properties: {
          privateDnsZoneId: files_private_zone.id
        }
      }
    ]
  }
}

// Standard endpoint
/*
resource standard_private_endpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: 'standardstorage'
  location: location
  properties: {
    subnet: {
      id: subnetReference
    }
    privateLinkServiceConnections: [
      {
        properties: {
          privateLinkServiceId: storage_standard.id
          groupIds: [
            'file'
          ]
        }
        name: 'StandardFilesEndpoint'
      }
    ]
  }
}
resource files_private_zone_group_standard 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${standard_private_endpoint.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'standard'
        properties: {
          privateDnsZoneId: files_private_zone.id
        }
      }
    ]
  }
}
*/

resource mq_file_services 'Microsoft.Storage/storageAccounts/fileServices@2021-08-01' = {
  name: 'default'
  parent: storage_premium
  properties: {
    cors: {
      corsRules: []
    }
    protocolSettings: {
      smb: {
        multichannel: {
          enabled: false
        }
      }
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource mq_file_share 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = {
  name: mqsharename
  parent: mq_file_services
  properties: {
    accessTier: 'Premium'
    enabledProtocols: 'NFS'
    metadata: {}
    rootSquash: 'NoRootSquash'
    shareQuota: 100
  }
}


resource storageLogAnalyticsSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployLogAnalytics  == 'Y' || deployLogAnalytics  == 'y') {
  name: storage_premium.name
  scope: storage_premium 
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    logs: [
      {
        category: 'StorageDelete'
        enabled: true
      }
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }

    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    workspaceId: resourceId(resourceGroup().name, 'insights-integration/providers/Microsoft.OperationalInsights/workspaces', logAnalyticsWorkSpaceName)
  }
}
