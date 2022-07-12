param location string
param geoRedundantBackup string
param backupRetentionDays int
param dbStorageSizeGB int
param postgreSQLVersion string
param postgreSQLVMClass string
param postgreSQLEdition string
param adminUserName string
param adminPassword string
param subnetDataName string
param virtualNetworkName string

var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetReference = '${vnetId}/subnets/${subnetDataName}'

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
  name: 'string'
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
