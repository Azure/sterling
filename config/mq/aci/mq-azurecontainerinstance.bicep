param location string
param containerName string
param virtualNetworkName string
param subnetName string
param imageName string
param acrName string
@secure()
param acrSecret string


var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)

resource amq_azurecontainerinstance_resource 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: 'oms-mq'
  location: location
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          environmentVariables: [
            {
                name: 'LICENSE'
                value: 'accept'
            }
            {
                name: 'MQ_QMGR_NAME'
                value: 'oms'
            }
          ]
          image: imageName
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 8
            }
          }
          ports: [
            {
                protocol: 'TCP'
                port: 1414
            }
            {
                protocol: 'TCP'
                port: 9443
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
                port: 1414
            }
            {
                protocol: 'TCP'
                port: 9443
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
  }
}
