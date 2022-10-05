param anfName string
param location string
param db2vmprefix string
param dataVolGB int
param logVolGB int
param virtualNetworkName string
param anfSubnetName string

var dataVolBytes = dataVolGB * 1073741824
var logVolBytes = logVolGB * 1073741824
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetReference = '${vnetId}/subnets/${anfSubnetName}'

resource anfAccount 'Microsoft.NetApp/netAppAccounts@2022-03-01' = {
  name: anfName
  location: location
  properties: {
    encryption: {
      keySource: 'Microsoft.NetApp'
    }
  }
}

resource db2vm1Pool 'Microsoft.NetApp/netAppAccounts/capacityPools@2022-03-01' = {
  name: '${db2vmprefix}-1'
  location: location
  properties: {
    serviceLevel: 'Ultra'
    size: 4398046511104
    qosType: 'Auto'
    encryptionType: 'Single'
    coolAccess: false
  }
}

resource db2vm2Pool 'Microsoft.NetApp/netAppAccounts/capacityPools@2022-03-01' = {
  name: '${db2vmprefix}-2'
  location: location
  properties: {
    serviceLevel: 'Ultra'
    size: 4398046511104
    qosType: 'Auto'
    encryptionType: 'Single'
    coolAccess: false
  }
}

resource db2vm1Datavol 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2022-03-01' = {
  name: '${anfAccount.name}/${db2vm1Pool}/${db2vmprefix}-1-data'
  location: location
  properties: {
    serviceLevel: 'Ultra'
    creationToken: '${db2vmprefix}-data'
    usageThreshold: dataVolBytes
    exportPolicy: {
        rules: [
            {
                ruleIndex: 1
                unixReadOnly: false
                unixReadWrite: true
                cifs: false
                nfsv3: false
                nfsv41: true
                allowedClients: '0.0.0.0/0'
                kerberos5ReadOnly: false
                kerberos5ReadWrite: false
                kerberos5iReadOnly: false
                kerberos5iReadWrite: false
                kerberos5pReadOnly: false
                kerberos5pReadWrite: false
                hasRootAccess: true
                chownMode: 'Restricted'
            }
        ]
    }
    protocolTypes: [
        'NFSv4.1'
    ]
    subnetId: subnetReference
    networkFeatures: 'Basic'
    snapshotDirectoryVisible: true
    kerberosEnabled: false
    securityStyle: 'Unix'
    smbEncryption: false
    smbContinuouslyAvailable: false
    encryptionKeySource: 'Microsoft.NetApp'
    ldapEnabled: false
    unixPermissions: '0770'
    volumeSpecName: 'generic'
    coolAccess: false
    avsDataStore: 'Disabled'
    isDefaultQuotaEnabled: false
    enableSubvolumes: 'Disabled'
  }
}

resource db2vm1Logvol 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2022-03-01' = {
  name: '${anfAccount.name}/${db2vm1Pool}/${db2vmprefix}-1-log'
  location: location
  properties: {
    serviceLevel: 'Ultra'
    creationToken: '${db2vmprefix}-log'
    usageThreshold: logVolBytes
    exportPolicy: {
        rules: [
            {
                ruleIndex: 1
                unixReadOnly: false
                unixReadWrite: true
                cifs: false
                nfsv3: false
                nfsv41: true
                allowedClients: '0.0.0.0/0'
                kerberos5ReadOnly: false
                kerberos5ReadWrite: false
                kerberos5iReadOnly: false
                kerberos5iReadWrite: false
                kerberos5pReadOnly: false
                kerberos5pReadWrite: false
                hasRootAccess: true
                chownMode: 'Restricted'
            }
        ]
    }
    protocolTypes: [
        'NFSv4.1'
    ]
    subnetId: subnetReference
    networkFeatures: 'Basic'
    snapshotDirectoryVisible: true
    kerberosEnabled: false
    securityStyle: 'Unix'
    smbEncryption: false
    smbContinuouslyAvailable: false
    encryptionKeySource: 'Microsoft.NetApp'
    ldapEnabled: false
    unixPermissions: '0770'
    volumeSpecName: 'generic'
    coolAccess: false
    avsDataStore: 'Disabled'
    isDefaultQuotaEnabled: false
    enableSubvolumes: 'Disabled'
  }
}

resource db2vm2Datavol 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2022-03-01' = {
  name: '${anfAccount.name}/${db2vm2Pool}/${db2vmprefix}-2-data'
  location: location
  properties: {
    serviceLevel: 'Ultra'
    creationToken: '${db2vmprefix}-data'
    usageThreshold: dataVolBytes
    exportPolicy: {
        rules: [
            {
                ruleIndex: 1
                unixReadOnly: false
                unixReadWrite: true
                cifs: false
                nfsv3: false
                nfsv41: true
                allowedClients: '0.0.0.0/0'
                kerberos5ReadOnly: false
                kerberos5ReadWrite: false
                kerberos5iReadOnly: false
                kerberos5iReadWrite: false
                kerberos5pReadOnly: false
                kerberos5pReadWrite: false
                hasRootAccess: true
                chownMode: 'Restricted'
            }
        ]
    }
    protocolTypes: [
        'NFSv4.1'
    ]
    subnetId: subnetReference
    networkFeatures: 'Basic'
    snapshotDirectoryVisible: true
    kerberosEnabled: false
    securityStyle: 'Unix'
    smbEncryption: false
    smbContinuouslyAvailable: false
    encryptionKeySource: 'Microsoft.NetApp'
    ldapEnabled: false
    unixPermissions: '0770'
    volumeSpecName: 'generic'
    coolAccess: false
    avsDataStore: 'Disabled'
    isDefaultQuotaEnabled: false
    enableSubvolumes: 'Disabled'
  }
}

resource db2vm2Logvol 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2022-03-01' = {
  name: '${anfAccount.name}/${db2vm2Pool}/${db2vmprefix}-2-log'
  location: location
  properties: {
    serviceLevel: 'Ultra'
    creationToken: '${db2vmprefix}-log'
    usageThreshold: logVolBytes
    exportPolicy: {
        rules: [
            {
                ruleIndex: 1
                unixReadOnly: false
                unixReadWrite: true
                cifs: false
                nfsv3: false
                nfsv41: true
                allowedClients: '0.0.0.0/0'
                kerberos5ReadOnly: false
                kerberos5ReadWrite: false
                kerberos5iReadOnly: false
                kerberos5iReadWrite: false
                kerberos5pReadOnly: false
                kerberos5pReadWrite: false
                hasRootAccess: true
                chownMode: 'Restricted'
            }
        ]
    }
    protocolTypes: [
        'NFSv4.1'
    ]
    subnetId: subnetReference
    networkFeatures: 'Basic'
    snapshotDirectoryVisible: true
    kerberosEnabled: false
    securityStyle: 'Unix'
    smbEncryption: false
    smbContinuouslyAvailable: false
    encryptionKeySource: 'Microsoft.NetApp'
    ldapEnabled: false
    unixPermissions: '0770'
    volumeSpecName: 'generic'
    coolAccess: false
    avsDataStore: 'Disabled'
    isDefaultQuotaEnabled: false
    enableSubvolumes: 'Disabled'
  }
}
