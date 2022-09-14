param location string
param containerName string
param virtualNetworkName string
param subnetName string
param storageAccountName string
@secure()
param storageAccountKey string
param imageName string
param acrName string
@secure()
param acrSecret string


var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)

resource amq_azurecontainerinstance_resource 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: 'oms-active-mq'
  location: location
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          environmentVariables: [
            {
                name: 'ACTIVEMQ_TMP'
                value: '/tmp'
            }
            {
                name: 'ACTIVEMQ_OPTS_MEMORY'
                value: '-Xms4G -Xmx7G'
            }
          ]
          image: imageName
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 8
            }
          }
          volumeMounts: [
            {
              mountPath: '/opt/apache/apache-activemq-5.17.1/data'
              name: 'activemq-storage'
              readOnly: false
            }
          ]
          ports: [
            {
                protocol: 'TCP'
                port: 8161
            }
            {
                protocol: 'TCP'
                port: 61616
            }
            {
                protocol: 'TCP'
                port: 5672
            }
            {
                protocol: 'TCP'
                port: 61613
            }
            {
                protocol: 'TCP'
                port: 1883
            }
          ]
        }
      }
    ]
    imageRegistryCredentials: [
      {
        server: '${acrName}.azurecr.io'
        username: acrName
        password: acrSecret
      }
    ]
    ipAddress: {
      ports: [
            {
                protocol: 'TCP'
                port: 8161
            }
            {
                protocol: 'TCP'
                port: 61616
            }
            {
                protocol: 'TCP'
                port: 5672
            }
            {
                protocol: 'TCP'
                port: 61613
            }
            {
                protocol: 'TCP'
                port: 1883
            }
        ]
      type: 'Private'
    }
    osType: 'Linux'
    restartPolicy: 'OnFailure'
    sku: 'Standard'
    subnetIds: [
        {
            id: '${vnetId}/subnets/${subnetName}'
        }
    ]
    volumes: [
      {
        name: 'activemq-storage'
        azureFile: {
          readOnly: false
          shareName: 'activemq-storage'
          storageAccountKey: storageAccountKey
          storageAccountName: storageAccountName
        }
      }
    ]
  }
}
