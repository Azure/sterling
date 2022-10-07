param location string
param geoRedundantBackup string
param backupRetentionDays int
param dbStorageSizeGB int
param postgreSQLVersion string
param postgreSQLVMClass string
param postgreSQLEdition string
param adminUserName string
@secure()
param adminPassword string
param subnetDataName string
param virtualNetworkName string
param postgreSQLName string
param deployLogAnalytics string
param logAnalyticsWorkSpaceName string

var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetReference = '${vnetId}/subnets/${subnetDataName}'
//var logAnalyticsId = resourceId(resourceGroup().name, 'insights-integration/providers/Microsoft.OperationalInsights/workspaces', logAnalyticsWorkSpaceName)

resource postgresprivatednszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'omspostgres.private.postgres.database.azure.com'
  location: 'global'
  properties: {}
}

resource registry_private_zone_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${postgresprivatednszone.name}/${virtualNetworkName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource postgressql 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: postgreSQLName
  location: location
  sku: {
    name: postgreSQLVMClass
    tier: postgreSQLEdition
  }
  properties: {
    administratorLogin: adminUserName
    administratorLoginPassword: adminPassword
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    createMode: 'Create'
    highAvailability: {
      mode: 'ZoneRedundant'
    }
    network: {
      delegatedSubnetResourceId: subnetReference
      privateDnsZoneArmResourceId: postgresprivatednszone.id
    }
    storage: {
      storageSizeGB: dbStorageSizeGB
    }
    version: postgreSQLVersion
  }
  dependsOn: [
    registry_private_zone_link
  ]
}

resource pgLogAnalyticsSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployLogAnalytics  == 'Y' || deployLogAnalytics  == 'y') {
  name: postgressql.name
  scope: postgressql
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    logs: [
      {
        category: 'PostgreSQLLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: resourceId(resourceGroup().name, 'insights-integration/providers/Microsoft.OperationalInsights/workspaces', logAnalyticsWorkSpaceName)
  }
}
