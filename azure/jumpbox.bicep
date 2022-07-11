param location string
param networkInterfaceName string
param networkSecurityGroupName string
param networkSecurityGroupRules array
param subnetName string
param virtualNetworkName string
param virtualMachineName string
param osDiskType string
param virtualMachineSize string
param adminUsername string
@secure()
param adminPassword string
param zone string
param installdb2container string
param installmqcontainer string
param aroName string
param clientID string
param clientSecret string
param omsNamespace string
param whichOMS string
param branchName string


var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/${subnetName}'
var subscriptionID = subscription().subscriptionId
var resourceGroupName = resourceGroup().name
var tenantID = tenant().tenantId
var cloudInitData = '#cloud-config\n\nruncmd:\n - export OMS_NAMESPACE=${omsNamespace}\n - export ARO_CLUSTER_NAME=${aroName}\n - export INSTALL_DB2_CONTAINER=${installdb2container}\n - export INSTALL_MQ_CONTAINER=${installmqcontainer}\n - export WHICH_OMS=${whichOMS}\n - sudo apt-get update -y \n - sudo apt-get install -y ca-certificates curl gnupg lsb-release\n - mkdir ~/.azure/\n - echo \'{"subscriptionId":"${subscriptionID}","clientId":"${clientID}","clientSecret":"${clientSecret}","tenantId":"${tenantID}","resourceGroup":"${resourceGroupName}"}\' > ~/.azure/osServicePrincipal.json\n - [ wget, -nv, "https://raw.githubusercontent.com/Azure/sterling/${branchName}/config/installers/config-aro-and-requirements.sh", -O, /tmp/config-aro-and-requirements.sh ]\n - chmod +x /tmp/config-aro-and-requirements.sh\n - sudo -E /tmp/config-aro-and-requirements.sh\n'


resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2018-10-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

// resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-11-01' = {
//   name: virtualNetworkName
//   location: location
//   properties: {
//     addressSpace: {
//       addressPrefixes: addressPrefixes
//     }
//     subnets: subnets
//   }
// }


resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '8_4'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      //customData: base64(cloudInitData)
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  zones: [
    zone
  ]
}
