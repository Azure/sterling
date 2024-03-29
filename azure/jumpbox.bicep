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
param aroName string
param clientID string
param clientSecret string
param omsNamespace string
param whichOMS string
param branchName string
param ibmEntitlementKey string
param acrName string

var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/${subnetName}'
var subscriptionID = subscription().subscriptionId
var resourceGroupName = resourceGroup().name
var tenantID = tenant().tenantId
var cloudInitData = '#cloud-config\n\nruncmd:\n - echo "Setting environment variables..."\n - export OMS_NAMESPACE=${omsNamespace}\n - export ARO_CLUSTER=${aroName}\n - export WHICH_OMS=${whichOMS}\n - export BRANCH_NAME=${branchName}\n - export LOCATION=${location}\n - export ADMIN_PASSWORD=${adminPassword}\n - export IBM_ENTITLEMENT_KEY=${ibmEntitlementKey}\n - export ACR_NAME=${acrName}\n - mkdir ~/.azure/\n - echo \'{"subscriptionId":"${subscriptionID}","clientId":"${clientID}","clientSecret":"${clientSecret}","tenantId":"${tenantID}","resourceGroup":"${resourceGroupName}"}\' > ~/.azure/osServicePrincipal.json\n - echo "Running system update..."\n - sudo dnf update -y\n - echo "System update completed!"\n - echo "Getting latest configuration script..."\n - [ wget, -nv, "https://raw.githubusercontent.com/Azure/sterling/${branchName}/config/installers/configure-aro-and-requirements.sh", -O, /tmp/configure-aro-and-requirements.sh ]\n - chmod +x /tmp/configure-aro-and-requirements.sh\n - echo "Running configuration script..."\n - sudo -E /tmp/configure-aro-and-requirements.sh\n - echo "Getting pgsql tools/configuration script..."\n - [ wget, -nv, "https://raw.githubusercontent.com/Azure/sterling/${branchName}/config/installers/setup-pgsql-tools.sh", -O, /tmp/setup-pgsql-tools.sh ]\n - echo "Running pgsql installation script..."\n - sudo -E /tmp/setup-pgsql-tools.sh'


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
      //customData: base64(loadTextContent('cloud-init-jumpbox.yaml'))
      customData: base64(cloudInitData)
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
